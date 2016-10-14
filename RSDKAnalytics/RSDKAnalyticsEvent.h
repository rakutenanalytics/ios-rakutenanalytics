/*
 * © Rakuten, Inc.
 * authors: "Rakuten Ecosystem Mobile" <ecosystem-mobile@mail.rakuten.com>
 */
#import <RSDKAnalytics/RSDKAnalyticsDefines.h>
#import "RSDKAnalyticsManager.h"

NS_ASSUME_NONNULL_BEGIN

/**
 * A single analytics event. Use the RSDKAnalyticsEvent::track: method for tracking the event.
 *
 * @par Swift 3
 * This class is exposed as **AnalyticsManager.Event**.
 *
 * @class RSDKAnalyticsEvent RSDKAnalyticsEvent.h <RSDKAnalytics/RSDKAnalyticsEvent.h>
 * @ingroup AnalyticsCore
 */
RSDKA_EXPORT RSDKA_SWIFT3_NAME(AnalyticsManager.Event) @interface RSDKAnalyticsEvent : NSObject<NSSecureCoding, NSCopying>

/**
 * Name of the event.
 * This allows custom @ref RSDKAnalyticsTracker "trackers" to recognize and process both
 * @ref AnalyticsEvents "standard events" and custom ones.
 *
 * @attention Unprefixed names are reserved for @ref AnalyticsEvents "standard events". For custom events, or
 * events targetting specific @ref RSDKAnalyticsTracker "trackers", please use a domain notation (e.g. `kobo.pageRead`).
 *
 * @note The @ref RATTracker "RAT tracker" provided by this SDK processes events with a name of the form `rat.etype`,
 * where `etype` is the standard RAT field going by that name. For convenience, you can create RAT-specific
 * events directly using RATTracker::eventWithEventType:parameters:.
 *
 * @see AnalyticsEvents
 */
@property (nonatomic, readonly, copy) NSString *name;

/**
 * Optional payload, for passing additional parameters to custom/3rd-party trackers.
 */
@property (nonatomic, readonly, copy) NSDictionary RSDKA_GENERIC(NSString *, id) *parameters;

/**
 * @internal
 */
- (instancetype)init NS_UNAVAILABLE;

/**
 * This method for creating a new event object.
 *
 * @attention For RAT-specific events, please use RATTracker::eventWithEventType:parameters: instead.
 *
 * @param name  Name of the event. We provides @ref AnalyticsEvents "standard events" as part of our SDK.
 *              For custom events, or events targetting specific trackers, please use a domain notation (e.g. `kobo.pageRead`).
 * @param parameters  Optional payload, for passing additional parameters to custom/3rd-party trackers.
 *
 * @return A newly-initialized event.
 *
 * @see AnalyticsEvents
 */
- (instancetype)initWithName:(NSString *)name parameters:(NSDictionary RSDKA_GENERIC(NSString *, id) * __nullable)parameters NS_DESIGNATED_INITIALIZER;

/**
 * Convenience method for tracking an event.
 * This does exactly the same as `[RSDKAnalyticsManager.sharedInstance process:event]`.
 */
- (void)track;
@end

/// @internal
struct RSDKA_SWIFT3_NAME(RSDKAnalyticsEvent.Name) RSDKAnalyticsEventName { };

/**
 * Event triggered on first launch after installation or reinstallation.
 * Always followed by a .sessionStart event.
 *
 * @par Swift 3
 * This value is exposed as **AnalyticsManager.Event.Name.initialLaunch**.
 *
 * @ingroup AnalyticsEvents
 */
RSDKA_EXPORT NSString *const RSDKAnalyticsInitialLaunchEventName  RSDKA_SWIFT3_NAME(RSDKAnalyticsEventName.initialLaunch);

/**
 * Event triggered on every launch, as well as resume from background when
 * the life cycle session timeout has been exceeded.
 *
 * @par Swift 3
 * This value is exposed as **AnalyticsManager.Event.Name.sessionStart**.
 *
 * @ingroup AnalyticsEvents
 */
RSDKA_EXPORT NSString *const RSDKAnalyticsSessionStartEventName  RSDKA_SWIFT3_NAME(RSDKAnalyticsEventName.sessionStart);

/**
 * Event triggered when the app goes into background.
 *
 * @par Swift 3
 * This value is exposed as **AnalyticsManager.Event.Name.sessionEnd**.
 *
 * @ingroup AnalyticsEvents
 */
RSDKA_EXPORT NSString *const RSDKAnalyticsSessionEndEventName  RSDKA_SWIFT3_NAME(RSDKAnalyticsEventName.sessionEnd);

/**
 * Event triggered on the first launch after an update.
 *
 * @par Swift 3
 * This value is exposed as **AnalyticsManager.Event.Name.applicationUpdate**.
 *
 * @ingroup AnalyticsEvents
 */
