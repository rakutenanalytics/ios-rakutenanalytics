import CoreLocation

// MARK: - GeoLocationManageable

protocol GeoLocationManageable {
    func attemptToRequestLocation(completionHandler: @escaping (GeoRequestLocationResult) -> Void)
    func stopLocationUpdates()
    func requestLocation(actionParameters: GeoActionParameters?, completionHandler: @escaping (GeoRequestLocationResult) -> Void)
}

// MARK: - GeoLocationManager

/// Handles the location.
final class GeoLocationManager: NSObject {

    /// `CLLocationManager` instance used to receive events from GPS.
    private let coreLocationManager: LocationManageable

    /// Callback to provide user action based location or error
    private var userActionLocationCallback: ((GeoRequestLocationResult) -> Void)?
    /// Callback to provide regular location or error.
    private var continualLocationCallback: ((GeoRequestLocationResult) -> Void)?

    /// user action info
    private var userActionParameters: GeoActionParameters?

    /// Boolean value indicating if location update is user action based
    private var isUserActionBasedLocationRequest = false

    /// Boolean value indicating if the location request is for regular location collection.
    private var isContinualLocationRequest = false

    /// `GeoConfigurationStore`.
    private let configurationStore: GeoConfigurationStorable

    /// Creates a new instance of `GeoLocationManager`.
    ///
    /// - Parameter coreLocationManager: The core location service manager.
    /// - Parameter configurationStore: Object to store configuration.
    init(coreLocationManager: LocationManageable,
         configurationStore: GeoConfigurationStore) {
        self.coreLocationManager = coreLocationManager
        self.configurationStore = configurationStore
        super.init()

        coreLocationManager.delegate = self

        coreLocationManager.desiredAccuracy = configurationStore.configuration.accuracy.desiredAccuracy
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

    /// This method requests a location only during collection interval.
    ///
    /// - Parameter completionHandler: The completion handler containing a location or an error.
    func attemptToRequestLocation(completionHandler: @escaping (GeoRequestLocationResult) -> Void) {
        guard isCollectionTime else {
            RLogger.debug(message: "could not startLocationUpdates() as it is not the collection time.")
            return
        }
        continualLocationCallback = completionHandler
        isContinualLocationRequest = true
        coreLocationManager.requestLocation()
    }

    /// This method stops any ongoing location request.
    func stopLocationUpdates() {
        coreLocationManager.stopUpdatingLocation()
    }
}

// MARK: - CLLocationManagerDelegate conformance

extension GeoLocationManager: CLLocationManagerDelegate {

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let mostRecentLocation = locations.last else {
            return
        }
        if let continualLocationCallback = continualLocationCallback,
           isContinualLocationRequest {
            isContinualLocationRequest = false
            continualLocationCallback(.success(LocationModel(location: mostRecentLocation)))
        }
        if let userActionLocationCallback = userActionLocationCallback,
           isUserActionBasedLocationRequest {
            isUserActionBasedLocationRequest = false
            userActionLocationCallback(.success(LocationModel(location: mostRecentLocation,
                                                              isAction: true,
                                                              actionParameters: userActionParameters)))
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        if isUserActionBasedLocationRequest,
           let userActionLocationCallback = userActionLocationCallback {
            isUserActionBasedLocationRequest = false
            userActionLocationCallback(.failure(error))
        }
        if isContinualLocationRequest,
           let continualLocationCallback = continualLocationCallback {
            isContinualLocationRequest = false
            continualLocationCallback(.failure(error))
        }
    }
}

extension GeoLocationManager {
    private var isCollectionTime: Bool {
        Date().timeInSeconds >= configurationStore.configuration.startTime.toSeconds &&
        Date().timeInSeconds <= configurationStore.configuration.endTime.toSeconds
    }
}
