import Foundation
import CoreLocation
import Testing
@testable import RakutenAnalytics
#if canImport(RAnalyticsTestHelpers)
import RAnalyticsTestHelpers
#endif

public enum TestingHelpers {
    
    // MARK: - Location Verification Helpers
    
    /// Verifies that vertical accuracy is not set in the location payload
    public static func verifyNilVerticalAccuracy(expecter: RAnalyticsRATExpecter, locationModel: LocationModel) async throws {
        var payload: [String: Any]?
        let state = Tracking.defaultState
        state.lastKnownLocation = locationModel

        expecter.expectEvent(Tracking.defaultEvent, state: state, equal: "defaultEvent") {
            payload = $0.first
        }
        try await TestingHelpers.eventually {
            payload != nil
        }

        let loc = payload?["loc"] as? [String: Any]
        let verticalAccuracy = loc?["vertical_accuracy"] as? NSNumber
        #expect(verticalAccuracy?.doubleValue == nil)
    }
    
    /// Verifies that altitude is not set in the location payload
    public static func verifyNilAltitude(expecter: RAnalyticsRATExpecter, locationModel: LocationModel) async throws {
        var payload: [String: Any]?
        let state = Tracking.defaultState
        state.lastKnownLocation = locationModel

        expecter.expectEvent(Tracking.defaultEvent, state: state, equal: "defaultEvent") {
            payload = $0.first
        }
        try await TestingHelpers.eventually {
            payload != nil
        }

        let loc = payload?["loc"] as? [String: Any]
        let altitude = loc?["altitude"] as? NSNumber
        #expect(altitude?.doubleValue == nil)
    }
    
    /// Verifies that coordinates (accu, lat, long) are not set in the location payload
    public static func verifyNilCoordinates(expecter: RAnalyticsRATExpecter, locationModel: LocationModel) async throws {
        var payload: [String: Any]?
        let state = Tracking.defaultState
        state.lastKnownLocation = locationModel

        expecter.expectEvent(Tracking.defaultEvent, state: state, equal: "defaultEvent") {
            payload = $0.first
        }
        try await TestingHelpers.eventually {
            payload != nil
        }

        let loc = payload?["loc"] as? [String: Any]
        #expect(loc?["accu"] as? NSNumber == nil)
        #expect(loc?["lat"] as? NSNumber == nil)
        #expect(loc?["long"] as? NSNumber == nil)
    }
    
    /// Verifies horizontal accuracy value in the location payload
    public static func verifyHorizontalAccuracy(expecter: RAnalyticsRATExpecter, locationModel: LocationModel, expectedHorizontalAccuracy: CLLocationAccuracy) async throws {
        var payload: [String: Any]?
        let state = Tracking.defaultState
        state.lastKnownLocation = locationModel

        expecter.expectEvent(Tracking.defaultEvent, state: state, equal: "defaultEvent") {
            payload = $0.first
        }
        try await TestingHelpers.eventually {
            payload != nil
        }

        let loc = payload?["loc"] as? [String: Any]
        let accu = loc?["accu"] as? NSNumber
        #expect(accu?.doubleValue == expectedHorizontalAccuracy)
    }
    
    /// Verifies coordinate values (latitude and longitude) in the location payload
    public static func verifyCoordinates(expecter: RAnalyticsRATExpecter, locationModel: LocationModel, expectedLatitude: CLLocationDegrees, expectedLongitude: CLLocationDegrees) async throws {
        var payload: [String: Any]?
        let state = Tracking.defaultState
        state.lastKnownLocation = locationModel

        expecter.expectEvent(Tracking.defaultEvent, state: state, equal: "defaultEvent") {
            payload = $0.first
        }
        try await TestingHelpers.eventually {
            payload != nil
        }

        let loc = payload?["loc"] as? [String: Any]
        let lat = loc?["lat"] as? NSNumber
        let long = loc?["long"] as? NSNumber
        #expect(lat?.doubleValue == expectedLatitude)
        #expect(long?.doubleValue == expectedLongitude)
    }
    
