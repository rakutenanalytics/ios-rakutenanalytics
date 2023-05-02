import Foundation
import CoreLocation

protocol LocationManageable: AnyObject {
    var allowsBackgroundLocationUpdates: Bool { get set }
    var desiredAccuracy: CLLocationAccuracy { get set }
    var delegate: CLLocationManagerDelegate? { get set }
    var location: CLLocation? { get }
    var monitoredRegions: Set<CLRegion> { get }
    static func authorizationStatus() -> CLAuthorizationStatus
    func startUpdatingLocation()
    func stopUpdatingLocation()
    func requestLocation()
    static func significantLocationChangeMonitoringAvailable() -> Bool
    func startMonitoringSignificantLocationChanges()
    func stopMonitoringSignificantLocationChanges()
    func startMonitoring(for region: CLRegion)
    func stopMonitoring(for region: CLRegion)
}

extension CLLocationManager: LocationManageable {}
