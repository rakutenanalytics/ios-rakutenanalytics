import UserNotifications
import RLogger

// This mimics RSDKA_BUILD_USER_NOTIFICATION_SUPPORT preprocessor macro in RAnalyticsDefines.h
#if canImport(UserNotifications)
let RSDKABuildUserNotificationSupport = true
#else
let RSDKABuildUserNotificationSupport = false
#endif

extension UNUserNotificationCenter: RAnalyticsClassManipulable, RuntimeLoadable {

    // swiftlint:disable:next identifier_name
    @objc public static var RAnalyticsNotificationsAreHandledByUNDelegate: Bool {
        guard RSDKABuildUserNotificationSupport else {
            return false
        }

        let delegateSelector = #selector(UNUserNotificationCenterDelegate.userNotificationCenter(_:didReceive:withCompletionHandler:))
        return UNUserNotificationCenter.current().delegate?.responds(to: delegateSelector) ?? false
    }

    @objc public static func loadSwift() {
        guard RSDKABuildUserNotificationSupport else {
            return
        }

        replaceMethod(#selector(setter: delegate),
                      inClass: self,
                      with: #selector(r_autotrack_setUserNotificationCenterDelegate),
                      onlyIfPresent: true)
        RLogger.verbose("Installed auto-tracking hooks for UNNotificationCenter")
    }

    @objc(r_autotrack_userNotificationCenter:didReceiveNotificationResponse:withCompletionHandler:)
    func r_autotrack_userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void) {

        _RAnalyticsLaunchCollector.sharedInstance().processPush(response)
        if responds(to: #selector(r_autotrack_userNotificationCenter(_:didReceive:withCompletionHandler:))) {
            r_autotrack_userNotificationCenter(center,
                                               didReceive: response,
                                               withCompletionHandler: completionHandler)
        }
    }

    @objc func r_autotrack_setUserNotificationCenterDelegate(_ delegate: UNUserNotificationCenterDelegate?) {

        RLogger.verbose("User notification center delegate is being set to %@ \(String(describing: delegate))")
        let swizzleSelector = #selector(r_autotrack_userNotificationCenter(_:didReceive:withCompletionHandler:))
        let delegateSelector = #selector(UNUserNotificationCenterDelegate.userNotificationCenter(_:didReceive:withCompletionHandler:))

        // set swizzle if currently not swizzled
        if let unwrappedDelegate = delegate,
           !unwrappedDelegate.responds(to: swizzleSelector) {
            UNUserNotificationCenter.replaceMethod(delegateSelector,
                                                   inClass: type(of: unwrappedDelegate),
                                                   with: swizzleSelector,
                                                   onlyIfPresent: true)
        }

        r_autotrack_setUserNotificationCenterDelegate(delegate)
    }
}
