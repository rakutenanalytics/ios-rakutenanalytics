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

    /// Convenience method for tracking a push notify event.
    ///
    /// - Parameters:
    ///     - pushNotificationPayload: The entire payload of a push notification.
    ///
    /// - Returns: A newly-initialized push notify event with the tracking identifier set into the parameter list.
    @objc public convenience init(pushNotificationPayload: [String: Any]) {
        var parameters = [String: Any]()
        if let trackingId = RAnalyticsPushTrackingUtility.trackingIdentifier(fromPayload: pushNotificationPayload) {
            parameters[AnalyticsManager.Event.Parameter.pushTrackingIdentifier] = trackingId
        }

        self.init(name: AnalyticsManager.Event.Name.pushNotification, parameters: parameters)
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
