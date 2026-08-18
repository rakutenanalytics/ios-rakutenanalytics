import Foundation
import UIKit
import CoreLocation
#if os(iOS)
import WebKit
import AdSupport
import CoreTelephony
#endif

protocol SimpleDependenciesContainable: AnalyticsHostBundleProviding {
    var notificationHandler: NotificationObservable { get }
    var userStorageHandler: UserStorageHandleable { get }
    var sharedUserStorageHandlerType: UserStorageHandleable.Type { get }
    var adIdentifierManager: AdvertisementIdentifiable { get }
    var wkHttpCookieStore: WKHTTPCookieStorable { get }
    var httpCookieStore: HTTPCookieStorable { get }
    var keychainHandler: KeychainHandleable { get }
    var locationManager: LocationManageable { get }
    var bundle: EnvironmentBundle { get }
    var telephonyNetworkInfoHandler: TelephonyNetworkInfoHandleable { get }
    var deviceCapability: DeviceCapability { get }
    var screenHandler: Screenable { get }
    var session: SwiftySessionable { get }
    var analyticsStatusBarOrientationGetter: StatusBarOrientationGettable? { get }
    var databaseConfiguration: DatabaseConfigurable? { get }
    var pushEventHandler: PushEventHandleable { get }
    var coreInfosCollector: CoreInfosCollectable { get }
    var automaticFieldsBuilder: AutomaticFieldsBuildable { get }
    var applicationStateGetter: ApplicationStateGettable? { get }
}

final class SimpleDependenciesContainer: SimpleDependenciesContainable {
    enum RATTrackerConstants {
        static let databaseName = "RSDKAnalytics.db"
        static let tableName = "RAKUTEN_ANALYTICS_TABLE"
    }

    let notificationHandler: NotificationObservable = NotificationCenter.default
    let userStorageHandler: UserStorageHandleable = UserDefaults.standard
    let sharedUserStorageHandlerType: UserStorageHandleable.Type = UserDefaults.self
    #if os(iOS)
    let adIdentifierManager: AdvertisementIdentifiable = ASIdentifierManager.shared()
    #elseif os(tvOS)
    let adIdentifierManager: AdvertisementIdentifiable = NoOpAdvertisementIdentifierManager()
    #endif
    let httpCookieStore: HTTPCookieStorable = HTTPCookieStorage.shared
    let locationManager: LocationManageable = LocationManagerFactory.makeDefault()
    let bundle: EnvironmentBundle = Bundle.main
    let keychainHandler: KeychainHandleable = KeychainHandler(bundle: Bundle.main)
    #if os(iOS)
    let telephonyNetworkInfoHandler: TelephonyNetworkInfoHandleable = CTTelephonyNetworkInfo()
    #elseif os(tvOS)
    let telephonyNetworkInfoHandler: TelephonyNetworkInfoHandleable = NoOpTelephonyNetworkInfo()
    #endif
    let deviceCapability: DeviceCapability = UIDevice.current
    let screenHandler: Screenable = UIScreen.screenableFromScene
    let session: SwiftySessionable = URLSession.shared
    let analyticsStatusBarOrientationGetter: StatusBarOrientationGettable? = RAnalyticsApplicationOrientationProvider()
    let databaseConfiguration: DatabaseConfigurable? = {
        DatabaseConfigurationHandler.create(databaseName: RATTrackerConstants.databaseName,
                                            tableName: RATTrackerConstants.tableName,
                                            databaseParentDirectory: Bundle.main.databaseParentDirectory)
    }()
    let pushEventHandler: PushEventHandleable
    let coreInfosCollector: CoreInfosCollectable = CoreInfosCollector()
    let automaticFieldsBuilder: AutomaticFieldsBuildable
    let applicationStateGetter: ApplicationStateGettable? = UIApplication.RAnalyticsSharedApplication
    #if os(iOS)
    lazy var wkHttpCookieStore: WKHTTPCookieStorable = WKWebsiteDataStore.default().httpCookieStore
    #elseif os(tvOS)
    lazy var wkHttpCookieStore: WKHTTPCookieStorable = NoOpWKHTTPCookieStore()
    #endif

    init() {
        let appGroupId = bundle.appGroupId
        let sharedUserStorageHandler = sharedUserStorageHandlerType.init(suiteName: appGroupId)
        pushEventHandler = PushEventHandler(sharedUserStorageHandler: sharedUserStorageHandler,
                                            appGroupId: appGroupId)

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
