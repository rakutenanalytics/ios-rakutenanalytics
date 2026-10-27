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

@Suite("GeoManager Location Collection")
struct GeoManagerLocationCollectionTests {
    static let coreLocationManager = CLLocationManager()
    static let dependenciesContainer = GeoDependenciesContainer()
    static let configurationStore = GeoConfigurationStore(userStorageHandler: dependenciesContainer.userStorageHandler)

    static let geoLocationManager = GeoLocationManager(
        bundle: BundleMock(),
        coreLocationManager: LocationManagerMock(),
        configurationStore: configurationStore)

    // MARK: - startLocationCollection Async Tests

    @Test("should call startMonitoringSignificantLocationChanges()")
    @MainActor
    func testStartMonitoringSignificantLocationChanges() async throws {
        let geoLocationManagerMock = GeoLocationManagerMock()
        let geoManager = GeoManager(
            userStorageHandler: Self.dependenciesContainer.userStorageHandler,
            geoLocationManager: geoLocationManagerMock,
            device: UIDevice.current,
            analyticsManager: {
                let analyticsManager = AnalyticsManager(dependenciesContainer: SimpleDependenciesContainer())
                analyticsManager.add(TrackerMock())
                return analyticsManager
            }())
        geoLocationManagerMock.startMonitoringSignificantLocationChangesIsCalled = false
        geoLocationManagerMock.requestLocationContinualIsCalled = false

        Self.dependenciesContainer.userStorageHandler.removeObject(forKey: UserDefaultsKeys.configurationKey)
        geoManager.startLocationCollection()

        try await TestingHelpers.eventuallyOnMain(timeout: 1.0) { geoLocationManagerMock.startMonitoringSignificantLocationChangesIsCalled }
        #expect(geoLocationManagerMock.startMonitoringSignificantLocationChangesIsCalled == true)
    }

    @Test("should call requestLocationUpdate(for: .continual) for initial update")
    @MainActor
    func testRequestLocationUpdateContinualInitial() async throws {
        let geoLocationManagerMock = GeoLocationManagerMock()
        let geoManager = GeoManager(
            userStorageHandler: Self.dependenciesContainer.userStorageHandler,
            geoLocationManager: geoLocationManagerMock,
            device: UIDevice.current,
            analyticsManager: {
                let analyticsManager = AnalyticsManager(dependenciesContainer: SimpleDependenciesContainer())
                analyticsManager.add(TrackerMock())
                return analyticsManager
            }())
        geoLocationManagerMock.startMonitoringSignificantLocationChangesIsCalled = false
        geoLocationManagerMock.requestLocationContinualIsCalled = false

        Self.dependenciesContainer.userStorageHandler.removeObject(forKey: UserDefaultsKeys.configurationKey)
        geoManager.startLocationCollection()

        try await TestingHelpers.eventuallyOnMain(timeout: 1.0) { geoLocationManagerMock.requestLocationContinualIsCalled }
        #expect(geoLocationManagerMock.requestLocationContinualIsCalled == true)
    }

    @Test("should call requestLocationUpdate(for: .continual) on configuring poller at specified timeInterval")
    @MainActor
    func testRequestLocationUpdateContinualPoller() async throws {
        let geoLocationManagerMock = GeoLocationManagerMock()
        let geoManager = GeoManager(
            userStorageHandler: Self.dependenciesContainer.userStorageHandler,
            geoLocationManager: geoLocationManagerMock,
            device: UIDevice.current,
            analyticsManager: {
                let analyticsManager = AnalyticsManager(dependenciesContainer: SimpleDependenciesContainer())
                analyticsManager.add(TrackerMock())
                return analyticsManager
            }())
        geoLocationManagerMock.startMonitoringSignificantLocationChangesIsCalled = false
        geoLocationManagerMock.requestLocationContinualIsCalled = false

        Self.dependenciesContainer.userStorageHandler.removeObject(forKey: UserDefaultsKeys.configurationKey)
        geoManager.startLocationCollection()

        try await TestingHelpers.eventuallyOnMain(timeout: 1.0) { geoLocationManagerMock.requestLocationContinualIsCalled }
        #expect(geoLocationManagerMock.requestLocationContinualIsCalled == true)
    }

