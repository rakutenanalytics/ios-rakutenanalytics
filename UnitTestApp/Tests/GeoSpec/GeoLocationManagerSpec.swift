import Quick
import Nimble
@testable import RakutenAnalytics
import CoreLocation.CLLocationManager

#if SWIFT_PACKAGE
import RAnalyticsTestHelpers
#endif

final class GeoLocationManagerSpec: QuickSpec {
    override class func spec() {

        let dependenciesContainer = GeoDependenciesContainer()
        let userStorageHandler = dependenciesContainer.userStorageHandler
        let configurationStore = GeoConfigurationStore(userStorageHandler: userStorageHandler)

        describe("GeoLocationManager") {

            var coreLocationManagerMock: LocationManagerMock!
            var geoLocationManager: GeoLocationManager!
            var geoLocationManagerMock: GeoLocationManagerMock!
            let coreLocationManager = CLLocationManager()
            let expectedError = NSError(domain: "", code: 0, userInfo: nil)
            let location = CLLocation(latitude: -56.6462520, longitude: -36.6462520)
            let expectedUserActionLocationModel = LocationModel(location: location,
                                                                isAction: true,
                                                                actionParameters: nil)
            let expectedContinualLocationModel = LocationModel(location: location,
                                                               isAction: false,
                                                               actionParameters: nil)

            beforeEach {
                coreLocationManagerMock = LocationManagerMock()
                geoLocationManager = GeoLocationManager(bundle: BundleMock(),
                                                        coreLocationManager: coreLocationManagerMock,
                                                        configurationStore: configurationStore)
                geoLocationManagerMock = GeoLocationManagerMock()
            }

            it("should set a non-nil core location manager delegate") {
                expect(coreLocationManagerMock.delegate as? GeoLocationManager).to(equal(geoLocationManager))
            }

            it("should set desiredAccuracy to configured value") {
                expect(coreLocationManager.desiredAccuracy).to(equal(kCLLocationAccuracyBest))
            }

            it("should set allowsBackgroundLocationUpdates as per configured capabilities") {
                expect(coreLocationManager.allowsBackgroundLocationUpdates).to(equal(false))
            }

            it("should return false for allowsBackgroundLocationUpdates by default") {
                expect(coreLocationManagerMock.allowsBackgroundLocationUpdates).to(beFalse())
            }

            it("should return true when allowsBackgroundLocationUpdates is set to true") {
                coreLocationManagerMock.allowsBackgroundLocationUpdates = true
                expect(coreLocationManagerMock.allowsBackgroundLocationUpdates).to(beTrue())
            }

            context("on instantiation") {
                it("should not be nil") {
                    expect(geoLocationManager).toNot(beNil())
                }
            }

            context("When requestLocationUpdate(for: .userAction) is called") {
                it("should call CLLocationManager's requestLocationUpdate(for: .userAction)") {
                    geoLocationManager.requestLocationUpdate(for: .userAction)

                    expect(coreLocationManagerMock.requestLocationIsCalled).toEventually(beTrue())
                }

                context("When core location manager returns a location") {
                    beforeEach {
                        geoLocationManager.requestLocationUpdate(for: .userAction)

                        coreLocationManagerMock.delegate?.locationManager?(coreLocationManager,
                                                                           didUpdateLocations: [location])

                        geoLocationManagerMock.geoLocationManager(didUpdateLocation: location, for: .userAction)
                    }
                    it("should return an expected location") {
                        expect(geoLocationManagerMock.delegateGeoLocationManagerDidUpdateLocationIsCalled).to(beTrue())
                        expect(geoLocationManagerMock.locationModel).toEventuallyNot(beNil())
                        expect(geoLocationManagerMock.locationModel).to(equal(expectedUserActionLocationModel))
                        expect(geoLocationManagerMock.locationModel.isAction).to(beTrue())
                    }
                }

                context("When core location manager returns an error") {
                    beforeEach {
                        geoLocationManager.requestLocationUpdate(for: .userAction)

                        coreLocationManagerMock.delegate?.locationManager?(coreLocationManager,
                                                                           didFailWithError: expectedError)

                        geoLocationManagerMock.geoLocationManager(didFailWithError: expectedError, for: .userAction)
                    }
                    it("should return an error") {
                        expect(geoLocationManagerMock.delegateGeoLocationManagerDidFailWithErrorIsCalled).to(beTrue())
                        expect(geoLocationManagerMock.locationError).toEventuallyNot(beNil())
                        expect(geoLocationManagerMock.locationError).to(equal(expectedError))
                    }
                }
            }

            context("locationManager(_:, didDetermineState:, for:)") {
                beforeEach {
                    geoLocationManagerMock.delegateCLLocationManagerDidDetermineStateIsCalled = false
                }

                it("should be called when state is outside and region identifier is correct") {
                    let monitoredRegion = CLCircularRegion(center: CLLocationCoordinate2D(latitude: 1.2345, longitude: 6.7890),
                                                           radius: 300,
                                                           identifier: "GeoLocationCollectionRegionIdentifier")

                    coreLocationManagerMock.delegate?.locationManager?(coreLocationManager, didDetermineState: .outside, for: monitoredRegion)
                    geoLocationManagerMock.locationManager(coreLocationManager, didDetermineState: .outside, for: monitoredRegion)

                    expect(geoLocationManagerMock.delegateCLLocationManagerDidDetermineStateIsCalled).to(beTrue())
                }

                it("should not be called when state is not outside and region identifier is incorrect") {
                    let monitoredRegion = CLCircularRegion(center: CLLocationCoordinate2D(latitude: 1.2345, longitude: 6.7890),
                                                           radius: 300,
                                                           identifier: "BadGeoLocationCollectionRegionIdentifier")

                    coreLocationManagerMock.delegate?.locationManager?(coreLocationManager, didDetermineState: .inside, for: monitoredRegion)
                    geoLocationManagerMock.locationManager(coreLocationManager, didDetermineState: .inside, for: monitoredRegion)

                    expect(geoLocationManagerMock.delegateCLLocationManagerDidDetermineStateIsCalled).to(beFalse())
                }

                it("should not be called when state is outside and region identifier is incorrect") {
                    let monitoredRegion = CLCircularRegion(center: CLLocationCoordinate2D(latitude: 1.2345, longitude: 6.7890),
                                                           radius: 300,
                                                           identifier: "BadGeoLocationCollectionRegionIdentifier")

                    coreLocationManagerMock.delegate?.locationManager?(coreLocationManager, didDetermineState: .outside, for: monitoredRegion)
                    geoLocationManagerMock.locationManager(coreLocationManager, didDetermineState: .outside, for: monitoredRegion)

                    expect(geoLocationManagerMock.delegateCLLocationManagerDidDetermineStateIsCalled).to(beFalse())
                }

                it("should not be called when state is not outside and region identifier is correct") {
                    let monitoredRegion = CLCircularRegion(center: CLLocationCoordinate2D(latitude: 1.2345, longitude: 6.7890),
                                                           radius: 300,
                                                           identifier: "GeoLocationCollectionRegionIdentifier")

                    coreLocationManagerMock.delegate?.locationManager?(coreLocationManager, didDetermineState: .inside, for: monitoredRegion)
                    geoLocationManagerMock.locationManager(coreLocationManager, didDetermineState: .inside, for: monitoredRegion)

                    expect(geoLocationManagerMock.delegateCLLocationManagerDidDetermineStateIsCalled).to(beFalse())
                }
            }

            context("When requestLocationUpdate(for: .continual) is called") {
                it("should call CLLocationManager's requestLocationUpdate(for: .continual)") {
                    geoLocationManager.requestLocationUpdate(for: .continual)

                    expect(coreLocationManagerMock.requestLocationIsCalled).toEventually(beTrue())
                }

                context("When core location manager returns a location") {
                    beforeEach {
                        geoLocationManager.requestLocationUpdate(for: .continual)

                        coreLocationManagerMock.delegate?.locationManager?(coreLocationManager,
                                                                           didUpdateLocations: [location])

                        geoLocationManagerMock.geoLocationManager(didUpdateLocation: location, for: .continual)
                    }
                    it("should return an expected location") {
                        expect(geoLocationManagerMock.delegateGeoLocationManagerDidUpdateLocationIsCalled).to(beTrue())
                        expect(geoLocationManagerMock.locationModel).toEventuallyNot(beNil())
                        expect(geoLocationManagerMock.locationModel).to(equal(expectedContinualLocationModel))
                        expect(geoLocationManagerMock.locationModel.isAction).to(beFalse())
                    }
                }

                context("When core location manager returns an error") {
                    beforeEach {
                        geoLocationManager.requestLocationUpdate(for: .continual)

                        coreLocationManagerMock.delegate?.locationManager?(coreLocationManager,
                                                                           didFailWithError: expectedError)

                        geoLocationManagerMock.geoLocationManager(didFailWithError: expectedError, for: .continual)
                    }
                    it("should return an error") {
                        expect(geoLocationManagerMock.delegateGeoLocationManagerDidFailWithErrorIsCalled).to(beTrue())
                        expect(geoLocationManagerMock.locationError).toEventuallyNot(beNil())
                        expect(geoLocationManagerMock.locationError).to(equal(expectedError))
                    }
                }
            }
        }
    }
}
