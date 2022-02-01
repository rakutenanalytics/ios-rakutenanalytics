import UserNotifications
#if canImport(RSDKUtils)
import struct RSDKUtils.RLogger
#else // SPM version
import RLogger
#endif

#if canImport(UserNotifications)
let rSDKABuildUserNotificationSupport = true
#else
let rSDKABuildUserNotificationSupport = false
#endif

extension UNUserNotificationCenter: RAnalyticsClassManipulable, RuntimeLoadable {

    @objc public static func loadSwift() {
        guard rSDKABuildUserNotificationSupport else {
            return
        }

        replaceMethod(#selector(setter: delegate),
                      inClass: self,
                      with: #selector(rAutotrackSetUserNotificationCenterDelegate),
                      onlyIfPresent: true)
        RLogger.verbose(message: "Installed auto-tracking hooks for UNNotificationCenter")
    }

    @objc(rAutotrackUserNotificationCenter:didReceiveNotificationResponse:withCompletionHandler:)
    func rAutotrackUserNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void) {

        AnalyticsManager.shared().launchCollector.processPushNotificationResponse(response)
        if responds(to: #selector(rAutotrackUserNotificationCenter(_:didReceive:withCompletionHandler:))) {
            rAutotrackUserNotificationCenter(center,
                                             didReceive: response,
                                             withCompletionHandler: completionHandler)
        }
    }

    @objc func rAutotrackSetUserNotificationCenterDelegate(_ delegate: UNUserNotificationCenterDelegate?) {

        RLogger.verbose(message: "User notification center delegate is being set to %@ \(String(describing: delegate))")
        let swizzleSelector = #selector(rAutotrackUserNotificationCenter(_:didReceive:withCompletionHandler:))
        let delegateSelector = #selector(UNUserNotificationCenterDelegate.userNotificationCenter(_:didReceive:withCompletionHandler:))

        // set swizzle if currently not swizzled
        if let unwrappedDelegate = delegate,
           !unwrappedDelegate.responds(to: swizzleSelector) {
            UNUserNotificationCenter.replaceMethod(delegateSelector,
                                                   inClass: type(of: unwrappedDelegate),
                                                   with: swizzleSelector,
                                                   onlyIfPresent: true)
        }

        rAutotrackSetUserNotificationCenterDelegate(delegate)
    }
}