    // MARK: - configurePoller Tests

    @Test("should start poller and call requestLocationUpdate(for:) with specified timeinterval as delay when lastCollectedLocationTms is nil")
    @MainActor
    func testConfigurePollerWhenLastCollectedLocationTmsNil() async throws {
        let geoLocationManagerMock = GeoLocationManagerMock()
        let geoManager = GeoManager(
            userStorageHandler: Self.dependenciesContainer.userStorageHandler,
            geoLocationManager: geoLocationManagerMock,
            device: UIDevice.current,
            analyticsManager: {
                let analyticsManager = AnalyticsManager(dependenciesContainer: SimpleDependenciesContainer())
                analyticsManager.add(TrackerMock())
                return analyticsManager
            }())
        let configuration = GeoConfiguration(
            distanceInterval: 100,
            timeInterval: 3,
            accuracy: .best,
            startTime: GeoTime(hours: 0, minutes: 0),
            endTime: GeoTime(hours: 23, minutes: 59))

        let configurationData = try? JSONEncoder().encode(configuration)

        Self.dependenciesContainer.userStorageHandler.removeObject(forKey: UserDefaultsKeys.locationTimestampKey)
        Self.dependenciesContainer.userStorageHandler.set(value: configurationData, forKey: UserDefaultsKeys.configurationKey)

        geoLocationManagerMock.requestLocationContinualIsCalled = false
        geoManager.configurePoller()

        try await TestingHelpers.eventuallyOnMain(timeout: 4.0) { geoLocationManagerMock.requestLocationContinualIsCalled }
        #expect(geoLocationManagerMock.requestLocationContinualIsCalled == true)

        Self.dependenciesContainer.userStorageHandler.removeObject(forKey: UserDefaultsKeys.locationTimestampKey)
        Self.dependenciesContainer.userStorageHandler.removeObject(forKey: UserDefaultsKeys.configurationKey)
    }

    @Test("should start poller and call requestLocationUpdate(for:) with no delay when lastCollectedLocationTms is non-nil and lapsed")
    @MainActor
    func testConfigurePollerWhenLastCollectedLocationTmsLapsed() async throws {
        let geoLocationManagerMock = GeoLocationManagerMock()
        let geoManager = GeoManager(
            userStorageHandler: Self.dependenciesContainer.userStorageHandler,
            geoLocationManager: geoLocationManagerMock,
            device: UIDevice.current,
            analyticsManager: {
                let analyticsManager = AnalyticsManager(dependenciesContainer: SimpleDependenciesContainer())
                analyticsManager.add(TrackerMock())
                return analyticsManager
            }())
        let configuration = GeoConfiguration(
            distanceInterval: 100,
            timeInterval: 3,
            accuracy: .best,
            startTime: GeoTime(hours: 0, minutes: 0),
            endTime: GeoTime(hours: 23, minutes: 59))

        let configurationData = try? JSONEncoder().encode(configuration)

        Self.dependenciesContainer.userStorageHandler.set(value: Date().addingTimeInterval(-4), forKey: UserDefaultsKeys.locationTimestampKey)
        Self.dependenciesContainer.userStorageHandler.set(value: configurationData, forKey: UserDefaultsKeys.configurationKey)

        geoLocationManagerMock.requestLocationContinualIsCalled = false
        geoManager.configurePoller()

        try await TestingHelpers.eventuallyOnMain { geoLocationManagerMock.requestLocationContinualIsCalled }
        #expect(geoLocationManagerMock.requestLocationContinualIsCalled == true)

        Self.dependenciesContainer.userStorageHandler.removeObject(forKey: UserDefaultsKeys.locationTimestampKey)
        Self.dependenciesContainer.userStorageHandler.removeObject(forKey: UserDefaultsKeys.configurationKey)
    }

