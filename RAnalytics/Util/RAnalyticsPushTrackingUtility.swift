import Foundation

internal enum RPushTrackingKeys {
    /// Info.plist key whose value holds the name of the App Group set by the App.
    static let AppGroupIdentifierPlistKey = "RPushAppGroupIdentifier"
    static let OpenCountSentUserDefaultKey = "com.analytics.push.sentOpenCount"
}

/// Constructs the tracking identifier from the push payload.
@objc public final class RAnalyticsPushTrackingUtility: NSObject {
    private enum PushKeys {
        static let aps = "aps"
        static let alert = "alert"
        static let title = "title"
        static let body = "body"
        static let contentAvailable = "content-available"
        static let rid = "rid"
        static let notificationId = "notification_id"
        static let nid = "nid"
        static let msg = "msg"
    }

    /// - Returns: The tracking identifier from the push payload.
    @objc public static func trackingIdentifier(fromPayload payload: [AnyHashable: Any]) -> String? {
        let aps = payload[PushKeys.aps] as? [AnyHashable: Any]
        let rid = payload[PushKeys.rid] as? String
        let nid = payload[PushKeys.notificationId] as? String

        // This ordering is important
        if let dict = aps,
           isSilentPushNotification(apsPayload: dict) {
            return nil

        } else if let str = rid,
                  !str.isEmpty {
            return "\(PushKeys.rid):\(str)"

        } else if let str = nid,
                  !str.isEmpty {
            return "\(PushKeys.nid):\(str)"

        } else if let dict = aps,
                  dict[PushKeys.alert] != nil,
                  let encryptedMessage = getQualifyingEncryptedMessage(aps: dict) {
            return "\(PushKeys.msg):\(encryptedMessage)"
        }
        return nil
    }

    /// - Returns: `true` or `false` based on the existence of the tracking identifier in the App Group User Defaults.
    @objc public dynamic static func analyticsEventHasBeenSent(with trackingIdentifier: String?) -> Bool {
        PushEventHandler(bundle: Bundle.main, userDefaultsType: UserDefaults.self).eventHasBeenSent(with: trackingIdentifier)
    }
}

// MARK: - Utils

private extension RAnalyticsPushTrackingUtility {
    static func isSilentPushNotification(apsPayload: [AnyHashable: Any]) -> Bool {
        // A push notification is a silent push notification if content available is true and
        // the alert part is not in the payload
        if let contentAvailable = apsPayload[PushKeys.contentAvailable] as? NSNumber,
           apsPayload[PushKeys.alert] == nil {
            return contentAvailable.boolValue
        }
        return false
    }

    static func getQualifyingEncryptedMessage(aps: [AnyHashable: Any]) -> String? {
        // Otherwise, fallback to .aps.alert if that's a string, or, if that's
        // a dictionary, for either .aps.alert.body or .aps.alert.title
        var msg = aps[PushKeys.alert]
        if let content = msg as? [AnyHashable: Any] {
            msg = content[PushKeys.body] ?? content[PushKeys.title]
        }

        if let str = msg as? String, str.isEmpty {
            return nil
        }
        return (msg as? String)?.ratEncrypt
    }
}
