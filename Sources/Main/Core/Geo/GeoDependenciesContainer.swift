import Foundation
import CoreLocation
import UIKit
#if os(iOS)
import CoreTelephony
#endif

protocol GeoDependenciesContainable: AnalyticsHostBundleProviding {
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
    let locationManager: LocationManageable = LocationManagerFactory.makeDefault()
    let bundle: EnvironmentBundle = Bundle.main
    #if os(iOS)
    let telephonyNetworkInfoHandler: TelephonyNetworkInfoHandleable = CTTelephonyNetworkInfo()
    #elseif os(tvOS)
    let telephonyNetworkInfoHandler: TelephonyNetworkInfoHandleable = NoOpTelephonyNetworkInfo()
    #endif
    let deviceCapability: DeviceCapability = UIDevice.current
    let screenHandler: Screenable = UIScreen.screenableFromScene
    let session: SwiftySessionable = URLSession.shared
    let analyticsStatusBarOrientationGetter: StatusBarOrientationGettable? = RAnalyticsApplicationOrientationProvider()
    let automaticFieldsBuilder: AutomaticFieldsBuildable

    init() {
        automaticFieldsBuilder = AutomaticFieldsBuilder(bundle: bundle,
                                                        deviceCapability: deviceCapability,
                                                        screenHandler: screenHandler,
                                                        telephonyNetworkInfoHandler: telephonyNetworkInfoHandler,
                                                        notificationHandler: notificationHandler,
                                                        analyticsStatusBarOrientationGetter: analyticsStatusBarOrientationGetter,
                                                        reachability: Reachability(),
                                                        userStorageHandler: userStorageHandler)
    }
}
