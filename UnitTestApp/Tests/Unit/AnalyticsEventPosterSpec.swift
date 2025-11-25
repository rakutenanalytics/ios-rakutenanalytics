import Quick
import Nimble
import Foundation
@testable import RakutenAnalytics
#if canImport(RAnalyticsTestHelpers)
import RAnalyticsTestHelpers
#endif

final class AnalyticsEventPosterSpec: QuickSpec {

    override class func spec() {
        describe("AnalyticsEventPoster") {
            let pushEventHandler: PushEventHandler = {
                let bundleMock = BundleMock()
                bundleMock.dictionary = [:]
                bundleMock.dictionary?[AppGroupUserDefaultsKeys.appGroupIdentifierPlistKey] = "group.test"
                let sharedUserDefaults = UserDefaultsMock(suiteName: "group.test")
                sharedUserDefaults?.dictionary = [:]

                return PushEventHandler(sharedUserStorageHandler: sharedUserDefaults,
                                        appGroupId: bundleMock.appGroupId)
            }()
            let expectedCacheEvents: [[String: Any]] = [[PushEventPayloadKeys.eventNameKey: RAnalyticsEvent.Name.pushNotificationExternal,
                                                         PushEventPayloadKeys.eventParametersKey: ["rid": "abcd1234"]]]

            beforeEach {
                pushEventHandler.clearDarwinEventsCache()
            }

            afterEach {
                pushEventHandler.clearDarwinEventsCache()
            }

            it("should cache the event") {
                AnalyticsEventPoster.post(name: RAnalyticsEvent.Name.pushNotificationExternal,
                                          parameters: ["rid": "abcd1234"],
                                          pushEventHandler: pushEventHandler)

                var cachedDarwinEvents: [[String: Any]] = [[String: Any]]()

                let events = pushEventHandler.cachedDarwinEvents()
                cachedDarwinEvents = events

                expect(cachedDarwinEvents.isEmpty).toEventually(beFalse())

                expect(cachedDarwinEvents[0][PushEventPayloadKeys.eventNameKey] as? String)
                    .to(equal(expectedCacheEvents[0][PushEventPayloadKeys.eventNameKey] as? String))

                expect(cachedDarwinEvents[0][PushEventPayloadKeys.eventParametersKey] as? [String: String])
                    .to(equal(expectedCacheEvents[0][PushEventPayloadKeys.eventParametersKey] as? [String: String]))
            }

            it("should send a Darwin Notification") {
                var isReceived = false

                NotificationCenter.default.addObserver(forName: .didReceiveDarwinNotification, object: nil, queue: nil) { _ in
                    isReceived = true
                }

                // Create a dummy class instance to use with Unmanaged.passUnretained
                class DummyClass {}
                let dummyInstance = DummyClass()

                // Note: A C function pointer cannot be formed from a closure that captures context.
                // As CFNotificationCenterAddObserver is a C function and cannot capture properties.
                // the solution is posting a notification through `NotificationCenter`.
                CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(),
                                                Unmanaged.passUnretained(dummyInstance).toOpaque(), { (_, _, _, _, _) in
                                                    NotificationCenter.default.post(name: .didReceiveDarwinNotification, object: nil, userInfo: nil)
                                                }, AnalyticsDarwinNotification.eventsTrackingRequest, nil, .deliverImmediately)

                AnalyticsEventPoster.post(name: RAnalyticsEvent.Name.pushNotificationExternal,
                                          parameters: ["rid": "abcd1234"],
                                          pushEventHandler: pushEventHandler)

                expect(isReceived).toEventually(beTrue())
            }
        }
    }
}