    @Test("should start poller and call requestLocationUpdate(for:) with remaining elapsed delay when lastCollectedLocationTms is non-nil and not lapsed")
    @MainActor
    func testConfigurePollerWhenLastCollectedLocationTmsNotLapsed() async throws {
        let geoLocationManagerMock = GeoLocationManagerMock()
        let geoManager = GeoManager(
            userStorageHandler: Self.dependenciesContainer.userStorageHandler,
            geoLocationManager: geoLocationManagerMock,
            device: UIDevice.current,
            analyticsManager: {
                let analyticsManager = AnalyticsManager(dependenciesContainer: SimpleDependenciesContainer())
                analyticsManager.add(TrackerMock())
                return analyticsManager
            }())
        let configuration = GeoConfiguration(
            distanceInterval: 100,
            timeInterval: 3,
            accuracy: .best,
            startTime: GeoTime(hours: 0, minutes: 0),
            endTime: GeoTime(hours: 23, minutes: 59))

        let configurationData = try? JSONEncoder().encode(configuration)

        Self.dependenciesContainer.userStorageHandler.set(value: Date().addingTimeInterval(-1), forKey: UserDefaultsKeys.locationTimestampKey)
        Self.dependenciesContainer.userStorageHandler.set(value: configurationData, forKey: UserDefaultsKeys.configurationKey)
        geoLocationManagerMock.requestLocationContinualIsCalled = false
        geoManager.configurePoller()

        try await TestingHelpers.eventuallyOnMain(timeout: 4.0) { geoLocationManagerMock.requestLocationContinualIsCalled }
        #expect(geoLocationManagerMock.requestLocationContinualIsCalled == true)

        Self.dependenciesContainer.userStorageHandler.removeObject(forKey: UserDefaultsKeys.locationTimestampKey)
        Self.dependenciesContainer.userStorageHandler.removeObject(forKey: UserDefaultsKeys.configurationKey)
    }

    // MARK: - Last Collected Location Timestamp Tests

    @Test("should set lastCollectedLocationTms on success with didUpdateLocations when lastCollectedLocationTms is nil")
    func testSetLastCollectedLocationTmsOnSuccess() {
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
            analyticsManager: {
                let analyticsManager = AnalyticsManager(dependenciesContainer: SimpleDependenciesContainer())
                analyticsManager.add(TrackerMock())
                return analyticsManager
            }())
        Self.dependenciesContainer.userStorageHandler.removeObject(forKey: UserDefaultsKeys.configurationKey)
        geoManager.startLocationCollection()

        Self.dependenciesContainer.userStorageHandler.removeObject(forKey: UserDefaultsKeys.locationTimestampKey)

        let location = CLLocation(
            coordinate: CLLocationCoordinate2D(latitude: 10.3317,
                                               longitude: -122.0325086),
            altitude: 12.0,
            horizontalAccuracy: 10.0,
            verticalAccuracy: 12.0,
            course: 1.0,
            speed: 10.0,
            timestamp: Date())

        coreLocationManagerMock.delegate?.locationManager?(Self.coreLocationManager, didUpdateLocations: [location])

