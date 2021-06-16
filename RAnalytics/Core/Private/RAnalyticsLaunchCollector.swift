import Foundation
import UIKit

enum RAnalyticsLaunchCollectorError: Error {
    case triggerTypeIsIncorrect
    case trackingIsNotProcessed
}

/// This class tracks launch events.
/// It creates event corresponding to each event, sends it to RAnalyticsManager's instance to process.
@objc final class RAnalyticsLaunchCollector: NSObject {
    private enum Constants {
        static let initialLaunchDateKey = "com.rakuten.esd.sdk.properties.analytics.launchInformation.initialLaunchDate"
        static let installLaunchDateKey = "com.rakuten.esd.sdk.properties.analytics.launchInformation.installLaunchDate"
        static let lastUpdateDateKey = "com.rakuten.esd.sdk.properties.analytics.launchInformation.lastUpdateDate"
        static let lastLaunchDateKey = "com.rakuten.esd.sdk.properties.analytics.launchInformation.lastLaunchDate"
        static let lastVersionKey = "com.rakuten.esd.sdk.properties.analytics.launchInformation.lastVersion"
        static let lastVersionLaunchesKey = "com.rakuten.esd.sdk.properties.analytics.launchInformation.lastVersionLaunches"
    }

    /// The initial launch date is being stored in keychain.
    @objc private(set) var initialLaunchDate: Date?

    /// The install launch date is being stored in shared preferences.
    @objc private(set) var installLaunchDate: Date?

    /// The last update date is being stored in shared preferences.
    @objc private(set) var lastUpdateDate: Date?

    /// The last launch date is being stored in shared preferences.
    @objc private(set) var lastLaunchDate: Date?

    /// The last version is being stored in shared preferences.
    @objc private(set) var lastVersion: String?

    /// The number of launches since last version is being stored in shared preferences.
    @objc private(set) var lastVersionLaunches: UInt = 0

    /// String identifying the origin of the launch or visit, if it can be determined.
    /// Default value: .internal
    @objc private(set) var origin: AnalyticsManager.State.Origin = .internal

    /// Currently-visited view controller.
    @objc private(set) var currentPage: UIViewController?

    /// The identifier is computed from push payload.
    /// It is used for tracking push notification. It is also sent together with a push notification event.
    @objc private(set) var pushTrackingIdentifier: String?

    private let notificationHandler: NotificationObservable?
    private let userStorageHandler: UserStorageHandleable?
    private let keychainHandler: KeychainHandleable?
    private let tracker: Trackable?

    private var pushTapTrackingDate: Date?
    private let pushTapEventTimeLimit: TimeInterval = 1.5

    @objc private(set) var isInitialLaunch: Bool = false
    @objc private(set) var isInstallLaunch: Bool = false
    @objc private(set) var isUpdateLaunch: Bool = false

    @available(*, unavailable)
    override init() {
        self.notificationHandler = nil
        self.userStorageHandler = nil
        self.keychainHandler = nil
        self.tracker = nil
        super.init()
    }

    /// Creates a launch collector
    ///
    /// - Parameters:
    ///   - dependenciesFactory: The dependencies factory.
    ///
    /// - Returns: An instance of RAnalyticsLaunchCollector or nil.
    @objc init?(dependenciesFactory: DependenciesFactory) {
        guard let notificationHandler = dependenciesFactory.notificationHandler,
              let userStorageHandler = dependenciesFactory.userStorageHandler,
              let keychainHandler = dependenciesFactory.keychainHandler,
              let tracker = dependenciesFactory.tracker else {
            return nil
        }
        self.notificationHandler = notificationHandler
        self.userStorageHandler = userStorageHandler
        self.keychainHandler = keychainHandler
        self.tracker = tracker

        super.init()

        configureNotifications()

        guard configureLaunchValues() else {
            return nil
        }

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
                                         selector: #selector(didBecomeActive(_:)),
                                         name: UIApplication.didBecomeActiveNotification,
                                         object: nil)

        notificationHandler?.addObserver(self,
                                         selector: #selector(didLaunch(_:)),
                                         name: UIApplication.didFinishLaunchingNotification,
                                         object: nil)
    }

    private func configureLaunchValues() -> Bool {
        // check initLaunchDate exists in keychain
        let response = keychainHandler?.item(for: Constants.initialLaunchDateKey)

        switch response?.status {
        case errSecSuccess:
            // keychain item exists
            guard let date = keychainHandler?.creationDate(for: response?.result) else {
                return false
            }
            initialLaunchDate = date
            isInitialLaunch = false
        default:
            // no keychain item
            initialLaunchDate = Date()
            keychainHandler?.set(creationDate: initialLaunchDate, for: Constants.initialLaunchDateKey)
            isInitialLaunch = true
        }
        return true
    }
}

// MARK: - App Life Cycle Observers

@objc extension RAnalyticsLaunchCollector {
    func willResume(_ notification: NSNotification) {
        update()
        tracker?.trackEvent(name: AnalyticsManager.Event.Name.sessionStart, parameters: nil)
    }

    func didSuspend(_ notification: NSNotification) {
        tracker?.trackEvent(name: AnalyticsManager.Event.Name.sessionEnd, parameters: nil)
    }

    func didBecomeActive(_ notification: NSNotification) {
        sendTapNonUNUserNotification()
    }

