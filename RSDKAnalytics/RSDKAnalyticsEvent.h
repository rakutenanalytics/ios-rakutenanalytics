/*
 * © Rakuten, Inc.
 * authors: "Rakuten Ecosystem Mobile" <ecosystem-mobile@mail.rakuten.com>
 */
#import <RSDKAnalytics/RSDKAnalyticsDefines.h>
#import "RSDKAnalyticsManager.h"

NS_ASSUME_NONNULL_BEGIN

/**
 * A single analytics event. Use RSDKAnalyticsEvent::track: method for tracking an event.
 * Events are tracked by trackers, a custom tracker can be add as a tracker by using RSDKAnalyticsManager::addTracker:error:.
 * If an event is tracked, the tracker will process it by using RSDKAnalyticsTracker::processEvent:state:.
 * When an event is processed, it is added to the database and uploaded to server.
 *
 * @class RSDKAnalyticsEvent RSDKAnalyticsEvent.h <RSDKAnalytics/RSDKAnalyticsEvent.h>
 */
RSDKA_EXPORT RSDKA_SWIFT3_NAME(RSDKAnalyticsManager.Event) @interface RSDKAnalyticsEvent : NSObject<NSSecureCoding, NSCopying>

/*
 * Name of the event.
 * This allows custom trackers to recognize and process standard events.
 *
 * @attention Unprefixed names are reserved for standard events. For custom events, or
 * events targetting specific trackers, please use a domain notation (e.g. `kobo.pageRead`).
 * The default tracker, RSDKAnalyticsRATTracker processes an event if the event name has a "rat." prefix.
 * A RAT-specific event tracked by RSDKAnalyticsRATTracker can be created 
 * by using RSDKAnalyticsRATTracker::eventWithEventType:parameters:.
 */
@property (nonatomic, readonly, copy) NSString *name;

/*
 * Optional payload, for passing additional parameters to custom/3rd-party trackers.
 */
@property (nonatomic, readonly, copy) NSDictionary RSDKA_GENERIC(NSString *, id) *parameters;

/**
 * This method for creating a new event object.
 *
 * @attention A RAT-specific event tracked by RSDKAnalyticsRATTracker can be created
 * by using RSDKAnalyticsRATTracker::eventWithEventType:parameters:.
 *
 * @param name  Name of the event, the SDK provides standard events whose names are provided in Event.Name.
 *              For custom events, or events targetting specific trackers, please use a domain notation (e.g. `kobo.pageRead`).
 * @param parameters  Optional payload, for passing additional parameters to custom/3rd-party trackers.
 *
 * @note For a list of RAT parameters and their names, see the [RAT Generic IDL](https://git.rakuten-it.com/projects/RG/repos/rg/browse/ratGeneric.idl ) document.
 *
 * @return New RSDKAnalyticsEvent object.
 */
- (instancetype)initWithName:(NSString *)name parameters:(NSDictionary RSDKA_GENERIC(NSString *, id) *)parameters NS_DESIGNATED_INITIALIZER;

/*
 * Convenience method for tracking an event.
 * After calling this method the event is tracked by trackers in tracker list. 
 * An singleton instance of RSDKAnalyticsRATTracker is created and added to tracker list in RSDKAnalyticsManager's initializer.
 * A custom tracker can be add as a tracker by using RSDKAnalyticsManager::addTracker:error:.
 * If an event is tracked, the tracker will process it by using RSDKAnalyticsTracker::processEvent:state:.
 * When an event is processed, it is added to the database and uploaded to server.
 */
- (void)track;
@end

/// @internal
struct RSDKA_SWIFT3_NAME(RSDKAnalyticsEvent.Name) RSDKAnalyticsManagerEventName { };

/*
 * Event triggered on first launch after installation or reinstallation.
 * Always followed by a .sessionStart event.
 */
RSDKA_EXPORT NSString *const RSDKAnalyticsInitialLaunchEventName  RSDKA_SWIFT3_NAME(RSDKAnalyticsManagerEventName.initialLaunch);

/*
 * Event triggered on every launch, as well as resume from background when
 * the life cycle session timeout has been exceeded.
 */
RSDKA_EXPORT NSString *const RSDKAnalyticsSessionStartEventName  RSDKA_SWIFT3_NAME(RSDKAnalyticsManagerEventName.sessionStart);

/*
 * Event triggered when the app goes into background or the session times out.
 */
RSDKA_EXPORT NSString *const RSDKAnalyticsSessionEndEventName  RSDKA_SWIFT3_NAME(RSDKAnalyticsManagerEventName.sessionEnd);

/*
 * Event triggered when a view controller is shown.
 */
RSDKA_EXPORT NSString *const RSDKAnalyticsPageVisitEventName  RSDKA_SWIFT3_NAME(RSDKAnalyticsManagerEventName.pageVisit);

/*
 * Event triggered on the first launch after an update.
 * Always followed by a .sessionStart event.
 */
RSDKA_EXPORT NSString *const RSDKAnalyticsApplicationUpdateEventName  RSDKA_SWIFT3_NAME(RSDKAnalyticsManagerEventName.applicationUpdate);

/*
 * Event triggered before .sessionStart if the application's last run resulted in a crash.
 */
RSDKA_EXPORT NSString *const RSDKAnalyticsCrashEventName  RSDKA_SWIFT3_NAME(RSDKAnalyticsManagerEventName.crash);

/*
 * Event triggered when a user logs in.
 */
RSDKA_EXPORT NSString *const RSDKAnalyticsLoginEventName  RSDKA_SWIFT3_NAME(RSDKAnalyticsManagerEventName.login);

/*
 * Event triggered when a user logs out.
 */
RSDKA_EXPORT NSString *const RSDKAnalyticsLogoutEventName  RSDKA_SWIFT3_NAME(RSDKAnalyticsManagerEventName.logout);

/*
 * Event triggered when the application handles a push notification.
 */
RSDKA_EXPORT NSString *const RSDKAnalyticsPushNotificationEventName  RSDKA_SWIFT3_NAME(RSDKAnalyticsManagerEventName.pushNotification);

/*
 * Event triggered on first run after app install with or without version change
 */
RSDKA_EXPORT NSString *const RSDKAnalyticsInstallEventName  RSDKA_SWIFT3_NAME(RSDKAnalyticsManagerEventName.install);

NS_ASSUME_NONNULL_END
