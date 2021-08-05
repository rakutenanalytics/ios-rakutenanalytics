import Foundation

protocol Trackable {
    func trackEvent(name: String, parameters: [String: Any]?)
}

final class AnalyticsTracker: NSObject, Trackable {
    func trackEvent(name: String, parameters: [String: Any]?) {
        AnalyticsManager.Event(name: name, parameters: parameters).track()
    }
}
