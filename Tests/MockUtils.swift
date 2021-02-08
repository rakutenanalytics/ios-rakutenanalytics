import Foundation
import RAnalytics

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

final class UserDefaultsMock: NSObject, UserStorageHandleable {
    var dictionary: [String: Any]?
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
