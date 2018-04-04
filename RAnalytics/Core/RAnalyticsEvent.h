#import <RAnalytics/RAnalyticsDefines.h>
#import <RAnalytics/RAnalyticsManager.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * A single analytics event. Use the RAnalyticsEvent::track: method for tracking the event.
 *
 * @par Swift 3
 * This class is exposed as **AnalyticsManager.Event**.
 *
 * @class RAnalyticsEvent RAnalyticsEvent.h <RAnalytics/RAnalyticsEvent.h>
 * @ingroup AnalyticsCore
 */
RSDKA_EXPORT RSDKA_SWIFT3_NAME(AnalyticsManager.Event) @interface RAnalyticsEvent : NSObject<NSSecureCoding, NSCopying>

/**
 * Name of the event.
 * This allows custom @ref RAnalyticsTracker "trackers" to recognize and process both
 * @ref AnalyticsEvents "standard events" and custom ones.
 *
 * @attention Unprefixed names are reserved for @ref AnalyticsEvents "standard events". For custom events, or
 * events targetting specific @ref RAnalyticsTracker "trackers", please use a domain notation (e.g. `kobo.pageRead`).
 *
 * @note The @ref RAnalyticsRATTracker "RAT tracker" provided by this SDK processes events with a name of the form `rat.etype`,
 * where `etype` is the standard RAT field going by that name. For convenience, you can create RAT-specific
 * events directly using RAnalyticsRATTracker::eventWithEventType:parameters:.
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
 * @attention For RAT-specific events, please use RAnalyticsRATTracker::eventWithEventType:parameters: instead.
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
 * This does exactly the same as `[RAnalyticsManager.sharedInstance process:event]`.
 */
- (void)track;
@end

/// @internal
struct RSDKA_SWIFT3_NAME(RAnalyticsEvent.Name) RAnalyticsEventName { };

/**
 * Event triggered on first launch after installation or reinstallation.
 * Always followed by a .sessionStart event.
 *
 * @par Swift 3
 * This value is exposed as **AnalyticsManager.Event.Name.initialLaunch**.
 *
 * @ingroup AnalyticsEvents
 */
RSDKA_EXPORT NSString *const RAnalyticsInitialLaunchEventName  RSDKA_SWIFT3_NAME(RAnalyticsEventName.initialLaunch);

/**
 * Event triggered on every launch, as well as resume from background when
 * the life cycle session timeout has been exceeded.
 *
 * @par Swift 3
 * This value is exposed as **AnalyticsManager.Event.Name.sessionStart**.
 *
 * @ingroup AnalyticsEvents
 */
RSDKA_EXPORT NSString *const RAnalyticsSessionStartEventName  RSDKA_SWIFT3_NAME(RAnalyticsEventName.sessionStart);

/**
 * Event triggered when the app goes into background.
 *
 * @par Swift 3
 * This value is exposed as **AnalyticsManager.Event.Name.sessionEnd**.
 *
 * @ingroup AnalyticsEvents
 */
RSDKA_EXPORT NSString *const RAnalyticsSessionEndEventName  RSDKA_SWIFT3_NAME(RAnalyticsEventName.sessionEnd);

/**
 * Event triggered on the first launch after an update.
 *
 * @par Swift 3
 * This value is exposed as **AnalyticsManager.Event.Name.applicationUpdate**.
 *
 * @ingroup AnalyticsEvents
 */
RSDKA_EXPORT NSString *const RAnalyticsApplicationUpdateEventName  RSDKA_SWIFT3_NAME(RAnalyticsEventName.applicationUpdate);

/**
 * Event triggered when a user logs in.
 *
 * @par Swift 3
 * This value is exposed as **AnalyticsManager.Event.Name.login**.
 *
 * @ingroup AnalyticsEvents
 */
RSDKA_EXPORT NSString *const RAnalyticsLoginEventName  RSDKA_SWIFT3_NAME(RAnalyticsEventName.login);


/**
 * Event triggered when a user login fails.
 *
 * @par Swift 3
 * This value is exposed as **AnalyticsManager.Event.Name.loginFailure**.
 *
 * @ingroup AnalyticsEvents
 */
RSDKA_EXPORT NSString *const RAnalyticsLoginFailureEventName  RSDKA_SWIFT3_NAME(RAnalyticsEventName.loginFailure);


/**
 * Event triggered when a user logs out.
 *
 * @par Swift 3
 * This value is exposed as **AnalyticsManager.Event.Name.logout**.
 *
 * @ingroup AnalyticsEvents
 */
RSDKA_EXPORT NSString *const RAnalyticsLogoutEventName  RSDKA_SWIFT3_NAME(RAnalyticsEventName.logout);

/**
 * Event triggered on first run after app install with or without version change
 *
 * @par Swift 3
 * This value is exposed as **AnalyticsManager.Event.Name.install**.
 *
 * @ingroup AnalyticsEvents
 */
RSDKA_EXPORT NSString *const RAnalyticsInstallEventName  RSDKA_SWIFT3_NAME(RAnalyticsEventName.install);

/**
 * Event triggered when a view controller is shown.
 *
 * @par Swift 3
 * This value is exposed as **AnalyticsManager.Event.Name.pageVisit**.
 *
 * @ingroup AnalyticsEvents
 */
RSDKA_EXPORT NSString *const RAnalyticsPageVisitEventName  RSDKA_SWIFT3_NAME(RAnalyticsEventName.pageVisit);

