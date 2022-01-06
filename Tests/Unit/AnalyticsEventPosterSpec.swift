import Quick
import Nimble
@testable import RAnalytics

final class AnalyticsEventPosterSpec: QuickSpec {

    override func spec() {
        describe("AnalyticsEventPoster") {
            let fileManager = FileManager.default
            let pushEventHandler: PushEventHandler = {
                let bundleMock = BundleMock()
                bundleMock.dictionary = [:]
                bundleMock.dictionary?[AppGroupUserDefaultsKeys.appGroupIdentifierPlistKey] = "group.test"
                let sharedUserDefaults = UserDefaultsMock(suiteName: "group.test")
                sharedUserDefaults?.dictionary = [:]

                return PushEventHandler(sharedUserStorageHandler: sharedUserDefaults,
                                        appGroupId: bundleMock.appGroupId,
                                        fileManager: fileManager,
                                        serializerType: JSONSerialization.self)
            }()
            let expectedCacheEvents: [[String: Any]] = [[PushEventPayloadKeys.eventNameKey: RAnalyticsEvent.Name.pushNotification,
                                                         PushEventPayloadKeys.eventParametersKey: ["rid": "abcd1234"]]]

            beforeEach {
                pushEventHandler.clearEventsCache { _ in }
            }

            afterEach {
                pushEventHandler.clearEventsCache { _ in }
            }

            it("should cache the event") {
                AnalyticsEventPoster.post(name: RAnalyticsEvent.Name.pushNotification,
                                          parameters: ["rid": "abcd1234"],
                                          pushEventHandler: pushEventHandler)

                var cachedEvents: [[String: Any]] = [[String: Any]]()

                pushEventHandler.cachedEvents { result in
                    if case .success(let events) = result {
                        cachedEvents = events
                    }
                }

                expect(cachedEvents.isEmpty).toEventually(beFalse())
                expect(cachedEvents as? [[String: AnyHashable]]).to(equal(expectedCacheEvents as? [[String: AnyHashable]]))
            }

            it("should send a Darwin Notification") {
                var isReceived = false

                NotificationCenter.default.addObserver(forName: .didReceiveDarwinNotification, object: nil, queue: nil) { _ in
                    isReceived = true
                }

                // Note: A C function pointer cannot be formed from a closure that captures context.
                // As CFNotificationCenterAddObserver is a C function and cannot capture properties.
                // the solution is posting a notification through `NotificationCenter`.
                CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(),
                                                Unmanaged.passUnretained(self).toOpaque(), { (_, _, _, _, _) in
                                                    NotificationCenter.default.post(name: .didReceiveDarwinNotification, object: nil, userInfo: nil)
                                                }, AnalyticsDarwinNotification.eventsTrackingRequest, nil, .deliverImmediately)

                AnalyticsEventPoster.post(name: RAnalyticsEvent.Name.pushNotification,
                                          parameters: ["rid": "abcd1234"],
                                          pushEventHandler: pushEventHandler)

                expect(isReceived).toAfterTimeout(beTrue())
            }
        }
    }
}
