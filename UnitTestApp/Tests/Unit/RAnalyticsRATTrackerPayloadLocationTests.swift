// swiftlint:disable line_length
// swiftlint:disable type_body_length
// swiftlint:disable function_body_length
// swiftlint:disable control_statement

import Foundation
import Testing
import CoreLocation
@preconcurrency @testable import RakutenAnalytics
#if canImport(RAnalyticsTestHelpers)
import RAnalyticsTestHelpers
#endif

@Suite("RAnalyticsRATTracker")
struct RAnalyticsRATTrackerPayloadLocationTests {
    @Suite("process(event:state:)")
    struct ProcessEventStateTests {
        @Suite("Location")
        struct LocationTests {
            var helper = PayloadTestHelper.TestHelper()
            
            @Test("should set a non-empty loc dictionary")
            mutating func testShouldSetNonEmptyLocDictionary() async throws {
                helper.setUp()
                defer { helper.tearDown() }
                
                var payload: [String: Any]?
                
                try await helper.expecter.expectEventAsync(Tracking.defaultEvent, state: Tracking.defaultState, equal: "defaultEvent") {
                    payload = $0.first
                }
                
                let loc = payload?["loc"] as? [String: Any]
                #expect(loc != nil)
            }
            
            @Suite("When vertical accuracy < 0")
            struct WhenVerticalAccuracyLessThanZeroTests {
                var helper = PayloadTestHelper.TestHelper()
                let locationModel = LocationModel.create(verticalAccuracy: -1)
                
                @Test("should not set vertical accuracy")
                mutating func testShouldNotSetVerticalAccuracy() async throws {
                    helper.setUp()
                    defer { helper.tearDown() }
                    try await CoreLocationHelper.verifyNilVerticalAccuracy(expecter: helper.expecter, locationModel: locationModel)
                }
                
                @Test("should not set altitude")
                mutating func testShouldNotSetAltitude() async throws {
                    helper.setUp()
                    defer { helper.tearDown() }
                    try await CoreLocationHelper.verifyNilAltitude(expecter: helper.expecter, locationModel: locationModel)
                }
            }
            
            @Suite("When vertical accuracy == 0")
            struct WhenVerticalAccuracyEqualsZeroTests {
                var helper = PayloadTestHelper.TestHelper()
                let locationModel = LocationModel.create(verticalAccuracy: 0)
                
                @Test("should not set vertical accuracy")
                mutating func testShouldNotSetVerticalAccuracy() async throws {
                    helper.setUp()
                    defer { helper.tearDown() }
                    try await CoreLocationHelper.verifyNilVerticalAccuracy(expecter: helper.expecter, locationModel: locationModel)
                }
                
                @Test("should not set altitude")
                mutating func testShouldNotSetAltitude() async throws {
                    helper.setUp()
                    defer { helper.tearDown() }
                    try await CoreLocationHelper.verifyNilAltitude(expecter: helper.expecter, locationModel: locationModel)
                }
            }
            
            @Suite("When vertical accuracy > 0")
            struct WhenVerticalAccuracyGreaterThanZeroTests {
                var helper = PayloadTestHelper.TestHelper()
                let locationModel = LocationModel.create(verticalAccuracy: 10, altitude: 153)
                
                @Test("should set vertical accuracy")
                mutating func testShouldSetVerticalAccuracy() async throws {
                    helper.setUp()
                    defer { helper.tearDown() }
                    
                    var payload: [String: Any]?
                    let state = Tracking.defaultState
                    state.lastKnownLocation = locationModel
                    
                    try await helper.expecter.expectEventAsync(Tracking.defaultEvent, state: state, equal: "defaultEvent") {
                        payload = $0.first
                    }
                    
                    let loc = payload?["loc"] as? [String: Any]
                    let verticalAccuracy = loc?["vertical_accuracy"] as? NSNumber
                    #expect(verticalAccuracy?.doubleValue == 10)
                }
                
                @Test("should set altitude")
                mutating func testShouldSetAltitude() async throws {
                    helper.setUp()
                    defer { helper.tearDown() }
                    
                    var payload: [String: Any]?
                    let state = Tracking.defaultState
                    state.lastKnownLocation = locationModel
                    
                    try await helper.expecter.expectEventAsync(Tracking.defaultEvent, state: state, equal: "defaultEvent") {
                        payload = $0.first
                    }
                    
                    let loc = payload?["loc"] as? [String: Any]
                    let altitude = loc?["altitude"] as? NSNumber
                    #expect(altitude?.doubleValue == 153)
                }
            }
            
