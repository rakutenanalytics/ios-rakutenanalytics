import Foundation
import CoreLocation

/// `GeoAccuracy` consists of accuracies for the location data that your app wants to receive.
///
/// Accuracy values are the number of meters from the original geographic coordinate that could yield the user’s actual location.
public enum GeoAccuracy: UInt {
    /// The best level of accuracy available.
    ///
    /// Specify this constant when you want very high accuracy but don’t need the same level of accuracy required for navigation apps. This level of accurate is available only if isAuthorizedForPreciseLocation is true.
    case best = 1
    /// Accurate to within ten meters of the desired target.
    ///
    /// This level of accurate is available only if isAuthorizedForPreciseLocation is true.
    case nearest
    /// The highest possible accuracy that uses additional sensor data to facilitate navigation apps.
    ///
    /// This level of accuracy is intended for use in navigation apps that require precise position information at all times. Because of the extra power requirements, use this level of accuracy only while the device is plugged in. This level of accurate is available only if isAuthorizedForPreciseLocation is true.
    case navigation
    /// Accurate to within one hundred meters.
    ///
    /// This level of accurate is available only if isAuthorizedForPreciseLocation is true.
    case hundredMeters
    /// Accurate to the nearest kilometer.
    ///
    /// This level of accurate is available only if isAuthorizedForPreciseLocation is true.
    case kilometer
    /// Accurate to the nearest three kilometers.
    ///
    /// This level of accurate is available only if isAuthorizedForPreciseLocation is true.
    case threeKilometers
    
    /// The accuracy of the location data that your app wants to receive.
    ///
    /// The location service does its best to achieve the requested accuracy; however, apps must be prepared to use less accurate data. If your app isn’t authorized to access precise location information (isAuthorizedForPreciseLocation is false), changes to this property’s value have no effect; the accuracy is always [kCLLocationAccuracyReduced](https://developer.apple.com/documentation/corelocation/kcllocationaccuracyreduced). To reduce your app’s impact on battery life, assign a value to this property that’s appropriate for your usage. For example, if you need the current location only within a kilometer, specify [kCLLocationAccuracyKilometer](https://developer.apple.com/documentation/corelocation/kcllocationaccuracykilometer). More accurate location data also takes more time to become available. After you request high-accuracy location data, your app might still get data with a lower accuracy for a period of time. During the time it takes to determine the location within the requested accuracy, the location service keeps providing the data that’s available, even though that data isn’t as accurate as your app requested. Your app receives more accurate location data as that data becomes available. For iOS, the default value of this property is [kCLLocationAccuracyBest](https://developer.apple.com/documentation/corelocation/kcllocationaccuracybest). For macOS, watchOS, and tvOS, the default value is [kCLLocationAccuracyHundredMeters](https://developer.apple.com/documentation/corelocation/kcllocationaccuracyhundredmeters). This property effects only the standard location services, not for monitoring significant location changes.
    var desiredAccuracy: CLLocationAccuracy {
        switch self {
        case .best:
            return kCLLocationAccuracyBest
        case .nearest:
            return kCLLocationAccuracyNearestTenMeters
        case .navigation:
            return kCLLocationAccuracyBestForNavigation
        case .hundredMeters:
            return kCLLocationAccuracyHundredMeters
        case .kilometer:
            return kCLLocationAccuracyKilometer
        case .threeKilometers:
            return kCLLocationAccuracyThreeKilometers
        }
    }
}
