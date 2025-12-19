// swiftlint:disable type_body_length
// swiftlint:disable function_body_length

import Testing
import Foundation
import CoreLocation
import UIKit.UIDevice
@testable import RakutenAnalytics

#if SWIFT_PACKAGE
import RAnalyticsTestHelpers
#endif

@Suite("GeoManager Configuration")
struct GeoManagerConfigurationTests {
    static let coreLocationManager = CLLocationManager()
    static let dependenciesContainer = GeoDependenciesContainer()
    static let configurationStore = GeoConfigurationStore(userStorageHandler: dependenciesContainer.userStorageHandler)
    
    static let geoLocationManager = GeoLocationManager(
        bundle: BundleMock(),
        coreLocationManager: LocationManagerMock(),
        configurationStore: configurationStore)
    
    // MARK: - getConfiguration Tests
    
    @Test("should set distanceInterval to be nil when startLocationCollection not called before getConfiguration()")
    func testGetConfigurationDistanceIntervalNil() {
        let geoManager = GeoManager(
            userStorageHandler: Self.dependenciesContainer.userStorageHandler,
            geoLocationManager: Self.geoLocationManager,
            device: UIDevice.current,
            tracker: TrackerMock(),
            analyticsManager: AnalyticsManager(dependenciesContainer: SimpleDependenciesContainer()))
        
        Self.dependenciesContainer.userStorageHandler.removeObject(forKey: UserDefaultsKeys.configurationKey)
        let configuration = geoManager.getConfiguration()
        
        #expect(configuration?.distanceInterval == nil)
    }
    
    @Test("should set timeInterval to be nil when startLocationCollection not called before getConfiguration()")
    func testGetConfigurationTimeIntervalNil() {
        let geoManager = GeoManager(
            userStorageHandler: Self.dependenciesContainer.userStorageHandler,
            geoLocationManager: Self.geoLocationManager,
            device: UIDevice.current,
            tracker: TrackerMock(),
            analyticsManager: AnalyticsManager(dependenciesContainer: SimpleDependenciesContainer()))
        
        Self.dependenciesContainer.userStorageHandler.removeObject(forKey: UserDefaultsKeys.configurationKey)
        let configuration = geoManager.getConfiguration()
        
        #expect(configuration?.timeInterval == nil)
    }
    
    @Test("should set accuracy to be nil when startLocationCollection not called before getConfiguration()")
    func testGetConfigurationAccuracyNil() {
        let geoManager = GeoManager(
            userStorageHandler: Self.dependenciesContainer.userStorageHandler,
            geoLocationManager: Self.geoLocationManager,
            device: UIDevice.current,
            tracker: TrackerMock(),
            analyticsManager: AnalyticsManager(dependenciesContainer: SimpleDependenciesContainer()))
        
        Self.dependenciesContainer.userStorageHandler.removeObject(forKey: UserDefaultsKeys.configurationKey)
        let configuration = geoManager.getConfiguration()
        
        #expect(configuration?.accuracy == nil)
    }
    
    @Test("should set startTime to be nil when startLocationCollection not called before getConfiguration()")
    func testGetConfigurationStartTimeNil() {
        let geoManager = GeoManager(
            userStorageHandler: Self.dependenciesContainer.userStorageHandler,
            geoLocationManager: Self.geoLocationManager,
            device: UIDevice.current,
            tracker: TrackerMock(),
            analyticsManager: AnalyticsManager(dependenciesContainer: SimpleDependenciesContainer()))
        
        Self.dependenciesContainer.userStorageHandler.removeObject(forKey: UserDefaultsKeys.configurationKey)
        let configuration = geoManager.getConfiguration()
        
        #expect(configuration?.startTime == nil)
    }
    
    @Test("should set endTime to be nil when startLocationCollection not called before getConfiguration()")
    func testGetConfigurationEndTimeNil() {
        let geoManager = GeoManager(
            userStorageHandler: Self.dependenciesContainer.userStorageHandler,
            geoLocationManager: Self.geoLocationManager,
            device: UIDevice.current,
            tracker: TrackerMock(),
            analyticsManager: AnalyticsManager(dependenciesContainer: SimpleDependenciesContainer()))
        
        Self.dependenciesContainer.userStorageHandler.removeObject(forKey: UserDefaultsKeys.configurationKey)
        let configuration = geoManager.getConfiguration()
        
        #expect(configuration?.endTime == nil)
    }
    
