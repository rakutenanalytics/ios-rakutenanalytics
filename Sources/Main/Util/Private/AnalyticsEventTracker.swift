import Foundation
#if canImport(RSDKUtils)
import struct RSDKUtils.RLogger
#else // SPM version
import RLogger
#endif

protocol AnalyticsEventTrackable {
    var delegate: AnalyticsManageable? { get set }
    func track(_ completion: (Error?) -> Void)
}

/// `AnalyticsEventTracker` track an array of events stored in the app group cache.
internal struct AnalyticsEventTracker {
    private let pushEventHandler: PushEventHandleable
    weak var delegate: AnalyticsManageable?

    /// Create a new instance of `AnalyticsEventTracker`.
    ///
    /// - Parameters:
    ///    - pushEventHandler: the push event handler.
    internal init(pushEventHandler: PushEventHandleable) {
        self.pushEventHandler = pushEventHandler
    }
}

extension AnalyticsEventTracker: AnalyticsEventTrackable {
    /// Track an array of events stored in the app group cache.
    ///
    /// - Note: the app group cache is cleared when all events are tracked.
    internal func track(_ completion: (Error?) -> Void) {
        pushEventHandler.cachedEvents { result in
            switch result {
            case .success(let cachedEvents):
                cachedEvents.forEach { eventDictionary in
                    guard let eventName = eventDictionary[PushEventPayloadKeys.eventNameKey] as? String,
                          let eventParameters = eventDictionary[PushEventPayloadKeys.eventParametersKey] as? [String: Any] else {
                        return
                    }
                    let event = RAnalyticsEvent(name: eventName, parameters: eventParameters)
                    _ = delegate?.process(event)
                    RLogger.debug(message: "AnalyticsEventTracker event is tracked: \(event.name) \(event.parameters)")
                }

                pushEventHandler.clearEventsCache { error in
                    completion(error)
                }

            case .failure(let error):
                ErrorRaiser.raise(.detailedError(domain: ErrorDomain.analyticsEventTrackerErrorDomain,
                                                 code: ErrorCode.analyticsEventTrackerCantTrackEvent.rawValue,
                                                 description: ErrorDescription.analyticsEventTrackerCantTrackEvent,
                                                 reason: error.localizedDescription))
                completion(error)
            }
        }
    }
}
