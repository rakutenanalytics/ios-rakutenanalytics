import Testing
import CoreLocation
@testable import RakutenAnalytics

@Suite("GeoAccuracy")
struct GeoAccuracySpec {
    
    @Test("should not be nil on instantiation")
    func testInstantiation() {
        let accuracy = GeoAccuracy.best
        #expect(accuracy == .best)
    }
    
    @Test("should not be nil on instantiating using rawValue")
    func testRawValueInstantiation() {
        let accuracy = GeoAccuracy(rawValue: 1)
        #expect(accuracy != nil)
        #expect(accuracy == .best)
    }
    
    @Test("should contain correct rawValue for respective accuracy case")
    func testRawValues() {
        #expect(GeoAccuracy.best.rawValue == 1)
        #expect(GeoAccuracy.nearest.rawValue == 2)
        #expect(GeoAccuracy.navigation.rawValue == 3)
        #expect(GeoAccuracy.hundredMeters.rawValue == 4)
        #expect(GeoAccuracy.kilometer.rawValue == 5)
        #expect(GeoAccuracy.threeKilometers.rawValue == 6)
    }
    
    @Test("should contain correct desiredAccuracy for respective accuracy case")
    func testDesiredAccuracy() {
        #expect(GeoAccuracy.best.desiredAccuracy == kCLLocationAccuracyBest)
        #expect(GeoAccuracy.nearest.desiredAccuracy == kCLLocationAccuracyNearestTenMeters)
        #expect(GeoAccuracy.navigation.desiredAccuracy == kCLLocationAccuracyBestForNavigation)
        #expect(GeoAccuracy.hundredMeters.desiredAccuracy == kCLLocationAccuracyHundredMeters)
        #expect(GeoAccuracy.kilometer.desiredAccuracy == kCLLocationAccuracyKilometer)
        #expect(GeoAccuracy.threeKilometers.desiredAccuracy == kCLLocationAccuracyThreeKilometers)
    }
}
