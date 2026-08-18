import UIKit

extension UIWindowScene: RuntimeLoadable {
    /// Hold a stored property.
    ///
    /// - Note: stored properties are not allowed in Swift extensions.
    private enum Holder {
        static var analyticsManager: ReferralAppTrackable?
        static var swizzledSceneDelegateClasses = Set<ObjectIdentifier>()
    }

    /// Returns the analytics manager for scene-delegate tracking callbacks.
    var analyticsManager: ReferralAppTrackable {
        get {
            if let analyticsManager = Holder.analyticsManager {
                return analyticsManager
            }
            let analyticsManager = AnalyticsManager.shared()
            Holder.analyticsManager = analyticsManager
            return analyticsManager
        }

        set(newValue) {
            Holder.analyticsManager = newValue
        }
    }

    // MARK: - RuntimeLoadable

    public static func loadSwift() {
        if !Bundle.main.isManualInitializationEnabled {
            if EnvironmentInformation.isRunningTests {
                installAutoTrackingHooks()
                SceneDelegateHelper.autoTrack()
                return
            }
            // Ensure AnalyticsManager is initialized before UIApplication.didFinishLaunchingNotification fires.
            _ = AnalyticsManager.shared()
            installAutoTrackingHooks()
            SceneDelegateHelper.autoTrack()
            GeoLaunchConfigurator.configureIfNeeded()
        }
    }

    public static func installAutoTrackingHooks() {
        UIScene.installStateRestorationAutoTrackingHooks()
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
        guard let recipient = resolveSceneDelegateClass(named: sceneDelegateClassName) else {
            RLogger.debug(message: "Could not resolve scene delegate class '\(sceneDelegateClassName)'. "
                + "Ensure Info.plist uses $(PRODUCT_MODULE_NAME).SceneDelegate.")
            ErrorRaiser.raise(.detailedError(domain: ErrorDomain.analyticsManagerErrorDomain,
                                             code: ErrorCode.sceneDelegateClassUnresolved.rawValue,
                                             description: ErrorDescription.sceneDelegateClassUnresolved,
                                             reason: ErrorReason.sceneDelegateClassUnresolved(className: sceneDelegateClassName)))
            return
        }
        swizzleSceneDelegateFunctions(recipient)
    }

    static func swizzleSceneDelegateFunctions(_ recipient: UISceneDelegate.Type) {
        let classIdentifier = ObjectIdentifier(recipient)
        guard !Holder.swizzledSceneDelegateClasses.contains(classIdentifier) else {
            RLogger.debug(message: "Scene delegate class \(recipient) already swizzled, skipping.")
            return
        }

        installTracking(#selector(UISceneDelegate.scene(_:willConnectTo:options:)),
                        rAutotrackSelector: #selector(rAutotrackScene(_:willConnectTo:options:)),
                        into: recipient)
        installTracking(#selector(UISceneDelegate.scene(_:openURLContexts:)),
                        rAutotrackSelector: #selector(rAutotrackScene(_:openURLContexts:)),
                        into: recipient)
        installTracking(#selector(UISceneDelegate.scene(_:continue:)),
                        rAutotrackSelector: #selector(rAutotrackScene(_:continue:)),
                        into: recipient)

        Holder.swizzledSceneDelegateClasses.insert(classIdentifier)
        RLogger.verbose(message: "Installed auto-tracking hooks for scene delegate \(recipient)")
    }