    @Test("should set the configuration as passed on startLocationCollection()")
    func testGetConfigurationAfterStartLocationCollection() {
        let geoManager = GeoManager(
            userStorageHandler: Self.dependenciesContainer.userStorageHandler,
            geoLocationManager: Self.geoLocationManager,
            device: UIDevice.current,
            tracker: TrackerMock(),
            analyticsManager: AnalyticsManager(dependenciesContainer: SimpleDependenciesContainer()))
        
        let configuration = GeoConfiguration(
            distanceInterval: 300,
            timeInterval: 600,
            accuracy: .nearest,
            startTime: GeoTime(hours: 12, minutes: 20),
            endTime: GeoTime(hours: 19, minutes: 30))
        geoManager.startLocationCollection(configuration: configuration)
        
        let geoConfiguration = geoManager.getConfiguration()
        
        #expect(geoConfiguration?.distanceInterval == 300)
        #expect(geoConfiguration?.timeInterval == 600)
        #expect(geoConfiguration?.accuracy == .nearest)
        #expect(geoConfiguration?.startTime == GeoTime(hours: 12, minutes: 20))
        #expect(geoConfiguration?.endTime == GeoTime(hours: 19, minutes: 30))
        
        Self.dependenciesContainer.userStorageHandler.removeObject(forKey: UserDefaultsKeys.configurationKey)
    }
    
    // MARK: - startLocationCollection Tests
    
    @Test("should return bool for locationCollectionKey as false before calling startLocationCollection(configuration:)")
    func testLocationCollectionKeyFalseBeforeStart() {
        Self.dependenciesContainer.userStorageHandler.removeObject(forKey: UserDefaultsKeys.configurationKey)
        Self.dependenciesContainer.userStorageHandler.removeObject(forKey: UserDefaultsKeys.locationCollectionKey)
        
        #expect(Self.dependenciesContainer.userStorageHandler.bool(forKey: UserDefaultsKeys.locationCollectionKey) == false)
    }
    
    @Test("should return bool for locationCollectionKey as true after calling startLocationCollection(configuration:)")
    func testLocationCollectionKeyTrueAfterStart() {
        let manager = GeoManager(
            userStorageHandler: Self.dependenciesContainer.userStorageHandler,
            geoLocationManager: Self.geoLocationManager,
            device: UIDevice.current,
            tracker: TrackerMock(),
            analyticsManager: AnalyticsManager(dependenciesContainer: SimpleDependenciesContainer()))
        
        Self.dependenciesContainer.userStorageHandler.removeObject(forKey: UserDefaultsKeys.configurationKey)
        Self.dependenciesContainer.userStorageHandler.removeObject(forKey: UserDefaultsKeys.locationCollectionKey)
        
        manager.startLocationCollection()
        
        #expect(Self.dependenciesContainer.userStorageHandler.bool(forKey: UserDefaultsKeys.locationCollectionKey) == true)
        
        Self.dependenciesContainer.userStorageHandler.removeObject(forKey: UserDefaultsKeys.locationCollectionKey)
    }
    
