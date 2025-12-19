import Foundation
import Testing
@testable import RakutenAnalytics
#if canImport(RAnalyticsTestHelpers)
import RAnalyticsTestHelpers
#endif

@Suite("PushEventHandlerIntegration")
struct PushEventHandlerIntegrationTests {
    let pushEventHandler: PushEventHandler = {
        return PushEventHandler(sharedUserStorageHandler: UserDefaults(suiteName: "group.test"), appGroupId: "group.test")
    }()
    
    @Test("should save the expected events in the cache")
    @MainActor
    func testSaveExpectedEventsInCache() async throws {
        defer {
            pushEventHandler.clearDarwinEventsCache()
        }
        
        for index in 0..<100 {
            let expectedEvents = (0..<index + 1).map { ["key\($0)": "value\($0)"] as [String: Any] }
            try await verifySavedEvents(expectedEvents)
        }
        
        func verifySavedEvents(_ expectedEvents: [[String: Any]]) async throws {
            pushEventHandler.save(darwinEvents: expectedEvents)
            let cachedDarwinEvents = pushEventHandler.cachedDarwinEvents()
            
            try await TestingHelpers.eventuallyOnMain { cachedDarwinEvents.count == expectedEvents.count }
            #expect(cachedDarwinEvents.count == expectedEvents.count)
            
            for (index, expectedEvent) in expectedEvents.enumerated() {
                let cachedEvent = cachedDarwinEvents[index]
                for (key, expectedValue) in expectedEvent {
                    guard let cachedValue = cachedEvent[key] else {
                        #expect(Bool(false), "Cached value for key '\(key)' is nil")
                        continue
                    }
                    if let expectedString = expectedValue as? String,
                       let cachedString = cachedValue as? String {
                        #expect(cachedString == expectedString)
                    } else {
                        let expectedNS = expectedValue as? NSObject
                        let cachedNS = cachedValue as? NSObject
                        #expect(cachedNS?.isEqual(expectedNS) == true)
                    }
                }
            }
            
            pushEventHandler.clearDarwinEventsCache()
        }
    }
    
    @Test("should clear the expected events from the cache")
    @MainActor
    func testClearExpectedEventsFromCache() async throws {
        defer {
            pushEventHandler.clearDarwinEventsCache()
        }
        
        for index in 0..<100 {
            let eventsToSave = (0..<index + 1).map { ["key\($0)": "value\($0)"] as [String: Any] }
            try await verifyCachedEvents(eventsToSave)
        }
        
        func verifyCachedEvents(_ eventsToSave: [[String: Any]]) async throws {
            pushEventHandler.save(darwinEvents: eventsToSave)
            let eventsSavedInCache = pushEventHandler.cachedDarwinEvents()
            
            try await TestingHelpers.eventuallyOnMain { eventsSavedInCache.count == eventsToSave.count }
            #expect(eventsSavedInCache.count == eventsToSave.count)
            
            pushEventHandler.clearDarwinEventsCache()
            let events = pushEventHandler.cachedDarwinEvents()
            
            try await TestingHelpers.eventuallyOnMain { events.isEmpty }
            #expect(events.isEmpty)
        }
    }
}
