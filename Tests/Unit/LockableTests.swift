import Quick
import Nimble

@testable import RAnalytics

class LockableTests: QuickSpec {

    override func spec() {

        describe("Lockable object") {
            var lockableObject: LockableObject<[Int]>!

            func appendResource(_ number: Int) {
                var resource = lockableObject.get()
                resource.append(number)
                lockableObject.set(value: resource)
            }

            beforeEach {
                lockableObject = LockableObject([Int]())
                appendResource(1)
                appendResource(2)
            }

            afterEach {
                lockableObject.unlock()
            }

            it("will lock provided resources when lock is called on them") {
                DispatchQueue.global().asyncAfter(deadline: .now() + 1, execute: {
                    appendResource(4)
                })

                lockableObject.lock()
                expect(lockableObject.get()).toAfterTimeout(equal([1, 2]), timeout: 2.0)
            }

            it("will unlock provided resources when unlock is called on them") {
                DispatchQueue.global().asyncAfter(deadline: .now() + 1, execute: {
                    appendResource(4)
                })

                lockableObject.lock()
                sleep(2)
                appendResource(3)
                lockableObject.unlock()

                expect(lockableObject.get()).toEventually(equal([1, 2, 3, 4]))
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
