import Foundation

/// A single analytics event. Use the RAnalyticsEvent::track: method for tracking the event.
@objc public final class RAnalyticsEvent: NSObject {
    /// Name of the event.
    /// This allows custom @ref RAnalyticsTracker "trackers" to recognize and process both
    /// - Reference:
    ///     AnalyticsEvents "standard events" and custom ones.
    ///
    /// - Attention:
    ///     Unprefixed names are reserved for @ref AnalyticsEvents "standard events". For custom events, or
    ///     events targetting specific @ref RAnalyticsTracker "trackers", please use a domain notation (e.g. `{app-name}.pageRead`).
    ///
    /// - Note:
    ///     The @ref RAnalyticsRATTracker "RAT tracker" provided by this SDK processes events with a name of the form `rat.etype`.
    ///     For convenience, you can create RAT-specific events directly using RAnalyticsRATTracker::eventWithEventType:parameters:.
    ///
    /// - See: AnalyticsEvents
    @objc public private(set) var name: String

    /// Optional payload, for passing additional parameters to custom/3rd-party trackers.
    @objc public private(set) var parameters: [String: Any]

    /// Standard event names
    public enum Name {
        /// Event triggered on first launch after installation or reinstallation.
        /// Always followed by a .sessionStart event.
        public static let initialLaunch = "_rem_init_launch"

        /// Event triggered on every launch, as well as resume from background when
        /// the life cycle session timeout has been exceeded.
        public static let sessionStart = "_rem_launch"

        /// Event triggered when the app goes into background.
        public static let sessionEnd = "_rem_end_session"

        /// Event triggered on the first launch after an update.
        public static let applicationUpdate = "_rem_update"

        /// Event triggered when a user logs in.
        public static let login = "_rem_login"

        /// Event triggered when a user login fails.
        public static let loginFailure = "_rem_login_failure"

        /// Event triggered when a user logs out.
        public static let logout = "_rem_logout"

        /// Event triggered on first run after app install with or without version change.
        public static let install = "_rem_install"

        /// Event triggered internally and converted to `pv` event for the Page Visit.
        /// See `pageVisitForRAT`.
        public static let pageVisit = "_rem_visit"

        /// Event triggered internally and converted to `pv` and `deeplink` events for the App-to-App referral tracking.
        public static let applink = "_rem_applink"

        /// Event triggered:
        /// - when a view controller is shown.
        /// - when the app is opened from a deeplink. In this case, the event is sent to the referred app (destination app).
        public static let pageVisitForRAT = "pv"

        /// Event triggered when the app is opened from a deeplink.
        /// - Note: this event is sent to the referral app (source app).
        public static let deeplink = "deeplink"

        /// Event triggered when a push notification is opened.
        /// This event has a parameter named `push_notify_value`.
        /// - Note: This event is renamed to `_rem_push_notify` on RAT backend.
        public static let pushNotificationExternal = "_rem_push_notify_external"

        /// Event sent to RAT when a push notification is opened.
        static let pushNotificationOpenedForRAT = "_rem_push_notify"

        /// Event triggered when a push notification is received.
        /// This event has a parameter named `push_notify_value`.
        /// This event has an optional parameter named `RAnalyticsEvent.Parameter.pushRequestIdentifier`.
        /// - Note: This event is renamed to `_rem_push_received` on RAT backend.
        public static let pushNotificationReceivedExternal = "_rem_push_received_external"

        /// Event sent to RAT when a push notification is received.
        static let pushNotificationReceivedForRAT = "_rem_push_received"

        /// Event to trigger manually for conversion tracking.
        /// This event has a parameter named `RAnalyticsEvent.Parameter.pushRequestIdentifier`.
        /// This event has a parameter named `RAnalyticsEvent.Parameter.pushNotificationConversion`.
        public static let pushNotificationConversion = "_rem_push_cv"

        /// Event triggered when a PNP auto registration occurs.
        /// This event has a non-empty parameter named `deviceId`.
        /// This event has a non-empty parameter named `pnpClientId`.
        /// - Note: This event is renamed to `_rem_push_auto_register` on RAT backend.
        public static let pushAutoRegistrationExternal = "_rem_push_auto_register_external"

        /// Event sent to RAT when a PNP auto registration occurs.
        static let pushAutoRegistrationForRAT = "_rem_push_auto_register"

        /// Event triggered when a PNP auto unregistration occurs.
        /// This event has a non-empty parameter named `deviceId`.
        /// This event has a non-empty parameter named `pnpClientId`.  
        /// - Note: This event is renamed to `_rem_push_auto_unregister` on RAT backend.
        public static let pushAutoUnregistrationExternal = "_rem_push_auto_unregister_external"

        /// Event sent to RAT when a PNP auto unregistration occurs.
        static let pushAutoUnregistrationForRAT = "_rem_push_auto_unregister"

        /// Event triggered when an SSO credential is found.
        public static let SSOCredentialFound = "_rem_sso_credential_found"

        /// Event triggered when a login credential is found.
        public static let loginCredentialFound = "_rem_login_credential_found"

