import Foundation
import UIKit

enum RAnalyticsLaunchCollectorError: Error {
    case triggerTypeIsIncorrect
    case trackingIsNotProcessed
}

/// This class tracks launch events.
/// It creates event corresponding to each event, sends it to RAnalyticsManager's instance to process.
final class RAnalyticsLaunchCollector {
    private enum Constants {
        static let initialLaunchDateKey = "com.rakuten.esd.sdk.properties.analytics.launchInformation.initialLaunchDate"
        static let installLaunchDateKey = "com.rakuten.esd.sdk.properties.analytics.launchInformation.installLaunchDate"
        static let lastUpdateDateKey = "com.rakuten.esd.sdk.properties.analytics.launchInformation.lastUpdateDate"
        static let lastLaunchDateKey = "com.rakuten.esd.sdk.properties.analytics.launchInformation.lastLaunchDate"
        static let lastVersionKey = "com.rakuten.esd.sdk.properties.analytics.launchInformation.lastVersion"
        static let lastVersionLaunchesKey = "com.rakuten.esd.sdk.properties.analytics.launchInformation.lastVersionLaunches"
    }

    /// The initial launch date is being stored in keychain.
    private(set) var initialLaunchDate: Date?

    /// The install launch date is being stored in shared preferences.
    private(set) var installLaunchDate: Date?

    /// The last update date is being stored in shared preferences.
    private(set) var lastUpdateDate: Date?

    /// The last launch date is being stored in shared preferences.
    private(set) var lastLaunchDate: Date?

    /// The last version is being stored in shared preferences.
    private(set) var lastVersion: String?

    /// The number of launches since last version is being stored in shared preferences.
    private(set) var lastVersionLaunches: UInt = 0

    /// String identifying the origin of the launch or visit, if it can be determined.
    /// Default value: .inner
    internal var origin: AnalyticsManager.State.Origin = .inner

    /// The referral tracking type.
    internal var referralTracking: ReferralTrackingType

    private let notificationHandler: NotificationObservable?
    private let userStorageHandler: UserStorageHandleable?
    private let pushEventHandler: PushEventHandleable
    private let keychainHandler: KeychainHandleable?

    /// A delegate for tracking an event and its parameters
    weak var trackerDelegate: Trackable?

    private(set) var isInitialLaunch: Bool = false
    private(set) var isInstallLaunch: Bool = false
    private(set) var isUpdateLaunch: Bool = false

    /// Creates a launch collector
    ///
    /// - Parameters:
    ///   - dependenciesContainer: The dependencies container.
    ///
    /// - Returns: An instance of RAnalyticsLaunchCollector.
    init(dependenciesContainer: SimpleDependenciesContainable) {
        self.notificationHandler = dependenciesContainer.notificationHandler
        self.userStorageHandler = dependenciesContainer.userStorageHandler
        self.keychainHandler = dependenciesContainer.keychainHandler
        self.referralTracking = .none
        pushEventHandler = dependenciesContainer.pushEventHandler

        configureNotifications()
        configureLaunchValues()
        resetToDefaults()
        isInstallLaunch = (installLaunchDate == nil)
        isUpdateLaunch = lastVersion != (Bundle.main.shortVersion ?? "")
    }

    private func configureNotifications() {
        notificationHandler?.addObserver(self,
                                         selector: #selector(willResume(_:)),
                                         name: UIApplication.willEnterForegroundNotification,
                                         object: nil)

        notificationHandler?.addObserver(self,
                                         selector: #selector(didSuspend(_:)),
                                         name: UIApplication.didEnterBackgroundNotification,
                                         object: nil)

        notificationHandler?.addObserver(self,
                                         selector: #selector(didLaunch(_:)),
                                         name: UIApplication.didFinishLaunchingNotification,
                                         object: nil)
    }

    private func configureLaunchValues() {
        // check initLaunchDate exists in keychain
        let response = keychainHandler?.item(for: Constants.initialLaunchDateKey)

        if response?.status == errSecSuccess {
            // keychain item exists
            guard let date = keychainHandler?.creationDate(for: response?.result) else {
                configureDefaultLaunchValues()
                return
            }
            initialLaunchDate = date
            isInitialLaunch = false
        } else {
            // no keychain item
            configureDefaultLaunchValues()
        }
    }

    private func configureDefaultLaunchValues() {
        initialLaunchDate = Date()
        keychainHandler?.set(creationDate: initialLaunchDate, for: Constants.initialLaunchDateKey)
        isInitialLaunch = true
    }
}

// MARK: - App Life Cycle Observers

