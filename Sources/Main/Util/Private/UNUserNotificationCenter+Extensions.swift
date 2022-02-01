import Foundation
import UserNotifications

extension UNUserNotificationCenter {
    /// Check if the UNUserNotificationCenter's delegate is implemented.
    ///
    /// - Returns: true if the UNUserNotificationCenter's delegate is implemented., false if the UNUserNotificationCenter's delegate is not implemented.
    static var notificationsAreHandledByUNDelegate: Bool {
        // UNUserNotificationCenter.current() crashes if the target is run from a Launch Agent
        guard Bundle.main.bundleIdentifier != "com.apple.dt.xctest.tool" else {
            return false
        }
        let selector = #selector(UNUserNotificationCenterDelegate.userNotificationCenter(_:didReceive:withCompletionHandler:))
        return UNUserNotificationCenter.current().delegate?.responds(to: selector) ?? false
    }
}
