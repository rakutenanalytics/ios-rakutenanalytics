import Quick
import Nimble
import Foundation
@testable import RAnalytics
#if canImport(RAnalyticsTestHelpers)
import RAnalyticsTestHelpers
#endif

final class PushEventHandlerSpec: QuickSpec {

    override func spec() {
        describe("PushEventHandler") {
            let sentTrackingId = "a_good_tracking_id"
            let appGroupDictionary = [AppGroupUserDefaultsKeys.appGroupIdentifierPlistKey: "appGroupId"]
            let openCountDictionary = [PushEventHandlerKeys.openCountSentUserDefaultKey: [sentTrackingId: true]]
            let bundleMock = BundleMock()
            bundleMock.dictionary = [:]
            bundleMock.dictionary?[AppGroupUserDefaultsKeys.appGroupIdentifierPlistKey] = "group.test"
            let sharedUserDefaults = UserDefaultsMock(suiteName: "group.test")
            sharedUserDefaults?.dictionary = [:]
            let eventsToCache = [[PushEventPayloadKeys.eventNameKey: RAnalyticsEvent.Name.pushNotification,
                                  PushEventPayloadKeys.eventParametersKey: ["rid": "abcd1234"]]]

            context("App Group User Defaults") {
                describe("isEventAlreadySent") {
                    context("RRPushAppGroupIdentifierPlistKey is not set in the main bundle") {
                        let pushEventHandler = PushEventHandler(sharedUserStorageHandler: UserDefaultsMock(suiteName: bundleMock.appGroupId),
                                                                appGroupId: bundleMock.appGroupId)

                        it("should return false when trackingIdentifier is not nil") {
                            expect(pushEventHandler.isEventAlreadySent(with: sentTrackingId)).to(beFalse())
                        }

                        it("should return false when trackingIdentifier is nil") {
                            expect(pushEventHandler.isEventAlreadySent(with: nil)).to(beFalse())
                        }
                    }

                    context("RRPushAppGroupIdentifierPlistKey is set in the main bundle") {
                        let bundleMock: BundleMock = {
                            let bundleMock = BundleMock()
                            bundleMock.dictionary = appGroupDictionary
                            return bundleMock
                        }()

                        context("valid open count dictionary") {
                            let pushEventHandler: PushEventHandler = {
                                let pushEventHandler = PushEventHandler(sharedUserStorageHandler: UserDefaultsMock(suiteName: bundleMock.appGroupId),
                                                                        appGroupId: bundleMock.appGroupId)
                                (pushEventHandler.sharedUserStorageHandler as? UserDefaultsMock)?.dictionary = openCountDictionary
                                return pushEventHandler
                            }()

                            it("should return true when trackingIdentifier is not nil") {
                                expect(pushEventHandler.isEventAlreadySent(with: sentTrackingId)).to(beTrue())
                            }

                            it("should return false when trackingIdentifier is nil") {
                                expect(pushEventHandler.isEventAlreadySent(with: nil)).to(beFalse())
                            }
                        }

                        context("invalid open count dictionary") {
                            let pushEventHandler = PushEventHandler(sharedUserStorageHandler: UserDefaultsMock(suiteName: bundleMock.appGroupId),
                                                                    appGroupId: bundleMock.appGroupId)

                            it("should return false when trackingIdentifier is not nil and open count dictionary is empty") {
                                (pushEventHandler.sharedUserStorageHandler as? UserDefaultsMock)?.dictionary = [:]
                                expect(pushEventHandler.isEventAlreadySent(with: sentTrackingId)).to(beFalse())
                            }

                            it("should return false when trackingIdentifier is not nil and open count dictionary is nil") {
                                (pushEventHandler.sharedUserStorageHandler as? UserDefaultsMock)?.dictionary = nil
                                expect(pushEventHandler.isEventAlreadySent(with: sentTrackingId)).to(beFalse())
                            }

                            it("should return false when trackingIdentifier is nil and open count dictionary is empty") {
                                (pushEventHandler.sharedUserStorageHandler as? UserDefaultsMock)?.dictionary = [:]
                                expect(pushEventHandler.isEventAlreadySent(with: nil)).to(beFalse())
                            }

                            it("should return false when trackingIdentifier is nil and open count dictionary is nil") {
                                (pushEventHandler.sharedUserStorageHandler as? UserDefaultsMock)?.dictionary = nil
                                expect(pushEventHandler.isEventAlreadySent(with: nil)).to(beFalse())
                            }
                        }
                    }
                }

                describe("cacheEvent(for:)") {
                    context("The shared app group user defaults is nil") {
                        let pushEventHandler = PushEventHandler(sharedUserStorageHandler: nil,
                                                                appGroupId: nil)

                        it("should not cache the event tracking identifier") {
                            expect(pushEventHandler.cacheEvent(for: sentTrackingId)).to(beFalse())
                        }
                    }

                    context("The shared app group user defaults is not nil") {
                        let pushEventHandler = PushEventHandler(sharedUserStorageHandler: sharedUserDefaults,
                                                                appGroupId: bundleMock.appGroupId)

                        it("should cache the event tracking identifier") {
                            expect(pushEventHandler.cacheEvent(for: sentTrackingId)).to(beTrue())
                        }

                        it("should set the tracking identifier caching status to true") {
                            let openSentMap = sharedUserDefaults?.object(forKey: PushEventHandlerKeys.openCountSentUserDefaultKey) as? [String: Bool]
                            expect(openSentMap?[sentTrackingId]).to(beTrue())
                        }
                    }
                }

                describe("clearCache()") {
                    context("The shared app group user defaults is nil") {
                        let pushEventHandler = PushEventHandler(sharedUserStorageHandler: nil,
                                                                appGroupId: nil)

                        it("should return false") {
                            expect(pushEventHandler.clearCache()).to(beFalse())
                        }
                    }

                    context("The shared app group user defaults is not nil") {
                        let pushEventHandler = PushEventHandler(sharedUserStorageHandler: sharedUserDefaults,
                                                                appGroupId: bundleMock.appGroupId)

                        it("should set the cache to nil") {
                            pushEventHandler.cacheEvent(for: sentTrackingId)
                            pushEventHandler.clearCache()

                            expect(sharedUserDefaults?.object(forKey: PushEventHandlerKeys.openCountSentUserDefaultKey)).to(beNil())
                        }

                        it("should return true") {
                            expect(pushEventHandler.clearCache()).to(beTrue())
                        }
                    }
                }
            }

            context("Darwin Events") {
                let pushEventHandler = PushEventHandler(sharedUserStorageHandler: sharedUserDefaults,
                                                        appGroupId: bundleMock.appGroupId)

                beforeEach {
                    sharedUserDefaults?.dictionary = [:]
                }

                describe("cachedDarwinEvents(completion:)") {
                    context("When the cached events array is empty") {
                        it("should return an empty cached events") {
                            let expectedEvents = [[String: Any]]()

                            sharedUserDefaults?.dictionary = [PushEventHandlerKeys.openCountCachedEventsKey: expectedEvents]

                            var cachedDarwinEvents: [[String: Any]] = [[String: Any]]()

                            let events = pushEventHandler.cachedDarwinEvents()
                            cachedDarwinEvents = events

                            expect(cachedDarwinEvents).toNotEventually(beNil())
                            expect(cachedDarwinEvents.isEmpty).toEventually(beTrue())
                        }
                    }

                    context("When the cached events array is not empty") {
                        it("should return the cached events when the cache is correct") {
                            let expectedEvents = eventsToCache

                            sharedUserDefaults?.dictionary = [PushEventHandlerKeys.openCountCachedEventsKey: expectedEvents]

                            var cachedDarwinEvents: [[String: Any]] = [[String: Any]]()

                            let events = pushEventHandler.cachedDarwinEvents()
                            cachedDarwinEvents = events

                            expect(cachedDarwinEvents).toNotEventually(beNil())
                            expect(cachedDarwinEvents as? [[String: AnyHashable]]).to(equal(expectedEvents as? [[String: AnyHashable]]))
                        }
                    }
                }

                describe("save(darwinEvents:)") {
                    context("When the cached events file exists") {
                        context("When the cached events array is empty") {
                            it("should save an empty array") {
                                pushEventHandler.save(darwinEvents: [])

                                expect(sharedUserDefaults?.array(forKey: PushEventHandlerKeys.openCountCachedEventsKey)).to(beEmpty())
                            }
                        }

                        context("When the cached events array is not empty") {
                            it("should save a not empty array") {
                                let expectedEvents = eventsToCache as? [[String: AnyHashable]]

                                pushEventHandler.save(darwinEvents: eventsToCache)

                                let savedEvents = sharedUserDefaults?.array(forKey: PushEventHandlerKeys.openCountCachedEventsKey)
                                expect(savedEvents as? [[String: AnyHashable]]).to(equal(expectedEvents))
                            }
                        }
                    }
                }

                describe("clearDarwinEventsCache()") {
                    context("When the cached events file exists") {
                        it("should clear the cache") {
                            pushEventHandler.clearDarwinEventsCache()

                            expect(sharedUserDefaults?.array(forKey: PushEventHandlerKeys.openCountCachedEventsKey)).to(beEmpty())
                        }
                    }
                }
            }
        }
    }
}
