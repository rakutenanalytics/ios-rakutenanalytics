// swiftlint:disable type_body_length
// swiftlint:disable function_body_length

import Quick
import Nimble
import CoreLocation
import UIKit.UIDevice
@testable import RakutenAnalytics

#if SWIFT_PACKAGE
import RAnalyticsTestHelpers
#endif

final class GeoManagerSpec: QuickSpec {
    override class func spec() {

        let dependenciesContainer = GeoDependenciesContainer()
        let configurationStore = GeoConfigurationStore(userStorageHandler: dependenciesContainer.userStorageHandler)

        describe("GeoManager") {
            let geoLocationManager = GeoLocationManager(bundle: BundleMock(),
                                                        coreLocationManager: LocationManagerMock(),
                                                        configurationStore: configurationStore)
            let coreLocationManager = CLLocationManager()

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

                    expect(locationManagerMock.requestLocationUserActionIsCalled).toEventually(beTrue())
                }

                context("When requestLocation(actionParameters:) is called") {
                    let analyticsDependenciesContainer = SimpleContainerMock()
                    let dependenciesContainer = SimpleContainerMock()
                    let expectedError = NSError(domain: "", code: 0, userInfo: nil)
                    var returnedError: NSError!
                    var returnedLocationModel: LocationModel!
                    var result: GeoRequestLocationResult!
                    let location = CLLocation(latitude: -56.6462520, longitude: -36.6462520)
                    var trackerMock: TrackerMock!
                    var coreLocationManagerMock: LocationManagerMock!
                    var geoLocationManager: GeoLocationManager!
                    var geoManager: GeoManager!
                    let asIdentifierManagerMock = ASIdentifierManagerMock()
                    asIdentifierManagerMock.advertisingIdentifierUUIDString = "E621E1F8-A36C-495B-93FC-0C247A3E6E5Q"
                    let userDefaultsMock = UserDefaultsMock([:])
                    userDefaultsMock.set(value: "flo_test", forKey: RAnalyticsExternalCollector.Constants.trackingIdentifierKey)
                    let keychainHandlerMock = KeychainHandlerMock()
                    keychainHandlerMock.set(value: "123456", for: RAnalyticsExternalCollector.Constants.easyIdentifierKey)

                    beforeEach {
                        trackerMock = TrackerMock()

                        coreLocationManagerMock = LocationManagerMock()
                        geoLocationManager = GeoLocationManager(bundle: BundleMock(),
                                                                coreLocationManager: coreLocationManagerMock,
                                                                configurationStore: configurationStore)

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
                        func verifyState() {
                            it("should process the location event with an expected name") {
                                expect(result).toEventuallyNot(beNil())
                                expect(trackerMock.event?.name).to(equal(RAnalyticsEvent.Name.geoLocation))
                            }

                            it("should process the location event with empty parameters") {
                                expect(result).toEventuallyNot(beNil())
                                expect(trackerMock.event?.parameters).to(beEmpty())
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
                                expect(trackerMock.state?.advertisingIdentifier).to(equal("E621E1F8-A36C-495B-93FC-0C247A3E6E5Q"))
                            }
                        }

                        context("When action parameters are nil") {
                            let expectedLocationModel = LocationModel(location: location,
                                                                      isAction: true,
                                                                      actionParameters: nil)

                            beforeEach {
                                geoManager.requestLocation(actionParameters: nil) { aResult in
                                    result = aResult
                                }

                                coreLocationManagerMock.delegate?.locationManager?(coreLocationManager, didUpdateLocations: [location])
                            }

                            verifyState()

                            it("should return an expected location") {
                                expect(result).toEventuallyNot(beNil())

                                if case .success(let locationModel) = result {
                                    returnedLocationModel = locationModel
                                }

                                expect(returnedLocationModel).to(equal(expectedLocationModel))
                            }

                            it("should process the location event with an expected location model") {
                                expect(result).toEventuallyNot(beNil())
                                expect(trackerMock.state?.lastKnownLocation).to(equal(expectedLocationModel))
                            }

                            it("should process the location event with nil action parameters") {
                                expect(result).toEventuallyNot(beNil())
                                expect(trackerMock.state?.lastKnownLocation?.actionParameters).to(beNil())
                            }
                        }

                        context("When action parameters are not nil") {
                            let actionParameters = GeoActionParameters(actionType: "test-actionType",
                                                                       actionLog: "test-actionLog",
                                                                       actionId: "test-actionId",
                                                                       actionDuration: "test-actionDuration",
                                                                       additionalLog: "test-additionalLog")

                            let expectedLocationModel = LocationModel(location: location,
                                                                      isAction: true,
                                                                      actionParameters: actionParameters)

                            beforeEach {
                                geoManager.requestLocation(actionParameters: actionParameters) { aResult in
                                    result = aResult
                                }

                                coreLocationManagerMock.delegate?.locationManager?(coreLocationManager, didUpdateLocations: [location])
                            }

                            verifyState()

                            it("should return an expected location") {
                                expect(result).toEventuallyNot(beNil())

                                if case .success(let locationModel) = result {
                                    returnedLocationModel = locationModel
                                }

                                expect(returnedLocationModel).to(equal(expectedLocationModel))
                            }

                            it("should process the location event with an expected location model") {
                                expect(result).toEventuallyNot(beNil())
                                expect(trackerMock.state?.lastKnownLocation).to(equal(expectedLocationModel))
                            }

                            it("should process the location event with an action type") {
                                expect(result).toEventuallyNot(beNil())
                                expect(trackerMock.state?.lastKnownLocation?.actionParameters?.actionType).to(equal("test-actionType"))
                            }

                            it("should process the location event with an action log") {
                                expect(result).toEventuallyNot(beNil())
                                expect(trackerMock.state?.lastKnownLocation?.actionParameters?.actionLog).to(equal("test-actionLog"))
                            }

                            it("should process the location event with an action id") {
                                expect(result).toEventuallyNot(beNil())
                                expect(trackerMock.state?.lastKnownLocation?.actionParameters?.actionId).to(equal("test-actionId"))
                            }

                            it("should process the location event with an action duration") {
                                expect(result).toEventuallyNot(beNil())
                                expect(trackerMock.state?.lastKnownLocation?.actionParameters?.actionDuration).to(equal("test-actionDuration"))
                            }

                            it("should process the location event with an additional log") {
                                expect(result).toEventuallyNot(beNil())
                                expect(trackerMock.state?.lastKnownLocation?.actionParameters?.additionalLog).to(equal("test-additionalLog"))
                            }
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
                    
                    var configuration: GeoConfiguration?
                    
                    beforeEach {
                        configuration = geoManager.getConfiguration()
                    }
                    
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

                    afterEach {
                        dependenciesContainer.userStorageHandler.removeObject(forKey: UserDefaultsKeys.configurationKey)
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
                        dependenciesContainer.userStorageHandler.removeObject(forKey: UserDefaultsKeys.configurationKey)
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
                        let setConfiguration = GeoConfiguration(distanceInterval: 400,
                                                                timeInterval: 450,
                                                                accuracy: .kilometer,
                                                                startTime: GeoTime(hours: 7, minutes: 10),
                                                                endTime: GeoTime(hours: 15, minutes: 10))
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

                    it("should return default configuration on calling getConfiguration") {
                        geoManager.startLocationCollection(configuration: nil)
                        expect(geoManager.getConfiguration()).to(equal(GeoConfigurationFactory.defaultConfiguration))
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

            describe("on startLocationCollection(configuration:)") {
                let location = CLLocation(coordinate: CLLocationCoordinate2D(latitude: 10.3317,
                                                                             longitude: -122.0325086),
                                          altitude: 12.0,
                                          horizontalAccuracy: 10.0,
                                          verticalAccuracy: 12.0,
                                          course: 1.0,
                                          speed: 10.0,
                                          timestamp: Date())
                let error = NSError(domain: "", code: 0, userInfo: nil)
                var configurationStore: GeoConfigurationStore!
                var geoLocationManager: GeoLocationManager!
                var geoLocationManagerMock: GeoLocationManagerMock!
                var coreLocationManagerMock: LocationManagerMock!
                var geoManager: GeoManager!

                beforeEach {
                    geoLocationManagerMock = GeoLocationManagerMock()

                    geoManager = GeoManager(userStorageHandler: dependenciesContainer.userStorageHandler,
                                            geoLocationManager: geoLocationManagerMock,
                                            device: UIDevice.current,
                                            tracker: TrackerMock(),
                                            analyticsManager: AnalyticsManager(dependenciesContainer: SimpleDependenciesContainer()))

                    geoLocationManagerMock.startMonitoringSignificantLocationChangesIsCalled = false
                    geoLocationManagerMock.requestLocationContinualIsCalled = false

                    dependenciesContainer.userStorageHandler.removeObject(forKey: UserDefaultsKeys.configurationKey)
                    geoManager.startLocationCollection()
                }

                it("should call startMonitoringSignificantLocationChanges()") {
                    waitUntil(timeout: .seconds(1)) { done in
                        DispatchQueue.main.asyncAfter(deadline: .now()) {
                            expect(geoLocationManagerMock.startMonitoringSignificantLocationChangesIsCalled).to(beTrue())
                            done()
                        }
                    }
                }

                it("should call requestLocationUpdate(for: .continual) for inital update") {
                    waitUntil(timeout: .seconds(1)) { done in
                        DispatchQueue.main.asyncAfter(deadline: .now()) {
                            expect(geoLocationManagerMock.requestLocationContinualIsCalled).to(beTrue())
                            done()
                        }
                    }
                }

                it("should call requestLocationUpdate(for: .continual) on configuring poller at specified timeInterval") {
                    waitUntil(timeout: .seconds(1)) { done in
                        DispatchQueue.main.asyncAfter(deadline: .now()) {
                            expect(geoLocationManagerMock.requestLocationContinualIsCalled).to(beTrue())
                            done()
                        }
                    }
                }

                context("configurePoller()") {
                    var configuration: GeoConfiguration!
                    var configurationData: Data!

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
                    }

                    context("when lastCollectedLocationTms is nil") {
                        beforeEach {

                            dependenciesContainer.userStorageHandler.removeObject(forKey: UserDefaultsKeys.locationTimestampKey)
                            dependenciesContainer.userStorageHandler.set(value: configurationData, forKey: UserDefaultsKeys.configurationKey)

                            geoLocationManagerMock.requestLocationContinualIsCalled = false
                            geoManager.configurePoller()
                        }

                        it("should start poller and call requestLocationUpdate(for:) with specified timeinterval as delay") {
                            expect(geoLocationManagerMock.requestLocationContinualIsCalled).toEventually(beTrue(), timeout: .seconds(4))
                        }
                    }

                    context("when lastCollectedLocationTms is non-nil and lapsed") {
                        beforeEach {
                            // swiftlint:disable:next line_length
                            dependenciesContainer.userStorageHandler.set(value: Date().addingTimeInterval(-4), forKey: UserDefaultsKeys.locationTimestampKey)
                            dependenciesContainer.userStorageHandler.set(value: configurationData, forKey: UserDefaultsKeys.configurationKey)

                            geoLocationManagerMock.requestLocationContinualIsCalled = false
                            geoManager.configurePoller()
                        }

                        it("should start poller and call requestLocationUpdate(for:) with no delay") {
                            expect(geoLocationManagerMock.requestLocationContinualIsCalled).toEventually(beTrue())
                        }
                    }

                    context("when lastCollectedLocationTms is non-nil and not lapsed") {
                        beforeEach {
                            // swiftlint:disable:next line_length
                            dependenciesContainer.userStorageHandler.set(value: Date().addingTimeInterval(-1), forKey: UserDefaultsKeys.locationTimestampKey)
                            dependenciesContainer.userStorageHandler.set(value: configurationData, forKey: UserDefaultsKeys.configurationKey)

                            geoLocationManagerMock.requestLocationContinualIsCalled = false
                            geoManager.configurePoller()
                        }

                        it("should start poller and call requestLocationUpdate(for:) with remaining elapsed delay") {
                            expect(geoLocationManagerMock.requestLocationContinualIsCalled).toEventually(beTrue(), timeout: .seconds(4))
                        }
                    }

                    afterEach {
                        dependenciesContainer.userStorageHandler.removeObject(forKey: UserDefaultsKeys.locationTimestampKey)
                        dependenciesContainer.userStorageHandler.removeObject(forKey: UserDefaultsKeys.configurationKey)
                    }
                }

                context("Last Collected Location Timestamp") {

                    beforeEach {
                        configurationStore = GeoConfigurationStore(userStorageHandler: dependenciesContainer.userStorageHandler)

                        coreLocationManagerMock = LocationManagerMock()

                        geoLocationManager = GeoLocationManager(bundle: BundleMock(),
                                                                coreLocationManager: coreLocationManagerMock,
                                                                configurationStore: configurationStore)

                        geoManager = GeoManager(userStorageHandler: dependenciesContainer.userStorageHandler,
                                                geoLocationManager: geoLocationManager,
                                                device: UIDevice.current,
                                                tracker: TrackerMock(),
                                                analyticsManager: AnalyticsManager(dependenciesContainer: SimpleDependenciesContainer()))

                        dependenciesContainer.userStorageHandler.removeObject(forKey: UserDefaultsKeys.configurationKey)

                        geoManager.startLocationCollection()
                    }

                    context("when lastCollectedLocationTms is nil") {
                        beforeEach {
                            dependenciesContainer.userStorageHandler.removeObject(forKey: UserDefaultsKeys.locationTimestampKey)
                        }

                        it("should set lastCollectedLocationTms on success with didUpdateLocations") {
                            coreLocationManagerMock?.delegate?.locationManager?(coreLocationManager, didUpdateLocations: [location])
                            expect(dependenciesContainer.userStorageHandler.object(forKey: UserDefaultsKeys.locationTimestampKey)).toNot(beNil())
                        }

                        it("should not set lastCollectedLocationTms on failure with didFailWithError") {
                            coreLocationManagerMock?.delegate?.locationManager?(coreLocationManager, didFailWithError: error)
                            expect(dependenciesContainer.userStorageHandler.object(forKey: UserDefaultsKeys.locationTimestampKey)).to(beNil())
                        }
                    }
                }
            }

            describe("on startLocationCollection(configuration:)") {
                var configurationStore: GeoConfigurationStore!
                var geoLocationManager: GeoLocationManager!
                var coreLocationManagerMock: LocationManagerMock!
                var geoManager: GeoManager!

                beforeEach {
                    configurationStore = GeoConfigurationStore(userStorageHandler: dependenciesContainer.userStorageHandler)

                    coreLocationManagerMock = LocationManagerMock()

                    geoLocationManager = GeoLocationManager(bundle: BundleMock(),
                                                            coreLocationManager: coreLocationManagerMock,
                                                            configurationStore: configurationStore)

                    geoManager = GeoManager(userStorageHandler: dependenciesContainer.userStorageHandler,
                                            geoLocationManager: geoLocationManager,
                                            device: UIDevice.current,
                                            tracker: TrackerMock(),
                                            analyticsManager: AnalyticsManager(dependenciesContainer: SimpleDependenciesContainer()))
                }
                context("distance based location collection") {

                    context("when the region is not monitored") {
                        beforeEach {
                            dependenciesContainer.userStorageHandler.removeObject(forKey: UserDefaultsKeys.configurationKey)

                            geoManager.startLocationCollection()
                            coreLocationManagerMock.delegate?.locationManager?(coreLocationManager,
                                                                               didUpdateLocations: [CLLocation(latitude: 78.9,
                                                                                                               longitude: 123.456)])
                        }

                        it("should start monitoring location collection region") {
                            let monitoredRegion = coreLocationManagerMock.monitoredRegions.first as? CLCircularRegion
                            expect(coreLocationManagerMock.monitoredRegions.count).to(equal(1))
                            expect(monitoredRegion?.radius).to(equal(300))
                            expect(monitoredRegion?.center.latitude).to(equal(78.9))
                            expect(monitoredRegion?.center.longitude).to(equal(123.456))
                            expect(monitoredRegion?.identifier).to(equal("GeoLocationCollectionRegionIdentifier"))
                        }
                    }

                    context("when the region is already monitored") {
                        let exisitingRegion = CLCircularRegion(center: CLLocationCoordinate2D(latitude: 123.456, longitude: 78.9),
                                                               radius: 400,
                                                               identifier: "GeoLocationCollectionRegionIdentifier")
                        beforeEach {
                            coreLocationManagerMock.monitoredRegions.insert(exisitingRegion)
                            geoManager.startLocationCollection()
                            coreLocationManagerMock.delegate?.locationManager?(coreLocationManager, didUpdateLocations: [CLLocation()])
                        }
                        it("should not monitor additional duplicate location collection region") {
                            let monitoredRegion = coreLocationManagerMock.monitoredRegions.first as? CLCircularRegion
                            expect(coreLocationManagerMock.monitoredRegions.count).to(equal(1))
                            expect(monitoredRegion?.radius).to(equal(400))
                            expect(monitoredRegion?.center.latitude).to(equal(123.456))
                            expect(monitoredRegion?.center.longitude).to(equal(78.9))
                            expect(monitoredRegion?.identifier).to(equal("GeoLocationCollectionRegionIdentifier"))
                        }
                    }

                    context("when CLLocationManagerDelegate didUpdateLocations returns empty location array") {
                        beforeEach {
                            geoManager.startLocationCollection()
                            coreLocationManagerMock.delegate?.locationManager?(coreLocationManager, didUpdateLocations: [])
                        }

                        it("will not monitor location collection region on intial location update") {
                            expect(coreLocationManagerMock.monitoredRegions.count).to(equal(0))
                        }
                    }
                }
            }

            describe("on stopLocationCollection()") {
                var configurationStore: GeoConfigurationStore!
                var geoLocationManager: GeoLocationManager!
                var coreLocationManagerMock: LocationManagerMock!
                var geoManager: GeoManager!

                context("Distance based location collection") {
                    beforeEach {
                        configurationStore = GeoConfigurationStore(userStorageHandler: dependenciesContainer.userStorageHandler)

                        coreLocationManagerMock = LocationManagerMock()

                        geoLocationManager = GeoLocationManager(bundle: BundleMock(),
                                                                coreLocationManager: coreLocationManagerMock,
                                                                configurationStore: configurationStore)

                        geoManager = GeoManager(userStorageHandler: dependenciesContainer.userStorageHandler,
                                                geoLocationManager: geoLocationManager,
                                                device: UIDevice.current,
                                                tracker: TrackerMock(),
                                                analyticsManager: AnalyticsManager(dependenciesContainer: SimpleDependenciesContainer()))

                        geoManager.startLocationCollection()
                        coreLocationManagerMock.delegate?.locationManager?(coreLocationManager, didUpdateLocations: [CLLocation()])
                    }

                    it("should stop monitoring location collection region") {
                        geoManager.stopLocationCollection()
                        expect(coreLocationManagerMock.monitoredRegions.count).to(equal(0))
                    }

                    it("should return nil on calling getConfiguration after stopLocationCollection") {
                        geoManager.stopLocationCollection()
                        expect(geoManager.getConfiguration()).to(beNil())
                    }
                }
                
            }

            describe("on stopLocationCollection()") {

                var geoManager: GeoManager!
                let geoLocationManagerMock = GeoLocationManagerMock()

                beforeEach {
                    geoManager = GeoManager(userStorageHandler: dependenciesContainer.userStorageHandler,
                                            geoLocationManager: geoLocationManagerMock,
                                            device: UIDevice.current,
                                            tracker: TrackerMock(),
                                            analyticsManager: AnalyticsManager(dependenciesContainer: SimpleDependenciesContainer()))

                    geoManager.stopLocationCollection()
                }

                it("should call stopLocationUpdates") {
                    expect(geoLocationManagerMock.stopLocationUpdatesCalled).to(beTrue())
                }

                it("should call stopMonitoringSignificantLocationChanges") {
                    expect(geoLocationManagerMock.stopMonitoringSignificantLocationChangesIsCalled).to(beTrue())
                }

                it("should return false for locationCollectionKey in userStorageHandler") {
                    expect(dependenciesContainer.userStorageHandler.bool(forKey: UserDefaultsKeys.locationCollectionKey)).to(beFalse())
                }

                it("should return nil for configurationKey in userStorageHandler") {
                    expect(dependenciesContainer.userStorageHandler.bool(forKey: UserDefaultsKeys.configurationKey)).to(beFalse())
                }

                it("should return nil on getConfiguration()") {
                    expect(geoManager.getConfiguration()).to(beNil())
                }
            }
        }
    }
}

// swiftlint:enable type_body_length
// swiftlint:enable function_body_length
