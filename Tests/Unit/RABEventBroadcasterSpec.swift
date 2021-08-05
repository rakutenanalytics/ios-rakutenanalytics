import Quick
import Nimble
import RAnalyticsBroadcast
@testable import RAnalytics

// MARK: - RABEventBroadcasterSpec

final class RABEventBroadcasterSpec: QuickSpec {
    override func spec() {
        describe("sendEventName") {
            var dependenciesContainer: SimpleContainerMock!
            beforeEach {
                dependenciesContainer = SimpleContainerMock()
                dependenciesContainer.tracker = AnalyticsTrackerMock()
            }
            it("should track AnalyticsManager.Event.Name.custom with eventName and eventData when an event is broadcasted with data") {
                let externalCollector = RAnalyticsExternalCollector(dependenciesContainer: dependenciesContainer)
                let tracker = (dependenciesContainer.tracker as? AnalyticsTrackerMock)

                expect(externalCollector).toNot(beNil())
                expect(tracker?.eventName).toEventually(beNil())
                expect(tracker?.params).toEventually(beNil())

                RABEventBroadcaster.sendEventName("blah", dataObject: ["foo": "bar"])

                expect(tracker?.eventName).toEventually(equal(AnalyticsManager.Event.Name.custom))
                expect(tracker?.params?["eventName"] as? String).toEventually(equal("blah"))
                expect(tracker?.params?["eventData"] as? [String: String]).toEventually(equal(["foo": "bar"]))
            }
            it("should track AnalyticsManager.Event.Name.custom with eventName and no eventData when an event is broadcasted without data") {
                let externalCollector = RAnalyticsExternalCollector(dependenciesContainer: dependenciesContainer)
                let tracker = (dependenciesContainer.tracker as? AnalyticsTrackerMock)

                expect(externalCollector).toNot(beNil())
                expect(tracker?.eventName).toEventually(beNil())
                expect(tracker?.params).toEventually(beNil())

                RABEventBroadcaster.sendEventName("blah", dataObject: nil)

                expect(tracker?.eventName).toEventually(equal(AnalyticsManager.Event.Name.custom))
                expect(tracker?.params?["eventName"] as? String).toEventually(equal("blah"))
                expect(tracker?.params?["eventData"]).toEventually(beNil())
            }
        }
    }
}
