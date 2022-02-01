import Foundation
#if canImport(RSDKUtils)
import struct RSDKUtils.RLogger
#else // SPM version
import RLogger
#endif

/// This class checks if an event should be processed.
final class EventChecker {
    var shouldTrackEventHandler: ((String) -> (Bool))?
    private let disabledEventsAtBuildTime: [String]?

    init(disabledEventsAtBuildTime: [String]?) {
        self.disabledEventsAtBuildTime = disabledEventsAtBuildTime
    }

    private func shouldTrackEventAtBuildtime(_ eventName: String) -> Bool {
        guard let disabledEventsAtBuildTime = disabledEventsAtBuildTime,
              disabledEventsAtBuildTime.contains(eventName) else {
            return true
        }
        RLogger.debug(message: "\(eventName) is disabled at build time")
        return false
    }

    private func shouldTrackEventAtRuntime(_ eventName: String) -> Bool {
        if let shouldTrackEventHandler = shouldTrackEventHandler, !shouldTrackEventHandler(eventName) {
            RLogger.debug(message: "\(eventName) is disabled at runtime")
            return false
        }
        return true
    }
}

// MARK: - Should process event

extension EventChecker {
    /// Returns a Boolean value indicating if the event should be processed.
    ///
    /// - Parameter eventName: The event name to be checked
    /// - Returns: `false` if the event is contained in `RATDisabledEventsList` array in the `RAnalyticsConfiguration.plist` file or if the event is not authorized by the `shouldTrackEventHandler` closure.
    ///   `true`.
    ///
    /// Note: The Runtime configuration (`shouldTrackEventHandler`) overrides the Build time configuration (`RATDisabledEventsList`)
    func shouldProcess(_ eventName: String) -> Bool {
        guard shouldTrackEventHandler != nil else {
            return shouldTrackEventAtBuildtime(eventName)
        }
        return shouldTrackEventAtRuntime(eventName)
    }
}
