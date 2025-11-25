import Quick
import Nimble
import CoreLocation
@testable import RakutenAnalytics

final class GeoAccuracySpec: QuickSpec {
    
    override class func spec() {
        describe("GeoAccuracy") {
            context("instance") {
                it("should not be nil on instantiation") {
                    let accuracy = GeoAccuracy.best
                    expect(accuracy).toNot(beNil())
                    expect(accuracy).to(equal(.best))
                }

                context("rawValues") {
                    it("should not be nil on instantiating using rawValue") {
                        let accuracy = GeoAccuracy(rawValue: 1)
                        expect(accuracy).toNot(beNil())
                        expect(accuracy).to(equal(.best))
                    }

                    it("should contain correct rawValue for respective accuracy case") {
                        expect(GeoAccuracy.best.rawValue).to(equal(1))
                        expect(GeoAccuracy.nearest.rawValue).to(equal(2))
                        expect(GeoAccuracy.navigation.rawValue).to(equal(3))
                        expect(GeoAccuracy.hundredMeters.rawValue).to(equal(4))
                        expect(GeoAccuracy.kilometer.rawValue).to(equal(5))
                        expect(GeoAccuracy.threeKilometers.rawValue).to(equal(6))
                    }
                }

                context("desiredAccuracy") {
                    it("should contain correct desiredAccuracy for respective accuracy case") {
                        expect(GeoAccuracy.best.desiredAccuracy).to(equal(kCLLocationAccuracyBest))
                        expect(GeoAccuracy.nearest.desiredAccuracy).to(equal(kCLLocationAccuracyNearestTenMeters))
                        expect(GeoAccuracy.navigation.desiredAccuracy).to(equal(kCLLocationAccuracyBestForNavigation))
                        expect(GeoAccuracy.hundredMeters.desiredAccuracy).to(equal(kCLLocationAccuracyHundredMeters))
                        expect(GeoAccuracy.kilometer.desiredAccuracy).to(equal(kCLLocationAccuracyKilometer))
                        expect(GeoAccuracy.threeKilometers.desiredAccuracy).to(equal(kCLLocationAccuracyThreeKilometers))
                    }
                }
            }
        }
    }
}
