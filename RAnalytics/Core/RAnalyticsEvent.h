#import <RAnalytics/RAnalyticsDefines.h>

NS_ASSUME_NONNULL_BEGIN

struct NS_SWIFT_NAME(RAnalyticsEvent.Name) RAnalyticsEventName { };

/**
 * Event triggered on first launch after installation or reinstallation.
 * Always followed by a .sessionStart event.
 *
 * @par Swift
 * This value is exposed as **AnalyticsManager.Event.Name.initialLaunch**.
 *
 * @ingroup AnalyticsEvents
 */
RSDKA_EXPORT NSString *const RAnalyticsInitialLaunchEventName  NS_SWIFT_NAME(RAnalyticsEventName.initialLaunch);

/**
 * Event triggered on every launch, as well as resume from background when
 * the life cycle session timeout has been exceeded.
 *
 * @par Swift
 * This value is exposed as **AnalyticsManager.Event.Name.sessionStart**.
 *
 * @ingroup AnalyticsEvents
 */
RSDKA_EXPORT NSString *const RAnalyticsSessionStartEventName  NS_SWIFT_NAME(RAnalyticsEventName.sessionStart);

/**
 * Event triggered when the app goes into background.
 *
 * @par Swift
 * This value is exposed as **AnalyticsManager.Event.Name.sessionEnd**.
 *
 * @ingroup AnalyticsEvents
 */
RSDKA_EXPORT NSString *const RAnalyticsSessionEndEventName  NS_SWIFT_NAME(RAnalyticsEventName.sessionEnd);

/**
 * Event triggered on the first launch after an update.
 *
 * @par Swift
 * This value is exposed as **AnalyticsManager.Event.Name.applicationUpdate**.
 *
 * @ingroup AnalyticsEvents
 */
RSDKA_EXPORT NSString *const RAnalyticsApplicationUpdateEventName  NS_SWIFT_NAME(RAnalyticsEventName.applicationUpdate);

/**
 * Event triggered when a user logs in.
 *
 * @par Swift
 * This value is exposed as **AnalyticsManager.Event.Name.login**.
 *
 * @ingroup AnalyticsEvents
 */
RSDKA_EXPORT NSString *const RAnalyticsLoginEventName  NS_SWIFT_NAME(RAnalyticsEventName.login);


/**
 * Event triggered when a user login fails.
 *
 * @par Swift
 * This value is exposed as **AnalyticsManager.Event.Name.loginFailure**.
 *
 * @ingroup AnalyticsEvents
 */
RSDKA_EXPORT NSString *const RAnalyticsLoginFailureEventName  NS_SWIFT_NAME(RAnalyticsEventName.loginFailure);


/**
 * Event triggered when a user logs out.
 *
 * @par Swift
 * This value is exposed as **AnalyticsManager.Event.Name.logout**.
 *
 * @ingroup AnalyticsEvents
 */
RSDKA_EXPORT NSString *const RAnalyticsLogoutEventName  NS_SWIFT_NAME(RAnalyticsEventName.logout);

/**
 * Event triggered on first run after app install with or without version change
 *
 * @par Swift
 * This value is exposed as **AnalyticsManager.Event.Name.install**.
 *
 * @ingroup AnalyticsEvents
 */
RSDKA_EXPORT NSString *const RAnalyticsInstallEventName  NS_SWIFT_NAME(RAnalyticsEventName.install);

/**
 * Event triggered when a view controller is shown.
 *
 * @par Swift
 * This value is exposed as **AnalyticsManager.Event.Name.pageVisit**.
 *
 * @ingroup AnalyticsEvents
 */
RSDKA_EXPORT NSString *const RAnalyticsPageVisitEventName  NS_SWIFT_NAME(RAnalyticsEventName.pageVisit);

/**
 * Event triggered when a push notification is received.
 * This event has a parameter named `RAnalyticsPushNotificationTrackingIdentifierParameter`
 *
 * @par Swift
 * This value is exposed as **AnalyticsManager.Event.Name.pushNotification**.
 *
 * @see RAnalyticsPushNotificationTrackingIdentifierParameter
 * @ingroup AnalyticsEvents
 */
RSDKA_EXPORT NSString *const RAnalyticsPushNotificationEventName  NS_SWIFT_NAME(RAnalyticsEventName.pushNotification);

/// @internal
struct NS_SWIFT_NAME(RAnalyticsEvent.Parameter) RAnalyticsParameter { };
/// @internal
struct NS_SWIFT_NAME(RAnalyticsEvent.LogoutMethod) RAnalyticsLogoutMethod { };


