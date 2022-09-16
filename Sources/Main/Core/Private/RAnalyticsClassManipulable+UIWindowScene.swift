import UIKit
#if canImport(RSDKUtils)
import struct RSDKUtils.RLogger
#else // SPM version
import RLogger
#endif

@available(iOS 13.0, *)
extension UIWindowScene: RAnalyticsClassManipulable, RuntimeLoadable {
    /// Hold a stored property.
    ///
    /// - Note: stored properties are not allowed in Swift extensions.
    private enum Holder {
        static var analyticsManager: AnalyticsManageable = AnalyticsManager.shared()
    }

    /// Inject the AnalyticsManager.
    var analyticsManager: AnalyticsManageable {
        get {
            return Holder.analyticsManager
        }

        set(newValue) {
            Holder.analyticsManager = newValue
        }
    }

    // MARK: - RuntimeLoadable

    public static func loadSwift() {
        replaceMethod(#selector(setter: delegate),
                      inClass: self,
                      with: #selector(rAutotrackSetSceneDelegate),
                      onlyIfPresent: true)
        RLogger.verbose(message: "Installed auto-tracking hooks for UIWindowScene")
    }

    // MARK: - RAnalyticsClassManipulable

    /// The swizzled version of UIWindowScene's delegate
    @objc func rAutotrackSetSceneDelegate(_ delegate: UISceneDelegate?) {
        defer {
            if responds(to: #selector(rAutotrackSetSceneDelegate(_:))) {
                rAutotrackSetSceneDelegate(delegate)
            }
        }

        guard let unwrappedDelegate = delegate else {
            return
        }

        let recipient = type(of: unwrappedDelegate)

        UIWindowScene.swizzleSceneDelegateFunctions(recipient)
    }

    /// Swizzle the UISceneDelegate functions for tracking URL Schemes and Universal Links
    ///
    /// - Parameter sceneDelegateClassName: the scene delegate class name
    static func rAutotrackSceneDelegateFunctions(_ sceneDelegateClassName: String) {
        guard let recipient = NSClassFromString(sceneDelegateClassName) as? UISceneDelegate.Type else {
            return
        }
        swizzleSceneDelegateFunctions(recipient)
    }

    static func swizzleSceneDelegateFunctions(_ recipient: UISceneDelegate.Type) {
        UIWindowScene.replaceMethod(
            #selector(UISceneDelegate.scene(_:willConnectTo:options:)),
            inClass: recipient,
            with: #selector(rAutotrackScene(_:willConnectTo:options:)),
            onlyIfPresent: false)

        UIWindowScene.replaceMethod(
            #selector(UISceneDelegate.scene(_:openURLContexts:)),
            inClass: recipient,
            with: #selector(rAutotrackScene(_:openURLContexts:)),
            onlyIfPresent: false)

        UIWindowScene.replaceMethod(
            #selector(UISceneDelegate.scene(_:continue:)),
            inClass: recipient,
            with: #selector(rAutotrackScene(_:continue:)),
            onlyIfPresent: false)
    }

    /// This delegate method is called when the app is opened from a URL Scheme or a Universal Link.
    ///
    /// - Note: This callback is called when the app is launched
    @objc func rAutotrackScene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        // URL Scheme
        let url = UIOpenURLContext.DefaultValues.url ?? connectionOptions.urlContexts.first?.url
        let sourceApplication = UIOpenURLContext.DefaultValues.sourceApplication ?? connectionOptions.urlContexts.first?.options.sourceApplication
        analyticsManager.tryToTrackReferralApp(with: url, sourceApplication: sourceApplication)

        // Universal Link
        analyticsManager.tryToTrackReferralApp(with: connectionOptions.userActivities.first?.webpageURL)

        // Delegates may not implement the original method
        if responds(to: #selector(rAutotrackScene(_:willConnectTo:options:))) {
            return rAutotrackScene(scene,
                                   willConnectTo: session,
                                   options: connectionOptions)
        }
    }

    /// This delegate method is called when the app is opened from a URL Scheme.
    ///
    /// - Note: This callback is not called when the app is launched. It is called when the app is already running.
    @objc func rAutotrackScene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
        let url = UIOpenURLContext.DefaultValues.url ?? URLContexts.first?.url
        let sourceApplication = UIOpenURLContext.DefaultValues.sourceApplication ?? URLContexts.first?.options.sourceApplication
        analyticsManager.tryToTrackReferralApp(with: url,
                                               sourceApplication: sourceApplication)

        // Delegates may not implement the original method
        if responds(to: #selector(rAutotrackScene(_:openURLContexts:))) {
            return rAutotrackScene(scene, openURLContexts: URLContexts)
        }
    }

    /// This delegate method is called when the app is opened from a Universal Link.
    ///
    /// - Note: This callback is not called when the app is launched. It is called when the app is already running.
    @objc func rAutotrackScene(_ scene: UIScene, continue userActivity: NSUserActivity) {
        analyticsManager.tryToTrackReferralApp(with: userActivity.webpageURL)

        // Delegates may not implement the original method
        if responds(to: #selector(rAutotrackScene(_:continue:))) {
            return rAutotrackScene(scene, continue: userActivity)
        }
    }
}

@available(iOS 13.0, *)
extension UIOpenURLContext {
    /// As `UIOpenURLContext`'s init is unavailable, this property below is used to inject the URL.
    ///
    /// - Warning: `UIOpenURLContext.DefaultValues` is only for internal use.
    enum DefaultValues {
        static var url: URL?
        static var sourceApplication: String?
    }
}
