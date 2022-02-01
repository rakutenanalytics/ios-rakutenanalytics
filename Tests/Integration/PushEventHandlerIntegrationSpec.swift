import Foundation
import Quick
import Nimble
@testable import RAnalytics
#if canImport(RAnalyticsTestHelpers)
import RAnalyticsTestHelpers
#endif

final class PushEventHandlerIntegrationSpec: QuickSpec {

    override func spec() {
        describe("PushEventHandlerIntegration") {
            let pushEventHandler: PushEventHandler = {
                return PushEventHandler(sharedUserStorageHandler: UserDefaults(suiteName: "group.test"),
                                        appGroupId: "group.test",
                                        fileManager: FileManager.default,
                                        serializerType: JSONSerialization.self)
            }()

            afterEach {
                pushEventHandler.clearEventsCache { _ in }
            }

            it("should save the expected events in the cache") {
                var cachedEvents: [[String: AnyHashable]]?

                (0..<100).forEach { index in
                    verifySavedEvents((0..<index + 1).map { ["key\($0)": "value\($0)"] })
                }

                func verifySavedEvents(_ expectedEvents: [[String: AnyHashable]]) {
                    pushEventHandler.save(events: expectedEvents) { _ in
                        pushEventHandler.cachedEvents { result in
                            switch result {
                            case .success(let events):
                                cachedEvents = events as? [[String: AnyHashable]]

                            case .failure(_): ()
                            }
                        }
                    }

                    expect(cachedEvents).toEventually(equal(expectedEvents))
                    expect(cachedEvents?.count).to(equal(expectedEvents.count))

                    pushEventHandler.clearEventsCache { _ in }
                }
            }

            it("should clear the expected events from the cache") {
                var savedEventsBeforeClearingCache: [[String: AnyHashable]]?
                var cachedEventsAfterClearingCache: [[String: AnyHashable]]?

                (0..<100).forEach { index in
                    verifyCachedEvents((0..<index + 1).map { ["key\($0)": "value\($0)"] })
                }

                func verifyCachedEvents(_ eventsToSave: [[String: AnyHashable]]) {
                    pushEventHandler.save(events: eventsToSave) { _ in
                        pushEventHandler.cachedEvents { result in
                            switch result {
                            case .success(let eventsSavedInCache):
                                savedEventsBeforeClearingCache = eventsSavedInCache as? [[String: AnyHashable]]

                                pushEventHandler.clearEventsCache { _ in
                                    pushEventHandler.cachedEvents { result in
                                        switch result {
                                        case .success(let events):
                                            cachedEventsAfterClearingCache = events as? [[String: AnyHashable]]

                                        case .failure(_): ()
                                        }
                                    }
                                }

                            case .failure(_): ()
                            }
                        }
                    }

                    expect(savedEventsBeforeClearingCache).toEventually(equal(eventsToSave))
                    expect(savedEventsBeforeClearingCache?.count).to(equal(eventsToSave.count))

                    expect(cachedEventsAfterClearingCache).toEventually(beEmpty())
                }
            }
        }
    }
}
