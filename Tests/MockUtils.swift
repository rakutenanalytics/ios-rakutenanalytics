import Foundation
import CoreLocation
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

final class SessionMock: RAnalyticsSessionable {
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

final class SwityURLSessionMock: SwiftySessionable {
    var urlRequest: URLRequest?

    func dataTask(with request: URLRequest, completionHandler: @escaping (Result<(data: Data?, response: URLResponse), Error>) -> Void) -> URLSessionTaskable {
        self.urlRequest = request
        completionHandler(.success((nil, URLResponse())))
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
    var endpointURL: URL = URL(string: "https://endpoint.co.jp")!

    override init() {
        super.init()
    }

    func process(event: RAnalyticsEvent, state: RAnalyticsState) -> Bool {
        false
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

// MARK: - Simple Container Mock

final class SimpleContainerMock: NSObject, SimpleDependenciesContainable {
    public let notificationHandler: NotificationObservable = NotificationCenter.default
    public let userStorageHandler: UserStorageHandleable = UserDefaultsMock()
    public let adIdentifierManager: AdvertisementIdentifiable = ASIdentifierManagerMock()
    public let httpCookieStore: WKHTTPCookieStorable = WKHTTPCookieStorageMock()
    public let keychainHandler: KeychainHandleable = KeychainHandlerMock()
    public let analyticsTracker = AnalyticsTrackerMock()
    public let locationManager: LocationManageable = LocationManagerMock()
    public let bundle: EnvironmentBundle = Bundle.main
    public let tracker: Trackable = AnalyticsTrackerMock()
}
