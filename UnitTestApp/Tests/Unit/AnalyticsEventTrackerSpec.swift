import Quick
import Nimble
import Foundation
@testable import RakutenAnalytics
#if canImport(RAnalyticsTestHelpers)
import RAnalyticsTestHelpers
#endif

final class AnalyticsEventTrackerSpec: QuickSpec {

    override class func spec() {
        describe("AnalyticsEventTracker") {
            let eventsToCache = [[PushEventPayloadKeys.eventNameKey: RAnalyticsEvent.Name.pushNotificationExternal,
                                  PushEventPayloadKeys.eventParametersKey: ["rid": "bonjour1998"]]]
            let pushEventHandler: PushEventHandler = {
                let bundleMock = BundleMock()
                bundleMock.dictionary = [:]
                bundleMock.dictionary?[AppGroupUserDefaultsKeys.appGroupIdentifierPlistKey] = "group.test"
                let sharedUserDefaults = UserDefaultsMock(suiteName: "group.test")
                sharedUserDefaults?.dictionary = [:]

                return PushEventHandler(sharedUserStorageHandler: sharedUserDefaults,
                                        appGroupId: bundleMock.appGroupId)
            }()
            var tracker = AnalyticsEventTracker(pushEventHandler: pushEventHandler)
            let delegate = AnalyticsManagerMock()
            tracker.delegate = delegate

            afterEach {
                delegate.processedEvents = [RAnalyticsEvent]()
            }

            context("When there is no event in the cache") {
                it("should not track an event") {
                    pushEventHandler.save(darwinEvents: [])
                    tracker.track()
                    
                    QuickSpec.performAsyncTest(timeForExecution: 1.0, timeout: 1.0) {
                        expect(delegate.processedEvents).to(beEmpty())
                    }
                }
            }

            context("When there is an event in the cache") {
                it("should track an event") {
                    pushEventHandler.save(darwinEvents: eventsToCache)
                    tracker.track()

                    expect(delegate.processedEvents).toEventuallyNot(beEmpty())
                    expect(delegate.processedEvents.count).to(equal(1))
                    expect(delegate.processedEvents.first?.parameters as? [String: AnyHashable]).to(equal(["rid": "bonjour1998"]))
                }
            }
        }
    }
}
