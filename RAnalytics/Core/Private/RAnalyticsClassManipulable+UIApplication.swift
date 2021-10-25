import UIKit
import struct RSDKUtils.RLogger

extension UIApplication: RAnalyticsClassManipulable, RuntimeLoadable {

    @objc public static func loadSwift() {
        replaceMethod(#selector(setter: delegate),
                      inClass: self,
                      with: #selector(r_autotrack_setApplicationDelegate),
                      onlyIfPresent: true)
        RLogger.verbose(message: "Installed auto-tracking hooks for UIApplication")
    }

    // MARK: Added to UIApplicationDelegate
    @objc func r_autotrack_application(
        _ application: UIApplication,
        willFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        RLogger.verbose(message: "Application will finish launching with options = \(String(describing: launchOptions))")

        // In any case, it is needed to keep the loading of AnalyticsManager singleton here
        // in `r_autotrack_application(application:willFinishLaunchingWithOptions:)`
        // because automatic events have to be tracked when the app is launched
        _ = AnalyticsManager.shared()

        AnalyticsManager.shared().launchCollector.origin = .internal

        // Delegates may not implement the original method
        if responds(to: #selector(r_autotrack_application(_:willFinishLaunchingWithOptions:))) {
            return r_autotrack_application(application,
                                           willFinishLaunchingWithOptions: launchOptions)
        }
        return true
    }

    @objc func r_autotrack_application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {

        RLogger.verbose(message: "Application did finish launching with options = \(String(describing: launchOptions))")

        AnalyticsManager.shared().launchCollector.origin = .internal

        // Delegates may not implement the original method
        if responds(to: #selector(r_autotrack_application(_:didFinishLaunchingWithOptions:))) {
            return r_autotrack_application(application,
                                           didFinishLaunchingWithOptions: launchOptions)
        }
        return true
    }

    /*
     * Methods below are only added if the delegate implements the original method.
     */
    @objc func r_autotrack_application(_ application: UIApplication,
                                       handleOpen url: URL) -> Bool {
        RLogger.verbose(message: "Application was asked to open URL \(url.absoluteString)")

        AnalyticsManager.shared().launchCollector.origin = .external

        AnalyticsManager.shared().trackReferralApp(url: url)

        // Delegates may not implement the original method
        if responds(to: #selector(r_autotrack_application(_:handleOpen:))) {
            return r_autotrack_application(application, handleOpen: url)
        }
        return true
    }

    @objc func r_autotrack_application(_ app: UIApplication,
                                       open url: URL,
                                       options: [UIApplication.OpenURLOptionsKey: Any] = [:]) -> Bool {
        RLogger.verbose(message: "Application was asked to open URL \(url.absoluteString) with options =  \(options)")

        AnalyticsManager.shared().launchCollector.origin = .external

        AnalyticsManager.shared().trackReferralApp(url: url, sourceApplication: options[.sourceApplication] as? String)

        // Delegates may not implement the original method
        if responds(to: #selector(r_autotrack_application(_:open:options:))) {
            return r_autotrack_application(app, open: url, options: options)
        }
        return true
    }

    @objc func r_autotrack_application(_ application: UIApplication,
                                       open url: URL,
                                       sourceApplication: String?,
                                       annotation: Any) -> Bool {
        let message = "Application was asked by \(sourceApplication ?? "nil") to open URL \(url.absoluteString) with annotation \(annotation)"
        RLogger.verbose(message: message)

        AnalyticsManager.shared().launchCollector.origin = .external

        AnalyticsManager.shared().trackReferralApp(url: url, sourceApplication: sourceApplication)

        // Delegates may not implement the original method
        if responds(to: #selector(r_autotrack_application(_:open:sourceApplication:annotation:))) {
            return r_autotrack_application(application,
                                           open: url,
                                           sourceApplication: sourceApplication,
                                           annotation: annotation)
        }
        return true
    }

    @objc func r_autotrack_application(
        _ application: UIApplication,
        continue userActivity: NSUserActivity,
        restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void) -> Bool {

        RLogger.verbose(message: "Application was asked to continue user activity \(userActivity.debugDescription)")

        AnalyticsManager.shared().launchCollector.origin = .external

        if let url = userActivity.webpageURL {
            AnalyticsManager.shared().trackReferralApp(url: url)
        }

        // Delegates may not implement the original method
        if responds(to: #selector(r_autotrack_application(_:continue:restorationHandler:))) {
            return r_autotrack_application(application,
                                           continue: userActivity,
                                           restorationHandler: restorationHandler)
        }
        return true
    }

