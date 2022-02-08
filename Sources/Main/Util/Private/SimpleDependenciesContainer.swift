import Foundation
import CoreLocation
import WebKit
import AdSupport
import CoreTelephony
#if canImport(RSDKUtils)
import RSDKUtils
#else // SPM version
import RLogger
import RSDKUtilsMain
#endif

protocol SimpleDependenciesContainable {
    var notificationHandler: NotificationObservable { get }
    var userStorageHandler: UserStorageHandleable { get }
    var sharedUserStorageHandlerType: UserStorageHandleable.Type { get }
    var adIdentifierManager: AdvertisementIdentifiable { get }
    var wkHttpCookieStore: WKHTTPCookieStorable { get }
    var httpCookieStore: HTTPCookieStorable { get }
    var keychainHandler: KeychainHandleable { get }
    var locationManager: LocationManageable { get }
    var bundle: EnvironmentBundle { get }
    var tracker: Trackable { get }
    var telephonyNetworkInfoHandler: TelephonyNetworkInfoHandleable { get }
    var deviceCapability: DeviceCapability { get }
    var screenHandler: Screenable { get }
    var session: SwiftySessionable { get }
    var analyticsStatusBarOrientationGetter: StatusBarOrientationGettable? { get }
    var databaseConfiguration: DatabaseConfigurable? { get }
    var pushEventHandler: PushEventHandleable { get }
    var fileManager: FileManageable { get }
    var serializerType: JSONSerializable.Type { get }
}

final class SimpleDependenciesContainer: SimpleDependenciesContainable {
    enum RATTrackerConstants {
        static let databaseName = "RSDKAnalytics.db"
        static let tableName = "RAKUTEN_ANALYTICS_TABLE"
    }

    let notificationHandler: NotificationObservable = NotificationCenter.default
    let userStorageHandler: UserStorageHandleable = UserDefaults.standard
    let sharedUserStorageHandlerType: UserStorageHandleable.Type = UserDefaults.self
    let adIdentifierManager: AdvertisementIdentifiable = ASIdentifierManager.shared()
    let wkHttpCookieStore: WKHTTPCookieStorable = WKWebsiteDataStore.default().httpCookieStore
    let httpCookieStore: HTTPCookieStorable = HTTPCookieStorage.shared
    let keychainHandler: KeychainHandleable = KeychainHandler()
    let analyticsTracker = AnalyticsTracker()
    let locationManager: LocationManageable = CLLocationManager()
    let bundle: EnvironmentBundle = Bundle.main
    let tracker: Trackable = AnalyticsTracker()
    let telephonyNetworkInfoHandler: TelephonyNetworkInfoHandleable = CTTelephonyNetworkInfo()
    let deviceCapability: DeviceCapability = UIDevice.current
    let screenHandler: Screenable = UIScreen.main
    let session: SwiftySessionable = URLSession.shared
    let analyticsStatusBarOrientationGetter: StatusBarOrientationGettable? = UIApplication.RAnalyticsSharedApplication
    let databaseConfiguration: DatabaseConfigurable? = {
        DatabaseConfigurationHandler.create(databaseName: RATTrackerConstants.databaseName,
                                            tableName: RATTrackerConstants.tableName,
                                            databaseParentDirectory: Bundle.main.databaseParentDirectory)
    }()
    let pushEventHandler: PushEventHandleable
    let fileManager: FileManageable = FileManager.default
    let serializerType: JSONSerializable.Type = JSONSerialization.self

    init() {
        let appGroupId = bundle.appGroupId
        let sharedUserStorageHandler = sharedUserStorageHandlerType.init(suiteName: appGroupId)
        pushEventHandler = PushEventHandler(sharedUserStorageHandler: sharedUserStorageHandler,
                                            appGroupId: appGroupId)
    }
}
