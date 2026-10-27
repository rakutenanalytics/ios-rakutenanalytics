import Foundation
import CoreLocation.CLLocationManager

enum GeoRequestLocationType {
    case continual, userAction
}

// MARK: - GeoTrackable
/// `GeoTrackable` defines a blueprint for tracking geo location informations.
protocol GeoTrackable {
    /// This method starts the location collection.
    ///
    /// Call this method to start the location collection.
    ///
    /// - Parameter configuration: GeoConfiguration used for location collection.
    ///
    /// - NOTE: On calling this method if a value is not passed in configuration, the default configuration value will be used.
    ///
    /// - NOTE: The timer interval based collection only works when the app is in foreground. The distance based collection will work in all states of the app provided user has granted always access to location services.
    ///
    /// - Warning: This function should be called on the main thread, otherwise starting the location collection is not guaranteed.
    ///
    /// - Note: Location collection is not supported on tvOS. Calling this method on tvOS has no effect.
    func startLocationCollection(configuration: GeoConfiguration?)

    /// This method stops the location collection.
    ///
    /// Call this method to any ongoing location collection.
    ///
    /// - Warning: This function should be called on the main thread, otherwise stopping the location collection is not guaranteed.
    func stopLocationCollection()

    /// Requests a one-time delivery of the user’s current location.
    ///
    /// Call this method to get a single location update of the user's current location.
    /// - parameters:
    ///     - actionParameters: Represents optional value of type `GeoActionParameters`.
    ///
    /// - Warning: This function should be called on the main thread, otherwise requesting the location collection is not guaranteed.
    ///
    /// - Note: On tvOS, this method throws immediately because location services are unavailable.
    @MainActor
    func requestLocation(actionParameters: GeoActionParameters?) async throws -> LocationModel

    /// Get configuration used for location collection.
    ///
    /// - Returns: GeoConfiguration set calling `startLocationCollection(configuration:)`.
    /// - NOTE: This method returns nil if no configuration was set.
    func getConfiguration() -> GeoConfiguration?
}

// MARK: - GeoManager
/// The object that you use to start, stop and request the delivery of location-related events to your app.
public final class GeoManager {

    private enum LocationPlatform {
        #if os(tvOS)
        static let unsupportedError: Error = NSError(
            domain: kCLErrorDomain,
            code: CLError.denied.rawValue,
            userInfo: [NSLocalizedDescriptionKey: "Location services are not available on tvOS."]
        )
        #endif
    }

    /// Instance of type `GeoLocationManageable`.
    private let geoLocationManager: GeoLocationManageable

    /// Instance of type `DeviceIdentifierHandler`.
    private let deviceIdentifierHandler: DeviceIdentifierHandler

    /// The Analytics Manager processing events.
    private let analyticsManager: AnalyticsManager

    /// Instance of type `Poller`.
    private let poller: GeoPoller

    /// Instance of type `UserStorageHandleable`.
    private let userStorageHandler: UserStorageHandleable

    /// Instance of type `GeoConfigurationStorable`.
    private let configurationStore: GeoConfigurationStorable

    /// Geo event tracker used to enqueue and send location payloads.
    private let geoTracker: GeoTracker?

    /// Consent store for location data collection.
    private let consentStore: DataCollectionConsentReadable

    /// When true, Geo Tracker workers are stopped because location consent is off, but configuration remains for resume.
    private var isGeoPausedForPrivacyConsent = false

    @MainActor private let userActionRequestCoordinator = GeoUserActionRequestCoordinator()

    /// - Returns: The shared instance of `GeoManager` object.
    public static let shared: GeoManager = {
        let dependenciesContainer = GeoDependenciesContainer()
        let coreLocationManager = dependenciesContainer.locationManager
        let userStorageHandler = dependenciesContainer.userStorageHandler
        let bundle = dependenciesContainer.bundle

        var geoTracker: GeoTracker?
        if let databaseConfiguration = DatabaseConfigurationHandler.create(databaseName: GeoTrackerConstants.databaseName,
                                                                           tableName: GeoTrackerConstants.tableName,
                                                                           databaseParentDirectory: bundle.databaseParentDirectory) {
            geoTracker = GeoTracker(dependenciesContainer: dependenciesContainer,
                                    databaseConfiguration: databaseConfiguration)
        }

        return GeoManager(userStorageHandler: userStorageHandler,
                          geoLocationManager: GeoLocationManager(bundle: bundle,
                                                                 coreLocationManager: coreLocationManager,
                                                                 configurationStore: GeoConfigurationStore(userStorageHandler: userStorageHandler)),
                          device: dependenciesContainer.deviceCapability,
                          geoTracker: geoTracker,
                          analyticsManager: AnalyticsManager.shared(),
                          consentStore: DataCollectionConsentStore.shared)
    }()

