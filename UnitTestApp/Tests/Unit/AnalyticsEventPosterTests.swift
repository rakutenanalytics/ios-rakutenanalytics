import Testing
import Foundation
@testable import RakutenAnalytics
#if canImport(RAnalyticsTestHelpers)
import RAnalyticsTestHelpers
#endif

@Suite("AnalyticsEventPoster")
struct AnalyticsEventPosterTests {
    
    static var pushEventHandler: PushEventHandler {
        let bundleMock = BundleMock()
        bundleMock.dictionary = [:]
        bundleMock.dictionary?[AppGroupUserDefaultsKeys.appGroupIdentifierPlistKey] = "group.test"
        let sharedUserDefaults = UserDefaultsMock(suiteName: "group.test")
        sharedUserDefaults?.dictionary = [:]
        return PushEventHandler(sharedUserStorageHandler: sharedUserDefaults, appGroupId: bundleMock.appGroupId)
    }
    
    static let expectedCacheEvents: [[String: Any]] = [[PushEventPayloadKeys.eventNameKey: RAnalyticsEvent.Name.pushNotificationExternal,
                                                         PushEventPayloadKeys.eventParametersKey: ["rid": "abcd1234"]]]
    
    var pushEventHandler: PushEventHandler
    
    init() {
        pushEventHandler = Self.pushEventHandler
    }
    
    mutating func setUp() {
        pushEventHandler.clearDarwinEventsCache()
    }
    
    mutating func tearDown() {
        pushEventHandler.clearDarwinEventsCache()
    }

    @Test("should cache the event")
    mutating func testCachesEvent() async throws {
        setUp()
        defer { tearDown() }
        
        AnalyticsEventPoster.post(name: RAnalyticsEvent.Name.pushNotificationExternal, parameters: ["rid": "abcd1234"], pushEventHandler: pushEventHandler)
        
        let testPushEventHandler = pushEventHandler
        try await TestingHelpers.eventuallyOnMain { !testPushEventHandler.cachedDarwinEvents().isEmpty }
        
        let cachedDarwinEvents = pushEventHandler.cachedDarwinEvents()
        #expect(cachedDarwinEvents[0][PushEventPayloadKeys.eventNameKey] as? String == Self.expectedCacheEvents[0][PushEventPayloadKeys.eventNameKey] as? String)
        #expect(cachedDarwinEvents[0][PushEventPayloadKeys.eventParametersKey] as? [String: String] == Self.expectedCacheEvents[0][PushEventPayloadKeys.eventParametersKey] as? [String: String])
    }

    @Test("should send a Darwin Notification")
    mutating func testSendsDarwinNotification() async throws {
        setUp()
        defer { tearDown() }
        
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
        CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), Unmanaged.passUnretained(dummyInstance).toOpaque(), { (_, _, _, _, _) in
            NotificationCenter.default.post(name: .didReceiveDarwinNotification, object: nil, userInfo: nil)
        }, AnalyticsDarwinNotification.eventsTrackingRequest, nil, .deliverImmediately)

        AnalyticsEventPoster.post(name: RAnalyticsEvent.Name.pushNotificationExternal, parameters: ["rid": "abcd1234"], pushEventHandler: pushEventHandler)
        try await TestingHelpers.eventuallyOnMain { isReceived }
    }
}
