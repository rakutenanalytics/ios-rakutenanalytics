import Foundation
import Quick
import Nimble
@testable import RAnalytics
#if canImport(RAnalyticsTestHelpers)
import RAnalyticsTestHelpers
#endif

#if canImport(RSDKUtilsNimble)
import RSDKUtilsNimble
#endif

final class AnalyticsEventTrackerIntegrationSpec: QuickSpec {

    override func spec() {
        describe("AnalyticsEventTrackerIntegration") {
            let pushEventHandler: PushEventHandler = {
                return PushEventHandler(sharedUserStorageHandler: UserDefaults(suiteName: "group.test"),
                                        appGroupId: "group.test",
                                        fileManager: FileManager.default,
                                        serializerType: JSONSerialization.self)
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
                    var savingError: Error?

                    (0..<100).forEach { index in
                        verifyEventsToTrack((0..<index + 1).map { [PushEventPayloadKeys.eventNameKey: "myEventName\($0)",
                                                                   PushEventPayloadKeys.eventParametersKey: ["rid": "bonjour\($0)"]] })
                    }

                    func verifyEventsToTrack(_ events: [[String: AnyHashable]]) {
                        pushEventHandler.save(events: events) { saveError in
                            savingError = saveError

                            tracker.track { anError in
                                trackingError = anError

                                pushEventHandler.cachedEvents { result in
                                    switch result {
                                    case .success(let cache): eventsCache = cache
                                    case .failure(_): ()
                                    }
                                }
                            }
                        }

                        expect(analyticsManager.processedEvents).toEventuallyNot(beEmpty())
                        expect(analyticsManager.processedEvents.count).to(equal(events.count))

                        (0..<events.count).forEach { index in
                            expect(analyticsManager.processedEvents[index].name).to(equal(events[index][PushEventPayloadKeys.eventNameKey]))
                        }

                        expect(eventsCache).toEventuallyNot(beNil())
                        expect(eventsCache).to(beEmpty())

                        expect(savingError).to(beNil())
                        expect(trackingError).to(beNil())

                        analyticsManager.processedEvents = [RAnalyticsEvent]()
                    }
                }
            }

            context("No events are cached before the tracking") {
                it("should not track events") {
                    tracker.track { _ in }

                    expect(analyticsManager.processedEvents).toAfterTimeout(beEmpty())
                }

                it("should have an empty cache") {
                    tracker.track { _ in }

                    pushEventHandler.cachedEvents { result in
                        switch result {
                        case .success(let cache): eventsCache = cache
                        case .failure(_): ()
                        }
                    }

                    expect(eventsCache).toAfterTimeout(beEmpty())
                }
            }
        }
    }
}
