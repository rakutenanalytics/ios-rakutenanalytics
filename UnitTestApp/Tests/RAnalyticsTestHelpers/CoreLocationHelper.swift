import Foundation
import CoreLocation
import Testing
@testable import RakutenAnalytics

// MARK: - CoreLocationHelper

/// Location verification helpers for RAnalyticsRATTracker payload tests.
/// These helpers require RAnalyticsRATExpecter and are only available in UnitTests target.
public enum CoreLocationHelper {
    
    /// Verifies that vertical accuracy is not set in the location payload
    public static func verifyNilVerticalAccuracy(expecter: RAnalyticsRATExpecter, locationModel: LocationModel) async throws {
        var payload: [String: Any]?
        let state = Tracking.defaultState
        state.lastKnownLocation = locationModel

        try await expecter.expectEventAsync(Tracking.defaultEvent, state: state, equal: "defaultEvent") {
            payload = $0.first
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

        try await expecter.expectEventAsync(Tracking.defaultEvent, state: state, equal: "defaultEvent") {
            payload = $0.first
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

        try await expecter.expectEventAsync(Tracking.defaultEvent, state: state, equal: "defaultEvent") {
            payload = $0.first
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

        try await expecter.expectEventAsync(Tracking.defaultEvent, state: state, equal: "defaultEvent") {
            payload = $0.first
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

        try await expecter.expectEventAsync(Tracking.defaultEvent, state: state, equal: "defaultEvent") {
            payload = $0.first
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

        try await expecter.expectEventAsync(Tracking.defaultEvent, state: state, equal: "defaultEvent") {
            payload = $0.first
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

        try await expecter.expectEventAsync(Tracking.defaultEvent, state: state, equal: "defaultEvent") {
            payload = $0.first
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

        try await expecter.expectEventAsync(Tracking.defaultEvent, state: state, equal: "defaultEvent") {
            payload = $0.first
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

        try await expecter.expectEventAsync(Tracking.defaultEvent, state: state, equal: "defaultEvent") {
            payload = $0.first
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

        try await expecter.expectEventAsync(Tracking.defaultEvent, state: state, equal: "defaultEvent") {
            payload = $0.first
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

        try await expecter.expectEventAsync(Tracking.defaultEvent, state: state, equal: "defaultEvent") {
            payload = $0.first
        }

        let loc = payload?["loc"] as? [String: Any]
        let bearing = loc?["bearing"] as? NSNumber
        #expect(bearing?.doubleValue == expectedBearing)
    }
}
