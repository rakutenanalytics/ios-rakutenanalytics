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

/**
 * Method for configuring account identifier.
 *
 * @deprecated Please set the 'RATAccountIdentifier' key to your RAT account ID in your app's Info.plist instead.
 *
 * @par Swift 3
 * This method is exposed as **.configure(withAccountId:)**.
 *
 * @param accountIdentifier       Account identifier, e.g.\ `1` for Rakuten Ichiba Japan, `3` for Rakuten Books, etc.
 *
 * @note The value set by this method will override any RATAccountIdentifier key value.
 *
 * @note Account identifier will be sent as the **acc** (`ACCOUNT_ID`) RAT parameter. See
 * the [RAT Generic IDL](https://git.rakuten-it.com/projects/RG/repos/rg/browse/ratGeneric.idl)
 * for more information.
 */
- (void)configureWithAccountId:(int64_t)accountIdentifier DEPRECATED_MSG_ATTRIBUTE("Please set the RATAccountIdentifier key to your RAT account ID in your app's Info.plist instead.");

/**
 * Method for configuring application identifier.
 *
 * @deprecated Please set the 'RATAppIdentifier' key to your RAT application ID in your app's Info.plist instead.
 *
 * @par Swift 3
 * This method is exposed as **.configure(withApplicationId:)**.
 *
 * @param applicationIdentifier       Application identifier, e.g.\ `14` for Singapore Mall.
 *
 * @note The value set by this method will override any RATAppIdentifier key value.
 *
 * @note Application identifier will be sent as the **aid** (`SERVICE_ID`) RAT parameter. See
 * the [RAT Generic IDL](https://git.rakuten-it.com/projects/RG/repos/rg/browse/ratGeneric.idl)
 * for more information.
 */
- (void)configureWithApplicationId:(int64_t)applicationIdentifier DEPRECATED_MSG_ATTRIBUTE("Please set the RATAppIdentifier key to your RAT application ID in your app's Info.plist instead.");
@end

NS_ASSUME_NONNULL_END
