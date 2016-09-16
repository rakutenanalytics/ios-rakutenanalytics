/*
 * © Rakuten, Inc.
 * authors: "Rakuten Ecosystem Mobile" <ecosystem-mobile@mail.rakuten.com>
 */
#import <RSDKAnalytics/RSDKAnalyticsDefines.h>
#import <RSDKAnalytics/RSDKAnalyticsTracker.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * Concrete implementation of @ref RSDKAnalyticsTracker that sends events to RAT.
 *
 * @attention Application developers **MUST** configure the instance by calling RATTracker::configureWithAccountId:
 * and RATTracker::configureWithApplicationId:.
 *
 * @class RATTracker RATTracker.h <RSDKAnalytics/RATTracker.h>
 */
RSDKA_EXPORT @interface RATTracker : NSObject<RSDKAnalyticsTracker>

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
 * Method for configuring account identifier.
 *
 * @par Swift 3
 * This method is exposed as **.configure(withAccountId:)**.
 *
 * @param accountIdentifier       Account identifier, e.g.\ `1` for Rakuten Ichiba Japan, `3` for Rakuten Books, etc.
 *
 * @note Account identifier will be sent as the **acc** (`ACCOUNT_ID`) RAT parameter. See
 * the [RAT Generic IDL](https://git.rakuten-it.com/projects/RG/repos/rg/browse/ratGeneric.idl)
 * for more information.
 */
- (void)configureWithAccountId:(int64_t)accountIdentifier;

/**
 * Method for configuring application identifier.
 *
 * @par Swift 3
 * This method is exposed as **.configure(withApplicationId:)**.
 *
 * @param applicationIdentifier       Application identifier, e.g.\ `14` for Singapore Mall.
 *
 * @note Application identifier will be sent as the **aid** (`SERVICE_ID`) RAT parameter. See
 * the [RAT Generic IDL](https://git.rakuten-it.com/projects/RG/repos/rg/browse/ratGeneric.idl)
 * for more information.
 */
- (void)configureWithApplicationId:(int64_t)applicationIdentifier;

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
- (RSDKAnalyticsEvent *)eventWithEventType:(NSString *)eventType parameters:(NSDictionary RSDKA_GENERIC(NSString *, id) * __nullable)parameters;

@end

/// @name Notifications

/**
 * The RATTracker sends this notification when it is about to make a request to upload a group of records to RAT servers.
 * `NSNotification.object` is the JSON payload being uploaded, in its unserialized `NSArray` form.
 *
 * @ingroup AnalyticsConstants
 */
RSDKA_EXPORT NSString *const RATWillUploadNotification;

/**
 * The RATTracker sends this notification after an upload failed.
 *
 * `object` is a the JSON payload that was being uploaded, in its unserialized
 * NSArray form.
 * `userInfo` contains a `NSError` instance under the key `NSUnderlyingErrorKey`, that uses the `NSURLErrorDomain` domain.
 *
 * @ingroup AnalyticsConstants
 */
RSDKA_EXPORT NSString *const RATUploadFailureNotification;

/**
 * The RATTracker sends this notification after an upload succeeded.
 *
 * `object` is a the JSON payload that was being uploaded, in its unserialized
 * `NSArray` form.
 *
 * @ingroup AnalyticsConstants
 */
RSDKA_EXPORT NSString *const RATUploadSuccessNotification;


/**
 * @deprecated Please use RATWillUploadNotification instead.
 * @ingroup AnalyticsConstants
 */
RSDKA_EXPORT NSString *const RSDKAnalyticsWillUploadNotification DEPRECATED_MSG_ATTRIBUTE("Please use RATWillUploadNotification instead.");

/**
 * @deprecated Please use RATUploadFailureNotification instead.
 * @ingroup AnalyticsConstants
 */
RSDKA_EXPORT NSString *const RSDKAnalyticsUploadFailureNotification DEPRECATED_MSG_ATTRIBUTE("Please use RATUploadFailureNotification instead.");

/**
 * @deprecated Please use RATUploadSuccessNotification instead.
 * @ingroup AnalyticsConstants
 */
RSDKA_EXPORT NSString *const RSDKAnalyticsUploadSuccessNotification DEPRECATED_MSG_ATTRIBUTE("Please use RATUploadSuccessNotification instead.");

NS_ASSUME_NONNULL_END
