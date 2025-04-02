import Foundation
import CoreLocation
import CoreTelephony
import UIKit

protocol GeoDependenciesContainable {
    var notificationHandler: NotificationObservable { get }
    var userStorageHandler: UserStorageHandleable { get }
    var locationManager: LocationManageable { get }
    var bundle: EnvironmentBundle { get }
    var telephonyNetworkInfoHandler: TelephonyNetworkInfoHandleable { get }
    var deviceCapability: DeviceCapability { get }
    var screenHandler: Screenable { get }
    var session: SwiftySessionable { get }
    var analyticsStatusBarOrientationGetter: StatusBarOrientationGettable? { get }
    var automaticFieldsBuilder: AutomaticFieldsBuildable { get }
}

/// This class contains the dependencies used by `GeoManager`.
final class GeoDependenciesContainer: GeoDependenciesContainable {
    let notificationHandler: NotificationObservable = NotificationCenter.default
    let userStorageHandler: UserStorageHandleable = UserDefaults.standard
    let locationManager: LocationManageable = CLLocationManager()
    let bundle: EnvironmentBundle = Bundle.main
    let telephonyNetworkInfoHandler: TelephonyNetworkInfoHandleable = CTTelephonyNetworkInfo()
    let deviceCapability: DeviceCapability = UIDevice.current
    let screenHandler: Screenable = UIScreen.main
    let session: SwiftySessionable = URLSession.shared
    let analyticsStatusBarOrientationGetter: StatusBarOrientationGettable? = UIApplication.RAnalyticsSharedApplication
    let automaticFieldsBuilder: AutomaticFieldsBuildable

    init() {
        automaticFieldsBuilder = AutomaticFieldsBuilder(bundle: bundle,
                                                        deviceCapability: deviceCapability,
                                                        screenHandler: screenHandler,
                                                        telephonyNetworkInfoHandler: telephonyNetworkInfoHandler,
                                                        notificationHandler: notificationHandler,
                                                        analyticsStatusBarOrientationGetter: analyticsStatusBarOrientationGetter,
                                                        reachability: Reachability())
    }
}
