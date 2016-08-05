/*
 * © Rakuten, Inc.
 * authors: "Rakuten Ecosystem Mobile" <ecosystem-mobile@mail.rakuten.com>
 */
#import <RSDKAnalytics/RSDKAnalyticsDefines.h>

NS_ASSUME_NONNULL_BEGIN

@class RSDKAnalyticsEvent;
@class RSDKAnalyticsState;

/*
 * Interface for tracker which can process an object of RSDKAnalyticsEvent.
 * The tracker comforming this protocol will process events passed from the manager.
 *
 * @protocol RSDKAnalyticsTracker RSDKAnalyticsRATTracker.h <RSDKAnalytics/RSDKAnalyticsRATTracker.h>
 */
RSDKA_EXPORT RSDKA_SWIFT3_NAME(Tracker) @protocol RSDKAnalyticsTracker <NSObject>
/*
 * Process an event.
 * @param event  An event is processed.
 * @param state  A state object which is processed with the event.
 *
 * @return true if it processed the event, false otherwise
 */
- (BOOL)processEvent:(RSDKAnalyticsEvent *)event state:(RSDKAnalyticsState *)state;

@end

/*
 * RAT tracker comforming @protocol RSDKAnalyticsTracker for processing events.
 * When an event is processed by RAT tracker, it is first saved on-disk, 
 * then uploaded asynchronously to the RAT server, on the background queue.
 *
 * @attention A singleton instance of this class is created in RSDKAnalyticsManager's initializer 
 * and added to tracker list. The application must configure RAT tracker with `configureWithAccountId:`
 * and `configureWithApplicationId:` for configuring account identifier and application identifier.
 *
 * @class RSDKAnalyticsRATTracker RSDKAnalyticsRATTracker.h <RSDKAnalytics/RSDKAnalyticsRATTracker.h>
 */
RSDKA_EXPORT RSDKA_SWIFT3_NAME(RATTracker) @interface RSDKAnalyticsRATTracker : NSObject<RSDKAnalyticsTracker>

/**
 * Retrieve the shared instance.
 *
 * @note **Swift 3+:** This method is now called `shared()`.
 *
 * @return The shared instance.
 */
+ (instancetype)sharedInstance RSDKA_SWIFT3_NAME(shared());

/**
 * Method for configuring account identifier.
 * @param accountIdentifier       Account identifier, e.g.\ `1` for Rakuten Ichiba Japan, `3` for Rakuten Books, etc.
 * @note Account identifier will be sent as the **acc** (`ACCOUNT_ID`) RAT parameter. See
 * the [RAT Generic IDL](https://git.rakuten-it.com/projects/RG/repos/rg/browse/ratGeneric.idl)
 * for more information.
 */
- (void)configureWithAccountId:(int64_t)accountIdentifier;

/**
 * Method for configuring application identifier.
 * @param applicationIdentifier       Application identifier, e.g.\ `14` for Singapore Mall. 
 * @note Application identifier will be sent as the **aid** (`SERVICE_ID`) RAT parameter. See
 * the [RAT Generic IDL](https://git.rakuten-it.com/projects/RG/repos/rg/browse/ratGeneric.idl)
 * for more information.
 */
- (void)configureWithApplicationId:(int64_t)applicationIdentifier;

/*
 * Create a RAT specific event.
 * @param eventType       RAT event type
 * @param parameters      Optional RAT parameters 
 *
 * @note For a list of RAT parameters and their names, see the [RAT Generic IDL](https://git.rakuten-it.com/projects/RG/repos/rg/browse/ratGeneric.idl ) document.
 */
- (RSDKAnalyticsEvent *)eventWithEventType:(NSString *)eventType parameters:(NSDictionary RSDKA_GENERIC(NSString *, id) *)parameters;

@end

NS_ASSUME_NONNULL_END
