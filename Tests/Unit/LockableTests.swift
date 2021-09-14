import Quick
import Nimble

@testable import RAnalytics

private class LockableTestObject: Lockable {
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

final class LockableTests: QuickSpec {

    override func spec() {

        describe("Lockable object") {
            var lockableObject: LockableTestObject!
            let backgroundThread = DispatchQueue(label: "LockableSpec.BackgroundThread")

            beforeEach {
                lockableObject?.unlockResources()
                lockableObject = LockableTestObject()
                lockableObject.append(1)
                lockableObject.append(2)
            }

            it("will lock provided resources when lock is called on them") {
                backgroundThread.asyncAfter(deadline: .now() + 1, execute: {
                    lockableObject.append(4)
                })

                lockableObject.lockResources()
                expect(lockableObject.resource.get()).toAfterTimeout(equal([1, 2]), timeout: 2.0)
            }

            it("will unlock provided resources when unlock is called on them") {
                backgroundThread.asyncAfter(deadline: .now() + 1, execute: {
                    lockableObject.append(4)
                })

                lockableObject.lockResources()
                sleep(2)
                lockableObject.append(3)
                lockableObject.unlockResources()

                expect(lockableObject.resource.get()).toEventually(equal([1, 2, 3, 4]))
            }

            it("will make other threads wait to execute lock() call") {
                let resource = lockableObject.resource
                resource.lock() // 1. thread A - lock
                DispatchQueue.global().async {
                    resource.lock() // 2. thread B - wait for their lock / 6. thread B - lock the resource again
                    expect(resource.get()).to(equal([1])) // 7. check the value set by thread A
                }
                expect(resource.isLocked).to(beTrue()) // 3. check if thread A locked the resource
                resource.set(value: [1]) // 4. thread A - modify the resource
                resource.unlock() // 5. thread A - unlock
                expect(resource.isLocked).toAfterTimeout(beTrue()) // 8. confirm thread B executed the lock
            }

            it("will keep the lock if number of unlock() calls did not match the number of lock() calls") {
                let resource = lockableObject.resource
                resource.lock()
                resource.lock()
                expect(resource.isLocked).to(beTrue())
                resource.unlock()
                expect(resource.isLocked).to(beTrue())
            }

            it("will not crash when unlock() was called more times than lock()") {
                let resource = lockableObject.resource
                resource.lock()
                expect(resource.isLocked).to(beTrue())
                resource.unlock()
                resource.unlock()
                expect(resource.isLocked).to(beFalse())
            }

            it("will not crash when lock() and unlock() are called in multiple threads") {
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
                expect(resource.isLocked).to(beFalse())
            }

            it("will not crash or unlock the resource when unlock() was called from some other thread") {
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
                expect(resource.lockCount).to(equal(1)) // ensure that lockCount doesn't change because of backgroundThread calls
                dispatchGroup.wait()
                resource.unlock()
                expect(resource.isLocked).to(beFalse())
            }

            it("will unlock the thread if the resource was deallocated") {
                var resource: LockableObject? = LockableObject([Int]())
                resource?.lock()
                resource?.lock()
                waitUntil { done in
                    DispatchQueue.global().async {
                        expect(resource?.get()).to(beNil())
                        done()
                    }
                    resource = nil
                }
            }
        }

        describe("Synchronizable") {

            context("when calling `withSynchronized`") {

                let objects = [LockableObject(1), LockableObject(2), LockableObject(3)]
                let dispatchQueue = DispatchQueue.global(qos: .default)

                for _ in 1...50 {
                    it("will lock all given Lockable objects") {

                        let objects = [LockableObject(1), LockableObject(2), LockableObject(3)]

                        dispatchQueue.async {
                            Synchronizable.withSynchronized(objects) {
                                expect(objects).to(allPass({ $0?.isLocked == true }))
                                usleep(useconds_t(0.2 * Double(USEC_PER_SEC)))
                            }
                        }

                        expect(objects).toEventually(allPass({ $0?.isLocked == true }))
                    }

                    it("will unlock all given Lockable objects after closure is finished") {
                        dispatchQueue.async {
                            Synchronizable.withSynchronized(objects) {
                                usleep(useconds_t(0.2 * Double(USEC_PER_SEC)))
                            }
                        }

                        expect(objects).toEventually(allPass({ $0?.isLocked == true })) // wait for lock
                        expect(objects).toEventually(allPass({ $0?.isLocked == false }))
                    }
                }
            }
        }
    }
}
