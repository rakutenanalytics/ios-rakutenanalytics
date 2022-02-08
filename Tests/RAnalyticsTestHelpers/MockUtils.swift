import Foundation
import CoreLocation
import CoreTelephony
import AdSupport
import WebKit

#if canImport(RSDKUtils)
@testable import RSDKUtils
#else // SPM version
@testable import RSDKUtilsMain
#endif

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

// MARK: - WKHTTP Cookie Storage

final class WKHTTPCookieStorageMock: WKHTTPCookieStorable {
    func allCookies(_ completionHandler: @escaping ([HTTPCookie]) -> Void) {
        // no-op
    }

    func set(cookie: HTTPCookie, completionHandler: (() -> Void)?) {
        // no-op
    }

    func delete(cookie: HTTPCookie, completionHandler: (() -> Void)?) {
        // no-op
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
    public func synchronize() -> Bool { true }
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
    public var state: RAnalyticsState?
    public var endpointURL: URL? = URL(string: "https://endpoint.co.jp")

    public override init() {
        super.init()
    }

    public func process(event: RAnalyticsEvent, state: RAnalyticsState) -> Bool {
        self.state = state
        return true
    }
}

// MARK: - Location Manager

public final class LocationManagerMock: NSObject, LocationManageable {
    public static func authorizationStatus() -> CLAuthorizationStatus {
        .authorizedAlways
    }
    public var desiredAccuracy: CLLocationAccuracy = 0.0
    public weak var delegate: CLLocationManagerDelegate?
    public var location: CLLocation?
    public var startUpdatingLocationIsCalled = false
    public var stopUpdatingLocationIsCalled = false

    public override init() {
        super.init()
    }

    public func startUpdatingLocation() {
        startUpdatingLocationIsCalled = true
    }

    public func stopUpdatingLocation() {
        stopUpdatingLocationIsCalled = true
    }
}

// MARK: - Keychain Handler

public final class KeychainHandlerMock: NSObject, KeychainHandleable {
    public var status: OSStatus = errSecItemNotFound
    private var creationDate: Date?

    public override init() {
        super.init()
    }

    public func item(for label: String) -> KeychainResult { KeychainResult(result: nil, status: status) }
    public func set(creationDate: Date?, for label: String) { self.creationDate = creationDate }
    public func creationDate(for reference: CFTypeRef?) -> Date? { creationDate }
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
        DatabaseConfigurationHandler.create(databaseName: Constants.ratDatabaseName,
                                            tableName: Constants.ratTableName,
                                            databaseParentDirectory: .documentDirectory)
    }()
    public var pushEventHandler: PushEventHandleable
    public var fileManager: FileManageable = FileManager.default
    public var serializerType: JSONSerializable.Type = JSONSerialization.self

    public override init() {
        let appGroupId = bundle.appGroupId
        let sharedUserStorageHandler = sharedUserStorageHandlerType.init(suiteName: appGroupId)
        pushEventHandler = PushEventHandler(sharedUserStorageHandler: sharedUserStorageHandler,
                                            appGroupId: appGroupId)
        super.init()
    }
}

// MARK: - CustomPage

public final class CustomPage: UIViewController {
    public init() {
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

// MARK: - Tracking

public enum Tracking {
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

public final class DeviceMock: NSObject, DeviceCapability {
    public override init() {
        super.init()
    }

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

// MARK: - FileManagerMock

public final class FileManagerMock: FileManageable {
    public var mockedContainerURL: URL?
    public var fileExists = true

    public init() {
    }

    public func createSafeFile(at url: URL) {
    }

    public func containerURL(forSecurityApplicationGroupIdentifier groupIdentifier: String) -> URL? {
        mockedContainerURL
    }

    public func fileExists(atPath path: String) -> Bool {
        fileExists
    }

    public func removeItem(at url: URL) throws {
        // no-op
    }
}

// MARK: - JSONSerializationMock

public final class JSONSerializationMock: JSONSerializable {
    public static var mockedData: Data?
    public static var mockedJsonObject: Any = [[String: Any]]()
    public static var error: Error?

    public static func data(withJSONObject obj: Any, options opt: JSONSerialization.WritingOptions) throws -> Data {
        if let error = error {
            throw error
        }
        return mockedData ?? Data()
    }

    public static func jsonObject(with data: Data, options opt: JSONSerialization.ReadingOptions) throws -> Any {
        if let error = error {
            throw error
        }
        return mockedJsonObject
    }
}

// MARK: - AnalyticsManagerMock

public final class AnalyticsManagerMock: AnalyticsManageable {
    public var processedEvents = [RAnalyticsEvent]()

    public init() {
    }

    public func process(_ event: RAnalyticsEvent) -> Bool {
        processedEvents.append(event)
        return true
    }
}

// MARK: - ReachabilityMock

public final class ReachabilityMock: ReachabilityType {
    public var connection: Reachability.Connection = .cellular

    public init() {
    }

    public func addObserver(_ observer: ReachabilityObserver) {
    }

    public func removeObserver(_ observer: ReachabilityObserver) {
    }
}