    /// Creates a new instance of GeoManager.
    ///
    /// - Parameter userStorageHandler: Parameter of type `UserStorageHandleable` provides an interface to the user’s defaults database, where you store key-value pairs persistently across launches of your app.
    /// - Parameter geoLocationManager: The geolocation manager.
    /// - Parameter device: The device capability.
    /// - Parameter geoTracker: The geo tracker.
    /// - Parameter analyticsManager: The analytics manager processing events.
    /// - Parameter consentStore: Consent store for location data collection.
    init(userStorageHandler: UserStorageHandleable,
         geoLocationManager: GeoLocationManageable,
         device: DeviceCapability,
         geoTracker: GeoTracker? = nil,
         analyticsManager: AnalyticsManager,
         consentStore: DataCollectionConsentReadable = DataCollectionConsentStore.shared) {
        self.poller = GeoPoller()

        self.userStorageHandler = userStorageHandler
        self.geoTracker = geoTracker

        self.configurationStore = GeoConfigurationStore(userStorageHandler: userStorageHandler)

        self.geoLocationManager = geoLocationManager

        self.consentStore = consentStore

        self.deviceIdentifierHandler = DeviceIdentifierHandler(device: device, hasher: SecureHasher())

        self.analyticsManager = analyticsManager

        if let geoTracker = geoTracker {
            self.analyticsManager.add(geoTracker)
        }

        self.geoLocationManager.delegate = self

        Task { @MainActor in
            PrivacyConsentReactor.shared.register(geo: self)
        }
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}

// MARK: - GeoManager conformance to GeoTrackable

extension GeoManager: GeoTrackable {

    public func startLocationCollection(configuration: GeoConfiguration? = nil) {
        #if os(tvOS)
        RLogger.debug(message: "startLocationCollection(configuration:) is not supported on tvOS.")
        #else
        if let safeConfiguration = configuration,
           safeConfiguration != getConfiguration() {
            handleConfigurationAndLocationCollection(configuration: safeConfiguration)
        } else if configuration == nil,
                  getConfiguration() != GeoConfiguration() {
            handleConfigurationAndLocationCollection(configuration: GeoConfiguration())
        }
        #endif
    }

    public func stopLocationCollection() {
        MainThreadExecutor.run {
            self.isGeoPausedForPrivacyConsent = false
            self.userStorageHandler.set(value: false, forKey: UserDefaultsKeys.locationCollectionKey)
            self.manageStopLocationCollection()
        }
    }

    @MainActor
    public func requestLocation(actionParameters: GeoActionParameters? = nil) async throws -> LocationModel {
        #if os(tvOS)
        throw LocationPlatform.unsupportedError
        #else
        try await userActionRequestCoordinator.begin(actionParameters: actionParameters) { [weak self] in
            self?.requestLocationUpdate(for: .userAction)
        }
        #endif
    }

    public func getConfiguration() -> GeoConfiguration? {
        configurationStore.retrieveGeoConfigurationFromStorage()
    }
}

// MARK: - Start Location Collection Helper

extension GeoManager {

    private func handleConfigurationAndLocationCollection(configuration: GeoConfiguration) {
        configurationStore.store(configuration: configuration)
        userStorageHandler.set(value: true, forKey: UserDefaultsKeys.locationCollectionKey)

        MainThreadExecutor.run {
            guard self.consentStore.isEnabled(.location) else {
                self.isGeoPausedForPrivacyConsent = true
                return
            }
            self.isGeoPausedForPrivacyConsent = false
            self.manageStartLocationCollection()
        }
    }

    private func manageStartLocationCollection() {
        geoLocationManager.startMonitoringSignificantLocationChanges()
        requestLocationUpdate(for: .continual)
        configurePoller()
    }

    func configurePoller() {
        #if os(tvOS)
        RLogger.debug(message: "Location collection is not supported on tvOS.")
        #else
        guard let lastCollectedLocationTms = userStorageHandler.object(forKey: UserDefaultsKeys.locationTimestampKey) as? Date else {
            startPoller(interval: configurationStore.configuration.timeInterval, delay: 0, repeats: true)
            return
        }
        let elapsedTimeInterval = Date.timeIntervalBetween(current: Date(), previous: lastCollectedLocationTms)
        let timeInterval = configurationStore.configuration.timeInterval
        let delay = elapsedTimeInterval < timeInterval ? (timeInterval - elapsedTimeInterval) : 0
        startPoller(interval: configurationStore.configuration.timeInterval, delay: delay, repeats: false)
        #endif
    }

    private func startPoller(interval: UInt, delay: UInt, repeats: Bool) {
        poller.pollLocationCollection(delay: repeats ? TimeInterval(interval) : TimeInterval(delay), repeats: repeats) { [weak self] in
            guard let self = self else { return }
            if !repeats {
                self.poller.invalidateLocationCollectionPoller {
                    self.startPoller(interval: interval, delay: delay, repeats: true)
                }
            }
            self.performLocationCollectionTasks()
        }
    }

