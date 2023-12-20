import Foundation
import Quick
import Nimble
@testable import RakutenAnalytics
#if canImport(RAnalyticsTestHelpers)
import RAnalyticsTestHelpers
#endif

final class PushEventHandlerIntegrationSpec: QuickSpec {

    override func spec() {
        describe("PushEventHandlerIntegration") {
            let pushEventHandler: PushEventHandler = {
                return PushEventHandler(sharedUserStorageHandler: UserDefaults(suiteName: "group.test"),
                                        appGroupId: "group.test")
            }()

            afterEach {
                pushEventHandler.clearDarwinEventsCache()
            }

            it("should save the expected events in the cache") {
                var cachedDarwinEvents: [[String: AnyHashable]]?

                (0..<100).forEach { index in
                    verifySavedEvents((0..<index + 1).map { ["key\($0)": "value\($0)"] })
                }

                func verifySavedEvents(_ expectedEvents: [[String: AnyHashable]]) {
                    pushEventHandler.save(darwinEvents: expectedEvents)
                    cachedDarwinEvents = pushEventHandler.cachedDarwinEvents() as? [[String: AnyHashable]]

                    expect(cachedDarwinEvents).toEventually(equal(expectedEvents))
                    expect(cachedDarwinEvents?.count).to(equal(expectedEvents.count))

                    pushEventHandler.clearDarwinEventsCache()
                }
            }

            it("should clear the expected events from the cache") {
                var savedEventsBeforeClearingCache: [[String: AnyHashable]]?
                var cachedEventsAfterClearingCache: [[String: AnyHashable]]?

                (0..<100).forEach { index in
                    verifyCachedEvents((0..<index + 1).map { ["key\($0)": "value\($0)"] })
                }

                func verifyCachedEvents(_ eventsToSave: [[String: AnyHashable]]) {
                    pushEventHandler.save(darwinEvents: eventsToSave)
                    let eventsSavedInCache = pushEventHandler.cachedDarwinEvents()

                    savedEventsBeforeClearingCache = eventsSavedInCache as? [[String: AnyHashable]]

                    pushEventHandler.clearDarwinEventsCache()
                    let events = pushEventHandler.cachedDarwinEvents()

                    cachedEventsAfterClearingCache = events as? [[String: AnyHashable]]

                    expect(savedEventsBeforeClearingCache).toEventually(equal(eventsToSave))
                    expect(savedEventsBeforeClearingCache?.count).to(equal(eventsToSave.count))

                    expect(cachedEventsAfterClearingCache).toEventually(beEmpty())
                }
            }
        }
    }
}
