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


/// @internal
struct RSDKA_SWIFT3_NAME(RSDKAnalyticsEvent.LogoutMethodParameter) RSDKAnalyticsLogoutMethodParameter { };

/**
 * Logout from the current app only.
 *
 * @note **Swift 3+:** This enum value is now called `RSDKAnalyticsEvent.LogoutMethodParameter.local`.
 */
RSDKA_EXPORT NSString *const RSDKAnalyticsLocalLogoutMethodParameter  RSDKA_SWIFT3_NAME(RSDKAnalyticsLogoutMethodParameter.local);

/**
 * Logout from all Rakuten apps.
 *
 * @note **Swift 3+:** This enum value is now called `RSDKAnalyticsEvent.LogoutMethodParameter.global`.
 */
RSDKA_EXPORT NSString *const RSDKAnalyticsGlobalLogoutMethodParameter  RSDKA_SWIFT3_NAME(RSDKAnalyticsLogoutMethodParameter.global);

/*
 * Event triggered when app launches the Card Scanner module
 */
RSDKA_EXPORT NSString *const RSDKAnalyticsEventCardScannerVisit RSDKA_SWIFT3_NAME(RSDKAnalyticsEvent.cardScannerVisit);

/*
 * Event triggered when the user starts the camera scan screen
 */
RSDKA_EXPORT NSString *const RSDKAnalyticsEventCardScannerScanStarted RSDKA_SWIFT3_NAME(RSDKAnalyticsEvent.cardScannerScanStarted);

/*
 * Event triggered when the user cancels the camera scan screen
 */
RSDKA_EXPORT NSString *const RSDKAnalyticsEventCardScannerScanCanceled RSDKA_SWIFT3_NAME(RSDKAnalyticEvent.cardScannerScanCanceled);

/*
 * Event triggered when the user opts to enter their card details manually
 */
RSDKA_EXPORT NSString *const RSDKAnalyticsEventCardScannerManual RSDKA_SWIFT3_NAME(RSDKAnalyticsEvent.cardScannerManual);

/*
 * Event triggered when the Card Scanner SDK has scanned the card number
 */
RSDKA_EXPORT NSString *const RSDKAnalyticsEventCardScannerNumberScanned RSDKA_SWIFT3_NAME(RSDKAnalyticsEvent.cardScannerNumberScanned);

/*
 * Event triggered when the Card Scanner SDK failed to scan the card number
 */
RSDKA_EXPORT NSString *const RSDKAnalyticsEventCardScannerNumberScanFailed RSDKA_SWIFT3_NAME(RSDKAnalyticsEvent.cardScannerNumberScanFailed);

/*
 * Event triggered when the user modified the scanned card number in the Card Scanner UI
 */
RSDKA_EXPORT NSString *const RSDKAnalyticsEventCardScannerNumberModified RSDKA_SWIFT3_NAME(RSDKAnalyticsEvent.cardScannerNumberModifed);

/*
 * Event triggered when the Card Scanner SDK has identified the card type
 */
RSDKA_EXPORT NSString *const RSDKAnalyticsEventCardScannerCardTypeIdentified RSDKA_SWIFT3_NAME(RSDKAnalyticsEvent.cardScannerCardTypeIdentified);

/*
 * Event triggered when the Card Scanner SDK has failed to identify the card type
 */
RSDKA_EXPORT NSString *const RSDKAnalyticsEventCardScannerCardTypeIdentifyFailed RSDKA_SWIFT3_NAME(RSDKAnalyticsEvent.cardScannerCardTypeIdentifyFailed);

/*
 * Event triggered when the user modified the identified card type in the Card Scanner UI
 */
RSDKA_EXPORT NSString *const RSDKAnalyticsEventCardScannerCardTypeModified RSDKA_SWIFT3_NAME(RSDKAnalyticsEvent.cardScannerCardTypeModifed);

/*
 * Event triggered when the Card Scanner SDK has scanned the card expiry
 */
RSDKA_EXPORT NSString *const RSDKAnalyticsEventCardScannerExpiryScanned RSDKA_SWIFT3_NAME(RSDKAnalyticsEvent.cardScannerExpiryScanned);

/*
 * Event triggered when the Card Scanner SDK failed to scan the card expiry
 */
RSDKA_EXPORT NSString *const RSDKAnalyticsEventCardScannerExpiryScanFailed RSDKA_SWIFT3_NAME(RSDKAnalyticsEvent.cardScannerExpiryScanFailed);

/*
 * Event triggered when the user modified the scanned card expiry in the Card Scanner UI
 */
RSDKA_EXPORT NSString *const RSDKAnalyticsEventCardScannerExpiryModified RSDKA_SWIFT3_NAME(RSDKAnalyticsEvent.cardScannerExpiryModifed);

NS_ASSUME_NONNULL_END
