import Foundation
import CoreLocation

@objc protocol LocationManageable {
    var desiredAccuracy: CLLocationAccuracy { get set }
    var delegate: CLLocationManagerDelegate? { get set }
    var location: CLLocation? { get }
    static func authorizationStatus() -> CLAuthorizationStatus
    func startUpdatingLocation()
    func stopUpdatingLocation()
}

@objc extension CLLocationManager: LocationManageable {}
