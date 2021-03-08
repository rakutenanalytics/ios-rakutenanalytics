import Foundation
import RLogger

@objc public protocol UserIdentifiable {
    var trackingIdentifier: String? { get }
    var userIdentifier: String? { get set }
}

/// This class tracks login, logout and push events.
/// It creates event corressponding to each event, sends it to RAnalyticsManager's instance to process.
@objc public final class RAnalyticsExternalCollector: NSObject, UserIdentifiable {
    private enum Constants {
        static let loginStateKey = "com.rakuten.esd.sdk.properties.analytics.loginInformation.loginState"
        static let trackingIdentifierKey = "com.rakuten.esd.sdk.properties.analytics.loginInformation.trackingIdentifier"
        static let userIdentifierKey = "com.rakuten.esd.sdk.properties.analytics.loginInformation.userIdentifier"
        static let loginMethodKey = "com.rakuten.esd.sdk.properties.analytics.loginInformation.loginMethod"
        static let notificationBaseName = "com.rakuten.esd.sdk.events"
    }

    /// The login state information is being stored in shared preferences.
    @objc public private(set) var isLoggedIn: Bool = false {
        willSet(newValue) {
            guard isLoggedIn != newValue else {
                return
            }
            userStorageHandler?.set(value: newValue, forKey: Constants.loginStateKey)
            userStorageHandler?.synchronize()
        }
    }

    /// The tracking identifier is being stored in shared preferences.
    @objc public private(set) var trackingIdentifier: String? {
        willSet(newValue) {
            guard trackingIdentifier != newValue else {
                return
            }
            if let trackingIdentifier = newValue,
               !trackingIdentifier.isEmpty {
                userStorageHandler?.set(value: trackingIdentifier, forKey: Constants.trackingIdentifierKey)

            } else {
                userStorageHandler?.removeObject(forKey: Constants.trackingIdentifierKey)
            }
            userStorageHandler?.synchronize()
        }
    }

    /// The user identifier is being stored in shared preferences.
    @objc public var userIdentifier: String? {
        willSet(newValue) {
            guard userIdentifier != newValue else {
                return
            }
            if let userIdentifier = newValue,
               !userIdentifier.isEmpty {
                userStorageHandler?.set(value: userIdentifier, forKey: Constants.userIdentifierKey)

            } else {
                userStorageHandler?.removeObject(forKey: Constants.userIdentifierKey)
            }
            userStorageHandler?.synchronize()
        }
    }

    /// The login method is being stored in shared preferences.
    @objc public private(set) var loginMethod: AnalyticsManager.State.LoginMethod = .other {
        willSet(newValue) {
            guard loginMethod != newValue else {
                return
            }
            // Note: loginMethod is set and got as NSNumber in RAnalytics version <= 7.x - _RAnalyticsExternalCollector.m
            userStorageHandler?.set(value: NSNumber(value: newValue.rawValue), forKey: Constants.loginMethodKey)
            userStorageHandler?.synchronize()
        }
    }

    /// Private

    private var logoutMethod: String?
    private var cardInfoEventMapping: NSDictionary?
    private let discoverEventMapping: [String: Notification.Name] = {
        ["visitPreview": .discoverPreviewVisit,
         "tapPreview": .discoverPreviewTap,
         "redirectPreview": .discoverPreviewRedirect,
         "tapShowMore": .discoverPreviewShowMore,
         "visitPage": .discoverPageVisit,
         "tapPage": .discoverPageTap,
         "redirectPage": .discoverPageRedirect]
    }()
    private let loginEvents = ["password", "one_tap", "other"]
    private let logoutEvents = ["local", "global"]
    private let credentialEvents = ["ssocredentialfound", "logincredentialfound"]
    private let eventsRequiringOnlyIdentifier = ["tapPage", "tapPreview"]
    private let eventsRequiringIdentifierAndRedirectString = ["redirectPage", "redirectPreview"]
    private let userStorageHandler: UserStorageHandleable?
    private let tracker: Trackable?

    @available(*, unavailable)
    override init() {
        self.userStorageHandler = nil
        self.tracker = nil
        super.init()
    }

