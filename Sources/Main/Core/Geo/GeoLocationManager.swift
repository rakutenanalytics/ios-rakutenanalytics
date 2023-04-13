import CoreLocation

// MARK: - GeoLocationManageable

protocol GeoLocationManageable {
    func requestLocation(actionParameters: GeoActionParameters?, completionHandler: @escaping (GeoRequestLocationResult) -> Void)
}

// MARK: - GeoLocationManager

/// Handles the location.
final class GeoLocationManager: NSObject {
    /// `CLLocationManager` instance used to receive events from GPS.
    private let coreLocationManager: LocationManageable

    /// The location configuration.
    private let configuration: GeoConfiguration

    /// Callback to provide user action based location or error
    private var userActionLocationCallback: ((GeoRequestLocationResult) -> Void)?

    /// user action info
    private var userActionParameters: GeoActionParameters?

    /// Boolean value indicating if location update is user action based
    private var isUserActionBasedLocationRequest = false

    /// Creates a new instance of `GeoLocationManager`.
    ///
    /// - Parameter configuration: The location configuration.
    /// - Parameter coreLocationManager: The core location service manager.
    init(configuration: GeoConfiguration, coreLocationManager: LocationManageable) {
        self.configuration = configuration
        self.coreLocationManager = coreLocationManager

        super.init()

        coreLocationManager.delegate = self
        coreLocationManager.desiredAccuracy = configuration.accuracy.desiredAccuracy
    }
}

// MARK: - GeoLocationManageable conformance

extension GeoLocationManager: GeoLocationManageable {
    /// Requests a location.
    ///
    /// - Parameter actionParameters: The action parameters (optional).
    /// - Parameter completionHandler: The completion handler containing a location or an error.
    func requestLocation(actionParameters: GeoActionParameters? = nil,
                         completionHandler: @escaping (GeoRequestLocationResult) -> Void) {
        userActionLocationCallback = completionHandler
        userActionParameters = actionParameters
        isUserActionBasedLocationRequest = true
        coreLocationManager.requestLocation()
    }
}

// MARK: - CLLocationManagerDelegate conformance

extension GeoLocationManager: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let mostRecentLocation = locations.last,
              isUserActionBasedLocationRequest,
              let userActionLocationCallback = userActionLocationCallback else {
            return
        }
        userActionLocationCallback(.success(LocationModel(location: mostRecentLocation,
                                                          isAction: isUserActionBasedLocationRequest,
                                                          actionParameters: userActionParameters)))
        isUserActionBasedLocationRequest = false
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        guard isUserActionBasedLocationRequest,
              let userActionLocationCallback = userActionLocationCallback else {
            return
        }
        userActionLocationCallback(.failure(error))
        isUserActionBasedLocationRequest = false
    }
}
