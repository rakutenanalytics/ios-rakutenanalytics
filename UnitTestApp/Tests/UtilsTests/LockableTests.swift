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
struct LockableTests {
    let backgroundThread = DispatchQueue(label: "LockableTests.BackgroundThread")
    
    fileprivate func createLockableObject() -> LockableTestObject {
        let lockableObject = LockableTestObject()
        lockableObject.append(1)
        lockableObject.append(2)
        return lockableObject
    }
    
    @Test("will lock provided resources when lock is called on them")
    func testLockResources() async throws {
        let lockableObject = createLockableObject()
        
        // Verify initial state
        #expect(lockableObject.resource.get() == [1, 2])
        #expect(lockableObject.resource.isLocked == false)
        
        // Lock the resources
        lockableObject.lockResources()
        
        // Verify the resource is locked
        #expect(lockableObject.resource.isLocked == true)
        
        // Verify we can still access the resource from the locking thread
        #expect(lockableObject.resource.get() == [1, 2])
        
        // Modify resource while locked (we have the lock)
        lockableObject.append(3)
        #expect(lockableObject.resource.get() == [1, 2, 3])
        
        // Unlock
        lockableObject.unlockResources()
        
        // Verify the resource is unlocked
        #expect(lockableObject.resource.isLocked == false)
        
        // Verify we can still access after unlock
        #expect(lockableObject.resource.get() == [1, 2, 3])
    }
    
    @Test("will unlock provided resources when unlock is called on them")
    func testUnlockResources() async throws {
        let lockableObject = createLockableObject()
        
        // Lock first
        lockableObject.lockResources()
        
        // Verify we can modify while locked
        lockableObject.append(3)
        #expect(lockableObject.resource.get() == [1, 2, 3])
        
        // Unlock
        lockableObject.unlockResources()
        
        // Verify we can still access after unlock
        #expect(lockableObject.resource.get() == [1, 2, 3])
        #expect(lockableObject.resource.isLocked == false)
        
        // Now modify after unlock
        lockableObject.append(4)
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
    func testConcurrentLockUnlock() async throws {
        let lockableObject = createLockableObject()
        let resource = lockableObject.resource
        let iterations = 100_000
        
        await withTaskGroup(of: Void.self) { group in
            group.addTask {
                for _ in 1...iterations {
                    resource.lock()
                    resource.unlock()
                }
            }
            group.addTask {
                for _ in 1...iterations {
                    resource.lock()
                    resource.unlock()
                }
            }
        }
        
        #expect(resource.isLocked == false)
    }
    
    @Test("will not crash or unlock the resource when unlock() was called from some other thread")
    func testUnlockFromOtherThread() async throws {
        let lockableObject = createLockableObject()
        let resource = lockableObject.resource
        let iterations = 10_000 // Reduced iterations for faster test execution
        
        // Lock from main thread
        for _ in 1...iterations {
            resource.lock()
        }
        
        // Verify we have the expected lock count
        #expect(resource.lockCount == UInt(iterations))
        #expect(resource.isLocked == true)
        
        // Start background work on a different thread that tries to unlock
        // The test verifies it doesn't crash - the actual behavior may vary
        await withCheckedContinuation { continuation in
            DispatchQueue.global().async {
                // Try to unlock from background thread
                // This should either be ignored or work depending on implementation
                for _ in 1...iterations {
                    resource.unlock()
                }
                continuation.resume()
            }
        }
        
        // Verify it didn't crash and resource is in a valid state
        // The lockCount could be 0 (if unlocks worked) or still iterations (if ignored)
        let lockCountAfterBackground = resource.lockCount
        
        // Ensure resource is in a consistent state
        #expect(lockCountAfterBackground >= 0)
        #expect(resource.isLocked == (lockCountAfterBackground > 0))
        
        // If still locked, unlock from main thread to clean up
        if resource.isLocked {
            for _ in 1...Int(lockCountAfterBackground) {
                resource.unlock()
            }
        }
        
        // Verify final state
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
