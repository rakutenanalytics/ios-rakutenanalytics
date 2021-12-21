import Foundation
import RSDKUtils

// MARK: - JSONSerializable

protocol JSONSerializable {
    static func data(withJSONObject obj: Any, options opt: JSONSerialization.WritingOptions) throws -> Data
    static func jsonObject(with data: Data, options opt: JSONSerialization.ReadingOptions) throws -> Any
}

extension JSONSerialization: JSONSerializable {}

// MARK: - PushEventHandlerKeys

enum PushEventHandlerKeys {
    /// The key to retrieve the sent open count event.
    static let OpenCountSentUserDefaultKey = "com.analytics.push.sentOpenCount"

    /// The key to retrieve the cached open count events to track.
    static let OpenCountCachedEventsKey = "com.analytics.push.sentOpenCount.events.list"

    /// The cached open count events file name,
    static let OpenCountCachedEventsFileName = "analyticsEventsCache.json"
}

// MARK: - PushEventError

enum PushEventError: Error, Equatable {
    case fileUrlIsNil
    case fileDoesNotExist
    case nativeError(error: Error)

    static func == (lhs: Self, rhs: Self) -> Bool {
        if case .fileUrlIsNil = lhs,
           case .fileUrlIsNil = rhs {
            return true

        } else if case .fileDoesNotExist = lhs,
                  case .fileDoesNotExist = rhs {
            return true

        } else if case .nativeError(let lError) = lhs,
                  case .nativeError(let rError) = rhs {
            return (lError as NSError) == (rError as NSError)
        }

        return false
    }
}

// MARK: - PushEventHandleable

protocol PushEventHandleable {
    func isEventAlreadySent(with trackingIdentifier: String?) -> Bool
    @discardableResult func cacheEvent(for trackingIdentifier: String) -> Bool
    @discardableResult func clearCache() -> Bool
    func cachedEvents(completion: (Result<[[String: Any]], PushEventError>) -> Void)
    func save(events: [[String: Any]], completion: ((PushEventError?) -> Void))
    func clearEventsCache(completion: ((PushEventError?) -> Void))
}

// MARK: - PushEventHandler

/// `PushEventHandler` handles the Push Tracking Identifier Cache.
internal struct PushEventHandler {
    internal let sharedUserStorageHandler: UserStorageHandleable?
    private let appGroupId: String?
    private let fileManager: FileManageable
    private let serializerType: JSONSerializable.Type
    private let coordinator = NSFileCoordinator()

    /// Create a new instance of `PushEventHandler` with an App Group User Defaults.
    ///
    /// - Parameter sharedUserStorageHandler: the App Group User Defaults.
    internal init(sharedUserStorageHandler: UserStorageHandleable?,
                  appGroupId: String?,
                  fileManager: FileManageable,
                  serializerType: JSONSerializable.Type) {
        self.sharedUserStorageHandler = sharedUserStorageHandler
        self.appGroupId = appGroupId
        self.fileManager = fileManager
        self.serializerType = serializerType

        do {
            let fileURL = try eventsCacheFileURL()
            fileManager.createSafeFile(at: fileURL)

        } catch {
            RLogger.error(message: "PushEventHandler error: \(error.localizedDescription)")
        }
    }

    /// - Returns: the events cache file URL if it exists
    /// - Throws: an error otherwise.
    private func eventsCacheFileURL() throws -> URL {
        guard let appGroupId = appGroupId,
              let url = fileManager.containerURL(forSecurityApplicationGroupIdentifier: appGroupId) else {
            throw PushEventError.fileUrlIsNil
        }
        return url.appendingPathComponent(PushEventHandlerKeys.OpenCountCachedEventsFileName)
    }
}

// MARK: - PushEventHandleable

extension PushEventHandler: PushEventHandleable {
    // MARK: - App Group User Defaults

    /// - Parameter trackingIdentifier: the push tracking identifier
    ///
    /// - Returns: `true` or `false` based on the existence of the push tracking identifier in the App Group User Defaults.
    internal func isEventAlreadySent(with trackingIdentifier: String?) -> Bool {
        guard let trackingIdentifier = trackingIdentifier,
              let domain = sharedUserStorageHandler?.dictionary(forKey: PushEventHandlerKeys.OpenCountSentUserDefaultKey),
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
        sharedUserStorageHandler.set(value: openSentMap, forKey: PushEventHandlerKeys.OpenCountSentUserDefaultKey)
        return true
    }

    /// Clear the push cache in the App Group User Defaults.
    @discardableResult
    internal func clearCache() -> Bool {
        guard let sharedUserStorageHandler = sharedUserStorageHandler else {
            return false
        }
        sharedUserStorageHandler.removeObject(forKey: PushEventHandlerKeys.OpenCountSentUserDefaultKey)
        return true
    }

    // MARK: - App Group File Cache

    /// Retrieve the cached events array from the App Group File Cache.
    ///
    /// - Parameters:
    ///    - completion: the completion that notifies when the cached events is retrieved or not.
    internal func cachedEvents(completion: (Result<[[String: Any]], PushEventError>) -> Void) {
        do {
            let url = try eventsCacheFileURL()

            coordinator.coordinate(readingItemAt: url, options: .withoutChanges, error: nil) { url in
                do {
                    guard fileManager.fileExists(atPath: url.path) else {
                        completion(.failure(.fileUrlIsNil))
                        return
                    }

                    let data = try Data(contentsOf: url)
                    let events = try serializerType.jsonObject(with: data, options: .allowFragments)

                    guard let events = events as? [[String: Any]] else {
                        completion(.success([[String: Any]]()))
                        return
                    }
                    completion(.success(events))

                } catch {
                    completion(.failure(.nativeError(error: error)))
                }
            }

        } catch {
            guard let anError = error as? PushEventError else {
                completion(.failure(.nativeError(error: error)))
                return
            }
            completion(.failure(anError))
        }
    }

    /// Save the updated events array to the App Group File Cache.
    ///
    /// - Warning: the existing file is replaced.
    ///
    /// - Parameters:
    ///    - events: the events to save.
    ///    - completion: the completion that notifies when the saving task has been completed or failed.
    internal func save(events: [[String: Any]], completion: ((PushEventError?) -> Void)) {
        do {
            let url = try eventsCacheFileURL()

            coordinator.coordinate(writingItemAt: url,
                                   options: .forReplacing,
                                   error: nil) { (url) in
                do {
                    let data = try serializerType.data(withJSONObject: events, options: [])

                    guard fileManager.fileExists(atPath: url.path) else {
                        completion(.fileDoesNotExist)
                        return
                    }

                    // Note: write(to:) does not fail when the file does not exist
                    try data.write(to: url)
                    completion(nil)

                } catch {
                    completion(.nativeError(error: error))
                }
            }

        } catch {
            guard let anError = error as? PushEventError else {
                completion(.nativeError(error: error))
                return
            }
            completion(anError)
        }
    }

    /// Clear the events array in the App Group File Cache.
    ///
    /// - Parameters:
    ///    - completion: the completion that notifies when the clearing task has been completed or failed.
    internal func clearEventsCache(completion: ((PushEventError?) -> Void)) {
        save(events: [], completion: completion)
    }
}
