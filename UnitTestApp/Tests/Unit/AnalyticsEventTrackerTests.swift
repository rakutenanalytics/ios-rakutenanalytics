import Testing
import Foundation
@testable import RakutenAnalytics
#if canImport(RAnalyticsTestHelpers)
import RAnalyticsTestHelpers
#endif

@Suite("AnalyticsEventTracker")
struct AnalyticsEventTrackerTests {
    static let eventsToCache = [[PushEventPayloadKeys.eventNameKey: RAnalyticsEvent.Name.pushNotificationExternal,
                                  PushEventPayloadKeys.eventParametersKey: ["rid": "bonjour1998"]]]
    
    static var pushEventHandler: PushEventHandler {
        let bundleMock = BundleMock()
        bundleMock.dictionary = [:]
        bundleMock.dictionary?[AppGroupUserDefaultsKeys.appGroupIdentifierPlistKey] = "group.test"
        let sharedUserDefaults = UserDefaultsMock(suiteName: "group.test")
        sharedUserDefaults?.dictionary = [:]
        return PushEventHandler(sharedUserStorageHandler: sharedUserDefaults, appGroupId: bundleMock.appGroupId)
    }
    
    var pushEventHandler: PushEventHandler
    var tracker: AnalyticsEventTracker
    var delegate: AnalyticsManagerMock
    
    init() {
        pushEventHandler = Self.pushEventHandler
        tracker = AnalyticsEventTracker(pushEventHandler: pushEventHandler)
        delegate = AnalyticsManagerMock()
        tracker.delegate = delegate
    }
    
    mutating func tearDown() {
        delegate.processedEvents = [RAnalyticsEvent]()
    }

    @Suite("When there is no event in the cache")
    struct WhenNoEventInCacheTests {
        let pushEventHandler = AnalyticsEventTrackerTests.pushEventHandler
        var tracker: AnalyticsEventTracker
        var delegate: AnalyticsManagerMock
        
        init() {
            tracker = AnalyticsEventTracker(pushEventHandler: pushEventHandler)
            delegate = AnalyticsManagerMock()
            tracker.delegate = delegate
        }
        
        mutating func tearDown() {
            delegate.processedEvents = [RAnalyticsEvent]()
        }
        
        @Test("should not track an event")
        mutating func testDoesNotTrackEvent() async throws {
            defer { tearDown() }
            
            pushEventHandler.save(darwinEvents: [])
            tracker.track()
            
            let testDelegate = delegate
            try await TestingHelpers.performAsyncTestOnMain(timeForExecution: 1.0, timeout: 1.0) {
                #expect(testDelegate.processedEvents.isEmpty)
            }
        }
    }

    @Suite("When there is an event in the cache")
    struct WhenEventInCacheTests {
        let pushEventHandler = AnalyticsEventTrackerTests.pushEventHandler
        var tracker: AnalyticsEventTracker
        var delegate: AnalyticsManagerMock
        
        init() {
            tracker = AnalyticsEventTracker(pushEventHandler: pushEventHandler)
            delegate = AnalyticsManagerMock()
            tracker.delegate = delegate
        }
        
        mutating func tearDown() {
            delegate.processedEvents = [RAnalyticsEvent]()
        }
        
        @Test("should track an event")
        mutating func testTracksEvent() async throws {
            defer { tearDown() }
            
            pushEventHandler.save(darwinEvents: AnalyticsEventTrackerTests.eventsToCache)
            tracker.track()

            let testDelegate = delegate
            try await TestingHelpers.eventuallyOnMain { !testDelegate.processedEvents.isEmpty }
            #expect(testDelegate.processedEvents.count == 1)
            #expect(testDelegate.processedEvents.first?.parameters as? [String: AnyHashable] == ["rid": "bonjour1998"])
        }
    }
}
