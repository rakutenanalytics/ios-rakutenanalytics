import UIKit

/// Configures geo tracking when the application launches.
///
/// ## Expected call order
///
/// 1. `+[_RAnalyticsSwiftLoader load]` → `UIWindowScene.loadSwift()` → `configureIfNeeded()`
///    installs the `didFinishLaunchingNotification` observer **before** the app delegate runs.
/// 2. `UIApplication` calls `application(_:didFinishLaunchingWithOptions:)` and then posts
///    `didFinishLaunchingNotification` — the observer fires and records whether the launch was
///    location-triggered into `Holder.didLaunchFromLocation`.
/// 3. `scene(_:willConnectTo:options:)` fires and calls `configureIfNeeded()` again.  By that
///    point `Holder.didLaunchFromLocation` is already populated, so geo setup is correct.
///
/// For apps that use manual initialisation (`RAnalyticsManualInitialization = YES`), `configure()`
/// must be called inside `application(_:didFinishLaunchingWithOptions:)` — before that method
/// returns — so that the observer is registered before the notification is posted.
enum GeoLaunchConfigurator {
    private enum Holder {
        static var didInstallLaunchObserver = false
        static var didLaunchFromLocation = false
        static var hasConfiguredLaunchGeo = false
        static var didRequestLaunchLocationUpdate = false
    }

    /// Configures geo location tracking and background timer continuation at launch.
    ///
    /// - Parameter isLocationLaunch: Optional explicit location-launch signal. Defaults to didFinishLaunching launch options.
    static func configureIfNeeded(isLocationLaunch: Bool? = nil) {
        installLaunchOptionsObserverIfNeeded()

        let analyticsManager = AnalyticsManager.shared()
        let locationLaunch = isLocationLaunch ?? Holder.didLaunchFromLocation

        if analyticsManager.isTrackingGeoLocation {
            if shouldRequestContinualLocationUpdate(isLocationLaunch: locationLaunch),
               !Holder.didRequestLaunchLocationUpdate {
                GeoManager.shared.requestLocationUpdate(for: .continual)
                Holder.didRequestLaunchLocationUpdate = true
            }
            if !Holder.hasConfiguredLaunchGeo {
                GeoManager.shared.configurePoller()
                Holder.hasConfiguredLaunchGeo = true
            }
        }

        if analyticsManager.shouldContinueGeoBackgroundTimer,
           !Holder.hasConfiguredLaunchGeo {
            _ = GeoManager.shared
            Holder.hasConfiguredLaunchGeo = true
        }
    }

    private static func installLaunchOptionsObserverIfNeeded() {
        guard !Holder.didInstallLaunchObserver else {
            return
        }
        Holder.didInstallLaunchObserver = true
        NotificationCenter.default.addObserver(forName: UIApplication.didFinishLaunchingNotification,
                                               object: nil,
                                               queue: nil) { notification in
            Holder.didLaunchFromLocation = isLocationLaunch(from: notification.userInfo)
        }
    }

    static func shouldRequestContinualLocationUpdate(isLocationLaunch: Bool) -> Bool {
        isLocationLaunch
    }

    static func resetForTesting() {
        Holder.didInstallLaunchObserver = false
        Holder.didLaunchFromLocation = false
        Holder.hasConfiguredLaunchGeo = false
        Holder.didRequestLaunchLocationUpdate = false
    }

    static func isLocationLaunch(from userInfo: [AnyHashable: Any]?) -> Bool {
        guard let userInfo else {
            return false
        }

        if let value = userInfo[UIApplication.LaunchOptionsKey.location] as? Bool {
            return value
        }
        if let value = userInfo[UIApplication.LaunchOptionsKey.location.rawValue] as? Bool {
            return value
        }
        if let value = userInfo[UIApplication.LaunchOptionsKey.location] as? NSNumber {
            return value.boolValue
        }
        if let value = userInfo[UIApplication.LaunchOptionsKey.location.rawValue] as? NSNumber {
            return value.boolValue
        }
        return false
    }
}
