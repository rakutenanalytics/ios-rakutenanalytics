import Quick
import Nimble
@testable import RAnalytics

final class GeoPollerSpec: QuickSpec {

    override func spec() {
        describe("Poller functions") {

            it("creates timer for location collection with time interval equal to delay param passed in function call") {
                let runLoop: MockRunLoop = MockRunLoop()
                let poller = GeoPoller(runLoop: runLoop)

                poller.pollLocationCollection(delay: 10.5, repeats: true) { }

                expect(runLoop.addedTimer?.timeInterval).toEventually(equal(10.5))
            }

            it("should invalidate timer for location collection on calling invalidateLocationCollectionPoller()") {
                let runLoop: MockRunLoop = MockRunLoop()
                let poller = GeoPoller(runLoop: runLoop)
                poller.pollLocationCollection(delay: 10.5, repeats: true) { }

                poller.invalidateLocationCollectionPoller()

                expect(runLoop.addedTimer?.isValid).toEventually(beFalse())
            }

            it("when repeats set as true, executes action closure in specified intervals") {
                var actionCalled = 0
                let poller = GeoPoller()

                poller.pollLocationCollection(delay: 0.5, repeats: true) {
                    actionCalled += 1
                }
                expect(actionCalled).toEventually(equal(2), timeout: .seconds(2))
            }

            it("when repeats set as false, executes action closure exactly once") {
                var actionCalled = 0
                let poller = GeoPoller()

                poller.pollLocationCollection(delay: 0.5, repeats: false) {
                    actionCalled += 1
                }
                expect(actionCalled).toEventually(equal(1), timeout: .seconds(1))
            }
        }
    }
}
