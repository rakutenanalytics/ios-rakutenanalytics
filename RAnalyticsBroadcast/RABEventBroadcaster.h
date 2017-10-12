/*
 * © Rakuten, Inc.
 * authors: "Rakuten Ecosystem Mobile" <ecosystem-mobile@mail.rakuten.com>
 */

#import <RAnalyticsBroadcast/RAnalyticsBroadcast.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * Utility class to send broadcasts to analytics module for event tracking.
 *
 * If the app depends on [Analytics module](https://www.raksdtd.com/ios-sdk/analytics-latest) version 2.12.0
 * or newer it will be processed. If there is no compatible analytics module present nothing happens.
 *
 * Events will be sent with name as `etype` and data as `cp`.
 */
@interface RABEventBroadcaster : NSObject

/**
 * Send event and data to analytics module
 *
 * @param name   Name of event
 * @param object Event data (can be nil)
 */
+ (void)sendEventName:(NSString *)name dataObject:(NSDictionary<NSString *, id> * __nullable)object;

@end

NS_ASSUME_NONNULL_END
