import Foundation

@objc public protocol Trackable {
    func trackEvent(name: String, parameters: [String: Any]?)
}

public final class AnalyticsTracker: NSObject, Trackable {
    public func trackEvent(name: String, parameters: [String: Any]?) {
        AnalyticsManager.Event(name: name, parameters: parameters).track()
    }
}
