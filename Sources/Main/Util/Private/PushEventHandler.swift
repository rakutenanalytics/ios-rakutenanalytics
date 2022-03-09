import Foundation

// MARK: - JSONSerializable

protocol JSONSerializable {
    static func data(withJSONObject obj: Any, options opt: JSONSerialization.WritingOptions) throws -> Data
    static func jsonObject(with data: Data, options opt: JSONSerialization.ReadingOptions) throws -> Any
}

extension JSONSerialization: JSONSerializable {}

// MARK: - PushEventHandlerKeys

enum PushEventHandlerKeys {
    /// The key to retrieve the sent open count event.
    static let openCountSentUserDefaultKey = "com.analytics.push.sentOpenCount"

    /// The key to retrieve the cached open count events to track.
    static let openCountCachedEventsKey = "com.analytics.push.sentOpenCount.events.list"
}

// MARK: - PushEventHandleable

protocol PushEventHandleable {
    func isEventAlreadySent(with trackingIdentifier: String?) -> Bool
    @discardableResult func cacheEvent(for trackingIdentifier: String) -> Bool
    @discardableResult func clearCache() -> Bool
    func cachedDarwinEvents() -> [[String: Any]]
    func save(darwinEvents: [[String: Any]])
    func clearDarwinEventsCache()
}

// MARK: - PushEventHandler

/// `PushEventHandler` handles the Push Tracking Identifier Cache.
internal struct PushEventHandler {
    internal let sharedUserStorageHandler: UserStorageHandleable?
    private let appGroupId: String?

    /// Create a new instance of `PushEventHandler` with an App Group User Defaults.
    ///
    /// - Parameters:
    ///    - sharedUserStorageHandler: the App Group User Defaults.
    ///    - appGroupId: the App Group identifier.
    internal init(sharedUserStorageHandler: UserStorageHandleable?,
                  appGroupId: String?) {
        self.sharedUserStorageHandler = sharedUserStorageHandler
        self.appGroupId = appGroupId
    }
}

// MARK: - PushEventHandleable

extension PushEventHandler: PushEventHandleable {
    // MARK: - Open Count Event

    /// - Parameter trackingIdentifier: the push tracking identifier
    ///
    /// - Returns: `true` or `false` based on the existence of the push tracking identifier in the App Group User Defaults.
    internal func isEventAlreadySent(with trackingIdentifier: String?) -> Bool {
        guard let trackingIdentifier = trackingIdentifier,
              let domain = sharedUserStorageHandler?.dictionary(forKey: PushEventHandlerKeys.openCountSentUserDefaultKey),
              let result = domain[trackingIdentifier] as? Bool else {
            return false
        }
        return result
    }

    /// Cache only one trackingIdentifier in the App Group User Defaults.
    ///
    /// - Parameter trackingIdentifier: the push tracking identifier
    ///
    /// - Returns: `true` if the tracking identifier is cached, `false` otherwise.
    @discardableResult
    internal func cacheEvent(for trackingIdentifier: String) -> Bool {
        guard let sharedUserStorageHandler = sharedUserStorageHandler else {
            return false
        }
        var openSentMap = [String: Bool]()
        openSentMap[trackingIdentifier] = true
        sharedUserStorageHandler.set(value: openSentMap, forKey: PushEventHandlerKeys.openCountSentUserDefaultKey)
        return true
    }

    /// Clear the push cache in the App Group User Defaults.
    @discardableResult
    internal func clearCache() -> Bool {
        guard let sharedUserStorageHandler = sharedUserStorageHandler else {
            return false
        }
        sharedUserStorageHandler.removeObject(forKey: PushEventHandlerKeys.openCountSentUserDefaultKey)
        return true
    }

    // MARK: - Darwin Events

    /// Retrieve the cached Darwin events array from the App Group User Defaults.
    ///
    /// - Returns: the cached events.
    internal func cachedDarwinEvents() -> [[String: Any]] {
        guard let events = sharedUserStorageHandler?.array(forKey: PushEventHandlerKeys.openCountCachedEventsKey) as? [[String: Any]] else {
            return [[String: Any]]()
        }
        return events
    }

    /// Save the updated Darwin events array to the App Group User Defaults.
    ///
    /// - Parameters:
    ///    - darwinEvents: the events to save.
    internal func save(darwinEvents: [[String: Any]]) {
        sharedUserStorageHandler?.set(value: darwinEvents, forKey: PushEventHandlerKeys.openCountCachedEventsKey)
    }

    /// Clear the Darwin events array in the App Group User Defaults.
    internal func clearDarwinEventsCache() {
        sharedUserStorageHandler?.set(value: [], forKey: PushEventHandlerKeys.openCountCachedEventsKey)
    }
}