    private func performLocationCollectionTasks() {
        MainThreadExecutor.run { [weak self] in
            guard let self = self,
                  self.userStorageHandler.bool(forKey: UserDefaultsKeys.locationCollectionKey),
                  self.consentStore.isEnabled(.location),
                  !self.isGeoPausedForPrivacyConsent else { return }
            self.requestLocationUpdate(for: .continual)
        }
    }

    func requestLocationUpdate(for requestType: GeoRequestLocationType) {
        geoLocationManager.requestLocationUpdate(for: requestType)
    }
}

// MARK: - Stop Location Collection Helper

extension GeoManager {

    private func manageStopLocationCollection() {
        geoLocationManager.stopMonitoringSignificantLocationChanges()
        geoLocationManager.stopLocationUpdates()
        poller.invalidateLocationCollectionPoller()
        configurationStore.purgeConfiguration()
        userStorageHandler.removeObject(forKey: UserDefaultsKeys.locationTimestampKey)
    }

    private func pauseLocationOperationsPreservingState() {
        geoLocationManager.stopMonitoringSignificantLocationChanges()
        geoLocationManager.stopLocationUpdates()
        poller.invalidateLocationCollectionPoller()
        userStorageHandler.removeObject(forKey: UserDefaultsKeys.locationTimestampKey)
    }

    func reconcileLocationCollectionWithPrivacyConsent() {
        guard consentStore.isPrivacyControlEnabled else {
            guard isGeoPausedForPrivacyConsent else { return }
            isGeoPausedForPrivacyConsent = false
            resumeGeoCollectionIfNeeded()
            return
        }

        let wantsCollection = userStorageHandler.bool(forKey: UserDefaultsKeys.locationCollectionKey)
        let allowed = consentStore.isEnabled(.location)

        if wantsCollection, !allowed, !isGeoPausedForPrivacyConsent {
            pauseLocationOperationsPreservingState()
            isGeoPausedForPrivacyConsent = true
        } else if wantsCollection, allowed, isGeoPausedForPrivacyConsent {
            isGeoPausedForPrivacyConsent = false
            manageStartLocationCollection()
        }
    }

    private func resumeGeoCollectionIfNeeded() {
        let wants = userStorageHandler.bool(forKey: UserDefaultsKeys.locationCollectionKey)
        guard wants, getConfiguration() != nil else { return }
        manageStartLocationCollection()
    }
}

// MARK: - Private extension

private extension GeoManager {
    /// Tracks the loc event.
    ///
    /// - Parameter location: The location model.
    func trackLocEvent(_ location: LocationModel) {
        let event = RAnalyticsEvent(name: RAnalyticsEvent.Name.geoLocation,
                                    parameters: nil)
        analyticsManager.process(event, coreOrigin: .geo(location))
    }
}

// MARK: - GeoLocationManagerDelegate

extension GeoManager: GeoLocationManagerDelegate {

    func geoLocationManager(didUpdateLocation location: CLLocation, for requestType: GeoRequestLocationType) {
        guard consentStore.isEnabled(.location) else {
            guard case .userAction = requestType else { return }
            let privacyError = NSError(domain: ErrorDomain.geoManagerErrorDomain,
                                       code: ErrorCode.locationDataCollectionDisabledByPrivacy.rawValue,
                                       userInfo: [NSLocalizedDescriptionKey: ErrorDescription.locationDataCollectionDisabledByPrivacy])
            Task { @MainActor [weak self] in
                self?.userActionRequestCoordinator.fail(with: privacyError)
            }
            return
        }
        switch requestType {
        case .continual:
            let locationModel = LocationModel(location: location)
            trackLocEvent(locationModel)
            userStorageHandler.set(value: locationModel.timestamp, forKey: UserDefaultsKeys.locationTimestampKey)
        case .userAction:
            Task { @MainActor [weak self] in
                guard let self = self else { return }
                let locationModel = LocationModel(
                    location: location,
                    isAction: true,
                    actionParameters: self.userActionRequestCoordinator.actionParameters
                )
                self.trackLocEvent(locationModel)
                self.userActionRequestCoordinator.complete(with: locationModel)
            }
        }
    }

    func geoLocationManager(didFailWithError error: Error, for requestType: GeoRequestLocationType) {
        switch requestType {
        case .continual:
            RLogger.debug(message: error.localizedDescription)
        case .userAction:
            Task { @MainActor [weak self] in
                self?.userActionRequestCoordinator.fail(with: error)
            }
        }
    }
}

// MARK: - Privacy consent reconciliation

extension GeoManager: GeoPrivacyConsentReconciling {}

// MARK: - DataErasable

extension GeoManager: DataErasable {
    func clearData() async throws {
        await MainActor.run {
            self.isGeoPausedForPrivacyConsent = false
            self.userStorageHandler.set(value: false, forKey: UserDefaultsKeys.locationCollectionKey)
            self.manageStopLocationCollection()
            self.userActionRequestCoordinator.cancel()
        }

        if let geoTracker = geoTracker {
            try await geoTracker.clearData()
        }
    }
}