    func didLaunch(_ notification: NSNotification) {
        update()

        /// Equivalent to installation or reinstallation.
        if isInitialLaunch {
            tracker?.trackEvent(name: AnalyticsManager.Event.Name.initialLaunch, parameters: nil)
            isInitialLaunch = false
        }

        /// Triggered on first run after app install with or without version change.
        else if isInstallLaunch {
            tracker?.trackEvent(name: AnalyticsManager.Event.Name.install, parameters: nil)
            isInstallLaunch = false
        }

        /// Triggered on first run after upgrade (anytime the version number changes).
        else if isUpdateLaunch {
            tracker?.trackEvent(name: AnalyticsManager.Event.Name.install, parameters: nil)
            tracker?.trackEvent(name: AnalyticsManager.Event.Name.applicationUpdate, parameters: nil)
            isUpdateLaunch = false
        }

        /// Trigger a session start.
        tracker?.trackEvent(name: AnalyticsManager.Event.Name.sessionStart, parameters: nil)

        /// Track the credentials status.
        let parameters = ["strategies": ["password-manager": Bundle.isPasswordExtensionAvailable ? "true" : "false"]]
        tracker?.trackEvent(name: AnalyticsManager.Event.Name.credentialStrategies, parameters: parameters)
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

        /// Keep a strong reference to the view controller in the launch collector only for the
        /// time the event is being processed. Note that it will be carried on by the analytics
        /// manager state, too.
        currentPage = viewController
        tracker?.trackEvent(name: AnalyticsManager.Event.Name.pageVisit, parameters: nil)
        currentPage = nil

        /// Reset the origin to RAnalyticsInternalOrigin for the next page visit after each external
        /// call or push notification.
        origin = .internal
    }
}

// MARK: - Push Notification

extension RAnalyticsLaunchCollector {
    /// For implementations that do NOT use the UNUserNotification Framework,  We need to distinguish between a tap of notification alert and
    /// receiving a push notification.  This can be done by measuring the time since when this function was called and the next app life cycle "App did become active" event occuring.
    func handleTapNonUNUserNotification(_ userInfo: [AnyHashable: Any], appState state: UIApplication.State) {
        guard !UNUserNotificationCenter.notificationsAreHandledByUNDelegate else {
            return
        }

        switch state {
        case .background, .inactive:
            pushTrackingIdentifier = RAnalyticsPushTrackingUtility.trackingIdentifier(fromPayload: userInfo)
            pushTapTrackingDate = Date()
        default: ()
        }
    }
}

extension RAnalyticsLaunchCollector {
    /// This method sends a push open notify event only if a tracking identifier can be pulled from the UNNotificationResponse
    /// - Returns:
    ///     - success if the trigger is kind of UNPushNotificationTrigger and if the tracking is processed. The associated value is the trigger.
    ///     - or a failure if the trigger is not kind of UNPushNotificationTrigger or if the tracking is not processed.
    @discardableResult
    func processPushNotificationResponse(_ notificationResponse: UNNotificationResponse) -> Result<UNNotificationTrigger, RAnalyticsLaunchCollectorError> {
        guard let trigger = notificationResponse.notification.request.trigger,
              trigger.isKind(of: UNPushNotificationTrigger.self) else {
            return .failure(.triggerTypeIsIncorrect)
        }

        var userText: String?
        if let textInputNotificationResponse = notificationResponse as? UNTextInputNotificationResponse,
           !textInputNotificationResponse.userText.isEmpty {
            userText = textInputNotificationResponse.userText
        }
        let isProcessed = processPushNotificationPayload(userInfo: notificationResponse.notification.request.content.userInfo,
                                                         userAction: notificationResponse.actionIdentifier,
                                                         userText: userText)
        guard isProcessed else {
            return .failure(.trackingIsNotProcessed)
        }
        return .success(trigger)
    }

    /// This method sends a push open notify event only if a tracking identifier can be pulled from the push payload
    /// - Returns: a boolean to know if the push notification event is tracked or not.
    @discardableResult
    func processPushNotificationPayload(userInfo: [AnyHashable: Any], userAction: String?, userText: String?) -> Bool {
        var isProcessed = false
        let trackingId = RAnalyticsPushTrackingUtility.trackingIdentifier(fromPayload: userInfo)

        if let trackingId = trackingId,
           !RAnalyticsPushTrackingUtility.analyticsEventHasBeenSent(with: trackingId) {
            pushTrackingIdentifier = trackingId
            let parameters = [AnalyticsManager.Event.Parameter.pushTrackingIdentifier: trackingId]
            tracker?.trackEvent(name: AnalyticsManager.Event.Name.pushNotification, parameters: parameters)
            isProcessed = true
        }

        if UIApplication.RAnalyticsSharedApplication?.applicationState != .active {
            /// set the origin to push type for the next _rem_visit event
            origin = .push
        }
        return isProcessed
    }
}

private extension RAnalyticsLaunchCollector {
    func sendTapNonUNUserNotification() {
        guard !UNUserNotificationCenter.notificationsAreHandledByUNDelegate else {
            return
        }

        if let pushTapTrackingDate = pushTapTrackingDate,
           let pushTrackingIdentifier = pushTrackingIdentifier,
           fabs(pushTapTrackingDate.timeIntervalSinceNow) < pushTapEventTimeLimit
            && !RAnalyticsPushTrackingUtility.analyticsEventHasBeenSent(with: pushTrackingIdentifier) {
            tracker?.trackEvent(name: AnalyticsManager.Event.Name.pushNotification,
                                parameters: [AnalyticsManager.Event.Parameter.pushTrackingIdentifier: pushTrackingIdentifier])
        }

        pushTrackingIdentifier = nil
        pushTapTrackingDate = nil
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

    func resetPushTrackingIdentifier() {
        pushTrackingIdentifier = nil
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

extension RAnalyticsLaunchCollector {
    func setOrigin(_ value: AnalyticsManager.State.Origin) {
        origin = value
    }
}
