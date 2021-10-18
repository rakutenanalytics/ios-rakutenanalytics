import Foundation
import CoreLocation
import CoreTelephony
import AdSupport
import WebKit
import RSDKUtils
@testable import RAnalytics

// MARK: - Tracker

struct TrackerResult {
    let tracked: Bool
    let parameters: [String: Any]?
}

final class AnalyticsTrackerMock: NSObject, Trackable {
    var dictionary: [String: TrackerResult]?
    private(set) var eventName: String?
    private(set) var params: [String: Any]?
    func trackEvent(name: String, parameters: [String: Any]?) {
        eventName = name
        params = parameters
        dictionary?[name] = TrackerResult(tracked: true, parameters: parameters)
    }
    func reset() {
        dictionary = nil
        eventName = nil
        params = nil
    }
}

// MARK: - ASIdentifierManagerMock

final class ASIdentifierManagerMock: NSObject, AdvertisementIdentifiable {
    var advertisingIdentifierUUIDString: String = ""
}

// MARK: - WKHTTP Cookie Storage

final class WKHTTPCookieStorageMock: WKHTTPCookieStorable {
    func allCookies(_ completionHandler: @escaping ([HTTPCookie]) -> Void) {
    }

    func set(cookie: HTTPCookie, completionHandler: (() -> Void)?) {
    }

    func delete(cookie: HTTPCookie, completionHandler: (() -> Void)?) {
    }
}

// MARK: - User Defaults

final class UserDefaultsMock: NSObject {
    var dictionary: [String: Any]?
    convenience init(_ dictionary: [String: Any]) {
        self.init()
        self.dictionary = dictionary
    }
}

extension UserDefaultsMock: UserStorageHandleable {
    convenience init?(suiteName suitename: String?) {
        guard suitename != nil else {
            return nil
        }
        self.init()
    }
    func dictionary(forKey defaultName: String) -> [String: Any]? { dictionary?[defaultName] as? [String: Any] }
    func set(value: Any?, forKey key: String) { dictionary?[key] = value }
    func removeObject(forKey defaultName: String) { dictionary?[defaultName] = nil }
    func object(forKey defaultName: String) -> Any? { dictionary?[defaultName] }
    func string(forKey defaultName: String) -> String? { dictionary?[defaultName] as? String }
    func bool(forKey defaultName: String) -> Bool {
        guard let result = dictionary?[defaultName] as? Bool else {
            return false
        }
        return result
    }
    func synchronize() -> Bool { true }
}

// MARK: - Session

