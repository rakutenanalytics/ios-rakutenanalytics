#if canImport(RSDKUtils)
import RSDKUtils
#else // SPM version
import RSDKUtilsMain
#endif

// MARK: - Dependencies Factory

protocol DependenciesFactory {
    var wkHttpCookieStore: WKHTTPCookieStorable? { get }
    var httpCookieStore: HTTPCookieStorable? { get }
    var adIdentifierManager: AdvertisementIdentifiable? { get }
    var notificationHandler: NotificationObservable? { get }
    var userStorageHandler: UserStorageHandleable? { get }
    var keychainHandler: KeychainHandleable? { get }
    var tracker: Trackable? { get }
    var bundle: EnvironmentBundle? { get }
    var telephonyNetworkInfoHandler: TelephonyNetworkInfoHandleable? { get }
    var analyticsStatusBarOrientationGetter: StatusBarOrientationGettable? { get }
    var device: DeviceCapability? { get }
    var screen: Screenable? { get }
    var databaseConfiguration: DatabaseConfigurable? { get }
    var session: SwiftySessionable? { get }
}

extension AnyDependenciesContainer: DependenciesFactory {
    var wkHttpCookieStore: WKHTTPCookieStorable? { resolve(WKHTTPCookieStorable.self) }
    var httpCookieStore: HTTPCookieStorable? { resolve(HTTPCookieStorable.self) }
    var adIdentifierManager: AdvertisementIdentifiable? { resolve(AdvertisementIdentifiable.self) }
    var notificationHandler: NotificationObservable? { resolve(NotificationObservable.self) }
    var userStorageHandler: UserStorageHandleable? { resolve(UserStorageHandleable.self) }
    var keychainHandler: KeychainHandleable? { resolve(KeychainHandleable.self) }
    var tracker: Trackable? { resolve(Trackable.self) }
    var bundle: EnvironmentBundle? { resolve(EnvironmentBundle.self) }
    var telephonyNetworkInfoHandler: TelephonyNetworkInfoHandleable? { resolve(TelephonyNetworkInfoHandleable.self) }
    var analyticsStatusBarOrientationGetter: StatusBarOrientationGettable? { resolve(StatusBarOrientationGettable.self) }
    var device: DeviceCapability? { resolve(DeviceCapability.self) }
    var screen: Screenable? { resolve(Screenable.self) }
    var databaseConfiguration: DatabaseConfigurable? { resolve(DatabaseConfigurable.self) }
    var session: SwiftySessionable? { resolve(SwiftySessionable.self) }
}