RSDKA_EXPORT NSString *const RSDKAnalyticsApplicationUpdateEventName  RSDKA_SWIFT3_NAME(RSDKAnalyticsEventName.applicationUpdate);

/**
 * Event triggered when a user logs in.
 *
 * @par Swift 3
 * This value is exposed as **AnalyticsManager.Event.Name.login**.
 *
 * @ingroup AnalyticsEvents
 */
RSDKA_EXPORT NSString *const RSDKAnalyticsLoginEventName  RSDKA_SWIFT3_NAME(RSDKAnalyticsEventName.login);

/**
 * Event triggered when a user logs out.
 *
 * @par Swift 3
 * This value is exposed as **AnalyticsManager.Event.Name.logout**.
 *
 * @ingroup AnalyticsEvents
 */
RSDKA_EXPORT NSString *const RSDKAnalyticsLogoutEventName  RSDKA_SWIFT3_NAME(RSDKAnalyticsEventName.logout);

/**
 * Event triggered on first run after app install with or without version change
 *
 * @par Swift 3
 * This value is exposed as **AnalyticsManager.Event.Name.install**.
 *
 * @ingroup AnalyticsEvents
 */
RSDKA_EXPORT NSString *const RSDKAnalyticsInstallEventName  RSDKA_SWIFT3_NAME(RSDKAnalyticsEventName.install);

/**
 * Event triggered when a view controller is shown.
 *
 * @par Swift 3
 * This value is exposed as **AnalyticsManager.Event.Name.pageVisit**.
 *
 * @ingroup AnalyticsEvents
 */
RSDKA_EXPORT NSString *const RSDKAnalyticsPageVisitEventName  RSDKA_SWIFT3_NAME(RSDKAnalyticsEventName.pageVisit);

/**
 * Event triggered when a push notification is received.
 * This event has a parameter named RSDKAnalyticPushNotificationTrackingIdentifierParameter
 *
 * @par Swift 3
 * This value is exposed as **AnalyticsManager.Event.Name.pushNotification**.
 *
 * @see RSDKAnalyticPushNotificationTrackingIdentifierParameter
 * @ingroup AnalyticsEvents
 */
RSDKA_EXPORT NSString *const RSDKAnalyticsPushNotificationEventName  RSDKA_SWIFT3_NAME(RSDKAnalyticsEventName.pushNotification);

/// @internal
struct RSDKA_SWIFT3_NAME(RSDKAnalyticsEvent.Parameter) RSDKAnalyticsParameter { };
/// @internal
struct RSDKA_SWIFT3_NAME(RSDKAnalyticsEvent.LogoutMethod) RSDKAnalyticsLogoutMethod { };


/**
 * Parameter for the logout method sent together with a logout event.
 *
 * @par Swift 3
 * This value is exposed as **AnalyticsManager.Event.Parameter.logoutMethod**.
 *
 * @see RSDKAnalyticsLogoutEventName
 * @see RSDKAnalyticsEventLogoutMethod
 * @ingroup AnalyticsConstants
 */
RSDKA_EXPORT NSString *const RSDKAnalyticsLogoutMethodEventParameter RSDKA_SWIFT3_NAME(RSDKAnalyticsParameter.logoutMethod);

/**
 * Parameter for the tracking identifier sent together with a push notification event.
 *
 * @par Swift 3
 * This value is exposed as **AnalyticsManager.Event.Parameter.pushTrackingIdentifier**.
 *
 * @see RSDKAnalyticsPushNotificationEventName
 * @ingroup AnalyticsConstants
 */
RSDKA_EXPORT NSString *const RSDKAnalyticPushNotificationTrackingIdentifierParameter RSDKA_SWIFT3_NAME(RSDKAnalyticsParameter.pushTrackingIdentifier);

/**
 * Logout method when the user was logged out of the current app only.
 *
 * @par Swift 3
 * This value is exposed as **AnalyticsManager.Event.LogoutMethod.local**.
 *
 * @see RSDKAnalyticsLogoutEventName
 * @see RSDKAnalyticsEventLogoutMethod
 * @ingroup AnalyticsConstants
 */
RSDKA_EXPORT NSString *const RSDKAnalyticsLocalLogoutMethod  RSDKA_SWIFT3_NAME(RSDKAnalyticsLogoutMethod.local);

/**
 * Logout method when the user was logged out of all apps and the account was deleted from the keychain.
 *
 * @par Swift 3
 * This value is exposed as **AnalyticsManager.Event.LogoutMethod.global**.
 *
 * @see RSDKAnalyticsLogoutEventName
 * @see RSDKAnalyticsEventLogoutMethod
 * @ingroup AnalyticsConstants
 */
RSDKA_EXPORT NSString *const RSDKAnalyticsGlobalLogoutMethod  RSDKA_SWIFT3_NAME(RSDKAnalyticsLogoutMethod.global);

NS_ASSUME_NONNULL_END
