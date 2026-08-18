import Testing
import Foundation
@testable import RakutenAnalytics
#if canImport(RAnalyticsTestHelpers)
import RAnalyticsTestHelpers
#endif

@Suite("Poller functions")
struct GeoPollerTests {
    
    @Test("creates timer for location collection with time interval equal to delay param passed in function call")
    func testTimerCreationWithCorrectInterval() async throws {
        let runLoop: MockRunLoop = MockRunLoop()
        let poller = GeoPoller(runLoop: runLoop)
        
        poller.pollLocationCollection(delay: 10.5, repeats: true) { }
        
        try await TestingHelpers.eventually { runLoop.addedTimer?.timeInterval == 10.5 }
        #expect(runLoop.addedTimer?.timeInterval == 10.5)
    }
    
    @Test("should invalidate timer for location collection on calling invalidateLocationCollectionPoller()")
    func testTimerInvalidation() async throws {
        let runLoop: MockRunLoop = MockRunLoop()
        let poller = GeoPoller(runLoop: runLoop)
        poller.pollLocationCollection(delay: 10.5, repeats: true) { }
        
        try await TestingHelpers.eventually { runLoop.addedTimer != nil }
        
        poller.invalidateLocationCollectionPoller()
        
        try await TestingHelpers.eventually { runLoop.addedTimer?.isValid == false }
        #expect(runLoop.addedTimer?.isValid == false)
    }
    
    @Test("when repeats set as true, executes action closure in specified intervals")
    @MainActor
    func testRepeatsTrueExecutesMultipleTimes() async throws {
        var actionCalled = 0
        let poller = GeoPoller()
        
        poller.pollLocationCollection(delay: 0.5, repeats: true) {
            actionCalled += 1
        }
        
        // Give time for async dispatch to complete and timer to be added
        try? await Task.sleep(nanoseconds: 50_000_000) // 0.05 seconds
        
        // Poll until we get at least 2 executions (timer fires at 0.5s intervals)
        try await TestingHelpers.eventuallyOnMain(timeout: 2.0) { actionCalled >= 2 }
        #expect(actionCalled >= 2)
    }
    
    @Test("when repeats set as false, executes action closure exactly once")
    @MainActor
    func testRepeatsFalseExecutesOnce() async throws {
        var actionCalled = 0
        let poller = GeoPoller()
        
        poller.pollLocationCollection(delay: 0.5, repeats: false) {
            actionCalled += 1
        }
        
        // Give time for async dispatch to complete and timer to be added
        try? await Task.sleep(nanoseconds: 50_000_000) // 0.05 seconds
        
        // Poll until we get the single execution (timer fires once after 0.5s)
        try await TestingHelpers.eventuallyOnMain(timeout: 1.0) { actionCalled == 1 }
        #expect(actionCalled == 1)
    }
}
