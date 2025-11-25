import Foundation
import CoreLocation.CLLocation
import Quick
import Nimble
@testable import RakutenAnalytics

class CLLocationExtensionsSpec: QuickSpec {
    override class func spec() {
        describe("CLLocation equalLocation") {
            context("when both locations are nil") {
                it("returns true") {
                    let result = CLLocation.equalLocation(lhs: nil, rhs: nil)
                    expect(result).to(beTrue())
                }
            }
            
            context("when one location is nil and the other is not") {
                it("returns false when lhs is nil and rhs is not nil") {
                    let location = CLLocation(latitude: 37.7749, longitude: -122.4194)
                    let result = CLLocation.equalLocation(lhs: nil, rhs: location)
                    expect(result).to(beFalse())
                }
                
                it("returns false when rhs is nil and lhs is not nil") {
                    let location = CLLocation(latitude: 37.7749, longitude: -122.4194)
                    let result = CLLocation.equalLocation(lhs: location, rhs: nil)
                    expect(result).to(beFalse())
                }
            }
            
            context("when both locations are non-nil") {
                it("returns true if the locations are the same") {
                    let location1 = CLLocation(latitude: 37.7749, longitude: -122.4194)
                    let location2 = CLLocation(latitude: 37.7749, longitude: -122.4194)
                    let result = CLLocation.equalLocation(lhs: location1, rhs: location2)
                    expect(result).to(beTrue())
                }
                
                it("returns false if the locations are different") {
                    let location1 = CLLocation(latitude: 37.7749, longitude: -122.4194)
                    let location2 = CLLocation(latitude: 34.0522, longitude: -118.2437)
                    let result = CLLocation.equalLocation(lhs: location1, rhs: location2)
                    expect(result).to(beFalse())
                }
                
                it("returns true if the locations are very close (distance is 0)") {
                    let location1 = CLLocation(latitude: 37.7749, longitude: -122.4194)
                    let location2 = CLLocation(latitude: 37.7749, longitude: -122.4194)
                    let result = CLLocation.equalLocation(lhs: location1, rhs: location2)
                    expect(result).to(beTrue())
                }
            }
        }
    }
}
