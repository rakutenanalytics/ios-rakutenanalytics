import Foundation
import CoreLocation.CLLocationManager

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
    /// - NOTE: On calling this method if a value is not passed in configuration, the default configuration value will be used.
    func startLocationCollection(configuration: GeoConfiguration?)
    /// This method stops the location collection.
    ///
    /// Call this method to any ongoing location collection.
    func stopLocationCollection()
    /// Requests a one-time delivery of the user’s current location.
    ///
    /// Call this method to get a single location update of the user's current location.
    /// - parameters:
    ///     - actionParameters: Represents optional value of type `GeoActionParameters`.
    ///     - completionHandler: Executes a block called `GeoRequestLocationBlock`.
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

    /// - Returns: The shared instance of `GeoManager` object.
    public static let shared: GeoManager = {
        let dependenciesContainer = SimpleDependenciesContainer()
        let coreLocationManager = dependenciesContainer.locationManager
        let userStorageHandler = dependenciesContainer.userStorageHandler

        var geoTracker: GeoTracker?
        if let databaseConfiguration = DatabaseConfigurationHandler.create(databaseName: GeoTrackerConstants.databaseName,
                                                                           tableName: GeoTrackerConstants.tableName,
                                                                           databaseParentDirectory: Bundle.main.databaseParentDirectory) {
            geoTracker = GeoTracker(dependenciesContainer: dependenciesContainer,
                                    databaseConfiguration: databaseConfiguration)
        }
        
        return GeoManager(userStorageHandler: userStorageHandler,
                          geoLocationManager: GeoLocationManager(coreLocationManager: coreLocationManager,
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
    }
}

// MARK: - GeoManager conformance to GeoTrackable

extension GeoManager: GeoTrackable {

    public func startLocationCollection(configuration: GeoConfiguration? = nil) {
        if let safeConfiguration = configuration,
               safeConfiguration != getConfiguration() {
            configurationStore.store(configuration: safeConfiguration)
        }
        userStorageHandler.set(value: true, forKey: UserDefaultsKeys.locationCollectionKey)
        manageStartLocationCollection()
    }

    public func stopLocationCollection() {
        manageStopLocationCollection()
    }

    public func requestLocation(actionParameters: GeoActionParameters? = nil,
                                completionHandler: @escaping GeoRequestLocationBlock) {
        geoLocationManager.requestLocation(actionParameters: actionParameters) { result in
            switch result {
            case .success(let location):
                self.trackLocEvent(location)
                completionHandler(.success(location))

            case .failure(let error):
                completionHandler(.failure(error))
            }
        }
    }

    public func getConfiguration() -> GeoConfiguration? {
        return configurationStore.retrieveGeoConfigurationFromStorage()
    }
}

// MARK: - Start Location Collection Helper

extension GeoManager {

    private func manageStartLocationCollection() {
        requestLocationUpdate()
        configurePoller()
    }

    private func requestLocationUpdate() {
        geoLocationManager.attemptToRequestLocation { result in
            switch result {
            case .success(let location):
                self.userStorageHandler.set(value: location.timestamp, forKey: UserDefaultsKeys.locationTimestampKey)
                self.trackLocEvent(location)
            case .failure(let error):
                RLogger.debug(message: error.localizedDescription)
            }
        }
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
            self.performLocationCollectionTasks()
            if !repeats {
                self.poller.invalidateLocationCollectionPoller()
                self.startPoller(interval: interval, delay: delay, repeats: true)
            }
        }
    }

    private func performLocationCollectionTasks() {
        DispatchQueue.global(qos: .utility).async { [weak self] in
            guard let strongSelf = self,
                  strongSelf.userStorageHandler.bool(forKey: UserDefaultsKeys.locationCollectionKey) else { return }
            strongSelf.requestLocationUpdate()
        }
    }
}

// MARK: - Stop Location Collection Helper

extension GeoManager {

    private func manageStopLocationCollection() {
        userStorageHandler.set(value: false, forKey: UserDefaultsKeys.locationCollectionKey)
        geoLocationManager.stopLocationUpdates()
        poller.invalidateLocationCollectionPoller()
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
