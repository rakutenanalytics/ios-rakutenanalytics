import Testing
import Foundation
@testable import RakutenAnalytics
#if canImport(RAnalyticsTestHelpers)
import RAnalyticsTestHelpers
#endif

@Suite("PushEventHandler")
struct PushEventHandlerTests {
    static let sentTrackingId = "a_good_tracking_id"
    static let appGroupDictionary = [AppGroupUserDefaultsKeys.appGroupIdentifierPlistKey: "appGroupId"]
    static var openCountDictionary: [String: Any] {
        [PushEventHandlerKeys.openCountSentUserDefaultKey: [sentTrackingId: true]]
    }
    
    static var bundleMock: BundleMock {
        let bundleMock = BundleMock()
        bundleMock.dictionary = [:]
        bundleMock.dictionary?[AppGroupUserDefaultsKeys.appGroupIdentifierPlistKey] = "group.test"
        return bundleMock
    }
    
    static var sharedUserDefaults: UserDefaultsMock? {
        UserDefaultsMock(suiteName: "group.test")
    }
    
    static let eventsToCache = [[PushEventPayloadKeys.eventNameKey: RAnalyticsEvent.Name.pushNotificationExternal,
                                 PushEventPayloadKeys.eventParametersKey: ["rid": "abcd1234"]]]

    @Suite("App Group User Defaults")
    struct AppGroupUserDefaultsTests {
        @Suite("isEventAlreadySent")
        struct IsEventAlreadySentTests {
            @Suite("RRPushAppGroupIdentifierPlistKey is not set in the main bundle")
            struct RRPushAppGroupIdentifierPlistKeyNotSetTests {
                static var pushEventHandler: PushEventHandler {
                    let bundleMock = PushEventHandlerTests.bundleMock
                    return PushEventHandler(sharedUserStorageHandler: UserDefaultsMock(suiteName: bundleMock.appGroupId), appGroupId: bundleMock.appGroupId)
                }

                @Test("should return false when trackingIdentifier is not nil")
                func testReturnsFalseWhenTrackingIdentifierIsNotNil() {
                    #expect(Self.pushEventHandler.isEventAlreadySent(with: PushEventHandlerTests.sentTrackingId) == false)
                }

                @Test("should return false when trackingIdentifier is nil")
                func testReturnsFalseWhenTrackingIdentifierIsNil() {
                    #expect(Self.pushEventHandler.isEventAlreadySent(with: nil) == false)
                }
            }

            @Suite("RRPushAppGroupIdentifierPlistKey is set in the main bundle")
            struct RRPushAppGroupIdentifierPlistKeySetTests {
                static var bundleMock: BundleMock {
                    let bundleMock = BundleMock()
                    bundleMock.dictionary = PushEventHandlerTests.appGroupDictionary
                    return bundleMock
                }

                @Suite("valid open count dictionary")
                struct ValidOpenCountDictionaryTests {
                    static var pushEventHandler: PushEventHandler {
                        let bundleMock = RRPushAppGroupIdentifierPlistKeySetTests.bundleMock
                        let pushEventHandler = PushEventHandler(sharedUserStorageHandler: UserDefaultsMock(suiteName: bundleMock.appGroupId), appGroupId: bundleMock.appGroupId)
                        (pushEventHandler.sharedUserStorageHandler as? UserDefaultsMock)?.dictionary = PushEventHandlerTests.openCountDictionary
                        return pushEventHandler
                    }

                    @Test("should return true when trackingIdentifier is not nil")
                    func testReturnsTrueWhenTrackingIdentifierIsNotNil() {
                        #expect(Self.pushEventHandler.isEventAlreadySent(with: PushEventHandlerTests.sentTrackingId) == true)
                    }

                    @Test("should return false when trackingIdentifier is nil")
                    func testReturnsFalseWhenTrackingIdentifierIsNil() {
                        #expect(Self.pushEventHandler.isEventAlreadySent(with: nil) == false)
                    }
                }

                @Suite("invalid open count dictionary")
                struct InvalidOpenCountDictionaryTests {
                    static var pushEventHandler: PushEventHandler {
                        let bundleMock = RRPushAppGroupIdentifierPlistKeySetTests.bundleMock
                        return PushEventHandler(sharedUserStorageHandler: UserDefaultsMock(suiteName: bundleMock.appGroupId), appGroupId: bundleMock.appGroupId)
                    }

                    @Test("should return false when trackingIdentifier is not nil and open count dictionary is empty")
                    func testReturnsFalseWhenTrackingIdentifierNotNilAndOpenCountDictionaryEmpty() {
                        let pushEventHandler = Self.pushEventHandler
                        (pushEventHandler.sharedUserStorageHandler as? UserDefaultsMock)?.dictionary = [:]
                        #expect(pushEventHandler.isEventAlreadySent(with: PushEventHandlerTests.sentTrackingId) == false)
                    }

