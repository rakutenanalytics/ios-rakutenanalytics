import Foundation
import UIKit

extension NSObject {
    /// Check if an object is kind of a given class name.
    ///
    /// - Parameters:
    ///   - className: The class name.
    ///
    /// - Returns: A boolean.
    func isKind(of className: String) -> Bool {
        guard let aClass = NSClassFromString(className),
              isKind(of: aClass.self) else {
            return false
        }
        return true
    }

    /// Check if an object is an Apple class.
    ///
    /// - Returns: A boolean.
    func isAppleClass() -> Bool {
        NSObject.isAppleClass(type(of: self).self)
    }

    /// Check if an object is an Apple private class.
    ///
    /// - Returns: A boolean.
    func isApplePrivateClass() -> Bool {
        NSObject.isApplePrivateClass(type(of: self).self)
    }
}

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