/**
 * Event triggered when a push notification is received.
 * This event has a parameter named RAnalyticsPushNotificationTrackingIdentifierParameter
 *
 * @par Swift 3
 * This value is exposed as **AnalyticsManager.Event.Name.pushNotification**.
 *
 * @see RAnalyticsPushNotificationTrackingIdentifierParameter
 * @ingroup AnalyticsEvents
 */
RSDKA_EXPORT NSString *const RAnalyticsPushNotificationEventName  RSDKA_SWIFT3_NAME(RAnalyticsEventName.pushNotification);

/// @internal
struct RSDKA_SWIFT3_NAME(RAnalyticsEvent.Parameter) RAnalyticsParameter { };
/// @internal
struct RSDKA_SWIFT3_NAME(RAnalyticsEvent.LogoutMethod) RAnalyticsLogoutMethod { };


/**
 * Parameter for the logout method sent together with a logout event.
 *
 * @par Swift 3
 * This value is exposed as **AnalyticsManager.Event.Parameter.logoutMethod**.
 *
 * @see RAnalyticsLogoutEventName
 * @see RAnalyticsEventLogoutMethod
 * @ingroup AnalyticsConstants
 */
RSDKA_EXPORT NSString *const RAnalyticsLogoutMethodEventParameter RSDKA_SWIFT3_NAME(RAnalyticsParameter.logoutMethod);

/**
 * Parameter for the tracking identifier sent together with a push notification event.
 *
 * @par Swift 3
 * This value is exposed as **AnalyticsManager.Event.Parameter.pushTrackingIdentifier**.
 *
 * @see RAnalyticsPushNotificationEventName
 * @ingroup AnalyticsConstants
 */
RSDKA_EXPORT NSString *const RAnalyticsPushNotificationTrackingIdentifierParameter RSDKA_SWIFT3_NAME(RAnalyticsParameter.pushTrackingIdentifier);

/**
 * Logout method when the user was logged out of the current app only.
 *
 * @par Swift 3
 * This value is exposed as **AnalyticsManager.Event.LogoutMethod.local**.
 *
 * @see RAnalyticsLogoutEventName
 * @see RAnalyticsEventLogoutMethod
 * @ingroup AnalyticsConstants
 */
RSDKA_EXPORT NSString *const RAnalyticsLocalLogoutMethod  RSDKA_SWIFT3_NAME(RAnalyticsLogoutMethod.local);

/**
 * Logout method when the user was logged out of all apps and the account was deleted from the keychain.
 *
 * @par Swift 3
 * This value is exposed as **AnalyticsManager.Event.LogoutMethod.global**.
 *
 * @see RAnalyticsLogoutEventName
 * @see RAnalyticsEventLogoutMethod
 * @ingroup AnalyticsConstants
 */
RSDKA_EXPORT NSString *const RAnalyticsGlobalLogoutMethod  RSDKA_SWIFT3_NAME(RAnalyticsLogoutMethod.global);

/**
 * Event triggered when an SSO credential is found.
 *
 * @par Swift 3
 * This value is exposed as **AnalyticsManager.Event.Name.SSOCredentialFound**.
 *
 * @ingroup AnalyticsEvents
 */
RSDKA_EXPORT NSString *const RAnalyticsSSOCredentialFoundEventName RSDKA_SWIFT3_NAME(RAnalyticsEventName.SSOCredentialFound);

/**
 * Event triggered when a login credential is found.
 *
 * @par Swift 3
 * This value is exposed as **AnalyticsManager.Event.Name.loginCredentialFound**.
 *
 * @ingroup AnalyticsEvents
 */
RSDKA_EXPORT NSString *const RAnalyticsLoginCredentialFoundEventName RSDKA_SWIFT3_NAME(RAnalyticsEventName.loginCredentialFound);

/**
 * Event triggered at launch to track credential strategies.
 *
 * @par Swift 3
 * This value is exposed as **AnalyticsManager.Event.Name.credentialStrategies**.
 *
 * @ingroup AnalyticsEvents
 */
RSDKA_EXPORT NSString *const RAnalyticsCredentialStrategiesEventName RSDKA_SWIFT3_NAME(RAnalyticsEventName.credentialStrategies);

/**
 * Event used to package an event name and its data.
 * This event has parameters RAnalyticsCustomEventNameParameter and RAnalyticsCustomEventDataParameter
 *
 * @par Swift 3
 * This value is exposed as **AnalyticsManager.Event.Name.custom**.
 *
 * @see RAnalyticsCustomEventNameParameter
 * @see RAnalyticsCustomEventDataParameter
 * @ingroup AnalyticsEvents
 */
RSDKA_EXPORT NSString *const RAnalyticsCustomEventName RSDKA_SWIFT3_NAME(RAnalyticsEventName.custom);

/**
 * Parameter for the event name sent with a custom event.
 *
 * @par Swift 3
 * This value is exposed as **AnalyticsManager.Event.Parameter.eventName**.
 *
 * @see RAnalyticsCustomEventName
 * @ingroup AnalyticsConstants
 */
RSDKA_EXPORT NSString *const RAnalyticsCustomEventNameParameter;

/**
 * Parameter for the event data sent with a custom event.
 *
 * @par Swift 3
 * This value is exposed as **AnalyticsManager.Event.Parameter.eventData**.
 *
 * @see RAnalyticsCustomEventName
 * @ingroup AnalyticsConstants
 */
RSDKA_EXPORT NSString *const RAnalyticsCustomEventDataParameter;

NS_ASSUME_NONNULL_END
