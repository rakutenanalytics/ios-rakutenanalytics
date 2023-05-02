import Foundation
import CoreLocation
import CoreTelephony
import AdSupport
import WebKit
import SystemConfiguration

@testable import RAnalytics

// MARK: - Tracker

public struct TrackerResult {
    public let tracked: Bool
    public let parameters: [String: Any]?

    public init(tracked: Bool, parameters: [String: Any]?) {
        self.tracked = tracked
        self.parameters = parameters
    }
}

public final class AnalyticsTrackerMock: NSObject, Trackable {
    public var dictionary: [String: TrackerResult]?
    public private(set) var eventName: String?
    public private(set) var params: [String: Any]?

    public override init() {
        super.init()
    }

    public func trackEvent(name: String, parameters: [String: Any]?) {
        eventName = name
        params = parameters
        dictionary?[name] = TrackerResult(tracked: true, parameters: parameters)
    }

    public func reset() {
        dictionary = nil
        eventName = nil
        params = nil
    }
}

// MARK: - ASIdentifierManagerMock

public final class ASIdentifierManagerMock: NSObject, AdvertisementIdentifiable {
    public var advertisingIdentifierUUIDString: String = ""

    public override init() {
        super.init()
    }
}

// MARK: - WKHTTPCookieStoreObservable

public protocol WKHTTPCookieStoreObservable: AnyObject {
    func cookiesDidChange(in cookieStore: WKHTTPCookieStorable)
}

// MARK: - WKHTTP Cookie Storage

public final class WKHTTPCookieStorageMock: WKHTTPCookieStorable {
    private var cookiesArray: [HTTPCookie]
    private var observers: [WKHTTPCookieStoreObservable]

    public init() {
        cookiesArray = [HTTPCookie]()
        observers = [WKHTTPCookieStoreObservable]()
    }

    private func updateObservers() {
        observers.forEach { observer in
            observer.cookiesDidChange(in: self)
        }
    }

    public func allCookies(_ completionHandler: @escaping ([HTTPCookie]) -> Void) {
        completionHandler(cookiesArray)
    }

    public func set(cookie: HTTPCookie, completionHandler: (() -> Void)?) {
        cookiesArray.append(cookie)
        completionHandler?()
        updateObservers()
    }

    public func delete(cookie: HTTPCookie, completionHandler: (() -> Void)?) {
        cookiesArray.removeAll { $0 == cookie }
        completionHandler?()
        updateObservers()
    }

    public func add(_ observer: WKHTTPCookieStoreObservable) {
        observers.append(observer)
    }
}

// MARK: - User Defaults

public final class UserDefaultsMock: NSObject {
    public var dictionary: [String: Any]?
    public convenience init(_ dictionary: [String: Any]) {
        self.init()
        self.dictionary = dictionary
    }
}

extension UserDefaultsMock: UserStorageHandleable {
    public convenience init?(suiteName suitename: String?) {
        guard suitename != nil else {
            return nil
        }
        self.init()
    }
    public func array(forKey defaultName: String) -> [Any]? { dictionary?[defaultName] as? [Any] }
    public func dictionary(forKey defaultName: String) -> [String: Any]? { dictionary?[defaultName] as? [String: Any] }
    public func set(value: Any?, forKey key: String) { dictionary?[key] = value }
    public func removeObject(forKey defaultName: String) { dictionary?[defaultName] = nil }
    public func object(forKey defaultName: String) -> Any? { dictionary?[defaultName] }
    public func string(forKey defaultName: String) -> String? { dictionary?[defaultName] as? String }
    public func bool(forKey defaultName: String) -> Bool {
        guard let result = dictionary?[defaultName] as? Bool else {
            return false
        }
        return result
    }
    public func data(forKey defaultName: String) -> Data? {
        dictionary?[defaultName] as? Data
    }

    public func register(defaults registrationDictionary: [String: Any]) {
    }
    public func synchronize() -> Bool { true }

    public func double(forKey key: String) -> Double {
        (dictionary?[key] as? Double) ?? 0.0
    }
}

// MARK: - Session

public final class SessionMock: Sessionable {
    public var willComplete: (() -> Void?)?
    public var data: Data?
    public var response: HTTPURLResponse?
    public var error: Error?

    public init() {
    }

    public func createDataTask(with request: URLRequest, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) -> URLSessionTaskable {
        willComplete?()
        completionHandler(data, response, error)
        return URLSessionTaskMock()
    }
}

// MARK: - URL Session Task

final class URLSessionTaskMock: URLSessionTaskable {
    func resume() {}
}

// MARK: - Swifty Session

