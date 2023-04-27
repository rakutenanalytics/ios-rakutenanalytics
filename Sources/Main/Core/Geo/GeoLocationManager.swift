import CoreLocation

// MARK: - GeoLocationManagerDelegate

protocol GeoLocationManagerDelegate: AnyObject {
    func geoLocationManager(didUpdateLocation location: CLLocation, for requestType: GeoRequestLocationType)
    func geoLocationManager(didFailWithError error: Error, for requestType: GeoRequestLocationType)
}

// MARK: - GeoLocationManageable

protocol GeoLocationManageable: AnyObject {
    var delegate: GeoLocationManagerDelegate? { get set }
    func requestLocationUpdate(for requestType: GeoRequestLocationType)
    func stopLocationUpdates()
    func startMonitoringSignificantLocationChanges()
    func stopMonitoringSignificantLocationChanges()
}

// MARK: - GeoConstants

private enum GeoConstants {
    static let locationCollectionRegionIdentifier = "GeoLocationCollectionRegionIdentifier"
}

// MARK: - GeoLocationManager

/// Handles the location.
final class GeoLocationManager: NSObject {

    /// `GeoLocationManagerDelegate`.
    weak var delegate: GeoLocationManagerDelegate?

    /// `CLLocationManager` instance used to receive events from GPS.
    private let coreLocationManager: LocationManageable

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
    func requestLocationUpdate(for requestType: GeoRequestLocationType) {
        switch requestType {
        case .userAction:
            isUserActionBasedLocationRequest = true
        case .continual:
            guard isCollectionTime else {
                RLogger.debug(message: "could not requestLocation() as it is not the collection time.")
                return
            }
            isContinualLocationRequest = true
        }
        coreLocationManager.requestLocation()
    }

    /// This method stops any ongoing location request.
    func stopLocationUpdates() {
        coreLocationManager.stopUpdatingLocation()
        stopRegionMonitoring()
    }

    func startMonitoringSignificantLocationChanges() {
        if CLLocationManager.significantLocationChangeMonitoringAvailable() {
            coreLocationManager.startMonitoringSignificantLocationChanges()
        }
    }

    func stopMonitoringSignificantLocationChanges() {
        coreLocationManager.stopMonitoringSignificantLocationChanges()
    }
}

// MARK: - CLLocationManagerDelegate conformance

extension GeoLocationManager: CLLocationManagerDelegate {

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let mostRecentLocation = locations.last else {
            return
        }
        if isContinualLocationRequest {
            isContinualLocationRequest = false
            handleDistanceBasedCollection(location: mostRecentLocation)
            delegate?.geoLocationManager(didUpdateLocation: mostRecentLocation, for: .continual)
        }
        if isUserActionBasedLocationRequest {
            isUserActionBasedLocationRequest = false
            delegate?.geoLocationManager(didUpdateLocation: mostRecentLocation, for: .userAction)
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        if isUserActionBasedLocationRequest {
            isUserActionBasedLocationRequest = false
            delegate?.geoLocationManager(didFailWithError: error, for: .userAction)
        }
        if isContinualLocationRequest {
            isContinualLocationRequest = false
            delegate?.geoLocationManager(didFailWithError: error, for: .continual)
        }
    }

    func locationManager(_ manager: CLLocationManager, didDetermineState state: CLRegionState, for region: CLRegion) {
        if state == .outside {
            guard isCollectionTime, let location = manager.location else {
                RLogger.debug(message: "could not requestLocation() as it is not the collection time.")
                return
            }
            startRegionMonitoring(at: location)
            delegate?.geoLocationManager(didUpdateLocation: location, for: .continual)
        }
    }

    func locationManager(_ manager: CLLocationManager, monitoringDidFailFor region: CLRegion?, withError error: Error) {
        guard let failedRegion = region,
              failedRegion.identifier == GeoConstants.locationCollectionRegionIdentifier else {
            return
        }
        RLogger.debug(message: "locationManager monitoringDidFailFor \(failedRegion.identifier) withError: \(error.localizedDescription)")
    }
}

// MARK: - GeoLocationManager Helpers

extension GeoLocationManager {
    private var isCollectionTime: Bool {
        Date().timeInSeconds >= configurationStore.configuration.startTime.toSeconds &&
        Date().timeInSeconds <= configurationStore.configuration.endTime.toSeconds
    }

    private func handleDistanceBasedCollection(location: CLLocation) {
        if !coreLocationManager.monitoredRegions.contains(where: { $0.identifier == GeoConstants.locationCollectionRegionIdentifier }) {
            startRegionMonitoring(at: location)
        }
    }

    private func startRegionMonitoring(at location: CLLocation) {
        stopRegionMonitoring()
        let region = CLCircularRegion(center: location.coordinate,
                                      radius: CLLocationDistance(configurationStore.configuration.distanceInterval),
                                      identifier: GeoConstants.locationCollectionRegionIdentifier)
        region.notifyOnEntry = false
        coreLocationManager.startMonitoring(for: region)
    }

    private func stopRegionMonitoring() {
        guard let region = coreLocationManager.monitoredRegions
            .first(where: { $0.identifier == GeoConstants.locationCollectionRegionIdentifier }) else {
            return
        }
        coreLocationManager.stopMonitoring(for: region)
    }
}
