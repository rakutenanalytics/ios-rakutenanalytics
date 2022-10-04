import Foundation

protocol Trackable: AnyObject {
    func trackEvent(name: String, parameters: [String: Any]?)
}

extension AnalyticsManager: Trackable {
    func trackEvent(name: String, parameters: [String: Any]?) {
        let event = AnalyticsManager.Event(name: name, parameters: parameters)
        process(event)
    }
}
