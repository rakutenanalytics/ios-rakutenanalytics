import Foundation
import RSDKUtils

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

            case .failure(let error):
                RLogger.debug(message: "AnalyticsEventTracker error: \(error.localizedDescription)")
            }
        }
        // Note: the cache is cleared when a new rich push is expanded.
    }
}
