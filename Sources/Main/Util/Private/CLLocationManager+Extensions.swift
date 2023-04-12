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
}

extension CLLocationManager: LocationManageable {}
