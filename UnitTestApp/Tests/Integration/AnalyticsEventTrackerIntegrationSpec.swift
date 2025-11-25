import Foundation
import Quick
import Nimble
@testable import RakutenAnalytics
#if canImport(RAnalyticsTestHelpers)
import RAnalyticsTestHelpers
#endif

final class AnalyticsEventTrackerIntegrationSpec: QuickSpec {

    override class func spec() {
        describe("AnalyticsEventTrackerIntegration") {
            let pushEventHandler: PushEventHandler = {
                return PushEventHandler(sharedUserStorageHandler: UserDefaults(suiteName: "group.test"),
                                        appGroupId: "group.test")
            }()

            let analyticsManager = AnalyticsManagerMock()

            var eventsCache: [[String: Any]]?
            var trackingError: Error?

            var tracker = AnalyticsEventTracker(pushEventHandler: pushEventHandler)
            tracker.delegate = analyticsManager

            afterEach {
                eventsCache = nil
                trackingError = nil
                analyticsManager.processedEvents = [RAnalyticsEvent]()
            }

            context("Events are cached before the tracking") {
                it("should track the events and clear the events cache") {
                    (0..<100).forEach { index in
                        verifyEventsToTrack((0..<index + 1).map { [PushEventPayloadKeys.eventNameKey: "myEventName\($0)",
                                                                   PushEventPayloadKeys.eventParametersKey: ["rid": "bonjour\($0)"]] })
                    }

                    func verifyEventsToTrack(_ events: [[String: AnyHashable]]) {
                        pushEventHandler.save(darwinEvents: events)

                        tracker.track()

                        let cache = pushEventHandler.cachedDarwinEvents()
                        eventsCache = cache

                        expect(analyticsManager.processedEvents).toEventuallyNot(beEmpty())
                        expect(analyticsManager.processedEvents.count).to(equal(events.count))

                        (0..<events.count).forEach { index in
                            expect(analyticsManager.processedEvents[index].name).to(equal(events[index][PushEventPayloadKeys.eventNameKey]))
                        }

                        expect(eventsCache).toEventuallyNot(beNil())
                        expect(eventsCache).to(beEmpty())

                        expect(trackingError).to(beNil())

                        analyticsManager.processedEvents = [RAnalyticsEvent]()
                    }
                }
            }

            context("No events are cached before the tracking") {
                it("should not track events") {
                    tracker.track()
                    QuickSpec.performAsyncTest(timeForExecution: 1.0, timeout: 1.0) {
                        expect(analyticsManager.processedEvents).to(beEmpty())
                    }
                }

                it("should have an empty cache") {
                    tracker.track()

                    let cache = pushEventHandler.cachedDarwinEvents()
                    eventsCache = cache

                    QuickSpec.performAsyncTest(timeForExecution: 1.0, timeout: 1.0) {
                        expect(eventsCache).to(beEmpty())
                    }
                }
            }
        }
    }
}
