import Foundation

extension NSObject {
    static var ratTracker: Tracker? {
        if let ratTrackerClass = NSClassFromString("RAnalyticsRATTracker") as? NSObject.Type {
            let selector = NSSelectorFromString("sharedInstance")
            if ratTrackerClass.responds(to: selector) {
                return ratTrackerClass.perform(selector)?.takeUnretainedValue() as? Tracker
            }
        }
        return nil
    }
}
