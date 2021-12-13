import Foundation

protocol PushEventHandleable {
    func isEventAlreadySent(with trackingIdentifier: String?) -> Bool
    @discardableResult func cacheEvent(for trackingIdentifier: String) -> Bool
    @discardableResult func clearCache() -> Bool
}

/// `PushEventHandler` handles the Push Tracking Identifier Cache.
struct PushEventHandler {
    let sharedUserStorageHandler: UserStorageHandleable?

    /// Create a new instance of `PushEventHandler` with an App Group User Defaults.
    ///
    /// - Parameter sharedUserStorageHandler: the App Group User Defaults.
    init(sharedUserStorageHandler: UserStorageHandleable?) {
        self.sharedUserStorageHandler = sharedUserStorageHandler
    }
}

// MARK: - PushEventHandleable

extension PushEventHandler: PushEventHandleable {
    /// - Parameter trackingIdentifier: the push tracking identifier
    ///
    /// - Returns: `true` or `false` based on the existence of the push tracking identifier in the App Group User Defaults.
    func isEventAlreadySent(with trackingIdentifier: String?) -> Bool {
        guard let trackingIdentifier = trackingIdentifier,
              let domain = sharedUserStorageHandler?.dictionary(forKey: RPushTrackingKeys.OpenCountSentUserDefaultKey),
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
    func cacheEvent(for trackingIdentifier: String) -> Bool {
        guard let sharedUserStorageHandler = sharedUserStorageHandler else {
            return false
        }
        var openSentMap = [String: Bool]()
        openSentMap[trackingIdentifier] = true
        sharedUserStorageHandler.set(value: openSentMap, forKey: RPushTrackingKeys.OpenCountSentUserDefaultKey)
        return true
    }

    /// Clear the push cache in the App Group User Defaults.
    @discardableResult
    func clearCache() -> Bool {
        guard let sharedUserStorageHandler = sharedUserStorageHandler else {
            return false
        }
        sharedUserStorageHandler.removeObject(forKey: RPushTrackingKeys.OpenCountSentUserDefaultKey)
        return true
    }
}
