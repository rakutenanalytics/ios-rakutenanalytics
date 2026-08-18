import Foundation
import CoreLocation

protocol LocationManageable: AnyObject {
    var desiredAccuracy: CLLocationAccuracy { get set }
    var delegate: CLLocationManagerDelegate? { get set }
    var location: CLLocation? { get }
    static func authorizationStatus() -> CLAuthorizationStatus
    func startUpdatingLocation()
    func stopUpdatingLocation()
    func requestLocation()
    #if os(iOS)
    var allowsBackgroundLocationUpdates: Bool { get set }
    var monitoredRegions: Set<CLRegion> { get }
    static func significantLocationChangeMonitoringAvailable() -> Bool
    func startMonitoringSignificantLocationChanges()
    func stopMonitoringSignificantLocationChanges()
    func startMonitoring(for region: CLRegion)
    func stopMonitoring(for region: CLRegion)
    #endif
}

#if os(iOS)

extension CLLocationManager: LocationManageable {}

#elseif os(tvOS)

/// Stub location manager for tvOS where most `CLLocationManager` APIs are unavailable.
final class TVLocationManager: NSObject, LocationManageable {
    var desiredAccuracy: CLLocationAccuracy = kCLLocationAccuracyThreeKilometers
    weak var delegate: CLLocationManagerDelegate?
    var location: CLLocation? { nil }

    static func authorizationStatus() -> CLAuthorizationStatus {
        .denied
    }

    func startUpdatingLocation() {}
    func stopUpdatingLocation() {}
    func requestLocation() {
        let error = NSError(
            domain: kCLErrorDomain,
            code: CLError.denied.rawValue,
            userInfo: [NSLocalizedDescriptionKey: "Location services are not available on tvOS."]
        )
        guard let delegate else { return }
        DispatchQueue.main.async {
            delegate.locationManager?(CLLocationManager(), didFailWithError: error)
        }
    }
}

#endif

enum LocationManagerFactory {
    static func makeDefault() -> LocationManageable {
        #if os(iOS)
        return CLLocationManager()
        #elseif os(tvOS)
        return TVLocationManager()
        #endif
    }
}
