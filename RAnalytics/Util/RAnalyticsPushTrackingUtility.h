#import <RAnalytics/RAnalyticsDefines.h>
#import <RAnalytics/RAnalyticsEvent.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * Constructs the tracking identifier from the push payload.
 */
RSDKA_EXPORT @interface RAnalyticsPushTrackingUtility: NSObject

/**
 * @return The tracking identifier from the push payload.
 */
+ (nullable NSString*)trackingIdentifierFromPayload:(NSDictionary*)payload;

/**
 * @return Returns true or false based on the existence of the tracking identifier in the App Group User Defaults.
 */
+ (BOOL)analyticsEventHasBeenSentWith:(nullable NSString*)trackingIdentifier;

@end

/**
 * Info.plist key whose value holds the name of the App Group set by the App.
 */
RSDKA_EXPORT NSString *const RPushAppGroupIdentifierPlistKey;
RSDKA_EXPORT NSString *const RPushOpenCountSentUserDefaultKey;

NS_ASSUME_NONNULL_END
