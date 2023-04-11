import Quick
import Nimble
import CoreLocation
import UIKit.UIDevice
@testable import RAnalytics

final class GeoManagerSpec: QuickSpec {

    override func spec() {
        
        let dependenciesContainer = SimpleDependenciesContainer()
        
        describe("GeoManager") {
            
            context("singleton plus") {
                it("should not be nil on accessing shared instance") {
                    expect(GeoManager.shared).toNot(beNil())
                }

                it("should not be nil on creating a new instance") {
                    let manager = GeoManager(userStorageHandler: dependenciesContainer.userStorageHandler)
                    expect(manager).toNot(beNil())
                }
            }

            describe("configuration get-only property") {
                let manager = GeoManager(userStorageHandler: dependenciesContainer.userStorageHandler)
                context("getter") {
                    beforeEach {
                        dependenciesContainer.userStorageHandler.removeObject(forKey: UserDefaultsKeys.geoConfigurationKey)
                    }

                    context("when no configuration is set on startLocationCollection(configuration:)") {
                        it("should not be nil") {
                            expect(manager.configuration).toNot(beNil())
                        }

                        it("should contain default configuration") {
                            expect(manager.configuration).to(equal(GeoConfigurationFactory.defaultConfiguration))
                        }
                    }

                    context("when configuration is set on startLocationCollection(configuration:)") {
                        it("should not be nil") {
                            expect(manager.configuration).toNot(beNil())
                        }

                        it("should contain configuration that was set") {
                            manager.startLocationCollection(configuration: GeoConfiguration(distanceInterval: 350))
                            expect(manager.configuration.distanceInterval).to(equal(350))
                        }
                    }
                }
            }

            describe("getConfiguration()") {
                let geoManager = GeoManager(userStorageHandler: dependenciesContainer.userStorageHandler)
                context("on startLocationCollection not called before getConfiguration()") {
                    
                    beforeEach {
                        dependenciesContainer.userStorageHandler.removeObject(forKey: UserDefaultsKeys.geoConfigurationKey)
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
                        dependenciesContainer.userStorageHandler.removeObject(forKey: UserDefaultsKeys.geoConfigurationKey)
                    }
                }
            }

            describe("on startLocationCollection(configuration:)") {
                let manager = GeoManager(userStorageHandler: dependenciesContainer.userStorageHandler)
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
                let geoManager = GeoManager(userStorageHandler: dependenciesContainer.userStorageHandler)
                context("When passed configuration is nil") {
                    beforeEach {
                        dependenciesContainer.userStorageHandler.removeObject(forKey: UserDefaultsKeys.geoConfigurationKey)
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
                        dependenciesContainer.userStorageHandler.removeObject(forKey: UserDefaultsKeys.geoConfigurationKey)
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
                        dependenciesContainer.userStorageHandler.removeObject(forKey: UserDefaultsKeys.geoConfigurationKey)
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
                        dependenciesContainer.userStorageHandler.removeObject(forKey: UserDefaultsKeys.geoConfigurationKey)
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
                        dependenciesContainer.userStorageHandler.removeObject(forKey: UserDefaultsKeys.geoConfigurationKey)
                    }
                }
            }
        }
    }
}
