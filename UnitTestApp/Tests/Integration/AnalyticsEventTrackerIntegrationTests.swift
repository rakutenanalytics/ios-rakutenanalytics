import Foundation
import Testing
@testable import RakutenAnalytics
#if canImport(RAnalyticsTestHelpers)
import RAnalyticsTestHelpers
#endif

@Suite("AnalyticsEventTrackerIntegration")
struct AnalyticsEventTrackerIntegrationTests {
    let pushEventHandler: PushEventHandler = {
        return PushEventHandler(sharedUserStorageHandler: UserDefaults(suiteName: "group.test"), appGroupId: "group.test")
    }()
    
    let analyticsManager = AnalyticsManagerMock()
    
    @Test("Events are cached before the tracking - should track the events and clear the events cache")
    @MainActor
    func testTrackEventsAndClearCache() async throws {
        var tracker = AnalyticsEventTracker(pushEventHandler: pushEventHandler)
        tracker.delegate = analyticsManager
        
        defer {
            analyticsManager.processedEvents = [RAnalyticsEvent]()
        }
        
        for index in 0..<100 {
            let events = (0..<index + 1).map { [PushEventPayloadKeys.eventNameKey: "myEventName\($0)",
                                                PushEventPayloadKeys.eventParametersKey: ["rid": "bonjour\($0)"]] as [String: Any] }
            try await verifyEventsToTrack(events, tracker: &tracker)
        }
        
        func verifyEventsToTrack(_ events: [[String: Any]], tracker: inout AnalyticsEventTracker) async throws {
            pushEventHandler.save(darwinEvents: events)
            
            tracker.track()
            
            try await TestingHelpers.eventuallyOnMain { !analyticsManager.processedEvents.isEmpty }
            #expect(analyticsManager.processedEvents.count == events.count)
            
            for index in 0..<events.count {
                let eventName = events[index][PushEventPayloadKeys.eventNameKey] as? String
                #expect(analyticsManager.processedEvents[index].name == eventName)
            }
            
            let cache = pushEventHandler.cachedDarwinEvents()
            try await TestingHelpers.eventuallyOnMain { cache.isEmpty }
            #expect(cache.isEmpty)
            
            analyticsManager.processedEvents = [RAnalyticsEvent]()
        }
    }
    
    @Test("No events are cached before the tracking - should not track events")
    @MainActor
    func testNoEventsCachedShouldNotTrack() async throws {
        var tracker = AnalyticsEventTracker(pushEventHandler: pushEventHandler)
        tracker.delegate = analyticsManager
        
        defer {
            analyticsManager.processedEvents = [RAnalyticsEvent]()
        }
        
        tracker.track()
        
        try await TestingHelpers.performAsyncTestOnMain(timeForExecution: 1.0, timeout: 1.0) {
            #expect(analyticsManager.processedEvents.isEmpty)
        }
    }
    
    @Test("No events are cached before the tracking - should have an empty cache")
    @MainActor
    func testNoEventsCachedShouldHaveEmptyCache() async throws {
        var tracker = AnalyticsEventTracker(pushEventHandler: pushEventHandler)
        tracker.delegate = analyticsManager
        
        defer {
            analyticsManager.processedEvents = [RAnalyticsEvent]()
        }
        
        tracker.track()
        
        let cache = pushEventHandler.cachedDarwinEvents()
        
        try await TestingHelpers.performAsyncTestOnMain(timeForExecution: 1.0, timeout: 1.0) {
            #expect(cache.isEmpty)
        }
    }
}
