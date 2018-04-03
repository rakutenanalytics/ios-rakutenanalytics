#import <RAnalytics/RAnalyticsDefines.h>
#import <RAnalytics/RAnalyticsTracker.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * Concrete implementation of @ref RAnalyticsTracker that sends events to RAT.
 *
 * @attention Application developers **MUST** configure the instance by setting
 * the `RATAccountIdentifier` and `RATAppIdentifier` keys in their app's Info.plist.
 *
 * @class RATTracker RATTracker.h <RAnalytics/RATTracker.h>
 */
RSDKA_EXPORT @interface RATTracker : NSObject<RAnalyticsTracker>

/**
 * Retrieve the shared instance.
 *
 * @par Swift 3
 * This method is exposed as **RATTracker.shared()**.
 *
 * @return The shared instance.
 */
+ (instancetype)sharedInstance RSDKA_SWIFT3_NAME(shared());

/**
 * Create a RAT specific event.
 *
 * @par Swift 3
 * This method is exposed as **.event(withEventType:parameters:)**.
 *
 * @param eventType       RAT event type
 * @param parameters      Optional RAT parameters 
 *
 * @note For a list of RAT parameters and their names, see the [RAT Generic IDL](https://git.rakuten-it.com/projects/RG/repos/rg/browse/ratGeneric.idl ) document.
 */
- (RAnalyticsEvent *)eventWithEventType:(NSString *)eventType parameters:(NSDictionary RSDKA_GENERIC(NSString *, id) * __nullable)parameters;

/**
 * This is the URL of RAT server which this module uploads records to.
 *
 * @return URL of the server.
 */
+ (NSURL *)endpointAddress;

/**
 * Will pass valid Rp cookie to completionHandler as soon as it is available.
 *
 * If a valid cookie is cached it will be returned immediately. Otherwise a new cookie will be retrieved
 * from RAT, which might take time or be delayed depending on network connectivity.
 *
 * @param completionHandler  Returns valid cookie or nil cookie and an error in case of failure
 */
- (void)getRpCookieCompletionHandler:(void (^)(NSHTTPCookie *cookie, NSError *error))completionHandler;
@end

NS_ASSUME_NONNULL_END