            @Test("should set a non-nil tms")
            mutating func testShouldSetNonNilTms() async throws {
                helper.setUp()
                defer { helper.tearDown() }
                
                let timestamp: TimeInterval = 1679991767.626
                let locationModel = LocationModel.create(timestamp: Date(timeIntervalSince1970: timestamp))
                
                var payload: [String: Any]?
                let state = Tracking.defaultState
                state.lastKnownLocation = locationModel
                
                try await helper.expecter.expectEventAsync(Tracking.defaultEvent, state: state, equal: "defaultEvent") {
                    payload = $0.first
                }
                
                let loc = payload?["loc"] as? [String: Any]
                let tms = loc?["tms"] as? NSNumber
                #expect(tms?.doubleValue == timestamp * 1000.0)
            }
            
            @Suite("When horizontal accuracy < 0")
            struct WhenHorizontalAccuracyLessThanZeroTests {
                var helper = PayloadTestHelper.TestHelper()
                
                @Test("should not set accu, lat, or long")
                mutating func testShouldNotSetCoordinates() async throws {
                    helper.setUp()
                    defer { helper.tearDown() }
                    try await CoreLocationHelper.verifyNilCoordinates(expecter: helper.expecter, locationModel: LocationModel.create(horizontalAccuracy: -9))
                }
            }
            
            @Suite("When latitude has an unexpected value")
            struct WhenLatitudeHasUnexpectedValueTests {
                var helper = PayloadTestHelper.TestHelper()
                
                @Test("should not set accu, lat, or long")
                mutating func testShouldNotSetCoordinates() async throws {
                    helper.setUp()
                    defer { helper.tearDown() }
                    try await CoreLocationHelper.verifyNilCoordinates(expecter: helper.expecter, locationModel: LocationModel.create(latitude: 5600))
                }
            }
            
            @Suite("When longitude has an unexpected value")
            struct WhenLongitudeHasUnexpectedValueTests {
                var helper = PayloadTestHelper.TestHelper()
                
                @Test("should not set accu, lat, or long")
                mutating func testShouldNotSetCoordinates() async throws {
                    helper.setUp()
                    defer { helper.tearDown() }
                    try await CoreLocationHelper.verifyNilCoordinates(expecter: helper.expecter, locationModel: LocationModel.create(latitude: -432))
                }
            }
            
            @Suite("When horizontal accuracy < 0 and latitude & longitude have unexpected values")
            struct WhenHorizontalAccuracyLessThanZeroAndLatLongUnexpectedTests {
                var helper = PayloadTestHelper.TestHelper()
                
                @Test("should not set accu, lat, or long")
                mutating func testShouldNotSetCoordinates() async throws {
                    helper.setUp()
                    defer { helper.tearDown() }
                    try await CoreLocationHelper.verifyNilCoordinates(expecter: helper.expecter, locationModel: LocationModel.create(latitude: 5600, longitude: -432, horizontalAccuracy: -9))
                }
            }
            
            @Suite("When horizontal accuracy == 0")
            struct WhenHorizontalAccuracyEqualsZeroTests {
                var helper = PayloadTestHelper.TestHelper()
                let locationModel = LocationModel.create(latitude: -56.6462520, longitude: -36.6462520, horizontalAccuracy: 0)
                
                @Test("should set accu to an expected value")
                mutating func testShouldSetAccuToExpectedValue() async throws {
                    helper.setUp()
                    defer { helper.tearDown() }
                    try await CoreLocationHelper.verifyHorizontalAccuracy(expecter: helper.expecter, locationModel: locationModel, expectedHorizontalAccuracy: 0)
                }
                
                @Test("should set coordinates")
                mutating func testShouldSetCoordinates() async throws {
                    helper.setUp()
                    defer { helper.tearDown() }
                    try await CoreLocationHelper.verifyCoordinates(expecter: helper.expecter, locationModel: locationModel, expectedLatitude: -56.6462520, expectedLongitude: -36.6462520)
                }
            }
            
            @Suite("When horizontal accuracy > 0")
            struct WhenHorizontalAccuracyGreaterThanZeroTests {
                var helper = PayloadTestHelper.TestHelper()
                let locationModel = LocationModel.create(latitude: -56.6462520, longitude: -36.6462520, horizontalAccuracy: 10)
                
                @Test("should set accu to an expected value")
                mutating func testShouldSetAccuToExpectedValue() async throws {
                    helper.setUp()
                    defer { helper.tearDown() }
                    try await CoreLocationHelper.verifyHorizontalAccuracy(expecter: helper.expecter, locationModel: locationModel, expectedHorizontalAccuracy: 10)
                }
                
                @Test("should set coordinates")
                mutating func testShouldSetCoordinates() async throws {
                    helper.setUp()
                    defer { helper.tearDown() }
                    try await CoreLocationHelper.verifyCoordinates(expecter: helper.expecter, locationModel: locationModel, expectedLatitude: -56.6462520, expectedLongitude: -36.6462520)
                }
            }
            
