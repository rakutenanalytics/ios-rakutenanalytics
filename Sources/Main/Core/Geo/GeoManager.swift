import Foundation
import CoreLocation.CLLocationManager

enum GeoRequestLocationType {
    case continual, userAction
}

/// The geo location result type.
public typealias GeoRequestLocationResult = Result<LocationModel, Error>

/// Completion block for request location.
///
/// This block is triggered on requesting a one-time delivery of the user’s current location.
///  - Returns: An object with value of type `LocationModel` on success or an error of type `Error` on failure.
public typealias GeoRequestLocationBlock = (GeoRequestLocationResult) -> Void

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
    ///     - completionHandler: Executes a block called `GeoRequestLocationBlock`.
    ///
    /// - Warning: This function should be called on the main thread, otherwise requesting the location collection is not guaranteed.
    func requestLocation(actionParameters: GeoActionParameters?,
                         completionHandler: @escaping GeoRequestLocationBlock)

    /// Get configuration used for location collection.
    ///
    /// - Returns: GeoConfiguration set calling `startLocationCollection(configuration:)`.
    /// - NOTE: This method returns nil if no configuration was set.
    func getConfiguration() -> GeoConfiguration?
}

// MARK: - GeoManager
/// The object that you use to start, stop and request the delivery of location-related events to your app.
public final class GeoManager {

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

    /// Callback to provide user action based location or error
    private var userActionLocationCallback: ((GeoRequestLocationResult) -> Void)?

    /// user action info
    private var userActionParameters: GeoActionParameters?

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
                          tracker: geoTracker,
                          analyticsManager: AnalyticsManager.shared())
    }()

    /// Creates a new instance of GeoManager.
    ///
    /// - Parameter userStorageHandler: Parameter of type `UserStorageHandleable` provides an interface to the user’s defaults database, where you store key-value pairs persistently across launches of your app.
    /// - Parameter geoLocationManager: The geolocation manager.
    /// - Parameter device: The device capability.
    /// - Parameter tracker: The geo tracker.
    /// - Parameter analyticsManager: The analytics manager processing events.
    init(userStorageHandler: UserStorageHandleable,
         geoLocationManager: GeoLocationManageable,
         device: DeviceCapability,
         tracker: Tracker?,
         analyticsManager: AnalyticsManager) {
        self.poller = GeoPoller()

        self.userStorageHandler = userStorageHandler

        self.configurationStore = GeoConfigurationStore(userStorageHandler: userStorageHandler)

        self.geoLocationManager = geoLocationManager

        self.deviceIdentifierHandler = DeviceIdentifierHandler(device: device, hasher: SecureHasher())

        self.analyticsManager = analyticsManager

        if let tracker = tracker {
            self.analyticsManager.add(tracker)
        }

        self.geoLocationManager.delegate = self
    }
}

// MARK: - GeoManager conformance to GeoTrackable

extension GeoManager: GeoTrackable {

    public func startLocationCollection(configuration: GeoConfiguration? = nil) {
        if let safeConfiguration = configuration,
           safeConfiguration != getConfiguration() {
            handleConfigurationAndLocationCollection(configuration: safeConfiguration)
        } else if configuration == nil,
                  getConfiguration() != GeoConfiguration() {
            handleConfigurationAndLocationCollection(configuration: GeoConfiguration())
        }
    }

    public func stopLocationCollection() {
        userStorageHandler.set(value: false, forKey: UserDefaultsKeys.locationCollectionKey)
        manageStopLocationCollection()
    }

    public func requestLocation(actionParameters: GeoActionParameters? = nil,
                                completionHandler: @escaping GeoRequestLocationBlock) {
        self.userActionParameters = actionParameters
        self.userActionLocationCallback = completionHandler
        requestLocationUpdate(for: .userAction)
    }

    public func getConfiguration() -> GeoConfiguration? {
        return configurationStore.retrieveGeoConfigurationFromStorage()
    }
}

// MARK: - Start Location Collection Helper

extension GeoManager {

    private func handleConfigurationAndLocationCollection(configuration: GeoConfiguration) {
        configurationStore.store(configuration: configuration)
        userStorageHandler.set(value: true, forKey: UserDefaultsKeys.locationCollectionKey)
        manageStartLocationCollection()
    }

    private func manageStartLocationCollection() {
        geoLocationManager.startMonitoringSignificantLocationChanges()
        requestLocationUpdate(for: .continual)
        configurePoller()
    }

    func configurePoller() {
        guard let lastCollectedLocationTms = userStorageHandler.object(forKey: UserDefaultsKeys.locationTimestampKey) as? Date else {
            startPoller(interval: configurationStore.configuration.timeInterval, delay: 0, repeats: true)
            return
        }
        let elapsedTimeInterval = Date.timeIntervalBetween(current: Date(), previous: lastCollectedLocationTms)
        let timeInterval = configurationStore.configuration.timeInterval
        let delay = elapsedTimeInterval < timeInterval ? (timeInterval - elapsedTimeInterval) : 0
        startPoller(interval: configurationStore.configuration.timeInterval, delay: delay, repeats: false)
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
        DispatchQueue.global(qos: .utility).async { [weak self] in
            guard let strongSelf = self,
                  strongSelf.userStorageHandler.bool(forKey: UserDefaultsKeys.locationCollectionKey) else { return }
            strongSelf.requestLocationUpdate(for: .continual)
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
        switch requestType {
        case .continual:
            let locationModel = LocationModel(location: location)
            trackLocEvent(locationModel)
            userStorageHandler.set(value: locationModel.timestamp, forKey: UserDefaultsKeys.locationTimestampKey)
        case .userAction:
            let locationModel = LocationModel(location: location, isAction: true, actionParameters: userActionParameters)
            trackLocEvent(locationModel)
            if let safeCallback = userActionLocationCallback {
                safeCallback(.success(locationModel))
            }
        }
    }

    func geoLocationManager(didFailWithError error: Error, for requestType: GeoRequestLocationType) {
        switch requestType {
        case .continual:
            RLogger.debug(message: error.localizedDescription)
        case .userAction:
            if let userActionLocationCallback = userActionLocationCallback {
                userActionLocationCallback(.failure(error))
            }
        }
    }
}
