import Foundation

extension UNUserNotificationCenter {
    /// Check if the UNUserNotificationCenter's delegate is implemented.
    ///
    /// - Returns: true if the UNUserNotificationCenter's delegate is implemented., false if the UNUserNotificationCenter's delegate is not implemented.
    static var notificationsAreHandledByUNDelegate: Bool {
        let selector = #selector(UNUserNotificationCenterDelegate.userNotificationCenter(_:didReceive:withCompletionHandler:))
        return UNUserNotificationCenter.current().delegate?.responds(to: selector) ?? false
    }
}
