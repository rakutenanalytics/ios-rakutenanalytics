import Testing
import RAnalyticsBroadcast
@testable import RakutenAnalytics
#if canImport(RAnalyticsTestHelpers)
import RAnalyticsTestHelpers
#endif

// MARK: - RABEventBroadcasterSpec

@Suite("sendEventName")
struct RABEventBroadcasterSpec {
    
    @Test("should track AnalyticsManager.Event.Name.custom with eventName and eventData when an event is broadcasted with data")
    @MainActor
    func testTrackEventWithData() async throws {
        let dependenciesContainer = SimpleContainerMock()
        dependenciesContainer.bundle = BundleMock.create()
        let tracker = AnalyticsTrackerMock()
        
        let externalCollector = RAnalyticsExternalCollector(dependenciesContainer: dependenciesContainer)
        externalCollector.trackerDelegate = tracker
        
        defer {
            tracker.reset()
        }
        
        try await TestingHelpers.eventuallyOnMain { tracker.eventName == nil }
        try await TestingHelpers.eventuallyOnMain { tracker.params == nil }
        
        RABEventBroadcaster.sendEventName("blah", dataObject: ["foo": "bar"])
        
        try await TestingHelpers.eventuallyOnMain { tracker.eventName == AnalyticsManager.Event.Name.custom }
        try await TestingHelpers.eventuallyOnMain { (tracker.params?["eventName"] as? String) == "blah" }
        try await TestingHelpers.eventuallyOnMain { (tracker.params?["eventData"] as? [String: String]) == ["foo": "bar"] }
        
        #expect(tracker.eventName == AnalyticsManager.Event.Name.custom)
        #expect(tracker.params?["eventName"] as? String == "blah")
        #expect(tracker.params?["eventData"] as? [String: String] == ["foo": "bar"])
    }
    
    @Test("should track AnalyticsManager.Event.Name.custom with eventName and no eventData when an event is broadcasted without data")
    @MainActor
    func testTrackEventWithoutData() async throws {
        let dependenciesContainer = SimpleContainerMock()
        dependenciesContainer.bundle = BundleMock.create()
        let tracker = AnalyticsTrackerMock()
        
        let externalCollector = RAnalyticsExternalCollector(dependenciesContainer: dependenciesContainer)
        externalCollector.trackerDelegate = tracker
        
        defer {
            tracker.reset()
        }
        
        try await TestingHelpers.eventuallyOnMain { tracker.eventName == nil }
        try await TestingHelpers.eventuallyOnMain { tracker.params == nil }
        
        RABEventBroadcaster.sendEventName("blah", dataObject: nil)
        
        try await TestingHelpers.eventuallyOnMain { tracker.eventName == AnalyticsManager.Event.Name.custom }
        try await TestingHelpers.eventuallyOnMain { (tracker.params?["eventName"] as? String) == "blah" }
        try await TestingHelpers.eventuallyOnMain { tracker.params?["eventData"] == nil }
        
        #expect(tracker.eventName == AnalyticsManager.Event.Name.custom)
        #expect(tracker.params?["eventName"] as? String == "blah")
        #expect(tracker.params?["eventData"] == nil)
    }
}
