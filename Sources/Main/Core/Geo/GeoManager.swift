import Foundation
import CoreLocation

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
    /// - Parameter configuration: The location collection configuration. if not passed, the default configuration is used
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
    /// - Returns: the location collection configuration which is passed during startLocationCollection. if not passsed, nil is returned
    func getConfiguration() -> Configuration?
}

// MARK: - GeoManager
/// The object that you use to start, stop and request the delivery of location-related events to your app.
public final class GeoManager {
    /// The location collection configuration.
    private var configuration: Configuration?
    private let geoSharedPreferenceHelper: GeoConfigurationHelper
    /// - Returns: The shared instance of `GeoManager` object.
    public static let shared: GeoManager = {
        let dependenciesContainer = SimpleDependenciesContainer()
        return GeoManager(userStorageHandler: dependenciesContainer.userStorageHandler)
    }()

    /// Creates a new instance of GeoManager.
    ///
    /// - Parameter userStorageHandler: Parameter of type `UserStorageHandleable` provides an interface to the user’s defaults database, where you store key-value pairs persistently across launches of your app.
    init(userStorageHandler: UserStorageHandleable) {
        self.geoSharedPreferenceHelper = GeoConfigurationHelper(userStorageHandler: userStorageHandler)
    }
}

// MARK: - GeoManager conformance to GeoTrackable
extension GeoManager: GeoTrackable {

    public func startLocationCollection(configuration: Configuration? = nil) {
        
        if let geoConfiguration = configuration {
            geoSharedPreferenceHelper.store(configuration: geoConfiguration)
        }
        
        self.configuration = configuration
    }

    public func stopLocationCollection() {
    }

    public func requestLocation(actionParameters: GeoActionParameters? = nil,
                                completionHandler: @escaping GeoRequestLocationBlock) {
    }

    public func getConfiguration() -> Configuration? {
        return geoSharedPreferenceHelper.retrieveGeoConfigurationFromStorage()
    }
}