    /// Creates an external collector
    ///
    /// - Parameters:
    ///   - dependenciesFactory: The dependencies factory.
    ///         It requires intances of these types: UserStorageHandleable, Trackable
    ///
    /// - Returns: An instance of RAnalyticsExternalCollector or nil.
    @objc public init?(dependenciesFactory: DependenciesFactory) {
        guard let userStorageHandler = dependenciesFactory.userStorageHandler,
              let tracker = dependenciesFactory.tracker else {
            RLogger.warning("RAnalyticsExternalCollector can't be created without userStorageHandler and tracker dependencies")
            return nil
        }
        self.userStorageHandler = userStorageHandler
        self.tracker = tracker
        super.init()
        addLoginObservers()
        addLoginFailureObservers()
        addLogoutObservers()
        addDiscoverObservers()
        addSSODialogObservers()
        addCredentialsObservers()
        addCustomEventObserver()
        update()
    }
}

// MARK: - Notification observers

private extension RAnalyticsExternalCollector {
    func addLoginObservers() {
        loginEvents.forEach {
            let evenName = "\(Constants.notificationBaseName).login.\($0)"
            addNotificationName(evenName, selector: #selector(receiveLoginNotification(_:)))
        }
    }

    func addLoginFailureObservers() {
        addNotificationName("\(Constants.notificationBaseName).login.failure", selector: #selector(receiveLoginFailureNotification(_:)))
    }

    func addLogoutObservers() {
        logoutEvents.forEach {
            let evenName = "\(Constants.notificationBaseName).logout.\($0)"
            addNotificationName(evenName, selector: #selector(receiveLogoutNotification(_:)))
        }
    }

    func addDiscoverObservers() {
        let eventBase = "\(Constants.notificationBaseName).discover."
        discoverEventMapping.forEach {
            addNotificationName("\(eventBase)\($0.key)", selector: #selector(receiveDiscoverNotification(_:)))
        }
    }

    func addSSODialogObservers() {
        let eventName = "\(Constants.notificationBaseName).ssodialog"
        addNotificationName(eventName, selector: #selector(receiveSSODialogNotification(_:)))
    }

    func addCredentialsObservers() {
        credentialEvents.forEach {
            let eventName = "\(Constants.notificationBaseName).\($0)"
            addNotificationName(eventName, selector: #selector(receiveCredentialsNotification(_:)))
        }
    }

    func addCustomEventObserver() {
        let eventName = "\(Constants.notificationBaseName).custom"
        addNotificationName(eventName, selector: #selector(receiveCustomEventNotification(_:)))
    }
}

// MARK: - Handle notifications

@objc private extension RAnalyticsExternalCollector {
    func receiveLoginNotification(_ notification: NSNotification) {
        update()

        if let trackingIdentifier = notification.object as? String {
            self.trackingIdentifier = trackingIdentifier
        }

        isLoggedIn = true

        // For login we want to provide the logged-in state with each event, and each event tracker can know how the user logged in, so the loginMethod should be persisted.

        let base = "\(Constants.notificationBaseName).login."
        switch notification.name.rawValue {
        case "\(base)password": loginMethod = .passwordInput
        case "\(base)one_tap": loginMethod = .oneTapLogin
        default: loginMethod = .other
        }

        tracker?.trackEvent(name: AnalyticsManager.Event.Name.login, parameters: nil)
    }

    func receiveLoginFailureNotification(_ notification: NSNotification) {
        update()

        guard notification.name.rawValue == "\(Constants.notificationBaseName).login.failure" else {
            return
        }

        isLoggedIn = false
        trackingIdentifier = nil

        var parameters = [String: Any]()

        if let params = notification.object as? [String: Any] {
            parameters["rae_error"] = params["rae_error"]
            parameters["type"] = params["type"]
            if let raeErrorMessage = params["rae_error_message"] {
                parameters["rae_error_message"] = raeErrorMessage
            }
        }

        tracker?.trackEvent(name: AnalyticsManager.Event.Name.loginFailure, parameters: parameters.isEmpty ? nil : parameters)
    }

    func receiveLogoutNotification(_ notification: NSNotification) {
        update()

        isLoggedIn = false
        trackingIdentifier = nil

        var parameters = [String: Any]()

        if notification.name.rawValue == "\(Constants.notificationBaseName).logout.local" {
            parameters[AnalyticsManager.Event.Parameter.logoutMethod] = AnalyticsManager.Event.LogoutMethod.local

        } else {
            parameters[AnalyticsManager.Event.Parameter.logoutMethod] = AnalyticsManager.Event.LogoutMethod.global
        }

        tracker?.trackEvent(name: AnalyticsManager.Event.Name.logout, parameters: parameters)
    }

    func receiveDiscoverNotification(_ notification: NSNotification) {
        let eventPrefix = "\(Constants.notificationBaseName).discover."
        let eventPrefixCount = eventPrefix.count
        guard eventPrefixCount < notification.name.rawValue.count else {
            return
        }

        let eventSuffix = notification.name.rawValue[eventPrefixCount..<notification.name.rawValue.count]

        var parameters = [String: Any]()

        if eventsRequiringIdentifierAndRedirectString.contains(eventSuffix),
           let dictionary = notification.object as? [String: Any],
           let identifier = dictionary["identifier"] as? String,
           let url = dictionary["url"] as? String {
            parameters["prApp"] = identifier
            parameters["prStoreUrl"] = url

        } else if eventsRequiringOnlyIdentifier.contains(eventSuffix),
                  let prApp = notification.object as? String,
                  !prApp.isEmpty {
            parameters["prApp"] = prApp
        }

        if let eventName = discoverEventMapping[eventSuffix]?.rawValue {
            tracker?.trackEvent(name: eventName, parameters: parameters.isEmpty ? nil : parameters)
        }
    }

    // Note: TO BE REMOVED?
    func receiveCardInfoNotification(_ notification: NSNotification) {
        let eventPrefix = "\(Constants.notificationBaseName).cardinfo."
        let eventPrefixCount = eventPrefix.count
        guard eventPrefixCount < notification.name.rawValue.count else {
            return
        }

        let key = notification.name.rawValue[eventPrefixCount..<notification.name.rawValue.count]
        if let eventName = cardInfoEventMapping?[key] as? String {
            tracker?.trackEvent(name: eventName, parameters: nil)
        }
    }

    func receiveSSODialogNotification(_ notification: NSNotification) {
        var pageIdentifier: String?
        if let aPageIdentifier = notification.object as? String {
            pageIdentifier = aPageIdentifier
        }
        var parameters = [String: Any]()
        if let pageIdentifier = pageIdentifier,
           !pageIdentifier.isEmpty {
            parameters["page_id"] = pageIdentifier
        }
        tracker?.trackEvent(name: AnalyticsManager.Event.Name.pageVisit, parameters: parameters)
    }

    func receiveCredentialsNotification(_ notification: NSNotification) {
        var eventName: String?
        if notification.name.rawValue == "\(Constants.notificationBaseName).ssocredentialfound" {
            eventName = AnalyticsManager.Event.Name.SSOCredentialFound

        } else {
            eventName = AnalyticsManager.Event.Name.loginCredentialFound
        }

        var parameters = [String: Any]()
        if let params = notification.object as? [String: Any],
           let source = params["source"] as? String {
            parameters["source"] = source
        }

        if let eventName = eventName {
            tracker?.trackEvent(name: eventName, parameters: parameters)
        }
    }

    func receiveCustomEventNotification(_ notification: NSNotification) {
        guard let parameters = notification.object as? [String: Any] else {
            return
        }
        tracker?.trackEvent(name: AnalyticsManager.Event.Name.custom, parameters: parameters)
    }
}

// MARK: - Store & retrieve login/logout state & tracking identifier.

private extension RAnalyticsExternalCollector {
    func update() {
        guard let userStorageHandler = userStorageHandler else {
            RLogger.warning("RAnalyticsExternalCollector can't be created without userStorageHandler dependency")
            return
        }
        isLoggedIn = userStorageHandler.bool(forKey: Constants.loginStateKey)
        trackingIdentifier = userStorageHandler.string(forKey: Constants.trackingIdentifierKey)
        userIdentifier = userStorageHandler.string(forKey: Constants.userIdentifierKey)

        // Note: loginMethod is set and got as NSNumber in RAnalytics version <= 7.x - _RAnalyticsExternalCollector.m
        let result = (userStorageHandler.object(forKey: Constants.loginMethodKey) as? NSNumber)?.uintValue ?? 0
        loginMethod = AnalyticsManager.State.LoginMethod(rawValue: result) ?? .other
    }
}

// MARK: - Helpers

private extension RAnalyticsExternalCollector {
    func addNotificationName(_ name: String, selector: Selector) {
        NotificationCenter.default.addObserver(self,
                                               selector: selector,
                                               name: NSNotification.Name(rawValue: name),
                                               object: nil)
    }
}
