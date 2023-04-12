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
    /// GeoConfiguration for location collection.
    internal var configuration: GeoConfiguration {
        getConfiguration() ?? GeoConfigurationFactory.defaultConfiguration
    }

    private let geoSharedPreferenceHelper: GeoConfigurationHelper

    /// The GeoLocation manager.
    private let geoLocationManager: GeoLocationManageable

    /// The device identifier handler.
    private let deviceIdentifierHandler: DeviceIdentifierHandler

    /// The Geo Tracker.
    ///
    /// - Note: The Geo Tracker instantiation returns nil when the endpoint URL is not configured (`RATEndpoint`).
    private let geoTracker: Tracker?

    /// - Returns: The shared instance of `GeoManager` object.
    public static let shared: GeoManager = {
        let dependenciesContainer = SimpleDependenciesContainer()
        let defaultGeoConfiguration = GeoConfiguration()
        let coreLocationManager = dependenciesContainer.locationManager
        var geoTracker: GeoTracker?
        if let databaseConfiguration = DatabaseConfigurationHandler.create(databaseName: GeoTrackerConstants.databaseName,
                                                                           tableName: GeoTrackerConstants.tableName,
                                                                           databaseParentDirectory: Bundle.main.databaseParentDirectory) {
            geoTracker = GeoTracker(dependenciesContainer: dependenciesContainer,
                                    databaseConfiguration: databaseConfiguration)
        }
        return GeoManager(userStorageHandler: dependenciesContainer.userStorageHandler,
                          geoLocationManager: GeoLocationManager(configuration: defaultGeoConfiguration,
                                                                 coreLocationManager: coreLocationManager),
                          device: dependenciesContainer.deviceCapability,
                          tracker: geoTracker)
    }()

    /// Creates a new instance of GeoManager.
    ///
    /// - Parameter userStorageHandler: Parameter of type `UserStorageHandleable` provides an interface to the user’s defaults database, where you store key-value pairs persistently across launches of your app.
    /// - Parameter geoLocationManager: The geolocation manager.
    /// - Parameter device: The device capability.
    init(userStorageHandler: UserStorageHandleable,
         geoLocationManager: GeoLocationManageable,
         device: DeviceCapability,
         tracker: Tracker?) {
        self.geoSharedPreferenceHelper = GeoConfigurationHelper(userStorageHandler: userStorageHandler)
        self.geoLocationManager = geoLocationManager
        self.deviceIdentifierHandler = DeviceIdentifierHandler(device: device, hasher: SecureHasher())
        self.geoTracker = tracker
    }
}

// MARK: - GeoManager conformance to GeoTrackable
extension GeoManager: GeoTrackable {

    public func startLocationCollection(configuration: GeoConfiguration? = nil) {
        if let safeConfiguration = configuration,
               safeConfiguration != getConfiguration() {
            geoSharedPreferenceHelper.store(configuration: safeConfiguration)
        }
    }

    public func stopLocationCollection() {
    }

    /// Requests a location.
    ///
    /// - Parameter actionParameters: The action parameters.
    /// - Parameter completionHandler: The completion handler containing a location or an error.
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
        return geoSharedPreferenceHelper.retrieveGeoConfigurationFromStorage()
    }
}

// MARK: - Private API

private extension GeoManager {
    /// Tracks the loc event.
    ///
    /// - Parameter location: The location model.
    func trackLocEvent(_ location: LocationModel) {
        let event = RAnalyticsEvent(name: RAnalyticsEvent.Name.geoLocation,
                                    parameters: nil)
        let state = RAnalyticsState(sessionIdentifier: Session.cks(),
                                    deviceIdentifier: deviceIdentifierHandler.ckp())
        state.lastKnownLocation = location

        _ = geoTracker?.process(event: event, state: state)
    }
}
