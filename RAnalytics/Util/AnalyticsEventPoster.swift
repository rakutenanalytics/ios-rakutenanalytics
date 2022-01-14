import Foundation
import RSDKUtils

// MARK: - PushEventPayloadKeys

internal enum PushEventPayloadKeys {
    internal static let eventNameKey = "eventName"
    internal static let eventParametersKey = "eventParameters"
}

// MARK: - AnalyticsDarwinNotification

internal enum AnalyticsDarwinNotification {
    internal static let eventsTrackingRequest: CFString = "com.rakuten.esd.sdk.notifications.analytics.events.tracking.request" as CFString
}

// MARK: - AnalyticsEventPoster

/// Use `AnalyticsEventPoster` from an iOS Extension in order to track an event.
public enum AnalyticsEventPoster {
    // MARK: - Public API

    /// Post a Darwin Notification in order to track an event.
    ///
    /// - Warning: Use it only from an iOS Extension.
    ///
    /// - Parameters:
    ///    - name: the event name.
    ///    - parameters: the event parameters.
    public static func post(name: String, parameters: [String: Any]?) {
        let pushEventHandler = PushEventHandler(sharedUserStorageHandler: UserDefaults(suiteName: Bundle.main.appGroupId),
                                                appGroupId: Bundle.main.appGroupId,
                                                fileManager: FileManager.default,
                                                serializerType: JSONSerialization.self)
        post(name: name,
             parameters: parameters,
             pushEventHandler: pushEventHandler)
    }

    // MARK: - Internal API

    /// Post a Darwin Notification in order to track an event.
    ///
    /// - Warning: Use it only from an iOS Extension.
    ///
    /// - Parameters:
    ///    - name: the event name.
    ///    - parameters: the event parameters.
    ///    - pushEventHandler: the push event handler.
    internal static func post(name: String,
                              parameters: [String: Any]?,
                              pushEventHandler: PushEventHandler) {
        pushEventHandler.cachedEvents { result in
            // Get the cached events
            var cachedEvents: [[String: Any]]
            switch result {
            case .success(let events):
                cachedEvents = events

            case .failure:
                cachedEvents = [[String: Any]]()
            }

            // Add the new event to track
            var eventDictionary: [String: Any] = [PushEventPayloadKeys.eventNameKey: name]
            if let parameters = parameters {
                eventDictionary[PushEventPayloadKeys.eventParametersKey] = parameters
            }
            cachedEvents.append(eventDictionary)

            // Save the new event to the cached events array
            pushEventHandler.save(events: cachedEvents) { anError in
                if let error = anError {
                    RLogger.debug(message: "AnalyticsEventPoster error: \(error.localizedDescription)")
                    return
                }
                // Track the new event
                DarwinNotificationHelper.send(notificationName: AnalyticsDarwinNotification.eventsTrackingRequest)
            }
        }
    }
}

enum DarwinNotificationHelper {
    /// Send a Darwin Notification.
    ///
    /// - Parameter notificationName: the Darwin Notification Name.
    internal static func send(notificationName: CFString) {
        CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(),
                                             CFNotificationName(rawValue: notificationName),
                                             nil,
                                             nil,
                                             true)
    }
}
