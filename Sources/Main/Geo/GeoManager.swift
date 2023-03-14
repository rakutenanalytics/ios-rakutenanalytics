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
    func startLocationCollection()
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
    /// This method sets the configuration for the GeoTracker.
    ///
    /// Call this method to configure the GeoTracker.
    /// - parameters:
    ///     - accuracy: The accuracy of a geographical coordinate.
    ///     - distanceInterval: The minimum distance in meters the device must move horizontally to obtain a location update event.
    ///     - timeInterval: The minimum time in seconds the device must wait to obtain a location update event.
    ///     - collectionTimeRange: The time range in milli seconds for location collection.
    func configureGeoTracker(accuracy: GeoAccuracy?,
                             distanceInterval: CLLocationDistance?,
                             timeInterval: TimeInterval?,
                             collectionTimeRange: (start: Int, end: Int)?)
}

// MARK: - GeoManager
/// The object that you use to start, stop and request the delivery of location-related events to your app.
public final class GeoManager {

    /// - Returns: The shared instance of `GeoManager` object.
    public static let shared: GeoManager = GeoManager()
}

// MARK: - GeoManager conformance to GeoTrackable
extension GeoManager: GeoTrackable {

    public func startLocationCollection() {
    }
    
    public func stopLocationCollection() {
    }

    public func requestLocation(actionParameters: GeoActionParameters? = nil,
                                completionHandler: @escaping GeoRequestLocationBlock) {
    }

    public func configureGeoTracker(accuracy: GeoAccuracy?,
                                    distanceInterval: CLLocationDistance?,
                                    timeInterval: TimeInterval?,
                                    collectionTimeRange: (start: Int, end: Int)?) {
    }
}