            @Suite("When speed accuracy < 0")
            struct WhenSpeedAccuracyLessThanZeroTests {
                @Suite("When speed > 0")
                struct WhenSpeedGreaterThanZeroTests {
                    var helper = PayloadTestHelper.TestHelper()
                    
                    @Test("should not set speed parameters")
                    mutating func testShouldNotSetSpeedParameters() async throws {
                        helper.setUp()
                        defer { helper.tearDown() }
                        try await CoreLocationHelper.verifyNilSpeedParameters(expecter: helper.expecter, locationModel: LocationModel.create(speed: 180, speedAccuracy: -7))
                    }
                }
                
                @Suite("When speed == 0")
                struct WhenSpeedEqualsZeroTests {
                    var helper = PayloadTestHelper.TestHelper()
                    
                    @Test("should not set speed parameters")
                    mutating func testShouldNotSetSpeedParameters() async throws {
                        helper.setUp()
                        defer { helper.tearDown() }
                        try await CoreLocationHelper.verifyNilSpeedParameters(expecter: helper.expecter, locationModel: LocationModel.create(speed: 0, speedAccuracy: -7))
                    }
                }
            }
            
            @Suite("When speed < 0")
            struct WhenSpeedLessThanZeroTests {
                @Suite("When speed accuracy > 0")
                struct WhenSpeedAccuracyGreaterThanZeroTests {
                    var helper = PayloadTestHelper.TestHelper()
                    
                    @Test("should not set speed parameters")
                    mutating func testShouldNotSetSpeedParameters() async throws {
                        helper.setUp()
                        defer { helper.tearDown() }
                        try await CoreLocationHelper.verifyNilSpeedParameters(expecter: helper.expecter, locationModel: LocationModel.create(speed: -180, speedAccuracy: 7))
                    }
                }
                
                @Suite("When speed accuracy == 0")
                struct WhenSpeedAccuracyEqualsZeroTests {
                    var helper = PayloadTestHelper.TestHelper()
                    
                    @Test("should not set speed parameters")
                    mutating func testShouldNotSetSpeedParameters() async throws {
                        helper.setUp()
                        defer { helper.tearDown() }
                        try await CoreLocationHelper.verifyNilSpeedParameters(expecter: helper.expecter, locationModel: LocationModel.create(speed: -180, speedAccuracy: 0))
                    }
                }
            }
            
            @Suite("When speed accuracy < 0 and speed < 0")
            struct WhenSpeedAccuracyLessThanZeroAndSpeedLessThanZeroTests {
                var helper = PayloadTestHelper.TestHelper()
                
                @Test("should not set speed parameters")
                mutating func testShouldNotSetSpeedParameters() async throws {
                    helper.setUp()
                    defer { helper.tearDown() }
                    try await CoreLocationHelper.verifyNilSpeedParameters(expecter: helper.expecter, locationModel: LocationModel.create(speed: -180, speedAccuracy: -7))
                }
            }
            
            @Suite("When speed accuracy == 0")
            struct WhenSpeedAccuracyEqualsZeroTests {
                var helper = PayloadTestHelper.TestHelper()
                let locationModel = LocationModel.create(speed: 54, speedAccuracy: 0)
                
                @Test("should set speed accuracy")
                mutating func testShouldSetSpeedAccuracy() async throws {
                    helper.setUp()
                    defer { helper.tearDown() }
                    try await CoreLocationHelper.verifySpeedAccuracy(expecter: helper.expecter, locationModel: locationModel, expectedSpeedAccuracy: 0)
                }
                
                @Test("should set speed to an expected value")
                mutating func testShouldSetSpeedToExpectedValue() async throws {
                    helper.setUp()
                    defer { helper.tearDown() }
                    try await CoreLocationHelper.verifySpeed(expecter: helper.expecter, locationModel: locationModel, expectedSpeed: 54)
                }
            }
            
            @Suite("When speed accuracy > 0")
            struct WhenSpeedAccuracyGreaterThanZeroTests {
                var helper = PayloadTestHelper.TestHelper()
                let locationModel = LocationModel.create(speed: 180, speedAccuracy: 7)
                
                @Test("should set speed accuracy")
                mutating func testShouldSetSpeedAccuracy() async throws {
                    helper.setUp()
                    defer { helper.tearDown() }
                    try await CoreLocationHelper.verifySpeedAccuracy(expecter: helper.expecter, locationModel: locationModel, expectedSpeedAccuracy: 7)
                }
                
                @Test("should set speed to an expected value")
                mutating func testShouldSetSpeedToExpectedValue() async throws {
                    helper.setUp()
                    defer { helper.tearDown() }
                    try await CoreLocationHelper.verifySpeed(expecter: helper.expecter, locationModel: locationModel, expectedSpeed: 180)
                }
            }
            