@objc extension RAnalyticsLaunchCollector {
    func willResume(_ notification: NSNotification) {
        guard UIApplication.shared.applicationState == .background || UIApplication.shared.applicationState == .inactive else {
            return
        }
        update()
        trackerDelegate?.trackEvent(name: AnalyticsManager.Event.Name.sessionStart, parameters: nil)
    }

    func didSuspend(_ notification: NSNotification) {
        trackerDelegate?.trackEvent(name: AnalyticsManager.Event.Name.sessionEnd, parameters: nil)
    }

    func didLaunch(_ notification: NSNotification) {
        update()

        /// Equivalent to installation or reinstallation.
        if isInitialLaunch {
            trackerDelegate?.trackEvent(name: AnalyticsManager.Event.Name.initialLaunch, parameters: nil)
            isInitialLaunch = false
        }

        /// Triggered on first run after app install with or without version change.
        else if isInstallLaunch {
            trackerDelegate?.trackEvent(name: AnalyticsManager.Event.Name.install, parameters: nil)
            isInstallLaunch = false
        }

        /// Triggered on first run after upgrade (anytime the version number changes).
        else if isUpdateLaunch {
            trackerDelegate?.trackEvent(name: AnalyticsManager.Event.Name.install, parameters: nil)
            trackerDelegate?.trackEvent(name: AnalyticsManager.Event.Name.applicationUpdate, parameters: nil)
            isUpdateLaunch = false
        }

        /// Trigger a session start.
        trackerDelegate?.trackEvent(name: AnalyticsManager.Event.Name.sessionStart, parameters: nil)

        /// Track the credentials status.
        let parameters = ["strategies": ["password-manager": Bundle.isPasswordExtensionAvailable ? "true" : "false"]]
        trackerDelegate?.trackEvent(name: AnalyticsManager.Event.Name.credentialStrategies, parameters: parameters)
    }
}

// MARK: - Presenting View Controller

extension RAnalyticsLaunchCollector {
    /// This method is called when the swizzling method _swizzled_viewDidAppear in _RAnalyticsTrackingPageView is called.
    /// The _swizzled_viewDidAppear is called when the view of an UIViewController is shown.
    func didPresentViewController(_ viewController: UIViewController) {
        guard viewController.isTrackableAsPageVisit else {
            return
        }
        trackPageVisit(with: .page(currentPage: viewController))
    }
}

// MARK: - Page Visit Tracking

extension RAnalyticsLaunchCollector {
    func trackPageVisit(with referralTracking: ReferralTrackingType) {
        /// Keep a strong reference to the view controller in the launch collector only for the
        /// time the event is being processed. Note that it will be carried on by the analytics
        /// manager state, too.
        self.referralTracking = referralTracking
        trackerDelegate?.trackEvent(name: AnalyticsManager.Event.Name.pageVisit, parameters: nil)
        self.referralTracking = .none

        /// Reset the origin to RAnalyticsInternalOrigin for the next page visit after each external
        /// call or push notification.
        origin = .inner
    }
}

// MARK: - Utils

extension RAnalyticsLaunchCollector {
    func resetToDefaults() {
        installLaunchDate = userStorageHandler?.object(forKey: Constants.installLaunchDateKey) as? Date
        lastUpdateDate = userStorageHandler?.object(forKey: Constants.lastUpdateDateKey) as? Date
        lastLaunchDate = userStorageHandler?.object(forKey: Constants.lastLaunchDateKey) as? Date
        lastVersion = userStorageHandler?.string(forKey: Constants.lastVersionKey)
        lastVersionLaunches = (userStorageHandler?.object(forKey: Constants.lastVersionLaunchesKey) as? NSNumber)?.uintValue ?? 0
    }
}

private extension RAnalyticsLaunchCollector {
    func update() {
        resetToDefaults()

        /// Update values for the next run
        let now = Date()
        let currentVersion = Bundle.main.shortVersion

        if !isInitialLaunch && installLaunchDate == nil {
            isInstallLaunch = true
            userStorageHandler?.set(value: now, forKey: Constants.installLaunchDateKey)
        }

        if lastVersion != currentVersion {
            isUpdateLaunch = true
            userStorageHandler?.set(value: currentVersion, forKey: Constants.lastVersionKey)
            userStorageHandler?.set(value: now, forKey: Constants.lastUpdateDateKey)
            userStorageHandler?.set(value: 1, forKey: Constants.lastVersionLaunchesKey)

        } else {
            lastVersionLaunches += 1
            userStorageHandler?.set(value: NSNumber(value: lastVersionLaunches), forKey: Constants.lastVersionLaunchesKey)
        }
        userStorageHandler?.set(value: now, forKey: Constants.lastLaunchDateKey)
    }
}