public final class SwityURLSessionMock: NSObject, SwiftySessionable {
    public var urlRequest: URLRequest?
    public var response: URLResponse?
    public var completion: (() -> Void)?

    public override init() {
        super.init()
    }

    public func dataTask(with request: URLRequest, completionHandler: @escaping (Result<(data: Data?, response: URLResponse), Error>) -> Void) -> URLSessionTaskable {
        self.urlRequest = request
        completionHandler(.success((nil, response ?? URLResponse())))
        completion?()
        return URLSessionTaskMock()
    }
}

// MARK: - HTTP Cookie Storage

public final class HTTPCookieStorageMock: HTTPCookieStorable {
    public var cookiesArray: [HTTPCookie]?

    public init() {
    }

    public func cookies(for url: URL) -> [HTTPCookie]? {
        cookiesArray
    }
}

// MARK: - Tracker

public final class TrackerMock: NSObject, Tracker {
    public var event: RAnalyticsEvent?
    public var state: RAnalyticsState?
    public var endpointURL: URL? = URL(string: "https://endpoint.co.jp")

    public override init() {
        super.init()
    }

    public func process(event: RAnalyticsEvent, state: RAnalyticsState) -> Bool {
        self.event = event
        self.state = state
        return true
    }
}

// MARK: - Location Manager

public final class LocationManagerMock: NSObject, LocationManageable {
    public var monitoredRegions: Set<CLRegion> = []
    public var desiredAccuracy: CLLocationAccuracy = 0.0
    public weak var delegate: CLLocationManagerDelegate?
    public var location: CLLocation?
    public var startUpdatingLocationIsCalled = false
    public var stopUpdatingLocationIsCalled = false
    public var requestLocationIsCalled = false
    public var startMonitoringSignificantLocationChangesIsCalled = false
    public var stopMonitoringSignificantLocationChangesIsCalled = false
    public var startMonitoringForRegionIsCalled = false
    public var stopMonitoringForRegionIsCalled = false

    public override init() {
        super.init()
    }

    public static func authorizationStatus() -> CLAuthorizationStatus {
        .authorizedAlways
    }

    public func startUpdatingLocation() {
        startUpdatingLocationIsCalled = true
    }

    public func stopUpdatingLocation() {
        stopUpdatingLocationIsCalled = true
    }

    public func requestLocation() {
        requestLocationIsCalled = true
    }

    public static func significantLocationChangeMonitoringAvailable() -> Bool {
        true
    }

    public func startMonitoringSignificantLocationChanges() {
        startMonitoringSignificantLocationChangesIsCalled = true
    }

    public func stopMonitoringSignificantLocationChanges() {
        stopMonitoringSignificantLocationChangesIsCalled = true
    }

    public func startMonitoring(for region: CLRegion) {
        startMonitoringForRegionIsCalled = true
        monitoredRegions.insert(region)
    }

    public func stopMonitoring(for region: CLRegion) {
        stopMonitoringForRegionIsCalled = true
        monitoredRegions.remove(region)
    }
}

// MARK: - Keychain Handler

public final class KeychainHandlerMock: NSObject, KeychainHandleable {
    public var status: OSStatus = errSecItemNotFound
    private var creationDate: Date?
    private var dictionary: [String: Any] = [:]

    public override init() {
        super.init()
    }

    public func item(for label: String) -> KeychainResult { KeychainResult(result: nil, status: status) }
    public func set(creationDate: Date?, for label: String) { self.creationDate = creationDate }
    public func creationDate(for reference: CFTypeRef?) -> Date? { creationDate }

    public func string(for key: String) -> String? {
        dictionary[key] as? String
    }

    public func set(value: String?, for key: String) {
        dictionary[key] = value
    }
}

// MARK: - SimpleContainerMock

public final class SimpleContainerMock: NSObject, SimpleDependenciesContainable {
    enum Constants {
        static let ratDatabaseName = "RSDKAnalytics.db"
        static let ratTableName = "RAKUTEN_ANALYTICS_TABLE"
    }

