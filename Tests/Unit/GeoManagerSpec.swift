import Quick
import Nimble
import CoreLocation
import UIKit.UIDevice
@testable import RAnalytics

final class GeoManagerSpec: QuickSpec {

    override func spec() {
        describe("GeoManager") {
            context("singleton plus") {
                it("should not be nil on accessing shared instance") {
                    expect(GeoManager.shared).toNot(beNil())
                }

                it("should not be nil on creating a new instance") {
                    let manager = GeoManager(geoTracker: nil, device: UIDevice.current)
                    expect(manager).toNot(beNil())
                }
            }

            describe("getConfiguration()") {
                let geoManager = GeoManager(geoTracker: nil, device: UIDevice.current)
                let configuration = geoManager.getConfiguration()

                it("should set distanceInterval to 300") {
                    expect(configuration.distanceInterval).to(equal(300))
                }

                it("should set timeInterval to 300") {
                    expect(configuration.timeInterval).to(equal(300))
                }

                it("should set accuracy to best") {
                    expect(configuration.accuracy).to(equal(.best))
                }

                it("should set startTime to 00:00") {
                    expect(configuration.startTime?.hour).to(equal(0))
                    expect(configuration.startTime?.minute).to(equal(0))
                }

                it("should set endTime to 23:59") {
                    expect(configuration.endTime?.hour).to(equal(23))
                    expect(configuration.endTime?.minute).to(equal(59))
                }
            }

            describe("startLocationCollection(configuration:)") {
                let geoManager = GeoManager(geoTracker: nil, device: UIDevice.current)

                context("When passed configuration is nil") {
                    beforeEach {
                        geoManager.startLocationCollection(configuration: nil)
                    }

                    it("should keep default configuration") {
                        expect(geoManager.getConfiguration()).to(equal(ConfigurationFactory.defaultConfiguration))
                    }
                }

                context("When passed configuration is not nil") {
                    let configuration = Configuration(distanceInterval: 150,
                                                      timeInterval: 400,
                                                      accuracy: .nearest,
                                                      startTime: GeoTime(hour: 14, minute: 20),
                                                      endTime: GeoTime(hour: 19, minute: 30))

                    beforeEach {
                        geoManager.startLocationCollection(configuration: configuration)
                    }

                    it("should not keep default configuration") {
                        expect(geoManager.getConfiguration()).toNot(equal(ConfigurationFactory.defaultConfiguration))
                    }

                    it("should set the expected configuration") {
                        expect(geoManager.getConfiguration().distanceInterval).to(equal(150))
                        expect(geoManager.getConfiguration().timeInterval).to(equal(400))
                        expect(geoManager.getConfiguration().accuracy).to(equal(.nearest))
                        expect(geoManager.getConfiguration().startTime).to(equal(GeoTime(hour: 14, minute: 20)))
                        expect(geoManager.getConfiguration().endTime).to(equal(GeoTime(hour: 19, minute: 30)))
                    }
                }
            }
        }
    }
}