    /// Verifies that speed parameters are not set in the location payload
    public static func verifyNilSpeedParameters(expecter: RAnalyticsRATExpecter, locationModel: LocationModel) async throws {
        var payload: [String: Any]?
        let state = Tracking.defaultState
        state.lastKnownLocation = locationModel

        expecter.expectEvent(Tracking.defaultEvent, state: state, equal: "defaultEvent") {
            payload = $0.first
        }
        try await TestingHelpers.eventually {
            payload != nil
        }

        let loc = payload?["loc"] as? [String: Any]
        #expect(loc?["speed_accuracy"] as? NSNumber == nil)
        #expect(loc?["speed"] as? NSNumber == nil)
    }
    
    /// Verifies speed accuracy value in the location payload
    public static func verifySpeedAccuracy(expecter: RAnalyticsRATExpecter, locationModel: LocationModel, expectedSpeedAccuracy: CLLocationSpeedAccuracy) async throws {
        var payload: [String: Any]?
        let state = Tracking.defaultState
        state.lastKnownLocation = locationModel

        expecter.expectEvent(Tracking.defaultEvent, state: state, equal: "defaultEvent") {
            payload = $0.first
        }
        try await TestingHelpers.eventually {
            payload != nil
        }

        let loc = payload?["loc"] as? [String: Any]
        let speedAccuracy = loc?["speed_accuracy"] as? NSNumber
        #expect(speedAccuracy?.doubleValue == expectedSpeedAccuracy)
    }
    
    /// Verifies speed value in the location payload
    public static func verifySpeed(expecter: RAnalyticsRATExpecter, locationModel: LocationModel, expectedSpeed: CLLocationSpeed) async throws {
        var payload: [String: Any]?
        let state = Tracking.defaultState
        state.lastKnownLocation = locationModel

        expecter.expectEvent(Tracking.defaultEvent, state: state, equal: "defaultEvent") {
            payload = $0.first
        }
        try await TestingHelpers.eventually {
            payload != nil
        }

        let loc = payload?["loc"] as? [String: Any]
        let speed = loc?["speed"] as? NSNumber
        #expect(speed?.doubleValue == expectedSpeed)
    }
    
    /// Verifies that bearing parameters are not set in the location payload
    public static func verifyNilBearingParameters(expecter: RAnalyticsRATExpecter, locationModel: LocationModel) async throws {
        var payload: [String: Any]?
        let state = Tracking.defaultState
        state.lastKnownLocation = locationModel

        expecter.expectEvent(Tracking.defaultEvent, state: state, equal: "defaultEvent") {
            payload = $0.first
        }
        try await TestingHelpers.eventually {
            payload != nil
        }

        let loc = payload?["loc"] as? [String: Any]
        #expect(loc?["bearing_accuracy"] as? NSNumber == nil)
        #expect(loc?["bearing"] as? NSNumber == nil)
    }
    
    /// Verifies bearing accuracy value in the location payload
    public static func verifyBearingAccuracy(expecter: RAnalyticsRATExpecter, locationModel: LocationModel, expectedBearingAccuracy: CLLocationDirectionAccuracy) async throws {
        var payload: [String: Any]?
        let state = Tracking.defaultState
        state.lastKnownLocation = locationModel

        expecter.expectEvent(Tracking.defaultEvent, state: state, equal: "defaultEvent") {
            payload = $0.first
        }
        try await TestingHelpers.eventually {
            payload != nil
        }

        let loc = payload?["loc"] as? [String: Any]
        let bearingAccuracy = loc?["bearing_accuracy"] as? NSNumber
        #expect(bearingAccuracy?.doubleValue == expectedBearingAccuracy)
    }
    
    /// Verifies bearing value in the location payload
    public static func verifyBearing(expecter: RAnalyticsRATExpecter, locationModel: LocationModel, expectedBearing: CLLocationDirection) async throws {
        var payload: [String: Any]?
        let state = Tracking.defaultState
        state.lastKnownLocation = locationModel

        expecter.expectEvent(Tracking.defaultEvent, state: state, equal: "defaultEvent") {
            payload = $0.first
        }
        try await TestingHelpers.eventually {
            payload != nil
        }

        let loc = payload?["loc"] as? [String: Any]
        let bearing = loc?["bearing"] as? NSNumber
        #expect(bearing?.doubleValue == expectedBearing)
    }
    