            @Suite("When course accuracy < 0")
            struct WhenCourseAccuracyLessThanZeroTests {
                @Suite("When course > 0")
                struct WhenCourseGreaterThanZeroTests {
                    var helper = PayloadTestHelper.TestHelper()
                    
                    @Test("should not set bearing parameters")
                    mutating func testShouldNotSetBearingParameters() async throws {
                        helper.setUp()
                        defer { helper.tearDown() }
                        try await CoreLocationHelper.verifyNilBearingParameters(expecter: helper.expecter, locationModel: LocationModel.create(course: 2, courseAccuracy: -1))
                    }
                }
                
                @Suite("When course == 0")
                struct WhenCourseEqualsZeroTests {
                    var helper = PayloadTestHelper.TestHelper()
                    
                    @Test("should not set bearing parameters")
                    mutating func testShouldNotSetBearingParameters() async throws {
                        helper.setUp()
                        defer { helper.tearDown() }
                        try await CoreLocationHelper.verifyNilBearingParameters(expecter: helper.expecter, locationModel: LocationModel.create(course: 0, courseAccuracy: -1))
                    }
                }
            }
            
            @Suite("When course < 0")
            struct WhenCourseLessThanZeroTests {
                @Suite("When course accuracy > 0")
                struct WhenCourseAccuracyGreaterThanZeroTests {
                    var helper = PayloadTestHelper.TestHelper()
                    
                    @Test("should not set bearing parameters")
                    mutating func testShouldNotSetBearingParameters() async throws {
                        helper.setUp()
                        defer { helper.tearDown() }
                        try await CoreLocationHelper.verifyNilBearingParameters(expecter: helper.expecter, locationModel: LocationModel.create(course: -2, courseAccuracy: 1))
                    }
                }
                
                @Suite("When course accuracy == 0")
                struct WhenCourseAccuracyEqualsZeroTests {
                    var helper = PayloadTestHelper.TestHelper()
                    
                    @Test("should not set bearing parameters")
                    mutating func testShouldNotSetBearingParameters() async throws {
                        helper.setUp()
                        defer { helper.tearDown() }
                        try await CoreLocationHelper.verifyNilBearingParameters(expecter: helper.expecter, locationModel: LocationModel.create(course: -2, courseAccuracy: 0))
                    }
                }
            }
            
            @Suite("When course < 0 and course accuracy < 0")
            struct WhenCourseLessThanZeroAndCourseAccuracyLessThanZeroTests {
                var helper = PayloadTestHelper.TestHelper()
                
                @Test("should not set bearing parameters")
                mutating func testShouldNotSetBearingParameters() async throws {
                    helper.setUp()
                    defer { helper.tearDown() }
                    try await CoreLocationHelper.verifyNilBearingParameters(expecter: helper.expecter, locationModel: LocationModel.create(course: -2, courseAccuracy: -1))
                }
            }
            
            @Suite("When course accuracy == 0")
            struct WhenCourseAccuracyEqualsZeroTests {
                var helper = PayloadTestHelper.TestHelper()
                let locationModel = LocationModel.create(course: 2, courseAccuracy: 0)
                
                @Test("should set bearing accuracy")
                mutating func testShouldSetBearingAccuracy() async throws {
                    helper.setUp()
                    defer { helper.tearDown() }
                    try await CoreLocationHelper.verifyBearingAccuracy(expecter: helper.expecter, locationModel: locationModel, expectedBearingAccuracy: 0)
                }
                
                @Test("should set bearing")
                mutating func testShouldSetBearing() async throws {
                    helper.setUp()
                    defer { helper.tearDown() }
                    try await CoreLocationHelper.verifyBearing(expecter: helper.expecter, locationModel: locationModel, expectedBearing: 2)
                }
            }
            
            @Suite("When course accuracy > 0")
            struct WhenCourseAccuracyGreaterThanZeroTests {
                var helper = PayloadTestHelper.TestHelper()
                let locationModel = LocationModel.create(course: 2, courseAccuracy: 19)
                
                @Test("should set bearing accuracy")
                mutating func testShouldSetBearingAccuracy() async throws {
                    helper.setUp()
                    defer { helper.tearDown() }
                    try await CoreLocationHelper.verifyBearingAccuracy(expecter: helper.expecter, locationModel: locationModel, expectedBearingAccuracy: 19)
                }
                
                @Test("should set bearing")
                mutating func testShouldSetBearing() async throws {
                    helper.setUp()
                    defer { helper.tearDown() }
                    try await CoreLocationHelper.verifyBearing(expecter: helper.expecter, locationModel: locationModel, expectedBearing: 2)
                }
            }
        }
    }
}

// swiftlint:enable line_length
// swiftlint:enable type_body_length
// swiftlint:enable function_body_length
// swiftlint:enable control_statement