/**
 * Parameter for the logout method sent together with a logout event.
 *
 * @par Swift
 * This value is exposed as **AnalyticsManager.Event.Parameter.logoutMethod**.
 *
 * @see RAnalyticsLogoutEventName
 * @see RAnalyticsEventLogoutMethod
 * @ingroup AnalyticsConstants
 */
RSDKA_EXPORT NSString *const RAnalyticsLogoutMethodEventParameter NS_SWIFT_NAME(RAnalyticsParameter.logoutMethod);

/**
 * Parameter for the tracking identifier sent together with a push notification event.
 *
 * @par Swift
 * This value is exposed as **AnalyticsManager.Event.Parameter.pushTrackingIdentifier**.
 *
 * @see RAnalyticsPushNotificationEventName
 * @ingroup AnalyticsConstants
 */
RSDKA_EXPORT NSString *const RAnalyticsPushNotificationTrackingIdentifierParameter NS_SWIFT_NAME(RAnalyticsParameter.pushTrackingIdentifier);

/**
 * Logout method when the user was logged out of the current app only.
 *
 * @par Swift
 * This value is exposed as **AnalyticsManager.Event.LogoutMethod.local**.
 *
 * @see RAnalyticsLogoutEventName
 * @see RAnalyticsEventLogoutMethod
 * @ingroup AnalyticsConstants
 */
RSDKA_EXPORT NSString *const RAnalyticsLocalLogoutMethod  NS_SWIFT_NAME(RAnalyticsLogoutMethod.local);

/**
 * Logout method when the user was logged out of all apps and the account was deleted from the keychain.
 *
 * @par Swift
 * This value is exposed as **AnalyticsManager.Event.LogoutMethod.global**.
 *
 * @see RAnalyticsLogoutEventName
 * @see RAnalyticsEventLogoutMethod
 * @ingroup AnalyticsConstants
 */
RSDKA_EXPORT NSString *const RAnalyticsGlobalLogoutMethod  NS_SWIFT_NAME(RAnalyticsLogoutMethod.global);

/**
 * Event triggered when an SSO credential is found.
 *
 * @par Swift
 * This value is exposed as **AnalyticsManager.Event.Name.SSOCredentialFound**.
 *
 * @ingroup AnalyticsEvents
 */
RSDKA_EXPORT NSString *const RAnalyticsSSOCredentialFoundEventName NS_SWIFT_NAME(RAnalyticsEventName.SSOCredentialFound);

/**
 * Event triggered when a login credential is found.
 *
 * @par Swift
 * This value is exposed as **AnalyticsManager.Event.Name.loginCredentialFound**.
 *
 * @ingroup AnalyticsEvents
 */
RSDKA_EXPORT NSString *const RAnalyticsLoginCredentialFoundEventName NS_SWIFT_NAME(RAnalyticsEventName.loginCredentialFound);

/**
 * Event triggered at launch to track credential strategies.
 *
 * @par Swift
 * This value is exposed as **AnalyticsManager.Event.Name.credentialStrategies**.
 *
 * @ingroup AnalyticsEvents
 */
RSDKA_EXPORT NSString *const RAnalyticsCredentialStrategiesEventName NS_SWIFT_NAME(RAnalyticsEventName.credentialStrategies);

/**
 * Event used to package an event name and its data.
 * This event has parameters RAnalyticsCustomEventNameParameter and RAnalyticsCustomEventDataParameter
 *
 * @par Swift
 * This value is exposed as **AnalyticsManager.Event.Name.custom**.
 *
 * @see RAnalyticsCustomEventNameParameter
 * @see RAnalyticsCustomEventDataParameter
 * @ingroup AnalyticsEvents
 */
RSDKA_EXPORT NSString *const RAnalyticsCustomEventName NS_SWIFT_NAME(RAnalyticsEventName.custom);

/**
 * Parameter for the event name sent with a custom event.
 *
 * @par Swift
 * This value is exposed as **AnalyticsManager.Event.Parameter.eventName**.
 *
 * @see RAnalyticsCustomEventName
 * @ingroup AnalyticsConstants
 */
RSDKA_EXPORT NSString *const RAnalyticsCustomEventNameParameter;

/**
 * Parameter for the event data sent with a custom event.
 *
 * @par Swift
 * This value is exposed as **AnalyticsManager.Event.Parameter.eventData**.
 *
 * @see RAnalyticsCustomEventName
 * @ingroup AnalyticsConstants
 */
RSDKA_EXPORT NSString *const RAnalyticsCustomEventDataParameter;
RSDKA_EXPORT NSString *const RAnalyticsCustomEventTopLevelObjectParameter;

NS_ASSUME_NONNULL_END
