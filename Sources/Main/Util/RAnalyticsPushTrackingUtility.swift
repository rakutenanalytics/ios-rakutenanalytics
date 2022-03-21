import Foundation

// MARK: - PnpReservedModel

private struct PnpReservedModel: Decodable {
    // MARK: - CodingKeys

    enum CodingKeys: String, CodingKey {
        case requestIdentifier = "request_id"
    }

    let requestIdentifier: String
}

// MARK: - PushNotificationModel

private struct PushNotificationModel: Decodable {
    // MARK: - CodingKeys

    enum CodingKeys: String, CodingKey {
        case pnpReserved = "_pnp_reserved"
    }

    let pnpReserved: PnpReservedModel
}

// MARK: - RAnalyticsPushTrackingUtility

/// Constructs the tracking identifier from the push payload.
@objc public final class RAnalyticsPushTrackingUtility: NSObject {
    private static let decoder = JSONDecoder()

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

    /// - Parameter payload: The APNS payload
    ///
    /// - Returns: The tracking identifier from the APNS push payload.
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
    @objc public static func analyticsEventHasBeenSent(with trackingIdentifier: String?) -> Bool {
        analyticsEventHasBeenSent(with: trackingIdentifier,
                                  sharedUserStorageHandler: UserDefaults(suiteName: Bundle.main.appGroupId),
                                  appGroupId: Bundle.main.appGroupId,
                                  fileManager: FileManager.default,
                                  serializerType: JSONSerialization.self)
    }

    internal static func analyticsEventHasBeenSent(with trackingIdentifier: String?,
                                                   sharedUserStorageHandler: UserStorageHandleable?,
                                                   appGroupId: String?,
                                                   fileManager: FileManageable,
                                                   serializerType: JSONSerializable.Type) -> Bool {
        PushEventHandler(sharedUserStorageHandler: sharedUserStorageHandler,
                         appGroupId: appGroupId).isEventAlreadySent(with: trackingIdentifier)
    }
}

// MARK: - Push Conversion Tracking

extension RAnalyticsPushTrackingUtility {
    /// - Parameter payload: The APNS push payload
    ///
    /// - Returns: The request identifier from the APNS push payload, `nil` otherwise if the APNS payload does not contain expected entries or if the APNS payload is malformed.
    @objc public static func pushRequestIdentifier(from payload: [AnyHashable: Any]) -> String? {
        guard let data = try? JSONSerialization.data(withJSONObject: payload, options: []),
              let model = try? decoder.decode(PushNotificationModel.self, from: data),
              !model.pnpReserved.requestIdentifier.isEmpty else {
            return nil
        }
        return model.pnpReserved.requestIdentifier
    }

    /// Method for tracking a push conversion event (`_rem_push_cv`).
    ///
    /// - Parameters:
    ///    - pushRequestIdentifier: The non-empty push request identifier.
    ///    - pushConversionAction: The non-empty push conversion action.
    ///
    /// - Throws: an error if `pushRequestIdentifier` is empty or if `pushConversionAction` is empty.
    @objc public static func trackPushConversionEvent(pushRequestIdentifier: String,
                                                      pushConversionAction: String) throws {
        guard !pushRequestIdentifier.isEmpty && !pushConversionAction.isEmpty else {
            throw ErrorConstants.pushConversionError
        }
        RAnalyticsEvent(pushRequestIdentifier: pushRequestIdentifier,
                        pushConversionAction: pushConversionAction).track()
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
