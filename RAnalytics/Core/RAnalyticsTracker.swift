import Foundation

public typealias BatchingDelayBlock = () -> TimeInterval

/// Interface for tracker which can process an object of RAnalyticsEvent.
/// The tracker conforming to this protocol will process events passed from `AnalyticsManager` only if the tracker is added to `AnalyticsManager`'s trackers.
@objc(RAnalyticsTracker) public protocol Tracker: EndpointSettable {
    /// Called by RAnalyticsManager when an event is to be processed.
    ///
    /// - Parameters:
    ///     - event: The event to process.
    ///     - state: The current state, as provided by the manager. This contains useful information to process the event.
    ///
    /// - Returns: `true` if the recipient consumed the event, `false` if it doesn't support it.
    @objc(processEvent:state:) func process(event: RAnalyticsEvent, state: RAnalyticsState) -> Bool

    /// Method for configuring the batching delay.
    ///
    /// - Parameters:
    ///     - batchingDelay: Delivery delay in seconds. Value should be >= 0 and <= 60.
    @objc(setBatchingDelay:) optional func set(batchingDelay: TimeInterval)

    /// Method for configuring the dynamic batching delay.
    ///
    /// - Parameters:
    ///     - batchingDelayBlock: The block returns delivery delay in seconds. Value should be >= 0 and <= 60.
    @objc(setBatchingDelayWithBlock:) optional func set(batchingDelayBlock: @escaping BatchingDelayBlock)
}