    /// Installs analytics tracking for a single scene delegate method without mutating
    /// UIWindowScene's own method table (which would corrupt subsequent swizzle calls).
    ///
    /// - If `recipient` implements `selector`: stores the original IMP under `rAutotrackSelector`
    ///   on `recipient` so the chain `scene → rAutotrack → original` is preserved, then replaces
    ///   `selector`'s IMP with the rAutotrack IMP read directly from UIWindowScene.
    /// - If `recipient` does not implement `selector`: adds `selector` with the rAutotrack IMP
    ///   (analytics-only, no chaining needed).
    private static func installTracking(_ selector: Selector,
                                        rAutotrackSelector: Selector,
                                        into recipient: UISceneDelegate.Type) {
        guard let rAutotrackMethod = class_getInstanceMethod(UIWindowScene.self, rAutotrackSelector) else {
            return
        }
        let rAutotrackIMP = method_getImplementation(rAutotrackMethod)
        let rAutotrackTypes = method_getTypeEncoding(rAutotrackMethod)

        if let originalMethod = class_getInstanceMethod(recipient, selector) {
            let originalIMP = method_getImplementation(originalMethod)
            if class_getInstanceMethod(recipient, rAutotrackSelector) == nil {
                class_addMethod(recipient, rAutotrackSelector, originalIMP, rAutotrackTypes)
            }
            method_setImplementation(originalMethod, rAutotrackIMP)
        } else {
            class_addMethod(recipient, selector, rAutotrackIMP, rAutotrackTypes)
        }
    }

    private static func resolveSceneDelegateClass(named className: String) -> UISceneDelegate.Type? {
        if let type = NSClassFromString(className) as? UISceneDelegate.Type {
            RLogger.verbose(message: "Resolved scene delegate class '\(className)'.")
            return type
        }

        guard !className.contains(".") else {
            return nil
        }

        let moduleNames = [
            Bundle.main.infoDictionary?["CFBundleName"] as? String,
            Bundle.main.infoDictionary?["CFBundleExecutable"] as? String
        ].compactMap { $0 }

        for moduleName in moduleNames {
            let qualifiedName = "\(moduleName).\(className)"
            if let type = NSClassFromString(qualifiedName) as? UISceneDelegate.Type {
                RLogger.verbose(message: "Resolved scene delegate class '\(className)' using module '\(moduleName)'.")
                return type
            }
        }

        return nil
    }

    /// This delegate method is called when the app is opened from a URL Scheme or a Universal Link.
    ///
    /// - Note: This callback is called when the app is launched
    @objc func rAutotrackScene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        let sharedManager = AnalyticsManager.shared()
        sharedManager.launchCollector.origin = .inner
        GeoLaunchConfigurator.configureIfNeeded()

        if connectionOptions.urlContexts.isEmpty,
           connectionOptions.userActivities.isEmpty,
           UIOpenURLContext.DefaultValues.url != nil || UIScene.ConnectionOptions.DefaultValues.webpageURL != nil {
            analyticsManager.handleIncomingColdLaunchFromInjectedValues()
        } else if let manager = analyticsManager as? AnalyticsManager {
            manager.handleIncomingConnectionOptionsWithLogging(connectionOptions)
        } else {
            analyticsManager.handleIncomingConnectionOptions(connectionOptions)
        }

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
    @objc func rAutotrackScene(_ scene: UIScene, openURLContexts urlContexts: Set<UIOpenURLContext>) {
        if let manager = analyticsManager as? AnalyticsManager {
            manager.handleIncomingURLContextsWithLogging(urlContexts)
        } else {
            analyticsManager.handleIncomingURLContexts(urlContexts)
        }

        // Delegates may not implement the original method
        if responds(to: #selector(rAutotrackScene(_:openURLContexts:))) {
            return rAutotrackScene(scene, openURLContexts: urlContexts)
        }
    }

    /// This delegate method is called when the app is opened from a Universal Link.
    ///
    /// - Note: This callback is not called when the app is launched. It is called when the app is already running.
    @objc func rAutotrackScene(_ scene: UIScene, continue userActivity: NSUserActivity) {
        if let manager = analyticsManager as? AnalyticsManager {
            manager.handleIncomingUserActivityWithLogging(userActivity)
        } else {
            analyticsManager.handleIncomingUserActivity(userActivity)
        }

        // Delegates may not implement the original method
        if responds(to: #selector(rAutotrackScene(_:continue:))) {
            return rAutotrackScene(scene, continue: userActivity)
        }
    }
}

extension UIOpenURLContext {
    /// As `UIOpenURLContext`'s init is unavailable, this property below is used to inject the URL.
    ///
    /// - Warning: `UIOpenURLContext.DefaultValues` is only for internal use.
    enum DefaultValues {
        static var url: URL?
        static var sourceApplication: String?
    }
}
