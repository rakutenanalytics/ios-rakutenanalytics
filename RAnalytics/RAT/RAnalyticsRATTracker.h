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
 *
 * @note For a list of RAT parameters and their names, see the [RAT Generic IDL](https://git.rakuten-it.com/projects/RG/repos/rg/browse/ratGeneric.idl ) document.
 */
- (RAnalyticsEvent *)eventWithEventType:(NSString *)eventType parameters:(NSDictionary<NSString *, id> * __nullable)parameters;

/**
 * This is the URL of RAT server which this module uploads records to.
 *
 * @return URL of the server.
 */
+ (NSURL *)endpointAddress;

/**
 * @deprecated Deprecated. Clients should use RAnalyticsRpCookieFetcher instead.
 *
 * Will pass valid Rp cookie to completionHandler as soon as it is available.
 *
 * If a valid cookie is cached it will be returned immediately. Otherwise a new cookie will be retrieved
 * from RAT, which might take time or be delayed depending on network connectivity.
 *
 * @param completionHandler  Returns valid cookie or nil cookie and an error in case of failure
 */
- (void)getRpCookieCompletionHandler:(void (^)(NSHTTPCookie * _Nullable cookie, NSError * _Nullable error))completionHandler DEPRECATED_MSG_ATTRIBUTE("Clients should use RAnalyticsRpCookieFetcher instead");
@end

NS_ASSUME_NONNULL_END
