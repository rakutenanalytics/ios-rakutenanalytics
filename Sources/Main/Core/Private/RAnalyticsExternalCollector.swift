import Foundation
#if canImport(RSDKUtils)
import struct RSDKUtils.RLogger
#else // SPM version
import RLogger
#endif

enum LoginFailureKey {
    static let type = "type"
    static let raeError = "rae_error"
    static let raeErrorMessage = "rae_error_message"
    static let idsdkError = "idsdk_error"
    static let idsdkErrorMessage = "idsdk_error_message"
}

protocol UserIdentifiable {
    var trackingIdentifier: String? { get }
    var userIdentifier: String? { get set }
}

/// This class tracks login, logout and push events.
/// It creates event corressponding to each event, sends it to RAnalyticsManager's instance to process.
final class RAnalyticsExternalCollector: UserIdentifiable {
    enum Constants {
        static let loginStateKey = "com.rakuten.esd.sdk.properties.analytics.loginInformation.loginState"
        static let trackingIdentifierKey = "com.rakuten.esd.sdk.properties.analytics.loginInformation.trackingIdentifier"
        static let easyIdentifierKey = "com.rakuten.esd.sdk.properties.analytics.loginInformation.easyIdentifier"
        static let userIdentifierKey = "com.rakuten.esd.sdk.properties.analytics.loginInformation.userIdentifier"
        static let loginMethodKey = "com.rakuten.esd.sdk.properties.analytics.loginInformation.loginMethod"
        static let notificationBaseName = "com.rakuten.esd.sdk.events"
        static let idTokenEvent = "idtoken_memberid"
    }

    /// The login state information is being stored in shared preferences.
    private(set) var isLoggedIn: Bool = false {
        willSet(newValue) {
            guard isLoggedIn != newValue else {
                return
            }
            userStorageHandler?.set(value: newValue, forKey: Constants.loginStateKey)
            userStorageHandler?.synchronize()
        }
    }

