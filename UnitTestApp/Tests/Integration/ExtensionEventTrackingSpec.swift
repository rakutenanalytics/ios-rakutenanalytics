import Foundation
import Testing
@testable import RakutenAnalytics
#if canImport(RAnalyticsTestHelpers)
import RAnalyticsTestHelpers
#endif

@Suite("ExtensionEventTracking")
struct ExtensionEventTrackingSpec {
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
        
        observer.startObservation(delegate: analyticsManager)
        
        for index in 0..<100 {
            AnalyticsEventPoster.post(
                name: RAnalyticsEvent.Name.pushNotificationExternal,
                parameters: ["rid": "helloworld\(index)"],
                pushEventHandler: pushEventHandler)
            
            try await TestingHelpers.eventuallyOnMain { !analyticsManager.processedEvents.isEmpty }
            #expect(analyticsManager.processedEvents.count == 1)
            #expect(analyticsManager.processedEvents.first?.name == RAnalyticsEvent.Name.pushNotificationExternal)
            #expect(analyticsManager.processedEvents.first?.parameters as? [String: AnyHashable] == ["rid": "helloworld\(index)"])
            
            let eventsCache = pushEventHandler.cachedDarwinEvents()
            try await TestingHelpers.eventuallyOnMain { eventsCache.isEmpty }
            #expect(eventsCache.isEmpty)
            
            analyticsManager.processedEvents = [RAnalyticsEvent]()
        }
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
        
        let eventsCache = pushEventHandler.cachedDarwinEvents()
        try await TestingHelpers.eventuallyOnMain { eventsCache.isEmpty }
        #expect(eventsCache.isEmpty)
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
        
        let eventsCache = pushEventHandler.cachedDarwinEvents()
        try await TestingHelpers.eventuallyOnMain { eventsCache.isEmpty }
        #expect(eventsCache.isEmpty)
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
        
        let eventsCache = pushEventHandler.cachedDarwinEvents()
        try await TestingHelpers.eventuallyOnMain { eventsCache.isEmpty }
        #expect(eventsCache.isEmpty)
    }
}
