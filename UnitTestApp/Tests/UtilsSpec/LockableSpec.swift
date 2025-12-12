import Foundation
import Testing
@preconcurrency @testable import RakutenAnalytics
#if canImport(RAnalyticsTestHelpers)
import RAnalyticsTestHelpers
#endif

private class LockableTestObject: Lockable, @unchecked Sendable {
    var resourcesToLock: [LockableResource] {
        return [resource]
    }
    let resource = LockableObject([Int]())

    func append(_ number: Int) {
        var resource = self.resource.get()
        resource.append(number)
        self.resource.set(value: resource)
    }

    func lockResources() {
        resourcesToLock.forEach { $0.lock() }
    }

    func unlockResources() {
        resourcesToLock.forEach { $0.unlock() }
    }
}

@Suite("Lockable object")
struct LockableSpec {
    let backgroundThread = DispatchQueue(label: "LockableSpec.BackgroundThread")
    
    fileprivate func createLockableObject() -> LockableTestObject {
        let lockableObject = LockableTestObject()
        lockableObject.append(1)
        lockableObject.append(2)
        return lockableObject
    }
    
    @Test("will lock provided resources when lock is called on them")
    func testLockResources() async throws {
        let lockableObject = createLockableObject()
        
        backgroundThread.asyncAfter(deadline: .now() + 1) {
            lockableObject.append(4)
        }
        
        lockableObject.lockResources()
        defer {
            lockableObject.unlockResources()
        }
        
        try await TestingHelpers.performAsyncTest(timeForExecution: 1.0, timeout: 2.0) {
            #expect(lockableObject.resource.get() == [1, 2])
        }
    }
    
    @Test("will unlock provided resources when unlock is called on them")
    func testUnlockResources() async throws {
        let lockableObject = createLockableObject()
        
        backgroundThread.asyncAfter(deadline: .now() + 1) {
            lockableObject.append(4)
        }
        
        lockableObject.lockResources()
        sleep(2)
        lockableObject.append(3)
        lockableObject.unlockResources()
        
        try await TestingHelpers.eventually(timeout: 2.0) {
            lockableObject.resource.get() == [1, 2, 3, 4]
        }
        #expect(lockableObject.resource.get() == [1, 2, 3, 4])
    }
    
    @Test("will make other threads wait to execute lock() call")
    func testOtherThreadsWaitForLock() async throws {
        let lockableObject = createLockableObject()
        let resource = lockableObject.resource
        
        resource.lock() // 1. thread A - lock
        
        let backgroundTask = Task {
            await withCheckedContinuation { continuation in
                DispatchQueue.global().async { [resource] in
                    resource.lock() // 2. thread B - wait for their lock / 6. thread B - lock the resource again
                    #expect(resource.get() == [1]) // 7. check the value set by thread A
                    continuation.resume()
                }
            }
        }
        
        #expect(resource.isLocked == true) // 3. check if thread A locked the resource
        resource.set(value: [1]) // 4. thread A - modify the resource
        resource.unlock() // 5. thread A - unlock
        
        try await TestingHelpers.performAsyncTest(timeForExecution: 1.0, timeout: 1.0) { [resource] in
            #expect(resource.isLocked == true) // 8. confirm thread B executed the lock
        }
        
        await backgroundTask.value
    }
    
    @Test("will keep the lock if number of unlock() calls did not match the number of lock() calls")
    func testLockCountMismatch() {
        let lockableObject = createLockableObject()
        let resource = lockableObject.resource
        
        resource.lock()
        resource.lock()
        #expect(resource.isLocked == true)
        resource.unlock()
        #expect(resource.isLocked == true)
    }
    
    @Test("will not crash when unlock() was called more times than lock()")
    func testUnlockCalledMoreThanLock() {
        let lockableObject = createLockableObject()
        let resource = lockableObject.resource
        
        resource.lock()
        #expect(resource.isLocked == true)
        resource.unlock()
        resource.unlock()
        #expect(resource.isLocked == false)
    }
    
    @Test("will not crash when lock() and unlock() are called in multiple threads")
    func testConcurrentLockUnlock() {
        let lockableObject = createLockableObject()
        let resource = lockableObject.resource
        let iterations = 100_000
        let dispatchGroup = DispatchGroup()
        dispatchGroup.enter()
        
        backgroundThread.async {
            for _ in 1...iterations {
                resource.lock()
                resource.unlock()
            }
            dispatchGroup.leave()
        }
        for _ in 1...iterations {
            resource.lock()
            resource.unlock()
        }
        dispatchGroup.wait()
        #expect(resource.isLocked == false)
    }
    
    @Test("will not crash or unlock the resource when unlock() was called from some other thread")
    func testUnlockFromOtherThread() {
        let lockableObject = createLockableObject()
        let resource = lockableObject.resource
        let iterations = 100_000
        let dispatchGroup = DispatchGroup()
        dispatchGroup.enter()
        
        for _ in 1...iterations {
            resource.lock()
        }
        backgroundThread.async {
            for _ in 1...iterations {
                resource.unlock() // this unlock has no effect as it's not called from locking thread
            }
            dispatchGroup.leave()
        }
        for _ in 1...iterations-1 {
            resource.unlock()
        }
        #expect(resource.lockCount == 1) // ensure that lockCount doesn't change because of backgroundThread calls
        dispatchGroup.wait()
        resource.unlock()
        #expect(resource.isLocked == false)
    }
    
    @Test("will unlock the thread if the resource was deallocated")
    func testUnlockOnDeallocation() async throws {
        final class ResourceHolder: @unchecked Sendable {
            var resource: LockableObject<[Int]>?
            init(_ resource: LockableObject<[Int]>) {
                self.resource = resource
            }
        }
        
        let holder = ResourceHolder(LockableObject([Int]()))
        holder.resource?.lock()
        
        DispatchQueue.global().async {
            holder.resource = nil
        }
        
        try await TestingHelpers.eventually(timeout: 2.0) {
            holder.resource == nil
        }
        #expect(holder.resource == nil)
    }
}
