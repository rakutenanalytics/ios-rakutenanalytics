import Quick
import Nimble
import CoreLocation
import UIKit.UIDevice
@testable import RAnalytics

final class GeoManagerSpec: QuickSpec {

    override func spec() {
        
        let dependenciesFactory = SimpleDependenciesContainer()
        
        describe("GeoManager") {
            
            context("singleton plus") {
                it("should not be nil on accessing shared instance") {
                    expect(GeoManager.shared).toNot(beNil())
                }

                it("should not be nil on creating a new instance") {
                    let manager = GeoManager(geoTracker: nil, device: UIDevice.current, userStorageHandler: dependenciesFactory.userStorageHandler)
                    expect(manager).toNot(beNil())
                }
            }

            describe("getConfiguration()") {
                let geoManager = GeoManager(geoTracker: nil, device: UIDevice.current, userStorageHandler: dependenciesFactory.userStorageHandler)
                context("on startLocationCollection not called before getConfiguration()") {
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
                        expect(configuration.startTime?.hours).to(equal(0))
                        expect(configuration.startTime?.minutes).to(equal(0))
                    }

                    it("should set endTime to 23:59") {
                        expect(configuration.endTime?.hours).to(equal(23))
                        expect(configuration.endTime?.minutes).to(equal(59))
                    }
                }
                
                context("on startLocationCollection called before getConfiguration()") {
                    let configuration = Configuration(distanceInterval: 300,
                                                      timeInterval: 600,
                                                      accuracy: .nearest,
                                                      startTime: GeoTime(hours: 12, minutes: 20),
                                                      endTime: GeoTime(hours: 19, minutes: 30))
                    
                    beforeEach {
                        geoManager.startLocationCollection(configuration: configuration)
                    }
                    
                    it("should set the configuration as passed on startLocationCollection()") {
                        expect(geoManager.getConfiguration().distanceInterval).to(equal(300))
                        expect(geoManager.getConfiguration().timeInterval).to(equal(600))
                        expect(geoManager.getConfiguration().accuracy).to(equal(.nearest))
                        expect(geoManager.getConfiguration().startTime).to(equal(GeoTime(hours: 12, minutes: 20)))
                        expect(geoManager.getConfiguration().endTime).to(equal(GeoTime(hours: 19, minutes: 30)))
                    }
                    afterEach {
                        dependenciesFactory.userStorageHandler.removeObject(forKey: "GeoConfiguration")
                    }
                }
            }

            describe("startLocationCollection(configuration:)") {
                let geoManager =  GeoManager(geoTracker: nil, device: UIDevice.current, userStorageHandler: dependenciesFactory.userStorageHandler)

                context("When passed configuration is nil") {
                    beforeEach {
                        geoManager.startLocationCollection(configuration: nil)
                    }

                    it("should keep default configuration") {
                        expect(geoManager.getConfiguration()).to(equal(ConfigurationFactory.defaultConfiguration))
                    }
                    
                    afterEach {
                        dependenciesFactory.userStorageHandler.removeObject(forKey: "GeoConfiguration")
                    }
                }                

                context("When passed configuration is not nil") {
                    let configuration = Configuration(distanceInterval: 250,
                                                      timeInterval: 400,
                                                      accuracy: .nearest,
                                                      startTime: GeoTime(hours: 14, minutes: 20),
                                                      endTime: GeoTime(hours: 19, minutes: 30))

                    beforeEach {
                        geoManager.startLocationCollection(configuration: configuration)
                    }

                    it("should not keep default configuration") {
                        expect(geoManager.getConfiguration()).toNot(equal(ConfigurationFactory.defaultConfiguration))
                    }

                    it("should set the expected configuration") {
                        expect(geoManager.getConfiguration().distanceInterval).to(equal(250))
                        expect(geoManager.getConfiguration().timeInterval).to(equal(400))
                        expect(geoManager.getConfiguration().accuracy).to(equal(.nearest))
                        expect(geoManager.getConfiguration().startTime).to(equal(GeoTime(hours: 14, minutes: 20)))
                        expect(geoManager.getConfiguration().endTime).to(equal(GeoTime(hours: 19, minutes: 30)))
                    }
                    afterEach {
                        dependenciesFactory.userStorageHandler.removeObject(forKey: "GeoConfiguration")
                    }
                }
                
                context("When passing no parameters to configuration") {
                    
                    let configuration = Configuration()
                    
                    geoManager.startLocationCollection(configuration: configuration)
                    let geoConfiguration = geoManager.getConfiguration()
                    it("should set distanceInterval to default distanceInterval") {
                        expect(geoConfiguration.distanceInterval).to(equal(ConfigurationConstants.distanceInterval))
                    }
                    
                    it("should set timeInterval to default timeInterval") {
                        expect(geoConfiguration.timeInterval).to(equal(ConfigurationConstants.timeInterval))
                    }
                    
                    it("should set accuracy to best") {
                        expect(geoConfiguration.accuracy).to(equal(.best))
                    }
                    
                    it("should set startTime to 00:00") {
                        expect(geoConfiguration.startTime?.hours).to(equal(ConfigurationConstants.startTime.hours))
                        expect(geoConfiguration.startTime?.minutes).to(equal(ConfigurationConstants.startTime.minutes))
                    }
                    
                    it("should set endTime to 23:59") {
                        expect(geoConfiguration.endTime?.hours).to(equal(ConfigurationConstants.endTime.hours))
                        expect(geoConfiguration.endTime?.minutes).to(equal(ConfigurationConstants.endTime.minutes))
                    }
                    
                    afterEach {
                        dependenciesFactory.userStorageHandler.removeObject(forKey: "GeoConfiguration")
                    }
                }
                
                context("When passing few parameters to configuration") {
                    let configuration = Configuration(distanceInterval: 400)
                    geoManager.startLocationCollection(configuration: configuration)
                    let geoConfiguration = geoManager.getConfiguration()
                    
                    it("should set distanceInterval as 400") {
                        expect(geoConfiguration.distanceInterval).to(equal(400))
                    }
                    
                    it("should set timeInterval to 300") {
                        expect(geoConfiguration.timeInterval).to(equal(ConfigurationConstants.timeInterval))
                    }
                    
                    it("should set accuracy to best") {
                        expect(geoConfiguration.accuracy).to(equal(.best))
                    }
                    
                    it("should set startTime to 00:00") {
                        expect(geoConfiguration.startTime?.hours).to(equal(ConfigurationConstants.startTime.hours))
                        expect(geoConfiguration.startTime?.minutes).to(equal(ConfigurationConstants.startTime.minutes))
                    }
                    
                    it("should set endTime to 23:59") {
                        expect(geoConfiguration.endTime?.hours).to(equal(ConfigurationConstants.endTime.hours))
                        expect(geoConfiguration.endTime?.minutes).to(equal(ConfigurationConstants.endTime.minutes))
                    }
                    
                    afterEach {
                        dependenciesFactory.userStorageHandler.removeObject(forKey: "GeoConfiguration")
                    }
                }
                
                describe("When passed configuration is more than the specified range") {
                    
                    context("on all the fields are more the range") {
                        let configuration = Configuration(distanceInterval: 10000,
                                                          timeInterval: 40000,
                                                          accuracy: .nearest,
                                                          startTime: GeoTime(hours: 25, minutes: 200),
                                                          endTime: GeoTime(hours: 200, minutes: 300))
                        geoManager.startLocationCollection(configuration: configuration)
                        let geoConfiguration = geoManager.getConfiguration()
                        
                        it("should set distanceInterval to default interval") {
                            expect(geoConfiguration.distanceInterval).to(equal(ConfigurationConstants.distanceInterval))
                        }
                        
                        it("should set timeInterval to 300") {
                            expect(geoConfiguration.timeInterval).to(equal(ConfigurationConstants.timeInterval))
                        }
                        
                        it("should same as what sent from Configuration") {
                            expect(geoConfiguration.accuracy).to(equal(.nearest))
                        }
                        
                        it("should set startTime to 00:00") {
                            expect(geoConfiguration.startTime?.hours).to(equal(ConfigurationConstants.startTime.hours))
                            expect(geoConfiguration.startTime?.minutes).to(equal(ConfigurationConstants.startTime.minutes))
                        }
                        
                        it("should set endTime to 23:59") {
                            expect(geoConfiguration.endTime?.hours).to(equal(ConfigurationConstants.endTime.hours))
                            expect(geoConfiguration.endTime?.minutes).to(equal(ConfigurationConstants.endTime.minutes))
                        }
                        
                        afterEach {
                            dependenciesFactory.userStorageHandler.removeObject(forKey: "GeoConfiguration")
                        }
                    }
                    
                    context("on minutes are more than the specified range") {
                        let configuration = Configuration(distanceInterval: 250,
                                                          timeInterval: 900,
                                                          accuracy: .nearest,
                                                          startTime: GeoTime(hours: 12, minutes: 200),
                                                          endTime: GeoTime(hours: 23, minutes: 300))
                        geoManager.startLocationCollection(configuration: configuration)
                        let geoConfiguration = geoManager.getConfiguration()
                        
                        it("should set start minutes as per defaults 59") {
                            expect(geoConfiguration.startTime?.minutes).to(equal(ConfigurationConstants.startTime.minutes))
                        }
                        
                        it("should set end minutes as per defaults 59") {
                            expect(geoConfiguration.endTime?.minutes).to(equal(ConfigurationConstants.endTime.minutes))
                        }
                        
                        afterEach {
                            dependenciesFactory.userStorageHandler.removeObject(forKey: "GeoConfiguration")
                        }
                        
                    }
                    
                }
            }
        }
    }
}