                    @Test("should return false when trackingIdentifier is not nil and open count dictionary is nil")
                    func testReturnsFalseWhenTrackingIdentifierNotNilAndOpenCountDictionaryNil() {
                        let pushEventHandler = Self.pushEventHandler
                        (pushEventHandler.sharedUserStorageHandler as? UserDefaultsMock)?.dictionary = nil
                        #expect(pushEventHandler.isEventAlreadySent(with: PushEventHandlerTests.sentTrackingId) == false)
                    }

                    @Test("should return false when trackingIdentifier is nil and open count dictionary is empty")
                    func testReturnsFalseWhenTrackingIdentifierNilAndOpenCountDictionaryEmpty() {
                        let pushEventHandler = Self.pushEventHandler
                        (pushEventHandler.sharedUserStorageHandler as? UserDefaultsMock)?.dictionary = [:]
                        #expect(pushEventHandler.isEventAlreadySent(with: nil) == false)
                    }

                    @Test("should return false when trackingIdentifier is nil and open count dictionary is nil")
                    func testReturnsFalseWhenTrackingIdentifierNilAndOpenCountDictionaryNil() {
                        let pushEventHandler = Self.pushEventHandler
                        (pushEventHandler.sharedUserStorageHandler as? UserDefaultsMock)?.dictionary = nil
                        #expect(pushEventHandler.isEventAlreadySent(with: nil) == false)
                    }
                }
            }
        }
    }

    @Suite("Darwin Events")
    struct DarwinEventsTests {
        var bundleMock: BundleMock
        var sharedUserDefaults: UserDefaultsMock?
        var pushEventHandler: PushEventHandler

        init() {
            bundleMock = PushEventHandlerTests.bundleMock
            sharedUserDefaults = PushEventHandlerTests.sharedUserDefaults
            pushEventHandler = PushEventHandler(sharedUserStorageHandler: sharedUserDefaults, appGroupId: bundleMock.appGroupId)
        }

        mutating func setUp() {
            sharedUserDefaults?.dictionary = [:]
        }

        @Suite("cachedDarwinEvents(completion:)")
        struct CachedDarwinEventsTests {
            var bundleMock: BundleMock
            var sharedUserDefaults: UserDefaultsMock?
            var pushEventHandler: PushEventHandler

            init() {
                bundleMock = PushEventHandlerTests.bundleMock
                sharedUserDefaults = PushEventHandlerTests.sharedUserDefaults
                pushEventHandler = PushEventHandler(sharedUserStorageHandler: sharedUserDefaults, appGroupId: bundleMock.appGroupId)
            }

            mutating func setUp() {
                sharedUserDefaults?.dictionary = [:]
            }

            @Suite("When the cached events array is empty")
            struct WhenCachedEventsArrayIsEmptyTests {
                var bundleMock: BundleMock
                var sharedUserDefaults: UserDefaultsMock?
                var pushEventHandler: PushEventHandler

                init() {
                    bundleMock = PushEventHandlerTests.bundleMock
                    sharedUserDefaults = PushEventHandlerTests.sharedUserDefaults
                    pushEventHandler = PushEventHandler(sharedUserStorageHandler: sharedUserDefaults, appGroupId: bundleMock.appGroupId)
                }

                mutating func setUp() {
                    sharedUserDefaults?.dictionary = [:]
                }

                @Test("should return an empty cached events")
                mutating func testReturnsEmptyCachedEvents() async throws {
                    setUp()
                    let expectedEvents = [[String: Any]]()

                    sharedUserDefaults?.dictionary = [PushEventHandlerKeys.openCountCachedEventsKey: expectedEvents]

                    let testPushEventHandler = pushEventHandler
                    try await TestingHelpers.eventuallyOnMain {
                        let events = testPushEventHandler.cachedDarwinEvents()
                        return events.isEmpty
                    }
                    let events = pushEventHandler.cachedDarwinEvents()
                    #expect(events.isEmpty == true)
                }
            }

            @Suite("When the cached events array is not empty")
            struct WhenCachedEventsArrayIsNotEmptyTests {
                var bundleMock: BundleMock
                var sharedUserDefaults: UserDefaultsMock?
                var pushEventHandler: PushEventHandler

                init() {
                    bundleMock = PushEventHandlerTests.bundleMock
                    sharedUserDefaults = PushEventHandlerTests.sharedUserDefaults
                    pushEventHandler = PushEventHandler(sharedUserStorageHandler: sharedUserDefaults, appGroupId: bundleMock.appGroupId)
                }

                mutating func setUp() {
                    sharedUserDefaults?.dictionary = [:]
                }

                @Test("should return the cached events when the cache is correct")
                mutating func testReturnsCachedEventsWhenCacheIsCorrect() async throws {
                    setUp()
                    let expectedEvents = PushEventHandlerTests.eventsToCache

                    sharedUserDefaults?.dictionary = [PushEventHandlerKeys.openCountCachedEventsKey: expectedEvents]

                    let testPushEventHandler = pushEventHandler
                    try await TestingHelpers.eventuallyOnMain {
                        let events = testPushEventHandler.cachedDarwinEvents()
                        return !events.isEmpty
                    }
                    let events = pushEventHandler.cachedDarwinEvents()
                    #expect(events as? [[String: AnyHashable]] == expectedEvents as? [[String: AnyHashable]])
                }
            }
        }