    /// The RAE user identifier.
    ///
    /// - Note: The tracking identifier is being stored in shared preferences.
    private(set) var trackingIdentifier: String? {
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

    /// The overriden RAE user identifier.
    ///
    /// - Note: The user identifier is being stored in shared preferences.
    /// - Note: `userIdentifier` is only used to override `trackingIdentifier` in the RAT payload.
    var userIdentifier: String? {
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

    /// The IDSDK user identifier.
    ///
    /// - Note: The easy identifier is being stored in shared preferences.
    var easyIdentifier: String? {
        willSet(newValue) {
            guard easyIdentifier != newValue else {
                return
            }
            if let easyIdentifier = newValue,
               !easyIdentifier.isEmpty {
                userStorageHandler?.set(value: easyIdentifier, forKey: Constants.easyIdentifierKey)

            } else {
                userStorageHandler?.removeObject(forKey: Constants.easyIdentifierKey)
            }
            userStorageHandler?.synchronize()
        }
    }

    /// The login method is being stored in shared preferences.
    private(set) var loginMethod: AnalyticsManager.State.LoginMethod = .other {
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
    private let discoverEventMapping: [String: Notification.Name] = {
        ["visitPreview": .discoverPreviewVisit,
         "tapPreview": .discoverPreviewTap,
         "redirectPreview": .discoverPreviewRedirect,
         "tapShowMore": .discoverPreviewShowMore,
         "visitPage": .discoverPageVisit,
         "tapPage": .discoverPageTap,
         "redirectPage": .discoverPageRedirect]
    }()
    private let loginEvents = ["password", "one_tap", "other", Constants.idTokenEvent]
    private let loginFailureEvents = ["failure", "failure.\(Constants.idTokenEvent)"]
    private let logoutEvents = ["local", "global", Constants.idTokenEvent]
    private let credentialEvents = ["ssocredentialfound", "logincredentialfound"]
    private let eventsRequiringOnlyIdentifier = ["tapPage", "tapPreview"]
    private let eventsRequiringIdentifierAndRedirectString = ["redirectPage", "redirectPreview"]
    private let userStorageHandler: UserStorageHandleable?
    private let tracker: Trackable?

    @available(*, unavailable)
    init() {
        self.userStorageHandler = nil
        self.tracker = nil
    }

    /// Creates an external collector
    ///
    /// - Parameters:
    ///   - dependenciesContainer: The dependencies container.
    ///         It requires intances of these types: UserStorageHandleable, Trackable
    ///

    /// - Returns: An instance of RAnalyticsExternalCollector.
    init(dependenciesContainer: SimpleDependenciesContainable) {
        self.userStorageHandler = dependenciesContainer.userStorageHandler
        self.tracker = dependenciesContainer.tracker

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
        loginFailureEvents.forEach {
            addNotificationName("\(Constants.notificationBaseName).login.\($0)", selector: #selector(receiveLoginFailureNotification(_:)))
        }
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

// MARK: - Tracking

extension RAnalyticsExternalCollector {
    func trackLogin(_ loginType: LoginType, usedLoginMethod: String = "") {
        update()

        switch loginType {
        case .userIdentifier(let anIdentifier): // RAE Login
            self.trackingIdentifier = anIdentifier
            self.easyIdentifier = nil

        case .easyIdentifier(let anIdentifier): // IDSDK Login
            self.easyIdentifier = anIdentifier
            self.trackingIdentifier = nil

        case .unknown: ()
        }

        isLoggedIn = true

        // For login we want to provide the logged-in state with each event, and each event tracker can know how the user logged in, so the loginMethod should be persisted.

        loginMethod = RAnalyticsLoginMethod.type(from: usedLoginMethod)

        tracker?.trackEvent(name: AnalyticsManager.Event.Name.login, parameters: nil)
    }

    func trackLoginFailure(_ failureType: LoginFailureType) {
        update()

        isLoggedIn = false
        trackingIdentifier = nil
        easyIdentifier = nil

        var parameters = [String: Any]()

        switch failureType {
        case .userIdentifier(let errorParams):
            parameters[LoginFailureKey.raeError] = errorParams[LoginFailureKey.raeError]
            parameters[LoginFailureKey.type] = errorParams[LoginFailureKey.type]
            if let raeErrorMessage = errorParams[LoginFailureKey.raeErrorMessage] {
                parameters[LoginFailureKey.raeErrorMessage] = raeErrorMessage
            }

        case .easyIdentifier(let error):
            parameters[LoginFailureKey.idsdkError] = error.localizedDescription
            parameters[LoginFailureKey.idsdkErrorMessage] = (error as NSError).localizedFailureReason

        case .unknown: ()
        }

        tracker?.trackEvent(name: AnalyticsManager.Event.Name.loginFailure, parameters: parameters.isEmpty ? nil : parameters)
    }

    func trackLogout(_ logoutMethod: String = "") {
        update()

        isLoggedIn = false
        trackingIdentifier = nil
        easyIdentifier = nil

        var parameters = [String: Any]()

        switch logoutMethod {
        case "\(Constants.notificationBaseName).logout.local":
            parameters[AnalyticsManager.Event.Parameter.logoutMethod] = AnalyticsManager.Event.LogoutMethod.local

        case "\(Constants.notificationBaseName).logout.global":
            parameters[AnalyticsManager.Event.Parameter.logoutMethod] = AnalyticsManager.Event.LogoutMethod.global

        default: ()
        }

        tracker?.trackEvent(name: AnalyticsManager.Event.Name.logout, parameters: parameters)
    }
}

// MARK: - Handle notifications

@objc private extension RAnalyticsExternalCollector {
    func receiveLoginNotification(_ notification: NSNotification) {
        trackLogin(LoginType.type(from: notification.name.rawValue, with: notification.object as? String),
                   usedLoginMethod: notification.name.rawValue)
    }

    func receiveLoginFailureNotification(_ notification: NSNotification) {
        trackLoginFailure(LoginFailureType.type(from: notification.name.rawValue, with: notification.object))
    }

    func receiveLogoutNotification(_ notification: NSNotification) {
        trackLogout(notification.name.rawValue)
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
    func receiveSSODialogNotification(_ notification: NSNotification) {
        var pageIdentifier: String?
        if let aPageIdentifier = notification.object as? String {
            pageIdentifier = aPageIdentifier
        }
        var parameters = [String: Any]()
        if let pageIdentifier = pageIdentifier,
           !pageIdentifier.isEmpty {
            parameters[RAnalyticsEvent.Parameter.pageId] = pageIdentifier
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
            RLogger.warning(message: "RAnalyticsExternalCollector can't be created without userStorageHandler dependency")
            return
        }
        isLoggedIn = userStorageHandler.bool(forKey: Constants.loginStateKey)
        trackingIdentifier = userStorageHandler.string(forKey: Constants.trackingIdentifierKey)
        easyIdentifier = userStorageHandler.string(forKey: Constants.easyIdentifierKey)
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
                                               name: Notification.Name(rawValue: name),
                                               object: nil)
    }
}
