import Quick
import Nimble
@testable import RAnalytics
import CoreLocation.CLLocationManager

#if SWIFT_PACKAGE
import RAnalyticsTestHelpers
#endif

final class GeoLocationManagerSpec: QuickSpec {
    override func spec() {
        let dependenciesContainer = SimpleDependenciesContainer()
        let preferences = GeoSharedPreferences(userStorageHandler: dependenciesContainer.userStorageHandler)
        describe("GeoLocationManager") {
            let coreLocationManager = CLLocationManager()
            let expectedError = NSError(domain: "", code: 0, userInfo: nil)
            var returnedError: NSError!
            var returnedLocationModel: LocationModel!
            var result: GeoRequestLocationResult!
            let location = CLLocation(latitude: -56.6462520, longitude: -36.6462520)
            let expectedLocationModel = LocationModel(location: location,
                                                      isAction: true,
                                                      actionParameters: nil)
            var coreLocationManagerMock: LocationManagerMock!
            var geoLocationManager: GeoLocationManager!

            beforeEach {
                coreLocationManagerMock = LocationManagerMock()
                geoLocationManager = GeoLocationManager(coreLocationManager: coreLocationManagerMock,
                                                        configurationStore: GeoConfigurationStore(preferences: preferences))
            }

            it("should set a non-nil core location manager delegate") {
                expect(coreLocationManagerMock.delegate as? GeoLocationManager).to(equal(geoLocationManager))
            }

            it("should set desiredAccuracy to configured value") {
                expect(coreLocationManager.desiredAccuracy).to(equal(kCLLocationAccuracyBest))
            }

            context("on instantiation") {
                it("should not be nil") {
                    expect(geoLocationManager).toNot(beNil())
                }
            }

            context("When requestLocation(actionParameters:) is called") {
                it("should call CLLocationManager's requestLocation()") {
                    geoLocationManager.requestLocation { _ in }

                    expect(coreLocationManagerMock.requestLocationIsCalled).toEventually(beTrue())
                }

                context("When core location manager returns a location") {
                    it("should return an expected location") {
                        geoLocationManager.requestLocation { aResult in
                            result = aResult
                        }

                        coreLocationManagerMock.delegate?.locationManager?(coreLocationManager,
                                                                           didUpdateLocations: [location])

                        expect(result).toEventuallyNot(beNil())

                        if case .success(let locationModel) = result {
                            returnedLocationModel = locationModel
                        }

                        expect(returnedLocationModel).to(equal(expectedLocationModel))
                    }
                }

                context("When core location manager returns an error") {
                    it("should return an error") {
                        geoLocationManager.requestLocation { aResult in
                            result = aResult
                        }

                        coreLocationManagerMock.delegate?.locationManager?(coreLocationManager,
                                                                           didFailWithError: expectedError)

                        expect(result).toEventuallyNot(beNil())

                        if case .failure(let error) = result {
                            returnedError = error as NSError
                        }

                        expect(returnedError).to(equal(expectedError))
                    }
                }
            }
        }
    }
}