final class SessionMock: Sessionable {
    var willComplete: (() -> Void?)?
    var data: Data?
    var response: HTTPURLResponse?
    var error: Error?
    func createDataTask(with request: URLRequest, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) -> URLSessionTaskable {
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

final class SwityURLSessionMock: NSObject, SwiftySessionable {
    var urlRequest: URLRequest?
    var response: URLResponse?
    var completion: (() -> Void)?

    func dataTask(with request: URLRequest, completionHandler: @escaping (Result<(data: Data?, response: URLResponse), Error>) -> Void) -> URLSessionTaskable {
        self.urlRequest = request
        completionHandler(.success((nil, response ?? URLResponse())))
        completion?()
        return URLSessionTaskMock()
    }
}

// MARK: - HTTP Cookie Storage

final class HTTPCookieStorageMock: HTTPCookieStorable {
    var cookiesArray: [HTTPCookie]?

    func cookies(for URL: URL) -> [HTTPCookie]? {
        cookiesArray
    }
}

// MARK: - Tracker

final class TrackerMock: NSObject, Tracker {
    var state: RAnalyticsState?
    var endpointURL: URL? = URL(string: "https://endpoint.co.jp")

    func process(event: RAnalyticsEvent, state: RAnalyticsState) -> Bool {
        self.state = state
        return true
    }
}

// MARK: - Location Manager

final class LocationManagerMock: NSObject, LocationManageable {
    static func authorizationStatus() -> CLAuthorizationStatus {
        .authorizedAlways
    }
    var desiredAccuracy: CLLocationAccuracy = 0.0
    weak var delegate: CLLocationManagerDelegate?
    var location: CLLocation?
    var startUpdatingLocationIsCalled = false
    var stopUpdatingLocationIsCalled = false

    func startUpdatingLocation() {
        startUpdatingLocationIsCalled = true
    }

    func stopUpdatingLocation() {
        stopUpdatingLocationIsCalled = true
    }
}

// MARK: - Keychain Handler

final class KeychainHandlerMock: NSObject, KeychainHandleable {
    var status: OSStatus = errSecItemNotFound
    private var creationDate: Date?
    func item(for label: String) -> KeychainResult { KeychainResult(result: nil, status: status) }
    func set(creationDate: Date?, for label: String) { self.creationDate = creationDate }
    func creationDate(for reference: CFTypeRef?) -> Date? { creationDate }
}

// MARK: - SimpleContainerMock

final class SimpleContainerMock: NSObject, SimpleDependenciesContainable {
    enum Constants {
        static let RATDatabaseName = "RSDKAnalytics.db"
        static let RATTableName = "RAKUTEN_ANALYTICS_TABLE"
    }

    public var notificationHandler: NotificationObservable = NotificationCenter.default
    public var userStorageHandler: UserStorageHandleable = UserDefaults.standard
    public var adIdentifierManager: AdvertisementIdentifiable = ASIdentifierManager.shared()
    public var wkHttpCookieStore: WKHTTPCookieStorable = WKWebsiteDataStore.default().httpCookieStore
    public var httpCookieStore: HTTPCookieStorable = HTTPCookieStorage.shared
    public var keychainHandler: KeychainHandleable = KeychainHandler()
    public var locationManager: LocationManageable = CLLocationManager()
    public var bundle: EnvironmentBundle = Bundle.main
    public var tracker: Trackable = AnalyticsTracker()
    public var telephonyNetworkInfoHandler: TelephonyNetworkInfoHandleable = CTTelephonyNetworkInfo()
    public var deviceCapability: DeviceCapability = UIDevice.current
    public var screenHandler: Screenable = UIScreen.main
    public var session: SwiftySessionable = URLSession.shared
    public var analyticsStatusBarOrientationGetter: StatusBarOrientationGettable? = UIApplication.RAnalyticsSharedApplication
    public var databaseConfiguration: DatabaseConfigurable? = {
        DatabaseConfigurationHandler.create(databaseName: Constants.RATDatabaseName,
                                            tableName: Constants.RATTableName,
                                            databaseParentDirectory: .documentDirectory)
    }()
}

// MARK: - CustomPage

final class CustomPage: UIViewController {
}

// MARK: - Tracking

enum Tracking {
    // MARK: - Default Event
    static let defaultEvent = RAnalyticsEvent(name: "rat.defaultEvent", parameters: ["param1": "value1"])

    // MARK: - Default State
    static let defaultState: RAnalyticsState = {
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
        defaultState.lastKnownLocation     = CLLocation(latitude: -56.6462520, longitude: -56.6462520)
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

        let currentPage = CustomPage()
        currentPage.view.frame = CGRect(x: 0, y: 0, width: 200, height: 200)
        defaultState.referralTracking = .page(currentPage: currentPage)

        return defaultState
    }()
}

// MARK: - DeviceMock

final class DeviceMock: NSObject, DeviceCapability {
    var batteryState: UIDevice.BatteryState {
        .unplugged
    }

    var batteryLevel: Float {
        0.5
    }

    func setBatteryMonitoring(_ value: Bool) {
    }
}

// MARK: - CarrierMock

final class CarrierMock: NSObject, Carrierable {
    var carrierName: String?
    var mobileCountryCode: String?
    var mobileNetworkCode: String?
    var isoCountryCode: String?
    var allowsVOIP: Bool = false
}

// MARK: - TelephonyNetworkInfoMock

let primaryCarrier: CarrierMock = {
    let carrierMock = CarrierMock()
    carrierMock.carrierName = "Carrier1"
    carrierMock.mobileNetworkCode = "20"
    carrierMock.mobileCountryCode = "234"
    carrierMock.isoCountryCode = "fr"
    return carrierMock
}()

let secondaryCarrier: CarrierMock = {
    let carrierMock = CarrierMock()
    carrierMock.carrierName = "Carrier2"
    carrierMock.mobileNetworkCode = "25"
    carrierMock.mobileCountryCode = "208"
    carrierMock.isoCountryCode = "gb"
    return carrierMock
}()

final class TelephonyNetworkInfoMock: NSObject, TelephonyNetworkInfoHandleable {
    enum Constants {
        static let primaryCarrierKey = "0000000100000001"
        static let secondaryCarrierKey = "0000000100000002"
    }

    var dataServiceIdentifier: String? = Constants.primaryCarrierKey

    var subscribers: [String: Carrierable]?

    var subscriber: Carrierable? {
        primaryCarrier
    }

    var serviceSubscriberCellularProvidersDidUpdateNotifier: ((String) -> Void)?

    var subscriberDidUpdateNotifier: ((Carrierable) -> Void)?

    var serviceCurrentRadioAccessTechnology: [String: String]?

    var currentRadioAccessTechnology: String?
}

// MARK: - ApplicationMock

final class ApplicationMock: NSObject, StatusBarOrientationGettable {
    var injectedValue: UIInterfaceOrientation

    init(_ injectedValue: UIInterfaceOrientation) {
        self.injectedValue = injectedValue
    }

    var analyticsStatusBarOrientation: UIInterfaceOrientation {
        injectedValue
    }
}
