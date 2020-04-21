#import <RAnalytics/RAnalyticsDefines.h>

NS_ASSUME_NONNULL_BEGIN

@class RAnalyticsEvent;
@class RAnalyticsState;

/**
 * Interface for tracker which can process an object of RAnalyticsEvent.
 * The tracker conforming to this protocol will process events passed from the manager.
 *
 * @par Swift
 * This protocol is exposed as **Tracker**.
 *
 * @protocol RAnalyticsTracker RAnalyticsTracker.h <RAnalytics/RAnalyticsTracker.h>
 */
RSDKA_EXPORT RSDKA_SWIFT_NAME(Tracker) @protocol RAnalyticsTracker <NSObject>

@required
/**
 * Called by RAnalyticsManager when an event is to be processed.
 *
 * @param event  The event to process.
 * @param state  The current state, as provided by the manager. This contains useful information to process the event.
 *
 * @return `YES` if the recipient consumed the event, `NO` if it doesn't support it.
 */
- (BOOL)processEvent:(RAnalyticsEvent *)event state:(RAnalyticsState *)state RSDKA_SWIFT_NAME(process(event:state:));

@optional
/**
 * Method for configuring the batching delay.
 *
 * @param batchingDelay  Delivery delay in seconds. Value should be >= 0 and <= 60.
 */
- (void)setBatchingDelay:(NSTimeInterval)batchingDelay RSDKA_SWIFT_NAME(set(batchingDelay:));

/**
 * Method for configuring the dynamic batching delay.
 *
 * @param batchingDelayBlock  The block returns delivery delay in seconds. Value should be >= 0 and <= 60.
 */
- (void)setBatchingDelayWithBlock:(BatchingDelayBlock)batchingDelayBlock RSDKA_SWIFT_NAME(set(batchingDelayBlock:));

@end

NS_ASSUME_NONNULL_END