        /// Event triggered at launch to track credential strategies.
        public static let credentialStrategies = "_rem_credential_strategies"

        /// Custom event name
        /// Event used to package an event name and its data.
        /// This event has parameters `RAnalyticsEvent.Parameter.eventName` and `RAnalyticsEvent.Parameter.eventData`.
        public static let custom = "_analytics_custom"

        /// Event triggered when the geolocation is updated.
        public static let geoLocation = "loc"
    }

    /// Event parameters
    public enum Parameter {
        // MARK: - Standard event parameters

        /// Parameter for the logout method sent together with a logout event.
        public static let logoutMethod = "logout_method"

        // MARK: - Push Notification parameters

        /// Parameter for the tracking identifier sent together with a push notification event.
        public static let pushTrackingIdentifier = "tracking_id"

        /// Parameter for the request identifier with a push notification event.
        public static let pushRequestIdentifier = "push_request_id"

        /// Parameter for the conversion tracking with a push notification event.
        public static let pushConversionAction = "push_cv_action"

        // MARK: - Page parameters

        public static let pageId = "page_id"

        // MARK: - PNP parameters

        /// Parameter for the PNP Registration Requests Optimization
        public static let deviceId = "deviceId"

        /// Parameter for the PNP Registration Requests Optimization
        public static let pnpClientId = "pnpClientId"

        // MARK: - Custom event parameters

        /// Parameter for the event name sent with a custom event.
        public static let eventName = "eventName"

        /// Parameter for the event data sent with a custom event.
        public static let eventData = "eventData"

        /// Parameter for the event top level object sent with a custom event.
        public static let topLevelObject = "topLevelObject"

        /// Parameter for custom account number object sent with a custom event.
        public static let customAccNumber = "customAccNumber"
    }

    /// Standard event parameter values
    public enum LogoutMethod {
        /// Logout method when the user was logged out of the current app only.
        public static let local = "local"

        /// Logout method when the user was logged out of all apps and the account was deleted from the keychain.
        public static let global = "global"
    }

    @available(*, unavailable)
    override init() {
        self.name = ""
        self.parameters = [:]
        super.init()
    }

    /// Create a new event.
    ///
    /// - Attention:
    ///     For RAT-specific events, please use RAnalyticsRATTracker::eventWithEventType:parameters: instead.
    ///
    /// - Parameters:
    ///     - name: Name of the event. We provides @ref AnalyticsEvents "standard events" as part of our SDK.
    ///     For custom events, or events targetting specific trackers, please use a domain notation (e.g. `{app-name}.pageRead`).
    ///     - parameters:  Optional payload, for passing additional parameters to custom/3rd-party trackers.
    ///
    /// - Returns: A newly-initialized event.
    @objc public init(name: String, parameters: [String: Any]?) {
        self.name = name
        self.parameters = parameters ?? [:]
        super.init()
    }

    @objc public override var hash: Int {
        var hasher = Hasher()
        hasher.combine(name)
        hasher.combine(parameters as NSDictionary?)
        return hasher.finalize()
    }

    @objc public override func isEqual(_ object: Any?) -> Bool {
        guard let object = object as? RAnalyticsEvent else {
            return false
        }
        return name == object.name && parameters == object.parameters
    }
}

// MARK: - Tracking

extension RAnalyticsEvent {
    /// Convenience method for tracking an event.
    /// This does exactly the same as `AnalyticsManager.shared().process(event)`.
    @discardableResult
    @objc public func track() -> Bool {
        AnalyticsManager.shared().process(self)
    }
}

// MARK: - Operator ==

func == (lhs: [String: Any], rhs: [String: Any]) -> Bool {
    return NSDictionary(dictionary: lhs).isEqual(to: rhs)
}

// MARK: - NSSecureCoding

extension RAnalyticsEvent: NSSecureCoding {
    enum CodingKeys: String {
        case name
        case parameters
    }

    public static var supportsSecureCoding: Bool {
        true
    }

    public func encode(with coder: NSCoder) {
        coder.encode(name, forKey: CodingKeys.name.rawValue)
        coder.encode(NSDictionary(dictionary: parameters), forKey: CodingKeys.parameters.rawValue)
    }

    public convenience init?(coder: NSCoder) {
        guard let name = coder.decodeObject(of: NSString.self, forKey: CodingKeys.name.rawValue) else { return nil }
        guard let parameters = coder.decodeObject(of: NSDictionary.self, forKey: CodingKeys.parameters.rawValue) else { return nil }
        self.init(name: name as String, parameters: parameters as? [String: Any])
    }
}

// MARK: - NSCopying

extension RAnalyticsEvent: NSCopying {
    @objc public func copy(with zone: NSZone? = nil) -> Any {
        RAnalyticsEvent(name: name, parameters: parameters)
    }
}

// MARK: - AnalyticsManager.Event

/// Note: The Event class is created in AnalyticsManager in order to keep the compatibility with apps using previous versions of RAnalytics version <= 7.x
public extension AnalyticsManager {
    typealias Event = RAnalyticsEvent
}