    public var notificationHandler: NotificationObservable = NotificationCenter.default
    public var userStorageHandler: UserStorageHandleable = UserDefaults.standard
    public var sharedUserStorageHandlerType: UserStorageHandleable.Type = UserDefaults.self
    public var adIdentifierManager: AdvertisementIdentifiable = ASIdentifierManager.shared()
    public var wkHttpCookieStore: WKHTTPCookieStorable = WKWebsiteDataStore.default().httpCookieStore
    public var httpCookieStore: HTTPCookieStorable = HTTPCookieStorage.shared
    public var keychainHandler: KeychainHandleable = KeychainHandler(bundle: Bundle.main)
    public var locationManager: LocationManageable = CLLocationManager()
    public var bundle: EnvironmentBundle = Bundle.main
    public var telephonyNetworkInfoHandler: TelephonyNetworkInfoHandleable = CTTelephonyNetworkInfo()
    public var deviceCapability: DeviceCapability = UIDevice.current
    public var screenHandler: Screenable = UIScreen.main
    public var session: SwiftySessionable = URLSession.shared
    public var analyticsStatusBarOrientationGetter: StatusBarOrientationGettable? = UIApplication.RAnalyticsSharedApplication
    public var databaseConfiguration: DatabaseConfigurable? = {
        DatabaseConfigurationHandler.create(databaseName: Constants.ratDatabaseName,
                                            tableName: Constants.ratTableName,
                                            databaseParentDirectory: .documentDirectory)
    }()
    public var pushEventHandler: PushEventHandleable
    public var coreInfosCollector: CoreInfosCollectable = CoreInfosCollector()
    public var automaticFieldsBuilder: AutomaticFieldsBuildable

    public override init() {
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
                                                        reachability: Reachability(hostname: ReachabilityConstants.host))
        super.init()
    }
}

// MARK: - CustomPage

