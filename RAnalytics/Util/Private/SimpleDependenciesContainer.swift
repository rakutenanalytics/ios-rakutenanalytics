import Foundation
import CoreLocation
import WebKit
import AdSupport

@objc public protocol SimpleDependenciesContainable {
    var notificationHandler: NotificationObservable { get }
    var userStorageHandler: UserStorageHandleable { get }
    var adIdentifierManager: AdvertisementIdentifiable { get }
    var httpCookieStore: WKHTTPCookieStorable { get }
    var keychainHandler: KeychainHandleable { get }
    var locationManager: LocationManageable { get }
    var bundle: EnvironmentBundle { get }
    var tracker: Trackable { get }
}

@objc public final class SimpleDependenciesContainer: NSObject, SimpleDependenciesContainable {
    public let notificationHandler: NotificationObservable = NotificationCenter.default
    public let userStorageHandler: UserStorageHandleable = UserDefaults.standard
    public let adIdentifierManager: AdvertisementIdentifiable = ASIdentifierManager.shared()
    public let httpCookieStore: WKHTTPCookieStorable = WKWebsiteDataStore.default().httpCookieStore
    public let keychainHandler: KeychainHandleable = KeychainHandler()
    public let analyticsTracker = AnalyticsTracker()
    public let locationManager: LocationManageable = CLLocationManager()
    public let bundle: EnvironmentBundle = Bundle.main
    public let tracker: Trackable = AnalyticsTracker()
}
