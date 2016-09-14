/*
 * © Rakuten, Inc.
 * authors: "Rakuten Ecosystem Mobile" <ecosystem-mobile@mail.rakuten.com>
 */
#import <RSDKAnalytics/RSDKAnalyticsDefines.h>

NS_ASSUME_NONNULL_BEGIN

@class RSDKAnalyticsEvent;
@class RSDKAnalyticsState;

/**
 * Interface for tracker which can process an object of RSDKAnalyticsEvent.
 * The tracker comforming this protocol will process events passed from the manager.
 *
 * @par Swift 3
 * This protocol is exposed as **Tracker**.
 *
 * @protocol RSDKAnalyticsTracker RSDKAnalyticsTracker.h <RSDKAnalytics/RSDKAnalyticsTracker.h>
 */
RSDKA_EXPORT RSDKA_SWIFT3_NAME(Tracker) @protocol RSDKAnalyticsTracker <NSObject>

/**
 * Called by RSDKAnalyticsManager when an event is to be processed.
 *
 * @param event  The event to process.
 * @param state  The current state, as provided by the manager. This contains useful information to process the event.
 *
 * @return `YES` if the recipient consumed the event, `NO` if it doesn't support it.
 */
- (BOOL)processEvent:(RSDKAnalyticsEvent *)event state:(RSDKAnalyticsState *)state RSDKA_SWIFT3_NAME(process(event:state:));

@end

NS_ASSUME_NONNULL_END
