#import <RAnalytics/RAnalyticsDefines.h>
#import <RAnalytics/RAnalyticsEvent.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * Utility class for calculating the tracking identifier for the push notification payload.
 */
RSDKA_EXPORT @interface RAnalyticsPushTrackingUtility: NSObject

/**
 * @return Gets the tracking identifier from the push notification payload based on the specificiations.
 */
+ (nullable NSString*)trackingIdentifierFromPayload:(NSDictionary*)payload;

/**
 * @return True or False based on the existence of the tracking identifier in the App Group User Defaults.
 */
+ (BOOL)analyticsEventHasBeenSentWith:(nullable NSString*)trackingIdentifier;

@end

/**
 * Info.plist key whose value holds the name of the App Group set by the App.
 */
RSDKA_EXPORT NSString *const RPushAppGroupIdentifierPlistKey;
RSDKA_EXPORT NSString *const RPushOpenCountSentUserDefaultKey;

NS_ASSUME_NONNULL_END
