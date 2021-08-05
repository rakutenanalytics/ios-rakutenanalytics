import Foundation
import CoreLocation
import WebKit
import AdSupport
import CoreTelephony

protocol SimpleDependenciesContainable {
    var notificationHandler: NotificationObservable { get }
    var userStorageHandler: UserStorageHandleable { get }
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
}

final class SimpleDependenciesContainer: NSObject, SimpleDependenciesContainable {
    enum Constants {
        static let RATDatabaseName = "RSDKAnalytics.db"
        static let RATTableName = "RAKUTEN_ANALYTICS_TABLE"
    }

    let notificationHandler: NotificationObservable = NotificationCenter.default
    let userStorageHandler: UserStorageHandleable = UserDefaults.standard
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
        if let connection = RAnalyticsDatabase.mkAnalyticsDBConnection(databaseName: Constants.RATDatabaseName) {
            let database = RAnalyticsDatabase.database(connection: connection)
            return DatabaseConfiguration(database: database, tableName: Constants.RATTableName)
        }
        return nil
    }()
}
