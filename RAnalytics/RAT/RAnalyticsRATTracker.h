#import <RAnalytics/RAnalyticsDefines.h>
#import <RAnalytics/RAnalyticsTracker.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * Concrete implementation of @ref RAnalyticsTracker that sends events to RAT.
 *
 * @attention Application developers **MUST** configure the instance by setting
 * the `RATAccountIdentifier` and `RATAppIdentifier` keys in their app's Info.plist.
 *
 * @class RAnalyticsRATTracker RAnalyticsRATTracker.h <RAnalytics/RAnalyticsRATTracker.h>
 */
RSDKA_EXPORT @interface RAnalyticsRATTracker : NSObject<RAnalyticsTracker>

/**
 * Retrieve the shared instance.
 *
 * @par Swift
 * This method is exposed as **RAnalyticsRATTracker.shared()**.
 *
 * @return The shared instance.
 */
+ (instancetype)sharedInstance RSDKA_SWIFT_NAME(shared());

/**
 * Create a RAT specific event.
 *
 * @par Swift
 * This method is exposed as **.event(withEventType:parameters:)**.
 *
 * @param eventType       RAT event type
 * @param parameters      Optional RAT parameters
 */
- (RAnalyticsEvent *)eventWithEventType:(NSString *)eventType parameters:(NSDictionary<NSString *, id> * __nullable)parameters;

/**
 * This is the URL of RAT server which this module uploads records to.
 *
 * @return URL of the server.
 */
+ (NSURL *)endpointAddress;

@end

NS_ASSUME_NONNULL_END