        @Suite("save(darwinEvents:)")
        struct SaveDarwinEventsTests {
            var bundleMock: BundleMock
            var sharedUserDefaults: UserDefaultsMock?
            var pushEventHandler: PushEventHandler

            init() {
                bundleMock = PushEventHandlerTests.bundleMock
                sharedUserDefaults = PushEventHandlerTests.sharedUserDefaults
                pushEventHandler = PushEventHandler(sharedUserStorageHandler: sharedUserDefaults, appGroupId: bundleMock.appGroupId)
            }

            mutating func setUp() {
                sharedUserDefaults?.dictionary = [:]
            }

            @Suite("When the cached events file exists")
            struct WhenCachedEventsFileExistsTests {
                var bundleMock: BundleMock
                var sharedUserDefaults: UserDefaultsMock?
                var pushEventHandler: PushEventHandler

                init() {
                    bundleMock = PushEventHandlerTests.bundleMock
                    sharedUserDefaults = PushEventHandlerTests.sharedUserDefaults
                    pushEventHandler = PushEventHandler(sharedUserStorageHandler: sharedUserDefaults, appGroupId: bundleMock.appGroupId)
                }

                mutating func setUp() {
                    sharedUserDefaults?.dictionary = [:]
                }

                @Suite("When the cached events array is empty")
                struct WhenCachedEventsArrayIsEmptyTests {
                    var bundleMock: BundleMock
                    var sharedUserDefaults: UserDefaultsMock?
                    var pushEventHandler: PushEventHandler

                    init() {
                        bundleMock = PushEventHandlerTests.bundleMock
                        sharedUserDefaults = PushEventHandlerTests.sharedUserDefaults
                        pushEventHandler = PushEventHandler(sharedUserStorageHandler: sharedUserDefaults, appGroupId: bundleMock.appGroupId)
                    }

                    mutating func setUp() {
                        sharedUserDefaults?.dictionary = [:]
                    }

                    @Test("should save an empty array")
                    mutating func testSavesEmptyArray() {
                        setUp()
                        pushEventHandler.save(darwinEvents: [])
                        #expect((sharedUserDefaults?.array(forKey: PushEventHandlerKeys.openCountCachedEventsKey)?.isEmpty) == true)
                    }
                }

                @Suite("When the cached events array is not empty")
                struct WhenCachedEventsArrayIsNotEmptyTests {
                    var bundleMock: BundleMock
                    var sharedUserDefaults: UserDefaultsMock?
                    var pushEventHandler: PushEventHandler

                    init() {
                        bundleMock = PushEventHandlerTests.bundleMock
                        sharedUserDefaults = PushEventHandlerTests.sharedUserDefaults
                        pushEventHandler = PushEventHandler(sharedUserStorageHandler: sharedUserDefaults, appGroupId: bundleMock.appGroupId)
                    }

                    mutating func setUp() {
                        sharedUserDefaults?.dictionary = [:]
                    }

                    @Test("should save a not empty array")
                    mutating func testSavesNotEmptyArray() {
                        setUp()
                        let expectedEvents = PushEventHandlerTests.eventsToCache as? [[String: AnyHashable]]

                        pushEventHandler.save(darwinEvents: PushEventHandlerTests.eventsToCache)

                        let savedEvents = sharedUserDefaults?.array(forKey: PushEventHandlerKeys.openCountCachedEventsKey)
                        #expect(savedEvents as? [[String: AnyHashable]] == expectedEvents)
                    }
                }
            }
        }

        @Suite("clearDarwinEventsCache()")
        struct ClearDarwinEventsCacheTests {
            var bundleMock: BundleMock
            var sharedUserDefaults: UserDefaultsMock?
            var pushEventHandler: PushEventHandler

            init() {
                bundleMock = PushEventHandlerTests.bundleMock
                sharedUserDefaults = PushEventHandlerTests.sharedUserDefaults
                pushEventHandler = PushEventHandler(sharedUserStorageHandler: sharedUserDefaults, appGroupId: bundleMock.appGroupId)
            }

            mutating func setUp() {
                sharedUserDefaults?.dictionary = [:]
            }

            @Suite("When the cached events file exists")
            struct WhenCachedEventsFileExistsTests {
                var bundleMock: BundleMock
                var sharedUserDefaults: UserDefaultsMock?
                var pushEventHandler: PushEventHandler

                init() {
                    bundleMock = PushEventHandlerTests.bundleMock
                    sharedUserDefaults = PushEventHandlerTests.sharedUserDefaults
                    pushEventHandler = PushEventHandler(sharedUserStorageHandler: sharedUserDefaults, appGroupId: bundleMock.appGroupId)
                }

                mutating func setUp() {
                    sharedUserDefaults?.dictionary = [:]
                }

                @Test("should clear the cache")
                mutating func testClearsCache() {
                    setUp()
                    pushEventHandler.clearDarwinEventsCache()
                    #expect((sharedUserDefaults?.array(forKey: PushEventHandlerKeys.openCountCachedEventsKey)?.isEmpty) == true)
                }
            }
        }
    }
}
