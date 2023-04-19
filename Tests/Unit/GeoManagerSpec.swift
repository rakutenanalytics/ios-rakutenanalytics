// swiftlint:disable type_body_length
// swiftlint:disable function_body_length

import Quick
import Nimble
import CoreLocation
import UIKit.UIDevice
@testable import RAnalytics

#if SWIFT_PACKAGE
import RAnalyticsTestHelpers
#endif

final class GeoManagerSpec: QuickSpec {
    override func spec() {
        let dependenciesContainer = SimpleContainerMock()
        let preferences = GeoSharedPreferences(userStorageHandler: dependenciesContainer.userStorageHandler)
        
        describe("GeoManager") {
            let geoLocationManager = GeoLocationManager(coreLocationManager: LocationManagerMock(),
                                                        configurationStore: GeoConfigurationStore(preferences: preferences))

            context("singleton plus") {
                it("should not be nil on accessing shared instance") {
                    expect(GeoManager.shared).toNot(beNil())
                }

                it("should not be nil on creating a new instance") {
                    let manager = GeoManager(userStorageHandler: dependenciesContainer.userStorageHandler,
                                             geoLocationManager: geoLocationManager,
                                             device: UIDevice.current,
                                             tracker: TrackerMock(),
                                             analyticsManager: AnalyticsManager(dependenciesContainer: SimpleDependenciesContainer()))
                    expect(manager).toNot(beNil())
                }
            }

            describe("requestLocation()") {
                it("should call locationManager's requestLocation()") {
                    let locationManagerMock = GeoLocationManagerMock()
                    let geoManager = GeoManager(userStorageHandler: dependenciesContainer.userStorageHandler,
                                                geoLocationManager: locationManagerMock,
                                                device: UIDevice.current,
                                                tracker: TrackerMock(),
                                                analyticsManager: AnalyticsManager(dependenciesContainer: SimpleDependenciesContainer()))

                    geoManager.requestLocation { _ in }

                    expect(locationManagerMock.requestLocationIsCalled).toEventually(beTrue())
                }

                context("When requestLocation(actionParameters:) is called") {
                    let analyticsDependenciesContainer = SimpleContainerMock()
                    let dependenciesContainer = SimpleContainerMock()
                    let coreLocationManager = CLLocationManager()
                    let expectedError = NSError(domain: "", code: 0, userInfo: nil)
                    var returnedError: NSError!
                    var returnedLocationModel: LocationModel!
                    var result: GeoRequestLocationResult!
                    let location = CLLocation(latitude: -56.6462520, longitude: -36.6462520)
                    let expectedLocationModel = LocationModel(location: location,
                                                              isAction: true,
                                                              actionParameters: nil)
                    var trackerMock: TrackerMock!
                    var coreLocationManagerMock: LocationManagerMock!
                    var geoLocationManager: GeoLocationManager!
                    var geoManager: GeoManager!
                    let asIdentifierManagerMock = ASIdentifierManagerMock()
                    asIdentifierManagerMock.advertisingIdentifierUUIDString = "E621E1F8-C36C-495A-93FC-0C247A3E6E5F"
                    let userDefaultsMock = UserDefaultsMock([:])
                    userDefaultsMock.set(value: "flo_test", forKey: RAnalyticsExternalCollector.Constants.trackingIdentifierKey)
                    let keychainHandlerMock = KeychainHandlerMock()
                    keychainHandlerMock.set(value: "123456", for: RAnalyticsExternalCollector.Constants.easyIdentifierKey)

                    beforeEach {
                        trackerMock = TrackerMock()

                        coreLocationManagerMock = LocationManagerMock()

                        geoLocationManager = GeoLocationManager(coreLocationManager: coreLocationManagerMock,
                                                                configurationStore: GeoConfigurationStore(preferences: preferences))

                        analyticsDependenciesContainer.adIdentifierManager = asIdentifierManagerMock
                        analyticsDependenciesContainer.userStorageHandler = userDefaultsMock
                        analyticsDependenciesContainer.keychainHandler = keychainHandlerMock

                        geoManager = GeoManager(userStorageHandler: dependenciesContainer.userStorageHandler,
                                                geoLocationManager: geoLocationManager,
                                                device: UIDevice.current,
                                                tracker: trackerMock,
                                                analyticsManager: AnalyticsManager(dependenciesContainer: analyticsDependenciesContainer))
                    }

                    it("should call CLLocationManager's requestLocation()") {
                        geoManager.requestLocation { _ in }

                        expect(coreLocationManagerMock.requestLocationIsCalled).toEventually(beTrue())
                    }

                    context("When core location manager returns a location") {
                        beforeEach {
                            geoManager.requestLocation { aResult in
                                result = aResult
                            }

                            coreLocationManagerMock.delegate?.locationManager?(coreLocationManager, didUpdateLocations: [location])
                        }

                        it("should return an expected location") {
                            expect(result).toEventuallyNot(beNil())
                            
                            if case .success(let locationModel) = result {
                                returnedLocationModel = locationModel
                            }
                            
                            expect(returnedLocationModel).to(equal(expectedLocationModel))
                        }

                        it("should process the location event with an expected name") {
                            expect(result).toEventuallyNot(beNil())
                            expect(trackerMock.event?.name).to(equal(RAnalyticsEvent.Name.geoLocation))
                        }

                        it("should process the location event with empty parameters") {
                            expect(result).toEventuallyNot(beNil())
                            expect(trackerMock.event?.parameters).to(beEmpty())
                        }

                        it("should process the location event with an expected state") {
                            expect(result).toEventuallyNot(beNil())
                            expect(trackerMock.state?.lastKnownLocation).to(equal(expectedLocationModel))
                        }

                        it("should process the location event with a non-empty cks") {
                            expect(result).toEventuallyNot(beNil())
                            expect(trackerMock.state?.sessionIdentifier).toNot(beEmpty())
                        }

                        it("should process the location event with a non-empty ckp") {
                            expect(result).toEventuallyNot(beNil())
                            expect(trackerMock.state?.deviceIdentifier).toNot(beEmpty())
                        }

                        it("should process the location event with a non-empty userid") {
                            expect(result).toEventuallyNot(beNil())
                            expect(trackerMock.state?.userIdentifier).to(equal("flo_test"))
                        }

                        it("should process the location event with a non-empty easyid") {
                            expect(result).toEventuallyNot(beNil())
                            expect(trackerMock.state?.easyIdentifier).to(equal("123456"))
                        }

                        it("should process the location event with a non-empty cka") {
                            expect(result).toEventuallyNot(beNil())
                            expect(trackerMock.state?.advertisingIdentifier).to(equal("E621E1F8-C36C-495A-93FC-0C247A3E6E5F"))
                        }
                    }

                    context("When core location manager returns an error") {
                        it("should return an error") {
                            geoManager.requestLocation { aResult in
                                result = aResult
                            }

                            coreLocationManagerMock.delegate?.locationManager?(coreLocationManager, didFailWithError: expectedError)

                            expect(result).toEventuallyNot(beNil())
                            
                            if case .failure(let error) = result {
                                returnedError = error as NSError
                            }

                            expect(returnedError).to(equal(expectedError))
                        }

                        it("should not process the location event") {
                            expect(result).toEventuallyNot(beNil())
                            expect(trackerMock.event).to(beNil())
                        }
                    }
                }
            }

            describe("getConfiguration()") {
                let geoManager = GeoManager(userStorageHandler: dependenciesContainer.userStorageHandler,
                                            geoLocationManager: geoLocationManager,
                                            device: UIDevice.current,
                                            tracker: TrackerMock(),
                                            analyticsManager: AnalyticsManager(dependenciesContainer: SimpleDependenciesContainer()))
                context("on startLocationCollection not called before getConfiguration()") {
                    
                    beforeEach {
                        dependenciesContainer.userStorageHandler.removeObject(forKey: UserDefaultsKeys.configurationKey)
                    }
                    
                    let configuration = geoManager.getConfiguration()
                    
                    it("should set distanceInterval to be nil") {
                        expect(configuration?.distanceInterval).to(beNil())
                    }

                    it("should set timeInterval to be nil") {
                        expect(configuration?.timeInterval).to(beNil())
                    }

                    it("should set accuracy to be nil") {
                        expect(configuration?.accuracy).to(beNil())
                    }

                    it("should set startTime to be nil") {
                        expect(configuration?.startTime).to(beNil())
                    }

                    it("should set endTime to be nil") {
                        expect(configuration?.endTime).to(beNil())
                    }
                }
                
                context("on startLocationCollection called before getConfiguration()") {
                    let configuration = GeoConfiguration(distanceInterval: 300,
                                                      timeInterval: 600,
                                                      accuracy: .nearest,
                                                      startTime: GeoTime(hours: 12, minutes: 20),
                                                      endTime: GeoTime(hours: 19, minutes: 30))
                    geoManager.startLocationCollection(configuration: configuration)
                    
                    let geoConfiguration = geoManager.getConfiguration()
                    
                    it("should set the configuration as passed on startLocationCollection()") {
                        expect(geoConfiguration?.distanceInterval).to(equal(300))
                        expect(geoConfiguration?.timeInterval).to(equal(600))
                        expect(geoConfiguration?.accuracy).to(equal(.nearest))
                        expect(geoConfiguration?.startTime).to(equal(GeoTime(hours: 12, minutes: 20)))
                        expect(geoConfiguration?.endTime).to(equal(GeoTime(hours: 19, minutes: 30)))
                    }
                    afterEach {
                        dependenciesContainer.userStorageHandler.removeObject(forKey: UserDefaultsKeys.configurationKey)
                    }
                }
            }

            describe("on startLocationCollection(configuration:)") {
                let manager = GeoManager(userStorageHandler: dependenciesContainer.userStorageHandler,
                                         geoLocationManager: geoLocationManager,
                                         device: UIDevice.current,
                                         tracker: TrackerMock(),
                                         analyticsManager: AnalyticsManager(dependenciesContainer: SimpleDependenciesContainer()))

                context("preferences") {
                    beforeEach {
                        dependenciesContainer.userStorageHandler.removeObject(forKey: UserDefaultsKeys.locationCollectionKey)
                    }

                    context("before calling startLocationCollection(configuration:)") {
                        it("should return bool for locationCollectionKey as false") {
                            expect(dependenciesContainer.userStorageHandler.bool(forKey: UserDefaultsKeys.locationCollectionKey)).to(beFalse())
                        }
                    }

                    context("after calling startLocationCollection(configuration:)") {
                        it("should return bool for locationCollectionKey as true") {
                            manager.startLocationCollection()
                            expect(dependenciesContainer.userStorageHandler.bool(forKey: UserDefaultsKeys.locationCollectionKey)).to(beTrue())
                        }
                    }

                    afterEach {
                        dependenciesContainer.userStorageHandler.removeObject(forKey: UserDefaultsKeys.locationCollectionKey)
                    }
                }

                context("when a configuration already exists") {
                    beforeEach {
                        // swiftlint:disable:next line_length
                        let setConfiguration = GeoConfiguration(distanceInterval: 400, timeInterval: 450, accuracy: .kilometer, startTime: GeoTime(hours: 7, minutes: 10), endTime: GeoTime(hours: 15, minutes: 10))
                        manager.startLocationCollection(configuration: setConfiguration)
                    }

                    it("should not update the configuration passed if values are equal") {
                        manager.startLocationCollection(configuration: GeoConfiguration(distanceInterval: 400,
                                                                                        timeInterval: 450,
                                                                                        accuracy: .kilometer,
                                                                                        startTime: GeoTime(hours: 7, minutes: 10),
                                                                                        endTime: GeoTime(hours: 15, minutes: 10)))
                        expect(manager.getConfiguration()).to(equal(GeoConfiguration(distanceInterval: 400,
                                                                                     timeInterval: 450,
                                                                                     accuracy: .kilometer,
                                                                                     startTime: GeoTime(hours: 7, minutes: 10),
                                                                                     endTime: GeoTime(hours: 15, minutes: 10))))
                    }

                    it("should update the configuration passed when values are not equal") {
                        manager.startLocationCollection(configuration: GeoConfiguration(distanceInterval: 350,
                                                                                        timeInterval: 400,
                                                                                        accuracy: .kilometer,
                                                                                        startTime: GeoTime(hours: 6, minutes: 10),
                                                                                        endTime: GeoTime(hours: 13, minutes: 10)))
                        expect(manager.getConfiguration()).to(equal(GeoConfiguration(distanceInterval: 350,
                                                                                     timeInterval: 400,
                                                                                     accuracy: .kilometer,
                                                                                     startTime: GeoTime(hours: 6, minutes: 10),
                                                                                     endTime: GeoTime(hours: 13, minutes: 10))))
                    }
                }
            }
            
            describe("startLocationCollection(configuration:)") {
                let geoManager = GeoManager(userStorageHandler: dependenciesContainer.userStorageHandler,
                                            geoLocationManager: geoLocationManager,
                                            device: UIDevice.current,
                                            tracker: TrackerMock(),
                                            analyticsManager: AnalyticsManager(dependenciesContainer: SimpleDependenciesContainer()))
                context("When passed configuration is nil") {
                    beforeEach {
                        dependenciesContainer.userStorageHandler.removeObject(forKey: UserDefaultsKeys.configurationKey)
                    }

                    it("should return configuration as nil from getConfiguration") {
                        geoManager.startLocationCollection(configuration: nil)
                        expect(geoManager.getConfiguration()).to(beNil())
                    }
                }                

                context("When passed configuration is not nil") {
                    let configuration = GeoConfiguration(distanceInterval: 250,
                                                      timeInterval: 400,
                                                      accuracy: .nearest,
                                                      startTime: GeoTime(hours: 14, minutes: 20),
                                                      endTime: GeoTime(hours: 19, minutes: 30))

                    beforeEach {
                        geoManager.startLocationCollection(configuration: configuration)
                    }

                    it("should not keep default configuration") {
                        expect(geoManager.getConfiguration()).toNot(equal(GeoConfigurationFactory.defaultConfiguration))
                    }

                    it("should set the expected configuration") {
                        expect(geoManager.getConfiguration()?.distanceInterval).to(equal(250))
                        expect(geoManager.getConfiguration()?.timeInterval).to(equal(400))
                        expect(geoManager.getConfiguration()?.accuracy).to(equal(.nearest))
                        expect(geoManager.getConfiguration()?.startTime).to(equal(GeoTime(hours: 14, minutes: 20)))
                        expect(geoManager.getConfiguration()?.endTime).to(equal(GeoTime(hours: 19, minutes: 30)))
                    }
                    afterEach {
                        dependenciesContainer.userStorageHandler.removeObject(forKey: UserDefaultsKeys.configurationKey)
                    }
                }
                
                context("When passing no parameters to configuration") {
                    
                    let configuration = GeoConfiguration()
                    
                    geoManager.startLocationCollection(configuration: configuration)
                    let geoConfiguration = geoManager.getConfiguration()
                    
                    it("should set distanceInterval to default distanceInterval") {
                        expect(geoConfiguration?.distanceInterval).to(equal(GeoConfigurationConstants.distanceInterval))
                    }
                    
                    it("should set timeInterval to default timeInterval") {
                        expect(geoConfiguration?.timeInterval).to(equal(GeoConfigurationConstants.timeInterval))
                    }
                    
                    it("should set accuracy to best") {
                        expect(geoConfiguration?.accuracy).to(equal(.best))
                    }
                    
                    it("should set startTime to 00:00") {
                        expect(geoConfiguration?.startTime.hours).to(equal(GeoConfigurationConstants.startTime.hours))
                        expect(geoConfiguration?.startTime.minutes).to(equal(GeoConfigurationConstants.startTime.minutes))
                    }
                    
                    it("should set endTime to 23:59") {
                        expect(geoConfiguration?.endTime.hours).to(equal(GeoConfigurationConstants.endTime.hours))
                        expect(geoConfiguration?.endTime.minutes).to(equal(GeoConfigurationConstants.endTime.minutes))
                    }
                    
                    afterEach {
                        dependenciesContainer.userStorageHandler.removeObject(forKey: UserDefaultsKeys.configurationKey)
                    }
                }
                
                context("When passing few parameters to configuration") {
                    
                    let configuration = GeoConfiguration(distanceInterval: 400)
                    geoManager.startLocationCollection(configuration: configuration)
                    let geoConfiguration = geoManager.getConfiguration()
                    
                    it("should set distanceInterval as 400") {
                        expect(geoConfiguration?.distanceInterval).to(equal(400))
                    }
                    
                    it("should set timeInterval to 300") {
                        expect(geoConfiguration?.timeInterval).to(equal(GeoConfigurationConstants.timeInterval))
                    }
                    
                    it("should set accuracy to best") {
                        expect(geoConfiguration?.accuracy).to(equal(.best))
                    }
                    
                    it("should set startTime to 00:00") {
                        expect(geoConfiguration?.startTime.hours).to(equal(GeoConfigurationConstants.startTime.hours))
                        expect(geoConfiguration?.startTime.minutes).to(equal(GeoConfigurationConstants.startTime.minutes))
                    }
                    
                    it("should set endTime to 23:59") {
                        expect(geoConfiguration?.endTime.hours).to(equal(GeoConfigurationConstants.endTime.hours))
                        expect(geoConfiguration?.endTime.minutes).to(equal(GeoConfigurationConstants.endTime.minutes))
                    }
                    
                    afterEach {
                        dependenciesContainer.userStorageHandler.removeObject(forKey: UserDefaultsKeys.configurationKey)
                    }
                }
                
                describe("When passed configuration is more than the specified range") {
                    
                    context("on all the fields are more than specified range") {
                        let configuration = GeoConfiguration(distanceInterval: 10000,
                                                          timeInterval: 40000,
                                                          accuracy: .nearest,
                                                          startTime: GeoTime(hours: 23, minutes: 20),
                                                          endTime: GeoTime(hours: 0, minutes: 3))
                        geoManager.startLocationCollection(configuration: configuration)
                        let geoConfiguration = geoManager.getConfiguration()
                        
                        it("should set distanceInterval to default interval") {
                            expect(geoConfiguration?.distanceInterval).to(equal(GeoConfigurationConstants.distanceInterval))
                        }
                        
                        it("should set timeInterval to 300") {
                            expect(geoConfiguration?.timeInterval).to(equal(GeoConfigurationConstants.timeInterval))
                        }
                        
                        it("should be same as what configured on Configuration") {
                            expect(geoConfiguration?.accuracy).to(equal(.nearest))
                        }
                        
                        it("should set startTime to 00:00") {
                            expect(geoConfiguration?.startTime.hours).to(equal(GeoConfigurationConstants.startTime.hours))
                            expect(geoConfiguration?.startTime.minutes).to(equal(GeoConfigurationConstants.startTime.minutes))
                        }
                        
                        it("should set endTime to 23:59") {
                            expect(geoConfiguration?.endTime.hours).to(equal(GeoConfigurationConstants.endTime.hours))
                            expect(geoConfiguration?.endTime.minutes).to(equal(GeoConfigurationConstants.endTime.minutes))
                        }
                    }
                    
                    context("on startTime & endTime minutes are more than the specified range") {
                        let configuration = GeoConfiguration(distanceInterval: 250,
                                                          timeInterval: 900,
                                                          accuracy: .nearest,
                                                          startTime: GeoTime(hours: 12, minutes: 200),
                                                          endTime: GeoTime(hours: 23, minutes: 300))
                        
                        geoManager.startLocationCollection(configuration: configuration)
                        let geoConfiguration = geoManager.getConfiguration()
                        
                        it("should set start minutes as per defaults 0") {
                            expect(geoConfiguration?.startTime.minutes).to(equal(GeoConfigurationConstants.startTime.minutes))
                        }
                        
                        it("should set end minutes as per defaults 59") {
                            expect(geoConfiguration?.endTime.minutes).to(equal(GeoConfigurationConstants.endTime.minutes))
                        }
                    }
                    
                    context("on startTime is greater than endTime") {
                        let configuration = GeoConfiguration(distanceInterval: 200,
                                                          timeInterval: 900,
                                                          accuracy: .nearest,
                                                          startTime: GeoTime(hours: 15, minutes: 40),
                                                          endTime: GeoTime(hours: 10, minutes: 30))
                        
                        geoManager.startLocationCollection(configuration: configuration)
                        let geoConfiguration = geoManager.getConfiguration()
                        
                        it("should set startTime as per the default startTime(00:00)") {
                            expect(geoConfiguration?.startTime).to(equal(GeoConfigurationConstants.startTime))
                        }
                        
                        it("should set endTime as per the default endTime(23:59)") {
                            expect(geoConfiguration?.endTime).to(equal(GeoConfigurationConstants.endTime))
                        }
                    }
                    
                    context("on startTime is greater than endTime with startTime and endTime are out of range") {
                        let configuration = GeoConfiguration(distanceInterval: 200,
                                                             timeInterval: 900,
                                                             accuracy: .nearest,
                                                             startTime: GeoTime(hours: 50, minutes: 60),
                                                             endTime: GeoTime(hours: 25, minutes: 80))
                        geoManager.startLocationCollection(configuration: configuration)
                        let geoConfiguration = geoManager.getConfiguration()
                        
                        it("should set startTime as per the default startTime(00:00)") {
                            expect(geoConfiguration?.startTime).to(equal(GeoConfigurationConstants.startTime))
                        }
                        
                        it("should set endTime as per the default endTime(23:59)") {
                            expect(geoConfiguration?.endTime).to(equal(GeoConfigurationConstants.endTime))
                        }
                        
                    }
                    
                    afterEach {
                        dependenciesContainer.userStorageHandler.removeObject(forKey: UserDefaultsKeys.configurationKey)
                    }
                }
            }

            describe("configurePoller()") {
                var geoLocationManagerMock: GeoLocationManagerMock!
                var geoManager: GeoManager!
                var configuration: GeoConfiguration!
                var configurationData: Data!

                context("when lastCollectedLocationTms is nil") {
                    beforeEach {
                        geoLocationManagerMock = GeoLocationManagerMock()
                        geoManager = GeoManager(userStorageHandler: dependenciesContainer.userStorageHandler,
                                                geoLocationManager: geoLocationManagerMock,
                                                device: UIDevice.current,
                                                tracker: TrackerMock(),
                                                analyticsManager: AnalyticsManager(dependenciesContainer: SimpleDependenciesContainer()))
                        configuration = GeoConfiguration(distanceInterval: 100,
                                                         timeInterval: 3,
                                                         accuracy: .best,
                                                         startTime: GeoTime(hours: 0, minutes: 0),
                                                         endTime: GeoTime(hours: 23, minutes: 59))
                        configurationData = try? JSONEncoder().encode(configuration)
                        dependenciesContainer.userStorageHandler.removeObject(forKey: UserDefaultsKeys.locationTimestampKey)
                        dependenciesContainer.userStorageHandler.set(value: configurationData, forKey: UserDefaultsKeys.configurationKey)
                    }

                    it("should start poller and call attemptToRequestLocation() with specified timeinterval as delay") {
                        geoManager.configurePoller()
                        expect(geoLocationManagerMock.attemptToRequestLocationUpdatesIsCalled).toEventually(beTrue(), timeout: .seconds(4))
                    }

                    it("should set lastCollectedLocationTms on success") {
                        geoManager.configurePoller()
                        // swiftlint:disable:next line_length
                        expect(dependenciesContainer.userStorageHandler.object(forKey: UserDefaultsKeys.locationTimestampKey)).toEventuallyNot(beNil(), timeout: .seconds(4))
                    }

                    it("should not set lastCollectedLocationTms on failure") {
                        geoLocationManagerMock.completionFailed = true
                        geoManager.configurePoller()
                        // swiftlint:disable:next line_length
                        expect(dependenciesContainer.userStorageHandler.object(forKey: UserDefaultsKeys.locationTimestampKey)).toEventually(beNil(), timeout: .seconds(4))
                    }
                }

                context("when lastCollectedLocationTms is non-nil and lapsed") {
                    beforeEach {
                        geoLocationManagerMock = GeoLocationManagerMock()
                        geoManager = GeoManager(userStorageHandler: dependenciesContainer.userStorageHandler,
                                                geoLocationManager: geoLocationManagerMock,
                                                device: UIDevice.current,
                                                tracker: TrackerMock(),
                                                analyticsManager: AnalyticsManager(dependenciesContainer: SimpleDependenciesContainer()))
                        configuration = GeoConfiguration(distanceInterval: 100,
                                                         timeInterval: 3,
                                                         accuracy: .best,
                                                         startTime: GeoTime(hours: 0, minutes: 0),
                                                         endTime: GeoTime(hours: 23, minutes: 59))
                        configurationData = try? JSONEncoder().encode(configuration)
                        // swiftlint:disable:next line_length
                        dependenciesContainer.userStorageHandler.set(value: Date().addingTimeInterval(-4), forKey: UserDefaultsKeys.locationTimestampKey)
                        dependenciesContainer.userStorageHandler.set(value: configurationData, forKey: UserDefaultsKeys.configurationKey)
                    }

                    it("should start poller and call attemptToRequestLocation() with no delay") {
                        geoManager.configurePoller()
                        expect(geoLocationManagerMock.attemptToRequestLocationUpdatesIsCalled).toEventually(beTrue())
                    }
                }

                context("when lastCollectedLocationTms is non-nil and not lapsed") {
                    beforeEach {
                        geoLocationManagerMock = GeoLocationManagerMock()
                        geoManager = GeoManager(userStorageHandler: dependenciesContainer.userStorageHandler,
                                                geoLocationManager: geoLocationManagerMock,
                                                device: UIDevice.current,
                                                tracker: TrackerMock(),
                                                analyticsManager: AnalyticsManager(dependenciesContainer: SimpleDependenciesContainer()))
                        configuration = GeoConfiguration(distanceInterval: 100,
                                                         timeInterval: 5,
                                                         accuracy: .best,
                                                         startTime: GeoTime(hours: 0, minutes: 0),
                                                         endTime: GeoTime(hours: 23, minutes: 59))
                        configurationData = try? JSONEncoder().encode(configuration)
                        // swiftlint:disable:next line_length
                        dependenciesContainer.userStorageHandler.set(value: Date().addingTimeInterval(-2), forKey: UserDefaultsKeys.locationTimestampKey)
                        dependenciesContainer.userStorageHandler.set(value: configurationData, forKey: UserDefaultsKeys.configurationKey)
                    }

                    it("should start poller and call attemptToRequestLocation() with remaining elapsed delay") {
                        geoManager.configurePoller()
                        expect(geoLocationManagerMock.attemptToRequestLocationUpdatesIsCalled).toEventually(beTrue(), timeout: .seconds(4))
                    }
                }

                afterEach {
                    dependenciesContainer.userStorageHandler.removeObject(forKey: UserDefaultsKeys.locationTimestampKey)
                    dependenciesContainer.userStorageHandler.removeObject(forKey: UserDefaultsKeys.configurationKey)
                }
            }

            describe("stopLocationCollection()") {
                let manager = GeoManager(userStorageHandler: dependenciesContainer.userStorageHandler,
                                         geoLocationManager: geoLocationManager,
                                         device: UIDevice.current,
                                         tracker: TrackerMock(),
                                         analyticsManager: AnalyticsManager(dependenciesContainer: SimpleDependenciesContainer()))
                context("preferences") {
                    context("on calling stopLocationCollection()") {
                        it("should return bool for locationCollectionKey as false") {
                            manager.stopLocationCollection()
                            // swiftlint:disable:next line_length
                            expect(dependenciesContainer.userStorageHandler.bool(forKey: UserDefaultsKeys.locationCollectionKey)).toEventually(beFalse(), timeout: .seconds(2))
                        }
                    }

                    afterEach {
                        dependenciesContainer.userStorageHandler.removeObject(forKey: UserDefaultsKeys.locationCollectionKey)
                    }
                }
            }
        }
    }
}

// swiftlint:enable type_body_length
// swiftlint:enable function_body_length