    @Test("should not update the configuration passed if values are equal")
    func testStartLocationCollectionNoUpdateWhenEqual() {
        let manager = GeoManager(
            userStorageHandler: Self.dependenciesContainer.userStorageHandler,
            geoLocationManager: Self.geoLocationManager,
            device: UIDevice.current,
            tracker: TrackerMock(),
            analyticsManager: AnalyticsManager(dependenciesContainer: SimpleDependenciesContainer()))
        
        let setConfiguration = GeoConfiguration(
            distanceInterval: 400,
            timeInterval: 450,
            accuracy: .kilometer,
            startTime: GeoTime(hours: 7, minutes: 10),
            endTime: GeoTime(hours: 15, minutes: 10))
        manager.startLocationCollection(configuration: setConfiguration)
        
        manager.startLocationCollection(configuration: GeoConfiguration(
            distanceInterval: 400,
            timeInterval: 450,
            accuracy: .kilometer,
            startTime: GeoTime(hours: 7, minutes: 10),
            endTime: GeoTime(hours: 15, minutes: 10)))
        
        #expect(manager.getConfiguration() == GeoConfiguration(
            distanceInterval: 400,
            timeInterval: 450,
            accuracy: .kilometer,
            startTime: GeoTime(hours: 7, minutes: 10),
            endTime: GeoTime(hours: 15, minutes: 10)))
    }
    
    @Test("should update the configuration passed when values are not equal")
    func testStartLocationCollectionUpdateWhenNotEqual() {
        let manager = GeoManager(
            userStorageHandler: Self.dependenciesContainer.userStorageHandler,
            geoLocationManager: Self.geoLocationManager,
            device: UIDevice.current,
            tracker: TrackerMock(),
            analyticsManager: AnalyticsManager(dependenciesContainer: SimpleDependenciesContainer()))
        
        let setConfiguration = GeoConfiguration(
            distanceInterval: 400,
            timeInterval: 450,
            accuracy: .kilometer,
            startTime: GeoTime(hours: 7, minutes: 10),
            endTime: GeoTime(hours: 15, minutes: 10))
        manager.startLocationCollection(configuration: setConfiguration)
        
        manager.startLocationCollection(configuration: GeoConfiguration(
            distanceInterval: 350,
            timeInterval: 400,
            accuracy: .kilometer,
            startTime: GeoTime(hours: 6, minutes: 10),
            endTime: GeoTime(hours: 13, minutes: 10)))
        
        #expect(manager.getConfiguration() == GeoConfiguration(
            distanceInterval: 350,
            timeInterval: 400,
            accuracy: .kilometer,
            startTime: GeoTime(hours: 6, minutes: 10),
            endTime: GeoTime(hours: 13, minutes: 10)))
    }
    
    @Test("should return default configuration on calling getConfiguration when passed configuration is nil")
    func testStartLocationCollectionWithNilConfiguration() {
        let geoManager = GeoManager(
            userStorageHandler: Self.dependenciesContainer.userStorageHandler,
            geoLocationManager: Self.geoLocationManager,
            device: UIDevice.current,
            tracker: TrackerMock(),
            analyticsManager: AnalyticsManager(dependenciesContainer: SimpleDependenciesContainer()))
        
        Self.dependenciesContainer.userStorageHandler.removeObject(forKey: UserDefaultsKeys.configurationKey)
        
        geoManager.startLocationCollection(configuration: nil)
        
        #expect(geoManager.getConfiguration() == GeoConfigurationFactory.defaultConfiguration)
    }
    
    @Test("should not keep default configuration when passed configuration is not nil")
    func testStartLocationCollectionNotKeepDefault() {
        let geoManager = GeoManager(
            userStorageHandler: Self.dependenciesContainer.userStorageHandler,
            geoLocationManager: Self.geoLocationManager,
            device: UIDevice.current,
            tracker: TrackerMock(),
            analyticsManager: AnalyticsManager(dependenciesContainer: SimpleDependenciesContainer()))
        
        let configuration = GeoConfiguration(
            distanceInterval: 250,
            timeInterval: 400,
            accuracy: .nearest,
            startTime: GeoTime(hours: 14, minutes: 20),
            endTime: GeoTime(hours: 19, minutes: 30))
        
        geoManager.startLocationCollection(configuration: configuration)
        
        #expect(geoManager.getConfiguration() != GeoConfigurationFactory.defaultConfiguration)
        
        Self.dependenciesContainer.userStorageHandler.removeObject(forKey: UserDefaultsKeys.configurationKey)
    }
    
    @Test("should set the expected configuration when passed configuration is not nil")
    func testStartLocationCollectionSetExpectedConfiguration() {
        let geoManager = GeoManager(
            userStorageHandler: Self.dependenciesContainer.userStorageHandler,
            geoLocationManager: Self.geoLocationManager,
            device: UIDevice.current,
            tracker: TrackerMock(),
            analyticsManager: AnalyticsManager(dependenciesContainer: SimpleDependenciesContainer()))
        
        let configuration = GeoConfiguration(
            distanceInterval: 250,
            timeInterval: 400,
            accuracy: .nearest,
            startTime: GeoTime(hours: 14, minutes: 20),
            endTime: GeoTime(hours: 19, minutes: 30))
        
        geoManager.startLocationCollection(configuration: configuration)
        
        #expect(geoManager.getConfiguration()?.distanceInterval == 250)
        #expect(geoManager.getConfiguration()?.timeInterval == 400)
        #expect(geoManager.getConfiguration()?.accuracy == .nearest)
        #expect(geoManager.getConfiguration()?.startTime == GeoTime(hours: 14, minutes: 20))
        #expect(geoManager.getConfiguration()?.endTime == GeoTime(hours: 19, minutes: 30))
        
        Self.dependenciesContainer.userStorageHandler.removeObject(forKey: UserDefaultsKeys.configurationKey)
    }
    
    @Test("should set distanceInterval to default distanceInterval when passing no parameters to configuration")
    func testStartLocationCollectionDefaultDistanceInterval() {
        let geoManager = GeoManager(
            userStorageHandler: Self.dependenciesContainer.userStorageHandler,
            geoLocationManager: Self.geoLocationManager,
            device: UIDevice.current,
            tracker: TrackerMock(),
            analyticsManager: AnalyticsManager(dependenciesContainer: SimpleDependenciesContainer()))
        
        let configuration = GeoConfiguration()
        geoManager.startLocationCollection(configuration: configuration)
        let geoConfiguration = geoManager.getConfiguration()
        
        #expect(geoConfiguration?.distanceInterval == GeoConfigurationConstants.distanceInterval)
        
        Self.dependenciesContainer.userStorageHandler.removeObject(forKey: UserDefaultsKeys.configurationKey)
    }
    
    @Test("should set timeInterval to default timeInterval when passing no parameters to configuration")
    func testStartLocationCollectionDefaultTimeInterval() {
        let geoManager = GeoManager(
            userStorageHandler: Self.dependenciesContainer.userStorageHandler,
            geoLocationManager: Self.geoLocationManager,
            device: UIDevice.current,
            tracker: TrackerMock(),
            analyticsManager: AnalyticsManager(dependenciesContainer: SimpleDependenciesContainer()))
        
        let configuration = GeoConfiguration()
        geoManager.startLocationCollection(configuration: configuration)
        let geoConfiguration = geoManager.getConfiguration()
        
        #expect(geoConfiguration?.timeInterval == GeoConfigurationConstants.timeInterval)
        
        Self.dependenciesContainer.userStorageHandler.removeObject(forKey: UserDefaultsKeys.configurationKey)
    }
    
    @Test("should set accuracy to best when passing no parameters to configuration")
    func testStartLocationCollectionDefaultAccuracy() {
        let geoManager = GeoManager(
            userStorageHandler: Self.dependenciesContainer.userStorageHandler,
            geoLocationManager: Self.geoLocationManager,
            device: UIDevice.current,
            tracker: TrackerMock(),
            analyticsManager: AnalyticsManager(dependenciesContainer: SimpleDependenciesContainer()))
        
        let configuration = GeoConfiguration()
        geoManager.startLocationCollection(configuration: configuration)
        let geoConfiguration = geoManager.getConfiguration()
        
        #expect(geoConfiguration?.accuracy == .best)
        
        Self.dependenciesContainer.userStorageHandler.removeObject(forKey: UserDefaultsKeys.configurationKey)
    }
    
    @Test("should set startTime to 00:00 when passing no parameters to configuration")
    func testStartLocationCollectionDefaultStartTime() {
        let geoManager = GeoManager(
            userStorageHandler: Self.dependenciesContainer.userStorageHandler,
            geoLocationManager: Self.geoLocationManager,
            device: UIDevice.current,
            tracker: TrackerMock(),
            analyticsManager: AnalyticsManager(dependenciesContainer: SimpleDependenciesContainer()))
        
        let configuration = GeoConfiguration()
        geoManager.startLocationCollection(configuration: configuration)
        let geoConfiguration = geoManager.getConfiguration()
        
        #expect(geoConfiguration?.startTime.hours == GeoConfigurationConstants.startTime.hours)
        #expect(geoConfiguration?.startTime.minutes == GeoConfigurationConstants.startTime.minutes)
        
        Self.dependenciesContainer.userStorageHandler.removeObject(forKey: UserDefaultsKeys.configurationKey)
    }
    
    @Test("should set endTime to 23:59 when passing no parameters to configuration")
    func testStartLocationCollectionDefaultEndTime() {
        let geoManager = GeoManager(
            userStorageHandler: Self.dependenciesContainer.userStorageHandler,
            geoLocationManager: Self.geoLocationManager,
            device: UIDevice.current,
            tracker: TrackerMock(),
            analyticsManager: AnalyticsManager(dependenciesContainer: SimpleDependenciesContainer()))
        
        let configuration = GeoConfiguration()
        geoManager.startLocationCollection(configuration: configuration)
        let geoConfiguration = geoManager.getConfiguration()
        
        #expect(geoConfiguration?.endTime.hours == GeoConfigurationConstants.endTime.hours)
        #expect(geoConfiguration?.endTime.minutes == GeoConfigurationConstants.endTime.minutes)
        
        Self.dependenciesContainer.userStorageHandler.removeObject(forKey: UserDefaultsKeys.configurationKey)
    }
    
    @Test("should set distanceInterval as 400 when passing few parameters to configuration")
    func testStartLocationCollectionPartialDistanceInterval() {
        let geoManager = GeoManager(
            userStorageHandler: Self.dependenciesContainer.userStorageHandler,
            geoLocationManager: Self.geoLocationManager,
            device: UIDevice.current,
            tracker: TrackerMock(),
            analyticsManager: AnalyticsManager(dependenciesContainer: SimpleDependenciesContainer()))
        
        let configuration = GeoConfiguration(distanceInterval: 400)
        geoManager.startLocationCollection(configuration: configuration)
        let geoConfiguration = geoManager.getConfiguration()
        
        #expect(geoConfiguration?.distanceInterval == 400)
        
        Self.dependenciesContainer.userStorageHandler.removeObject(forKey: UserDefaultsKeys.configurationKey)
    }
    
    @Test("should set timeInterval to 300 when passing few parameters to configuration")
    func testStartLocationCollectionPartialTimeInterval() {
        let geoManager = GeoManager(
            userStorageHandler: Self.dependenciesContainer.userStorageHandler,
            geoLocationManager: Self.geoLocationManager,
            device: UIDevice.current,
            tracker: TrackerMock(),
            analyticsManager: AnalyticsManager(dependenciesContainer: SimpleDependenciesContainer()))
        
        let configuration = GeoConfiguration(distanceInterval: 400)
        geoManager.startLocationCollection(configuration: configuration)
        let geoConfiguration = geoManager.getConfiguration()
        
        #expect(geoConfiguration?.timeInterval == GeoConfigurationConstants.timeInterval)
        
        Self.dependenciesContainer.userStorageHandler.removeObject(forKey: UserDefaultsKeys.configurationKey)
    }
    
    @Test("should set accuracy to best when passing few parameters to configuration")
    func testStartLocationCollectionPartialAccuracy() {
        let geoManager = GeoManager(
            userStorageHandler: Self.dependenciesContainer.userStorageHandler,
            geoLocationManager: Self.geoLocationManager,
            device: UIDevice.current,
            tracker: TrackerMock(),
            analyticsManager: AnalyticsManager(dependenciesContainer: SimpleDependenciesContainer()))
        
        let configuration = GeoConfiguration(distanceInterval: 400)
        geoManager.startLocationCollection(configuration: configuration)
        let geoConfiguration = geoManager.getConfiguration()
        
        #expect(geoConfiguration?.accuracy == .best)
        
        Self.dependenciesContainer.userStorageHandler.removeObject(forKey: UserDefaultsKeys.configurationKey)
    }
    
    @Test("should set startTime to 00:00 when passing few parameters to configuration")
    func testStartLocationCollectionPartialStartTime() {
        let geoManager = GeoManager(
            userStorageHandler: Self.dependenciesContainer.userStorageHandler,
            geoLocationManager: Self.geoLocationManager,
            device: UIDevice.current,
            tracker: TrackerMock(),
            analyticsManager: AnalyticsManager(dependenciesContainer: SimpleDependenciesContainer()))
        
        let configuration = GeoConfiguration(distanceInterval: 400)
        geoManager.startLocationCollection(configuration: configuration)
        let geoConfiguration = geoManager.getConfiguration()
        
        #expect(geoConfiguration?.startTime.hours == GeoConfigurationConstants.startTime.hours)
        #expect(geoConfiguration?.startTime.minutes == GeoConfigurationConstants.startTime.minutes)
        
        Self.dependenciesContainer.userStorageHandler.removeObject(forKey: UserDefaultsKeys.configurationKey)
    }
    
    @Test("should set endTime to 23:59 when passing few parameters to configuration")
    func testStartLocationCollectionPartialEndTime() {
        let geoManager = GeoManager(
            userStorageHandler: Self.dependenciesContainer.userStorageHandler,
            geoLocationManager: Self.geoLocationManager,
            device: UIDevice.current,
            tracker: TrackerMock(),
            analyticsManager: AnalyticsManager(dependenciesContainer: SimpleDependenciesContainer()))
        
        let configuration = GeoConfiguration(distanceInterval: 400)
        geoManager.startLocationCollection(configuration: configuration)
        let geoConfiguration = geoManager.getConfiguration()
        
        #expect(geoConfiguration?.endTime.hours == GeoConfigurationConstants.endTime.hours)
        #expect(geoConfiguration?.endTime.minutes == GeoConfigurationConstants.endTime.minutes)
        
        Self.dependenciesContainer.userStorageHandler.removeObject(forKey: UserDefaultsKeys.configurationKey)
    }
    
    // MARK: - Configuration Range Tests
    
    @Test("should set distanceInterval to default interval when all fields are more than specified range")
    func testStartLocationCollectionRangeDistanceInterval() {
        let geoManager = GeoManager(
            userStorageHandler: Self.dependenciesContainer.userStorageHandler,
            geoLocationManager: Self.geoLocationManager,
            device: UIDevice.current,
            tracker: TrackerMock(),
            analyticsManager: AnalyticsManager(dependenciesContainer: SimpleDependenciesContainer()))
        
        let configuration = GeoConfiguration(
            distanceInterval: 10000,
            timeInterval: 40000,
            accuracy: .nearest,
            startTime: GeoTime(hours: 23, minutes: 20),
            endTime: GeoTime(hours: 0, minutes: 3))
        geoManager.startLocationCollection(configuration: configuration)
        let geoConfiguration = geoManager.getConfiguration()
        
        #expect(geoConfiguration?.distanceInterval == GeoConfigurationConstants.distanceInterval)
        
        Self.dependenciesContainer.userStorageHandler.removeObject(forKey: UserDefaultsKeys.configurationKey)
    }
    
    @Test("should set timeInterval to 300 when all fields are more than specified range")
    func testStartLocationCollectionRangeTimeInterval() {
        let geoManager = GeoManager(
            userStorageHandler: Self.dependenciesContainer.userStorageHandler,
            geoLocationManager: Self.geoLocationManager,
            device: UIDevice.current,
            tracker: TrackerMock(),
            analyticsManager: AnalyticsManager(dependenciesContainer: SimpleDependenciesContainer()))
        
        let configuration = GeoConfiguration(
            distanceInterval: 10000,
            timeInterval: 40000,
            accuracy: .nearest,
            startTime: GeoTime(hours: 23, minutes: 20),
            endTime: GeoTime(hours: 0, minutes: 3))
        geoManager.startLocationCollection(configuration: configuration)
        let geoConfiguration = geoManager.getConfiguration()
        
        #expect(geoConfiguration?.timeInterval == GeoConfigurationConstants.timeInterval)
        
        Self.dependenciesContainer.userStorageHandler.removeObject(forKey: UserDefaultsKeys.configurationKey)
    }
    
    @Test("should be same as what configured on Configuration when all fields are more than specified range")
    func testStartLocationCollectionRangeAccuracy() {
        let geoManager = GeoManager(
            userStorageHandler: Self.dependenciesContainer.userStorageHandler,
            geoLocationManager: Self.geoLocationManager,
            device: UIDevice.current,
            tracker: TrackerMock(),
            analyticsManager: AnalyticsManager(dependenciesContainer: SimpleDependenciesContainer()))
        
        let configuration = GeoConfiguration(
            distanceInterval: 10000,
            timeInterval: 40000,
            accuracy: .nearest,
            startTime: GeoTime(hours: 23, minutes: 20),
            endTime: GeoTime(hours: 0, minutes: 3))
        geoManager.startLocationCollection(configuration: configuration)
        let geoConfiguration = geoManager.getConfiguration()
        
        #expect(geoConfiguration?.accuracy == .nearest)
        
        Self.dependenciesContainer.userStorageHandler.removeObject(forKey: UserDefaultsKeys.configurationKey)
    }
    
    @Test("should set startTime to 00:00 when all fields are more than specified range")
    func testStartLocationCollectionRangeStartTime() {
        let geoManager = GeoManager(
            userStorageHandler: Self.dependenciesContainer.userStorageHandler,
            geoLocationManager: Self.geoLocationManager,
            device: UIDevice.current,
            tracker: TrackerMock(),
            analyticsManager: AnalyticsManager(dependenciesContainer: SimpleDependenciesContainer()))
        
        let configuration = GeoConfiguration(
            distanceInterval: 10000,
            timeInterval: 40000,
            accuracy: .nearest,
            startTime: GeoTime(hours: 23, minutes: 20),
            endTime: GeoTime(hours: 0, minutes: 3))
        geoManager.startLocationCollection(configuration: configuration)
        let geoConfiguration = geoManager.getConfiguration()
        
        #expect(geoConfiguration?.startTime.hours == GeoConfigurationConstants.startTime.hours)
        #expect(geoConfiguration?.startTime.minutes == GeoConfigurationConstants.startTime.minutes)
        
        Self.dependenciesContainer.userStorageHandler.removeObject(forKey: UserDefaultsKeys.configurationKey)
    }
    
    @Test("should set endTime to 23:59 when all fields are more than specified range")
    func testStartLocationCollectionRangeEndTime() {
        let geoManager = GeoManager(
            userStorageHandler: Self.dependenciesContainer.userStorageHandler,
            geoLocationManager: Self.geoLocationManager,
            device: UIDevice.current,
            tracker: TrackerMock(),
            analyticsManager: AnalyticsManager(dependenciesContainer: SimpleDependenciesContainer()))
        
        let configuration = GeoConfiguration(
            distanceInterval: 10000,
            timeInterval: 40000,
            accuracy: .nearest,
            startTime: GeoTime(hours: 23, minutes: 20),
            endTime: GeoTime(hours: 0, minutes: 3))
        geoManager.startLocationCollection(configuration: configuration)
        let geoConfiguration = geoManager.getConfiguration()
        
        #expect(geoConfiguration?.endTime.hours == GeoConfigurationConstants.endTime.hours)
        #expect(geoConfiguration?.endTime.minutes == GeoConfigurationConstants.endTime.minutes)
        
        Self.dependenciesContainer.userStorageHandler.removeObject(forKey: UserDefaultsKeys.configurationKey)
    }
    
    @Test("should set start minutes as per defaults 0 when startTime & endTime minutes are more than the specified range")
    func testStartLocationCollectionMinutesRangeStart() {
        let geoManager = GeoManager(
            userStorageHandler: Self.dependenciesContainer.userStorageHandler,
            geoLocationManager: Self.geoLocationManager,
            device: UIDevice.current,
            tracker: TrackerMock(),
            analyticsManager: AnalyticsManager(dependenciesContainer: SimpleDependenciesContainer()))
        
        let configuration = GeoConfiguration(
            distanceInterval: 250,
            timeInterval: 900,
            accuracy: .nearest,
            startTime: GeoTime(hours: 12, minutes: 200),
            endTime: GeoTime(hours: 23, minutes: 300))
        
        geoManager.startLocationCollection(configuration: configuration)
        let geoConfiguration = geoManager.getConfiguration()
        
        #expect(geoConfiguration?.startTime.minutes == GeoConfigurationConstants.startTime.minutes)
        
        Self.dependenciesContainer.userStorageHandler.removeObject(forKey: UserDefaultsKeys.configurationKey)
    }
    
    @Test("should set end minutes as per defaults 59 when startTime & endTime minutes are more than the specified range")
    func testStartLocationCollectionMinutesRangeEnd() {
        let geoManager = GeoManager(
            userStorageHandler: Self.dependenciesContainer.userStorageHandler,
            geoLocationManager: Self.geoLocationManager,
            device: UIDevice.current,
            tracker: TrackerMock(),
            analyticsManager: AnalyticsManager(dependenciesContainer: SimpleDependenciesContainer()))
        
        let configuration = GeoConfiguration(
            distanceInterval: 250,
            timeInterval: 900,
            accuracy: .nearest,
            startTime: GeoTime(hours: 12, minutes: 200),
            endTime: GeoTime(hours: 23, minutes: 300))
        
        geoManager.startLocationCollection(configuration: configuration)
        let geoConfiguration = geoManager.getConfiguration()
        
        #expect(geoConfiguration?.endTime.minutes == GeoConfigurationConstants.endTime.minutes)
        
        Self.dependenciesContainer.userStorageHandler.removeObject(forKey: UserDefaultsKeys.configurationKey)
    }
    
    @Test("should set startTime as per the default startTime(00:00) when startTime is greater than endTime")
    func testStartLocationCollectionStartTimeGreaterThanEndTime() {
        let geoManager = GeoManager(
            userStorageHandler: Self.dependenciesContainer.userStorageHandler,
            geoLocationManager: Self.geoLocationManager,
            device: UIDevice.current,
            tracker: TrackerMock(),
            analyticsManager: AnalyticsManager(dependenciesContainer: SimpleDependenciesContainer()))
        
        let configuration = GeoConfiguration(
            distanceInterval: 200,
            timeInterval: 900,
            accuracy: .nearest,
            startTime: GeoTime(hours: 15, minutes: 40),
            endTime: GeoTime(hours: 10, minutes: 30))
        
        geoManager.startLocationCollection(configuration: configuration)
        let geoConfiguration = geoManager.getConfiguration()
        
        #expect(geoConfiguration?.startTime == GeoConfigurationConstants.startTime)
        
        Self.dependenciesContainer.userStorageHandler.removeObject(forKey: UserDefaultsKeys.configurationKey)
    }
    
    @Test("should set endTime as per the default endTime(23:59) when startTime is greater than endTime")
    func testStartLocationCollectionEndTimeWhenStartGreaterThanEnd() {
        let geoManager = GeoManager(
            userStorageHandler: Self.dependenciesContainer.userStorageHandler,
            geoLocationManager: Self.geoLocationManager,
            device: UIDevice.current,
            tracker: TrackerMock(),
            analyticsManager: AnalyticsManager(dependenciesContainer: SimpleDependenciesContainer()))
        
        let configuration = GeoConfiguration(
            distanceInterval: 200,
            timeInterval: 900,
            accuracy: .nearest,
            startTime: GeoTime(hours: 15, minutes: 40),
            endTime: GeoTime(hours: 10, minutes: 30))
        
        geoManager.startLocationCollection(configuration: configuration)
        let geoConfiguration = geoManager.getConfiguration()
        
        #expect(geoConfiguration?.endTime == GeoConfigurationConstants.endTime)
        
        Self.dependenciesContainer.userStorageHandler.removeObject(forKey: UserDefaultsKeys.configurationKey)
    }
    
    @Test("should set startTime as per the default startTime(00:00) when startTime is greater than endTime with startTime and endTime are out of range")
    func testStartLocationCollectionStartTimeOutOfRange() {
        let geoManager = GeoManager(
            userStorageHandler: Self.dependenciesContainer.userStorageHandler,
            geoLocationManager: Self.geoLocationManager,
            device: UIDevice.current,
            tracker: TrackerMock(),
            analyticsManager: AnalyticsManager(dependenciesContainer: SimpleDependenciesContainer()))
        
        let configuration = GeoConfiguration(
            distanceInterval: 200,
            timeInterval: 900,
            accuracy: .nearest,
            startTime: GeoTime(hours: 50, minutes: 60),
            endTime: GeoTime(hours: 25, minutes: 80))
        geoManager.startLocationCollection(configuration: configuration)
        let geoConfiguration = geoManager.getConfiguration()
        
        #expect(geoConfiguration?.startTime == GeoConfigurationConstants.startTime)
        
        Self.dependenciesContainer.userStorageHandler.removeObject(forKey: UserDefaultsKeys.configurationKey)
    }
    
    @Test("should set endTime as per the default endTime(23:59) when startTime is greater than endTime with startTime and endTime are out of range")
    func testStartLocationCollectionEndTimeOutOfRange() {
        let geoManager = GeoManager(
            userStorageHandler: Self.dependenciesContainer.userStorageHandler,
            geoLocationManager: Self.geoLocationManager,
            device: UIDevice.current,
            tracker: TrackerMock(),
            analyticsManager: AnalyticsManager(dependenciesContainer: SimpleDependenciesContainer()))
        
        let configuration = GeoConfiguration(
            distanceInterval: 200,
            timeInterval: 900,
            accuracy: .nearest,
            startTime: GeoTime(hours: 50, minutes: 60),
            endTime: GeoTime(hours: 25, minutes: 80))
        geoManager.startLocationCollection(configuration: configuration)
        let geoConfiguration = geoManager.getConfiguration()
        
        #expect(geoConfiguration?.endTime == GeoConfigurationConstants.endTime)
        
        Self.dependenciesContainer.userStorageHandler.removeObject(forKey: UserDefaultsKeys.configurationKey)
    }
    // MARK: - stopLocationCollection Tests
    
    @Test("should stop monitoring location collection region")
    func testStopMonitoringRegion() {
        let configurationStore = GeoConfigurationStore(userStorageHandler: Self.dependenciesContainer.userStorageHandler)
        let coreLocationManagerMock = LocationManagerMock()
        let geoLocationManager = GeoLocationManager(
            bundle: BundleMock(),
            coreLocationManager: coreLocationManagerMock,
            configurationStore: configurationStore)
        
        let geoManager = GeoManager(
            userStorageHandler: Self.dependenciesContainer.userStorageHandler,
            geoLocationManager: geoLocationManager,
            device: UIDevice.current,
            tracker: TrackerMock(),
            analyticsManager: AnalyticsManager(dependenciesContainer: SimpleDependenciesContainer()))
        
        geoManager.startLocationCollection()
        coreLocationManagerMock.delegate?.locationManager?(Self.coreLocationManager, didUpdateLocations: [CLLocation()])
        
        geoManager.stopLocationCollection()
        #expect(coreLocationManagerMock.monitoredRegions.count == 0)
    }
    
    @Test("should return nil on calling getConfiguration after stopLocationCollection")
    func testGetConfigurationNilAfterStop() {
        let configurationStore = GeoConfigurationStore(userStorageHandler: Self.dependenciesContainer.userStorageHandler)
        let coreLocationManagerMock = LocationManagerMock()
        let geoLocationManager = GeoLocationManager(
            bundle: BundleMock(),
            coreLocationManager: coreLocationManagerMock,
            configurationStore: configurationStore)
        
        let geoManager = GeoManager(
            userStorageHandler: Self.dependenciesContainer.userStorageHandler,
            geoLocationManager: geoLocationManager,
            device: UIDevice.current,
            tracker: TrackerMock(),
            analyticsManager: AnalyticsManager(dependenciesContainer: SimpleDependenciesContainer()))
        
        geoManager.startLocationCollection()
        coreLocationManagerMock.delegate?.locationManager?(Self.coreLocationManager, didUpdateLocations: [CLLocation()])
        
        geoManager.stopLocationCollection()
        #expect(geoManager.getConfiguration() == nil)
    }
    
    @Test("should call stopLocationUpdates")
    func testStopLocationUpdates() {
        let geoLocationManagerMock = GeoLocationManagerMock()
        let geoManager = GeoManager(
            userStorageHandler: Self.dependenciesContainer.userStorageHandler,
            geoLocationManager: geoLocationManagerMock,
            device: UIDevice.current,
            tracker: TrackerMock(),
            analyticsManager: AnalyticsManager(dependenciesContainer: SimpleDependenciesContainer()))
        
        geoManager.stopLocationCollection()
        #expect(geoLocationManagerMock.stopLocationUpdatesCalled == true)
    }
    
    @Test("should call stopMonitoringSignificantLocationChanges")
    func testStopMonitoringSignificantLocationChanges() {
        let geoLocationManagerMock = GeoLocationManagerMock()
        let geoManager = GeoManager(
            userStorageHandler: Self.dependenciesContainer.userStorageHandler,
            geoLocationManager: geoLocationManagerMock,
            device: UIDevice.current,
            tracker: TrackerMock(),
            analyticsManager: AnalyticsManager(dependenciesContainer: SimpleDependenciesContainer()))
        
        geoManager.stopLocationCollection()
        #expect(geoLocationManagerMock.stopMonitoringSignificantLocationChangesIsCalled == true)
    }
    
    @Test("should return false for locationCollectionKey in userStorageHandler")
    func testLocationCollectionKeyFalseAfterStop() {
        let geoLocationManagerMock = GeoLocationManagerMock()
        let geoManager = GeoManager(
            userStorageHandler: Self.dependenciesContainer.userStorageHandler,
            geoLocationManager: geoLocationManagerMock,
            device: UIDevice.current,
            tracker: TrackerMock(),
            analyticsManager: AnalyticsManager(dependenciesContainer: SimpleDependenciesContainer()))
        
        geoManager.stopLocationCollection()
        #expect(Self.dependenciesContainer.userStorageHandler.bool(forKey: UserDefaultsKeys.locationCollectionKey) == false)
    }
    
    @Test("should return nil for configurationKey in userStorageHandler")
    func testConfigurationKeyNilAfterStop() {
        let geoLocationManagerMock = GeoLocationManagerMock()
        let geoManager = GeoManager(
            userStorageHandler: Self.dependenciesContainer.userStorageHandler,
            geoLocationManager: geoLocationManagerMock,
            device: UIDevice.current,
            tracker: TrackerMock(),
            analyticsManager: AnalyticsManager(dependenciesContainer: SimpleDependenciesContainer()))
        
        geoManager.stopLocationCollection()
        #expect(Self.dependenciesContainer.userStorageHandler.bool(forKey: UserDefaultsKeys.configurationKey) == false)
    }
    
    @Test("should return nil on getConfiguration()")
    func testGetConfigurationNilAfterStopLocationCollection() {
        let geoLocationManagerMock = GeoLocationManagerMock()
        let geoManager = GeoManager(
            userStorageHandler: Self.dependenciesContainer.userStorageHandler,
            geoLocationManager: geoLocationManagerMock,
            device: UIDevice.current,
            tracker: TrackerMock(),
            analyticsManager: AnalyticsManager(dependenciesContainer: SimpleDependenciesContainer()))
        
        geoManager.stopLocationCollection()
        #expect(geoManager.getConfiguration() == nil)
    }
}