    /*
     * Swizzle didReceiveRemoteNotification. This was deprecated in iOS version 10.
     * This won't be called if Application Delegate was implemented:
     * application:didReceiveRemoteNotification:fetchCompletionHandler:
     *
     * or
     *
     * UNUserNotificationCenter delegate method was implemented:
     * userNotificationCenter:didReceiveNotificationResponse:withCompletionHandler:
     */
    @objc func r_autotrack_application(_ application: UIApplication,
                                       didReceiveRemoteNotification userInfo: [AnyHashable: Any]) {

        RLogger.verbose(message: "Application did receive remote notification \(userInfo)")

        AnalyticsManager.shared().launchCollector.handleTapNonUNUserNotification(
            userInfo,
            appState: application.applicationState)

        // If we're executing this, the original method exists
        r_autotrack_application(application, didReceiveRemoteNotification: userInfo)
    }

    /*
     * Swizzle application:didReceiveRemoteNotification:fetchCompletionHandler:
     * if UNUserNotificationCenter delegate was set
     * - this will only be called for background or silent push notifications.
     *
     * else:
     *
     * - this will be called for all push notifications when the app is launched
     */
    @objc func r_autotrack_application(
        _ application: UIApplication,
        didReceiveRemoteNotification userInfo: [AnyHashable: Any],
        fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {

        RLogger.verbose(message: "Application did receive remote notification \(userInfo)")

        AnalyticsManager.shared().launchCollector.handleTapNonUNUserNotification(
            userInfo,
            appState: application.applicationState)

        // If we're executing this, the original method exists
        r_autotrack_application(application,
                                didReceiveRemoteNotification: userInfo,
                                fetchCompletionHandler: completionHandler)
    }

    // MARK: Added to UIApplication
    @objc func r_autotrack_setApplicationDelegate(_ delegate: UIApplicationDelegate?) {

        RLogger.verbose(message: "Application delegate is being set to \(String(describing: delegate))")

        defer {
            r_autotrack_setApplicationDelegate(delegate)
        }

        guard let unwrappedDelegate = delegate,
              !unwrappedDelegate.responds(to:
                                            #selector(r_autotrack_application(_:willFinishLaunchingWithOptions:))),
              !unwrappedDelegate.responds(to:
                                            #selector(r_autotrack_application(_:didFinishLaunchingWithOptions:))) else {
            // This delegate has already been extended.
            return
        }

        let recipient = type(of: unwrappedDelegate)
        UIApplication.replaceMethod(
            #selector(UIApplicationDelegate.application(_:willFinishLaunchingWithOptions:)),
            inClass: recipient,
            with: #selector(r_autotrack_application(_:willFinishLaunchingWithOptions:)),
            onlyIfPresent: false)

        UIApplication.replaceMethod(
            #selector(UIApplicationDelegate.application(_:didFinishLaunchingWithOptions:)),
            inClass: recipient,
            with: #selector(r_autotrack_application(_:didFinishLaunchingWithOptions:)),
            onlyIfPresent: false)

        UIApplication.replaceMethod(
            #selector(UIApplicationDelegate.application(_:handleOpen:)),
            inClass: recipient,
            with: #selector(r_autotrack_application(_:handleOpen:)),
            onlyIfPresent: false)

        UIApplication.replaceMethod(
            #selector(UIApplicationDelegate.application(_:open:options:)),
            inClass: recipient,
            with: #selector(r_autotrack_application(_:open:options:)),
            onlyIfPresent: false)

        UIApplication.replaceMethod(
            #selector(UIApplicationDelegate.application(_:open:sourceApplication:annotation:)),
            inClass: recipient,
            with: #selector(r_autotrack_application(_:open:sourceApplication:annotation:)),
            onlyIfPresent: false)

        UIApplication.replaceMethod(
            #selector(UIApplicationDelegate.application(_:continue:restorationHandler:)),
            inClass: recipient,
            with: #selector(r_autotrack_application(_:continue:restorationHandler:)),
            onlyIfPresent: false)

        /*
         * Attention: The selectors below should _only_ be swizzled if the delegate responds to
         * them (i.e. onlyIfPresent = true).
         */

        UIApplication.replaceMethod(
            #selector(UIApplicationDelegate.application(_:didReceiveRemoteNotification:)),
            inClass: recipient,
            with: #selector(r_autotrack_application(_:didReceiveRemoteNotification:)),
            onlyIfPresent: true)

        UIApplication.replaceMethod(
            #selector(UIApplicationDelegate.application(_:didReceiveRemoteNotification:fetchCompletionHandler:)),
            inClass: recipient,
            with: #selector(r_autotrack_application(_:didReceiveRemoteNotification:fetchCompletionHandler:)),
            onlyIfPresent: true)
    }
}
