import Foundation
import CoreLocation.CLLocation
import Testing
@testable import RakutenAnalytics

@Suite("CLLocation equalLocation")
struct CLLocationExtensionsSpec {
    
    @Suite("when both locations are nil")
    struct BothLocationsNilTests {
        @Test("returns true")
        func testBothNilReturnsTrue() {
            let result = CLLocation.equalLocation(lhs: nil, rhs: nil)
            #expect(result == true)
        }
    }
    
    @Suite("when one location is nil and the other is not")
    struct OneLocationNilTests {
        @Test("returns false when lhs is nil and rhs is not nil")
        func testLhsNilRhsNotNilReturnsFalse() {
            let location = CLLocation(latitude: 37.7749, longitude: -122.4194)
            let result = CLLocation.equalLocation(lhs: nil, rhs: location)
            #expect(result == false)
        }
        
        @Test("returns false when rhs is nil and lhs is not nil")
        func testRhsNilLhsNotNilReturnsFalse() {
            let location = CLLocation(latitude: 37.7749, longitude: -122.4194)
            let result = CLLocation.equalLocation(lhs: location, rhs: nil)
            #expect(result == false)
        }
    }
    
    @Suite("when both locations are non-nil")
    struct BothLocationsNonNilTests {
        @Test("returns true if the locations are the same")
        func testSameLocationsReturnsTrue() {
            let location1 = CLLocation(latitude: 37.7749, longitude: -122.4194)
            let location2 = CLLocation(latitude: 37.7749, longitude: -122.4194)
            let result = CLLocation.equalLocation(lhs: location1, rhs: location2)
            #expect(result == true)
        }
        
        @Test("returns false if the locations are different")
        func testDifferentLocationsReturnsFalse() {
            let location1 = CLLocation(latitude: 37.7749, longitude: -122.4194)
            let location2 = CLLocation(latitude: 34.0522, longitude: -118.2437)
            let result = CLLocation.equalLocation(lhs: location1, rhs: location2)
            #expect(result == false)
        }
        
        @Test("returns true if the locations are very close (distance is 0)")
        func testVeryCloseLocationsReturnsTrue() {
            let location1 = CLLocation(latitude: 37.7749, longitude: -122.4194)
            let location2 = CLLocation(latitude: 37.7749, longitude: -122.4194)
            let result = CLLocation.equalLocation(lhs: location1, rhs: location2)
            #expect(result == true)
        }
    }
}
