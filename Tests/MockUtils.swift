import Foundation
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

// MARK: - External Collector Factory

struct ExternalCollectorFactory {
    static func mock() -> RAnalyticsExternalCollector? {
        let container = AnyDependenciesContainer()
        container.registerObject(UserDefaultsMock([:]))
        container.registerObject(AnalyticsTrackerMock())
        return RAnalyticsExternalCollector(dependenciesFactory: container)
    }
}

// MARK: - Session

final class SessionMock: Sessionable {
    var willComplete: (() -> Void?)?
    var response: HTTPURLResponse?
    func createDataTask(with request: URLRequest, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) -> URLSessionTaskable {
        willComplete?()
        completionHandler(nil, response, nil)
        return URLSessionTaskMock()
    }
}

// MARK: - URL Session Task

final class URLSessionTaskMock: URLSessionTaskable {
    func resume() {}
}

// MARK: - HTTP Cookie Storage

final class HTTPCookieStorageMock: HTTPCookieStorable {
    var cookiesArray: [HTTPCookie]?

    func cookies(for URL: URL) -> [HTTPCookie]? {
        cookiesArray
    }
}