        #expect(Self.dependenciesContainer.userStorageHandler.object(forKey: UserDefaultsKeys.locationTimestampKey) != nil)
    }

    @Test("should not set lastCollectedLocationTms on failure with didFailWithError when lastCollectedLocationTms is nil")
    func testNotSetLastCollectedLocationTmsOnFailure() {
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
            analyticsManager: {
                let analyticsManager = AnalyticsManager(dependenciesContainer: SimpleDependenciesContainer())
                analyticsManager.add(TrackerMock())
                return analyticsManager
            }())
        Self.dependenciesContainer.userStorageHandler.removeObject(forKey: UserDefaultsKeys.configurationKey)
        geoManager.startLocationCollection()

        Self.dependenciesContainer.userStorageHandler.removeObject(forKey: UserDefaultsKeys.locationTimestampKey)

        let error = NSError(domain: "", code: 0, userInfo: nil)
        coreLocationManagerMock.delegate?.locationManager?(Self.coreLocationManager, didFailWithError: error)

        #expect(Self.dependenciesContainer.userStorageHandler.object(forKey: UserDefaultsKeys.locationTimestampKey) == nil)
    }

    // MARK: - Distance Based Location Collection Tests

    @Test("should start monitoring location collection region when the region is not monitored")
    func testStartMonitoringRegionWhenNotMonitored() {
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
            analyticsManager: {
                let analyticsManager = AnalyticsManager(dependenciesContainer: SimpleDependenciesContainer())
                analyticsManager.add(TrackerMock())
                return analyticsManager
            }())
        Self.dependenciesContainer.userStorageHandler.removeObject(forKey: UserDefaultsKeys.configurationKey)

        geoManager.startLocationCollection()
        coreLocationManagerMock.delegate?.locationManager?(
            Self.coreLocationManager,
            didUpdateLocations: [CLLocation(latitude: 78.9,
                                            longitude: 123.456)])

        let monitoredRegion = coreLocationManagerMock.monitoredRegions.first as? CLCircularRegion
        #expect(coreLocationManagerMock.monitoredRegions.count == 1)
        #expect(monitoredRegion?.radius == 300)
        #expect(monitoredRegion?.center.latitude == 78.9)
        #expect(monitoredRegion?.center.longitude == 123.456)
        #expect(monitoredRegion?.identifier == "GeoLocationCollectionRegionIdentifier")
    }

    @Test("should not monitor additional duplicate location collection region when the region is already monitored")
    func testNotMonitorDuplicateRegion() {
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
            analyticsManager: {
                let analyticsManager = AnalyticsManager(dependenciesContainer: SimpleDependenciesContainer())
                analyticsManager.add(TrackerMock())
                return analyticsManager
            }())
        let existingRegion = CLCircularRegion(
            center: CLLocationCoordinate2D(latitude: 123.456, longitude: 78.9),
            radius: 400,
            identifier: "GeoLocationCollectionRegionIdentifier")

        coreLocationManagerMock.monitoredRegions.insert(existingRegion)
        geoManager.startLocationCollection()
        coreLocationManagerMock.delegate?.locationManager?(Self.coreLocationManager, didUpdateLocations: [CLLocation()])

        let monitoredRegion = coreLocationManagerMock.monitoredRegions.first as? CLCircularRegion
        #expect(coreLocationManagerMock.monitoredRegions.count == 1)
        #expect(monitoredRegion?.radius == 400)
        #expect(monitoredRegion?.center.latitude == 123.456)
        #expect(monitoredRegion?.center.longitude == 78.9)
        #expect(monitoredRegion?.identifier == "GeoLocationCollectionRegionIdentifier")
    }

    @Test("will not monitor location collection region on initial location update when CLLocationManagerDelegate didUpdateLocations returns empty location array")
    func testNotMonitorRegionOnEmptyLocationArray() {
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
            analyticsManager: {
                let analyticsManager = AnalyticsManager(dependenciesContainer: SimpleDependenciesContainer())
                analyticsManager.add(TrackerMock())
                return analyticsManager
            }())
        geoManager.startLocationCollection()
        coreLocationManagerMock.delegate?.locationManager?(Self.coreLocationManager, didUpdateLocations: [])

        #expect(coreLocationManagerMock.monitoredRegions.isEmpty)
    }

    @Test("reconcileLocationCollectionWithPrivacyConsent pauses monitoring when location consent is revoked")
    @MainActor
    func testReconcilePausesMonitoringWhenLocationConsentRevoked() async throws {
        let userStorage = UserDefaultsMock([:])
        let consentMock = DataCollectionConsentStoreMock()
        consentMock.isPrivacyControlEnabled = true
        consentMock.enabledTypes = Set(DataCollectionType.individualTypes)

        let geoLocationManagerMock = GeoLocationManagerMock()
        let geoManager = GeoManager(
            userStorageHandler: userStorage,
            geoLocationManager: geoLocationManagerMock,
            device: UIDevice.current,
            analyticsManager: {
                let analyticsManager = AnalyticsManager(dependenciesContainer: SimpleDependenciesContainer())
                analyticsManager.add(TrackerMock())
                return analyticsManager
            }(),
            consentStore: consentMock
        )

        userStorage.removeObject(forKey: UserDefaultsKeys.configurationKey)
        geoManager.startLocationCollection()
        try await TestingHelpers.eventuallyOnMain(timeout: 1.0) { geoLocationManagerMock.requestLocationContinualIsCalled }

        geoLocationManagerMock.stopMonitoringSignificantLocationChangesIsCalled = false
        consentMock.enabledTypes = [.mobileNetwork, .deviceInformation]
        geoManager.reconcileLocationCollectionWithPrivacyConsent()
        #expect(geoLocationManagerMock.stopMonitoringSignificantLocationChangesIsCalled == true)
    }

    @Test("continual location update does not track event after location consent is revoked")
    @MainActor
    func testContinualLocationDoesNotTrackAfterConsentRevoke() async throws {
        let userStorage = UserDefaultsMock([:])
        let consentMock = DataCollectionConsentStoreMock()
        consentMock.isPrivacyControlEnabled = true
        consentMock.enabledTypes = Set(DataCollectionType.individualTypes)

        let trackerMock = TrackerMock()
        let geoLocationManagerMock = GeoLocationManagerMock()
        let analyticsManager = AnalyticsManager(dependenciesContainer: SimpleDependenciesContainer())
        analyticsManager.add(trackerMock)

        let geoManager = GeoManager(
            userStorageHandler: userStorage,
            geoLocationManager: geoLocationManagerMock,
            device: UIDevice.current,
            analyticsManager: analyticsManager,
            consentStore: consentMock
        )

        userStorage.removeObject(forKey: UserDefaultsKeys.configurationKey)
        geoManager.startLocationCollection()
        try await TestingHelpers.eventuallyOnMain(timeout: 1.0) { geoLocationManagerMock.requestLocationContinualIsCalled }

        let location = CLLocation(latitude: 10.0, longitude: 20.0)
        geoLocationManagerMock.delegate?.geoLocationManager(didUpdateLocation: location, for: .continual)
        try await TestingHelpers.eventuallyOnMain(timeout: 1.0) { trackerMock.event != nil }
        #expect(trackerMock.event?.name == RAnalyticsEvent.Name.geoLocation)

        trackerMock.event = nil
        consentMock.enabledTypes = [.mobileNetwork, .deviceInformation, .userInformation]
        geoManager.reconcileLocationCollectionWithPrivacyConsent()
        #expect(geoLocationManagerMock.stopMonitoringSignificantLocationChangesIsCalled == true)

        geoLocationManagerMock.delegate?.geoLocationManager(didUpdateLocation: location, for: .continual)
        try await Task.sleep(nanoseconds: 100_000_000)
        #expect(trackerMock.event == nil)
    }

    @Test("store consent revoke pauses collection with no location event after revoke")
    @MainActor
    func testStoreConsentRevokePausesCollectionWithNoLocationEvent() async throws {
        let userStorage = UserDefaultsMock([:])
        let bundle = BundleMock()
        bundle.isPrivacyControlEnabled = true
        let consentStore = DataCollectionConsentStore(userStorageHandler: userStorage, bundle: bundle)
        await consentStore.setEnabled(true, for: .all)

        let trackerMock = TrackerMock()
        let geoLocationManagerMock = GeoLocationManagerMock()
        let analyticsManager = AnalyticsManager(dependenciesContainer: SimpleDependenciesContainer())
        analyticsManager.add(trackerMock)

        let geoManager = GeoManager(
            userStorageHandler: userStorage,
            geoLocationManager: geoLocationManagerMock,
            device: UIDevice.current,
            analyticsManager: analyticsManager,
            consentStore: consentStore
        )

        userStorage.removeObject(forKey: UserDefaultsKeys.configurationKey)
        geoManager.startLocationCollection()
        try await TestingHelpers.eventuallyOnMain(timeout: 1.0) { geoLocationManagerMock.requestLocationContinualIsCalled }

        let location = CLLocation(latitude: 10.0, longitude: 20.0)
        geoLocationManagerMock.delegate?.geoLocationManager(didUpdateLocation: location, for: .continual)
        try await TestingHelpers.eventuallyOnMain(timeout: 1.0) { trackerMock.event != nil }
        #expect(trackerMock.event?.name == RAnalyticsEvent.Name.geoLocation)

        trackerMock.event = nil
        await consentStore.setEnabled(false, for: .location)
        #expect(geoLocationManagerMock.stopMonitoringSignificantLocationChangesIsCalled == true)

        geoLocationManagerMock.delegate?.geoLocationManager(didUpdateLocation: location, for: .continual)
        try await Task.sleep(nanoseconds: 100_000_000)
        #expect(trackerMock.event == nil)
    }
}
// swiftlint:enable type_body_length
// swiftlint:enable function_body_length
