import Foundation
#if canImport(RSDKUtils)
import struct RSDKUtils.RLogger
#else // SPM version
import RLogger
#endif

protocol AnalyticsEventTrackable {
    var delegate: AnalyticsManageable? { get set }
    func track()
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
    internal func track() {
        let cachedDarwinEvents = pushEventHandler.cachedDarwinEvents()

        cachedDarwinEvents.forEach { eventDictionary in
            guard let eventName = eventDictionary[PushEventPayloadKeys.eventNameKey] as? String else {
                return
            }
            let eventParameters = eventDictionary[PushEventPayloadKeys.eventParametersKey] as? [String: Any]
            let event = RAnalyticsEvent(name: eventName, parameters: eventParameters)
            let isProcessed = delegate?.process(event) ?? false

            let isTracked = isProcessed ? "tracked" : "not tracked"
            let message = "AnalyticsEventTracker event is \(isTracked): \(event.name) \(event.parameters)"
            RLogger.debug(message: message)
        }

        pushEventHandler.clearDarwinEventsCache()
    }
}