public final class CustomPage: UIViewController {
    public init(frame: CGRect) {
        super.init(nibName: nil, bundle: nil)
        view.frame = frame
        title = "CustomPageTitle"
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

// MARK: - CustomWebPage

public final class CustomWebPage: UIViewController {
    private let url: URL! = URL(string: "https://rat.rakuten.co.jp/")
    private var webView: WKWebView!

    public init(frame: CGRect) {
        super.init(nibName: nil, bundle: nil)
        view.frame = frame
        title = "CustomWebPageTitle"

        self.webView = WKWebView()
        self.webView?.load(URLRequest(url: url))
        view.addSubview(self.webView)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

// MARK: - Tracking

public enum Tracking {
    // MARK: - APNS Device Token
    public static let deviceToken = "e621e1f7c36c495a93fc0c247a3e6e5f"

    // MARK: - PNP Client Identifier
    public static let pnpClientIdentifier = "pnpClientIdentifier"

    public static let customPage: CustomPage = {
        CustomPage(frame: CGRect(x: 0, y: 0, width: 200, height: 200))
    }()
    
    // MARK: - Default Event
    public static let defaultEvent = RAnalyticsEvent(name: "rat.defaultEvent", parameters: ["param1": "value1"])

    // MARK: - Default State
    public static let defaultState: RAnalyticsState = {
        let defaultState = RAnalyticsState(sessionIdentifier: "CA7A88AB-82FE-40C9-A836-B1B3455DECAB",
                                           deviceIdentifier: "deviceId")

        let calendar = Calendar(identifier: .gregorian)
        var dateComponents = DateComponents(calendar: calendar,
                                            year: 2016,
                                            month: 6,
                                            day: 10,
                                            hour: 9,
                                            minute: 15,
                                            second: 30)
        let sessionStartDate = dateComponents.date

        dateComponents.day = 1
        let initialLaunchDate = dateComponents.date

        dateComponents.day = 3
        let lastLaunchDate = dateComponents.date

        dateComponents.day = 2
        let lastUpdateDate = dateComponents.date

        defaultState.advertisingIdentifier = "adId"
        defaultState.lastKnownLocation     = LocationModel(location: CLLocation(latitude: -56.6462520, longitude: -56.6462520),
                                                           isAction: false,
                                                           actionParameters: nil)
        defaultState.sessionStartDate      = sessionStartDate
        defaultState.userIdentifier        = "userId"
        defaultState.easyIdentifier        = "easyId"
        defaultState.loginMethod           = .oneTapLogin
        defaultState.origin                = .internal
        defaultState.lastVersion           = "1.0"
        defaultState.initialLaunchDate     = initialLaunchDate
        defaultState.installLaunchDate     = initialLaunchDate?.addingTimeInterval(-10)
        defaultState.lastLaunchDate        = lastLaunchDate
        defaultState.lastUpdateDate        = lastUpdateDate
        defaultState.lastVersionLaunches   = 10

        return defaultState
    }()
}

// MARK: - DeviceMock

public final class DeviceMock: NSObject, DeviceCapability {
    public override init() {
        super.init()
    }

    public var idfvUUID: String?

    public var batteryState: UIDevice.BatteryState {
        .unplugged
    }

    public var batteryLevel: Float {
        0.5
    }

    public func setBatteryMonitoring(_ value: Bool) {
    }
}

// MARK: - CarrierMock

public final class CarrierMock: NSObject, Carrierable {
    public var carrierName: String?
    public var mobileCountryCode: String?
    public var mobileNetworkCode: String?
    public var isoCountryCode: String?
    public var allowsVOIP: Bool = false

    public override init() {
        super.init()
    }
}

// MARK: - TelephonyNetworkInfoMock

public let primaryCarrier: CarrierMock = {
    let carrierMock = CarrierMock()
    carrierMock.carrierName = "Carrier1"
    carrierMock.mobileNetworkCode = "20"
    carrierMock.mobileCountryCode = "234"
    carrierMock.isoCountryCode = "fr"
    return carrierMock
}()

public let secondaryCarrier: CarrierMock = {
    let carrierMock = CarrierMock()
    carrierMock.carrierName = "Carrier2"
    carrierMock.mobileNetworkCode = "25"
    carrierMock.mobileCountryCode = "208"
    carrierMock.isoCountryCode = "gb"
    return carrierMock
}()

public final class TelephonyNetworkInfoMock: NSObject, TelephonyNetworkInfoHandleable {
    public enum Constants {
        public static let primaryCarrierKey = "0000000100000001"
        public static let secondaryCarrierKey = "0000000100000002"
    }

    public var safeDataServiceIdentifier: String? = Constants.primaryCarrierKey

    public var subscribers: [String: Carrierable]?

    public var subscriber: Carrierable? {
        primaryCarrier
    }

    public var serviceSubscriberCellularProvidersDidUpdateNotifier: ((String) -> Void)?

    public var subscriberDidUpdateNotifier: ((Carrierable) -> Void)?

    public var serviceCurrentRadioAccessTechnology: [String: String]?

    public var currentRadioAccessTechnology: String?

    public override init() {
        super.init()
    }
}

// MARK: - ApplicationMock

public final class ApplicationMock: NSObject, StatusBarOrientationGettable {
    public var injectedValue: UIInterfaceOrientation

    public init(_ injectedValue: UIInterfaceOrientation) {
        self.injectedValue = injectedValue
    }

    public var analyticsStatusBarOrientation: UIInterfaceOrientation {
        injectedValue
    }
}

// MARK: - AnalyticsManagerMock

public final class AnalyticsManagerMock: AnalyticsManageable {
    public var defaultWebViewUserAgent: String?

    public var processedEvents = [RAnalyticsEvent]()

    public init() {
    }

    public func process(_ event: RAnalyticsEvent) -> Bool {
        processedEvents.append(event)
        return true
    }

    public func tryToTrackReferralApp(with url: URL?, sourceApplication: String?) {
    }

    public func tryToTrackReferralApp(with webpageURL: URL?) {
    }
}

// MARK: - ReachabilityMock

public final class ReachabilityMock: ReachabilityType {
    public var flags: SCNetworkReachabilityFlags?

    public var connection: Reachability.Connection = .cellular

    public init() {
    }

    public func addObserver(_ observer: ReachabilityObserver) {
    }

    public func removeObserver(_ observer: ReachabilityObserver) {
    }
}

// MARK: - CookieStoreObserver

public final class CookieStoreObserver: NSObject, WKHTTPCookieStoreObservable {
    private var completion: () -> Void
    public init(completion: @escaping () -> Void) {
        self.completion = completion
    }

    public func cookiesDidChange(in cookieStore: WKHTTPCookieStorable) {
        completion()
    }
}

// MARK: - BundleMock

public final class BundleMock: NSObject, EnvironmentBundle {
    public var languageCode: Any?
    public var accountIdentifier: Int64 = 1
    public var applicationIdentifier: Int64 = 1
    public var disabledEventsAtBuildTime: [String]?
    public var duplicateAccounts: [RATAccount]?
    public var bundleIdentifier: String?
    public var useDefaultSharedCookieStorage: Bool {
        (dictionary?["RATDisableSharedCookieStorage"] as? Bool) ?? false
    }
    public var endpointAddress: URL?
    public var enableInternalSerialization: Bool { mutableEnableInternalSerialization }
    public static var assetsBundle: Bundle? { nil }
    public static var sdkComponentMap: NSDictionary? { nil }

    public var dictionary: [String: Any]?
    public var mutableEnableInternalSerialization: Bool = false

    public func object(forInfoDictionaryKey key: String) -> Any? { dictionary?[key] }

    public var appGroupId: String? {
        object(forInfoDictionaryKey: AppGroupUserDefaultsKeys.appGroupIdentifierPlistKey) as? String
    }

    public var shortVersion: String? {
        get {
            dictionary?["CFBundleShortVersionString"] as? String
        }

        set(newValue) {
            dictionary?["CFBundleShortVersionString"] = newValue
        }
    }

    public var version: String? = "1"
    public var applicationSceneManifest: RAnalytics.ApplicationSceneManifest?
    public var isWebViewAppUserAgentEnabledAtBuildtime: Bool = true

    public override init() {
        self.dictionary = [String: Any]()
    }

    public init(bundleIdentifier: String, shortVersion: String) {
        self.bundleIdentifier = bundleIdentifier
        self.dictionary = [String: Any]()
        dictionary?["CFBundleShortVersionString"] = shortVersion
    }

    /// Factory function for creating a mocked bundle
    public static func create() -> BundleMock {
        let bundle = BundleMock()
        bundle.accountIdentifier = 477
        bundle.applicationIdentifier = 1
        bundle.endpointAddress = URL(string: "https://endpoint.co.jp")
        return bundle
    }
}

// MARK: - MainDependenciesContainer

public enum MainDependenciesContainer {
    static let dependenciesContainer: SimpleContainerMock = {
        let dependenciesContainer = SimpleContainerMock()
        dependenciesContainer.bundle = BundleMock.create()
        return dependenciesContainer
    }()

    public static let ratTracker = RAnalyticsRATTracker(dependenciesContainer: dependenciesContainer)

    public static let analyticsManager: AnalyticsManager = {
        let manager = AnalyticsManager(dependenciesContainer: dependenciesContainer)
        manager.remove(RAnalyticsRATTracker.shared())
        manager.add(ratTracker)
        return manager
    }()
}

// MARK: - CoreInfosCollectorMock

public struct CoreInfosCollectorMock: CoreInfosCollectable {
    public let appInfo: String?
    public let sdkDependencies: [String: Any]?

    public init(appInfo: String?, sdkDependencies: [String: Any]?) {
        self.appInfo = appInfo
        self.sdkDependencies = sdkDependencies
    }

    public func getCollectedInfos(sdkComponentMap: NSDictionary?, allFrameworks: [RAnalytics.EnvironmentBundle]) -> [String: Any]? {
        nil
    }
}

// MARK: - ScreenMock

public final class ScreenMock: Screenable {
    private let screenBounds: CGRect

    public init(bounds: CGRect) {
        self.screenBounds = bounds
    }

    public var bounds: CGRect {
        screenBounds
    }
}

// MARK: - GeoLocationManagerMock

public final class GeoLocationManagerMock: GeoLocationManageable, GeoLocationManagerDelegate {

    public var locationModel: LocationModel!
    public var locationError: NSError!
    public var delegate: RAnalytics.GeoLocationManagerDelegate?
    public var requestLocationUserActionIsCalled = false
    public var requestLocationContinualIsCalled = false
    public var stopLocationUpdatesCalled = false
    public var startMonitoringSignificantLocationChangesIsCalled = false
    public var stopMonitoringSignificantLocationChangesIsCalled = false
    public var delegateGeoLocationManagerDidUpdateLocationIsCalled = false
    public var delegateGeoLocationManagerDidFailWithErrorIsCalled = false

    public init() {
    }

    public func stopLocationUpdates() {
        stopLocationUpdatesCalled = true
    }

    public func requestLocationUpdate(for requestType: RAnalytics.GeoRequestLocationType) {
        switch requestType {
        case .continual:
            requestLocationContinualIsCalled = true
        case .userAction:
            requestLocationUserActionIsCalled = true
        }
    }

    public func startMonitoringSignificantLocationChanges() {
        startMonitoringSignificantLocationChangesIsCalled = true
    }

    public func stopMonitoringSignificantLocationChanges() {
        stopMonitoringSignificantLocationChangesIsCalled = true
    }

    public func geoLocationManager(didUpdateLocation location: CLLocation, for requestType: GeoRequestLocationType) {
        delegateGeoLocationManagerDidUpdateLocationIsCalled = true
        switch requestType {
        case .continual:
            locationModel = LocationModel(location: location)
        case .userAction:
            locationModel = LocationModel(location: location, isAction: true)
        }
    }

    public func geoLocationManager(didFailWithError error: Error, for requestType: GeoRequestLocationType) {
        delegateGeoLocationManagerDidFailWithErrorIsCalled = true
        locationError = error as NSError
    }
}

// MARK: - MockRunLoop

public class MockRunLoop: PollerRunLoopProtocol {
    public var addedTimer: Timer?

    public init() {
    }

    public func add(timer: Timer) {
        self.addedTimer = timer
    }

    public func invalidate(timer: Timer) {
        timer.invalidate()
    }
}
