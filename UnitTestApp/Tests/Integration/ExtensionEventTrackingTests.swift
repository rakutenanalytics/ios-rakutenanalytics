import Foundation
import Testing
@testable import RakutenAnalytics
#if canImport(RAnalyticsTestHelpers)
import RAnalyticsTestHelpers
#endif

@Suite("ExtensionEventTracking")
struct ExtensionEventTrackingTests {
    let pushEventHandler: PushEventHandler = {
        return PushEventHandler(sharedUserStorageHandler: UserDefaults(suiteName: "group.test"), appGroupId: "group.test")
    }()
    
    let analyticsManager = AnalyticsManagerMock()
    
    @Test("AnalyticsEventObserver starts observation before events - An event is posted - should process the event and clear the events cache")
    @MainActor
    func testObserverStartsBeforeEventPostedProcessesAndClearsCache() async throws {
        let observer = AnalyticsEventObserver(pushEventHandler: pushEventHandler)
        
        defer {
            observer.stopObservation()
        }
        
        // Ensure no events leak in from other tests using the same app group suite.
        pushEventHandler.clearDarwinEventsCache()
        analyticsManager.processedEvents = []

        observer.startObservation(delegate: analyticsManager)
        
        // Post many events while observation is active.
        // Keep this reasonably small: the Darwin notification delivery can be asynchronous and polling on
        // the main actor uses a 0.1s interval, so very large counts can inflate wall-clock time in CI.
        let eventCount = 20
        for index in 0..<eventCount {
            AnalyticsEventPoster.post(
                name: RAnalyticsEvent.Name.pushNotificationExternal,
                parameters: ["rid": "helloworld\(index)"],
                pushEventHandler: pushEventHandler)
        }

        // Wait once until all events are processed (instead of polling per event).
        try await TestingHelpers.eventuallyOnMain { analyticsManager.processedEvents.count == eventCount }
        #expect(analyticsManager.processedEvents.count == eventCount)

        // Validate we received the expected payloads (order is not guaranteed across multiple notifications).
        #expect(analyticsManager.processedEvents.allSatisfy { $0.name == RAnalyticsEvent.Name.pushNotificationExternal })

        let receivedRids: Set<String> = Set(
            analyticsManager.processedEvents.compactMap { $0.parameters["rid"] as? String }
        )
        let expectedRids = Set((0..<eventCount).map { "helloworld\($0)" })
        #expect(receivedRids == expectedRids)

        // Cache should be cleared once events are tracked.
        try await TestingHelpers.eventuallyOnMain { pushEventHandler.cachedDarwinEvents().isEmpty }
        #expect(pushEventHandler.cachedDarwinEvents().isEmpty)
    }
    
    @Test("AnalyticsEventObserver starts observation before events - No event is posted - should not process any events")
    @MainActor
    func testObserverStartsBeforeNoEventPostedShouldNotProcessEvents() async throws {
        let observer = AnalyticsEventObserver(pushEventHandler: pushEventHandler)
        
        defer {
            observer.stopObservation()
        }
        
        observer.startObservation(delegate: analyticsManager)
        
        #expect(analyticsManager.processedEvents.isEmpty)
    }
    
    @Test("AnalyticsEventObserver starts observation before events - No event is posted - should have an empty cache")
    @MainActor
    func testObserverStartsBeforeNoEventPostedShouldHaveEmptyCache() async throws {
        let observer = AnalyticsEventObserver(pushEventHandler: pushEventHandler)
        
        defer {
            observer.stopObservation()
        }
        
        observer.startObservation(delegate: analyticsManager)
        
        try await TestingHelpers.eventuallyOnMain { pushEventHandler.cachedDarwinEvents().isEmpty }
        #expect(pushEventHandler.cachedDarwinEvents().isEmpty)
    }
    
    @Test("AnalyticsEventObserver starts observation after events - Many events are posted - should process the event and clear the events cache")
    @MainActor
    func testObserverStartsAfterManyEventsPostedProcessesAndClearsCache() async throws {
        let observer = AnalyticsEventObserver(pushEventHandler: pushEventHandler)
        
        defer {
            observer.stopObservation()
            analyticsManager.processedEvents = [RAnalyticsEvent]()
        }
        
        for index in 0..<100 {
            AnalyticsEventPoster.post(
                name: RAnalyticsEvent.Name.pushNotificationExternal,
                parameters: ["rid": "helloworld\(index)"],
                pushEventHandler: pushEventHandler)
        }
        
        observer.startObservation(delegate: analyticsManager)
        observer.trackCachedEvents()
        
        try await TestingHelpers.eventuallyOnMain { !analyticsManager.processedEvents.isEmpty }
        #expect(analyticsManager.processedEvents.count == 100)
        
        for index in 0..<100 {
            #expect(analyticsManager.processedEvents[index].name == RAnalyticsEvent.Name.pushNotificationExternal)
            #expect(analyticsManager.processedEvents[index].parameters as? [String: AnyHashable] == ["rid": "helloworld\(index)"])
        }
        
        try await TestingHelpers.eventuallyOnMain { pushEventHandler.cachedDarwinEvents().isEmpty }
        #expect(pushEventHandler.cachedDarwinEvents().isEmpty)
    }
    
    @Test("AnalyticsEventObserver starts observation after events - No event is posted - should not process any events")
    @MainActor
    func testObserverStartsAfterNoEventPostedShouldNotProcessEvents() async throws {
        let observer = AnalyticsEventObserver(pushEventHandler: pushEventHandler)
        
        defer {
            observer.stopObservation()
            analyticsManager.processedEvents = [RAnalyticsEvent]()
        }
        
        observer.startObservation(delegate: analyticsManager)
        observer.trackCachedEvents()
        
        #expect(analyticsManager.processedEvents.isEmpty)
    }
    
    @Test("AnalyticsEventObserver starts observation after events - No event is posted - should have an empty cache")
    @MainActor
    func testObserverStartsAfterNoEventPostedShouldHaveEmptyCache() async throws {
        let observer = AnalyticsEventObserver(pushEventHandler: pushEventHandler)
        
        defer {
            observer.stopObservation()
            analyticsManager.processedEvents = [RAnalyticsEvent]()
        }
        
        observer.startObservation(delegate: analyticsManager)
        observer.trackCachedEvents()
        
        try await TestingHelpers.eventuallyOnMain { pushEventHandler.cachedDarwinEvents().isEmpty }
        #expect(pushEventHandler.cachedDarwinEvents().isEmpty)
    }
}