    /// Polls until a condition is met, similar to `toEventually` in Quick/Nimble
    /// - Parameters:
    ///   - timeout: Maximum time to wait for the condition (default: 2.0 seconds)
    ///   - condition: Closure that returns true when the condition is met
    /// - Throws: `TestError.conditionNotMet` if condition is not met within timeout
    public static func eventually(timeout: TimeInterval = 2.0, condition: @escaping () -> Bool) async throws {
        let startTime = Date()
        let pollInterval = 50_000_000 // 0.05 seconds
        
        while Date().timeIntervalSince(startTime) < timeout {
            if condition() {
                return
            }
            try await Task.sleep(nanoseconds: UInt64(pollInterval))
        }
        
        if !condition() {
            throw TestError.conditionNotMet
        }
    }
    
    /// Polls until a condition is met on main actor, allowing run loop events to process
    /// Similar to `toEventually` in Quick/Nimble, but ensures run loop processes timer events
    /// - Parameters:
    ///   - timeout: Maximum time to wait for the condition (default: 2.0 seconds)
    ///   - condition: Closure that returns true when the condition is met
    /// - Throws: `TestError.conditionNotMet` if condition is not met within timeout
    @MainActor
    public static func eventuallyOnMain(timeout: TimeInterval = 2.0, condition: @escaping () -> Bool) async throws {
        let startTime = Date()
        // Use a longer poll interval to give run loop time to process timer events
        let pollInterval = 100_000_000 // 0.1 seconds
        
        while Date().timeIntervalSince(startTime) < timeout {
            // Yield to allow other tasks and run loop events to process
            await Task.yield()
            
            if condition() {
                return
            }
            // Sleep longer to allow run loop to process timer events
            try await Task.sleep(nanoseconds: UInt64(pollInterval))
        }
        
        if !condition() {
            throw TestError.conditionNotMet
        }
    }
    
    /// Performs an async test similar to `QuickSpec.performAsyncTest`
    /// Waits for a specified timeout period, then executes the expectation closure
    /// - Parameters:
    ///   - timeForExecution: Expected time for async work to complete (used for documentation/logging)
    ///   - timeout: Time to wait before executing the expectation closure
    ///   - expectation: Closure containing test assertions to execute after the wait period
    /// - Note: This is equivalent to Quick/Nimble's `performAsyncTest`. The expectation is executed
    ///   after `timeout` seconds, allowing async work (expected to complete in `timeForExecution`) to finish.
    public static func performAsyncTest(
        timeForExecution: TimeInterval,
        timeout: TimeInterval,
        expectation: @escaping () async throws -> Void
    ) async throws {
        // Wait for the timeout period (equivalent to Quick's asyncAfter delay)
        let timeoutNanoseconds = UInt64(timeout * 1_000_000_000)
        try await Task.sleep(nanoseconds: timeoutNanoseconds)
        
        // Execute the expectation
        try await expectation()
    }
    
    /// Performs an async test on the main actor, similar to `QuickSpec.performAsyncTest`
    /// Waits for a specified timeout period, then executes the expectation closure on the main thread
    /// - Parameters:
    ///   - timeForExecution: Expected time for async work to complete (used for documentation/logging)
    ///   - timeout: Time to wait before executing the expectation closure
    ///   - expectation: Closure containing test assertions to execute after the wait period
    /// - Note: This ensures the expectation runs on the main thread, useful for UI-related tests.
    ///   The expectation is executed after `timeout` seconds, allowing async work to finish.
    @MainActor
    public static func performAsyncTestOnMain(
        timeForExecution: TimeInterval,
        timeout: TimeInterval,
        expectation: @escaping () async throws -> Void
    ) async throws {
        // Wait for the timeout period, yielding to allow run loop to process events
        let startTime = Date()
        while Date().timeIntervalSince(startTime) < timeout {
            await Task.yield()
            try await Task.sleep(nanoseconds: 10_000_000) // 0.01 seconds
        }
        
        // Execute the expectation on main actor
        try await expectation()
    }
    
    /// Error thrown when a condition is not met within the timeout period
    public enum TestError: Error {
        case conditionNotMet
    }
}

