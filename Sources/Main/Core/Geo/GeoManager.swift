import Foundation
import CoreLocation
import UIKit.UIDevice

/// Completion block for request location.
///
/// This block is triggered on requesting a one-time delivery of the user’s current location.
///  - Returns: An object with value of type `CLLocation` on success or an error of type `CLError` on failure.
public typealias GeoRequestLocationBlock = (Result<CLLocation, CLError>) -> Void

// MARK: - GeoTrackable
/// `GeoTrackable` defines a blueprint for tracking geo location informations.
protocol GeoTrackable {
    /// This method starts the location collection.
    ///
    /// Call this method to start the location collection.
    /// 
    /// - Parameter configuration: The location collection configuration. If nil, the default configuration is used.
    func startLocationCollection(configuration: Configuration?)
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
    /// Get the location collection configuration.
    ///
    /// - Returns: the location collection configuration.
    func getConfiguration() -> Configuration
}

// MARK: - GeoManager
/// The object that you use to start, stop and request the delivery of location-related events to your app.
public final class GeoManager {
    /// The Geo Tracker.
    ///
    /// - Note: The Geo Tracker instantiation returns nil when the endpoint URL is not configured (`RATEndpoint`).
    private let geoTracker: Tracker?

    /// The device identifier handler.
    private let deviceIdentifierHandler: DeviceIdentifierHandler

    /// The current location of the user.
    private var location: CLLocation?

    /// The location collection configuration.
    private var configuration: Configuration?

    /// - Returns: The shared instance of `GeoManager` object.
    public static let shared: GeoManager = {
        let device = UIDevice.current

        guard let databaseConfiguration = DatabaseConfigurationHandler.create(databaseName: GeoTrackerConstants.databaseName,
                                                                              tableName: GeoTrackerConstants.tableName,
                                                                              databaseParentDirectory: Bundle.main.databaseParentDirectory) else {
            RLogger.error(message: "The GeoTracker could not be created because the SQLite connection failed.")
            return GeoManager(geoTracker: nil, device: device)
        }

        let geoTracker = GeoTracker(dependenciesContainer: SimpleDependenciesContainer(),
                                    databaseConfiguration: databaseConfiguration)
        return GeoManager(geoTracker: geoTracker, device: device)
    }()

    /// Creates a new instance of GeoManager.
    ///
    /// - Parameter geoTracker: The GeoTracker instance or nil when the SQLite connection fails to create the GeoTracker Database.
    /// If the GeoTracker could not be created, the other features of GeoManager are still running.
    ///
    /// - Parameter device: The device capability used to calculate the `ckp`.
    init(geoTracker: Tracker?,
         device: DeviceCapability) {
        self.geoTracker = geoTracker

        self.deviceIdentifierHandler = DeviceIdentifierHandler(device: device,
                                                               hasher: SecureHasher())
    }
}

// MARK: - GeoManager conformance to GeoTrackable
extension GeoManager: GeoTrackable {

    public func startLocationCollection(configuration: Configuration?) {
        self.configuration = configuration

        // Note: GeoManager has to calculate the location.
        guard let location = location else {
            return
        }

        // Note: GeoManager has to fill these values:
        // - isAction
        // - actionParameters
        let state = RAnalyticsState(sessionIdentifier: Session.cks(),
                                    deviceIdentifier: deviceIdentifierHandler.ckp())
        state.lastKnownLocation = LocationModel(location: location,
                                                isAction: false,
                                                actionParameters: nil)

        _ = geoTracker?.process(event: RAnalyticsEvent(name: RAnalyticsEvent.Name.geoLocation,
                                                       parameters: nil),
                                state: state)
    }

    public func stopLocationCollection() {
    }

    public func requestLocation(actionParameters: GeoActionParameters? = nil,
                                completionHandler: @escaping GeoRequestLocationBlock) {
    }

    public func getConfiguration() -> Configuration {
        guard let configuration = configuration else {
            return ConfigurationFactory.defaultConfiguration
        }
        return configuration
    }
}
