/*
 * © Rakuten, Inc.
 * authors: "Rakuten Ecosystem Mobile" <ecosystem-mobile@mail.rakuten.com>
 */
#import <RSDKAnalytics/RSDKAnalyticsDefines.h>
#import "RSDKAnalyticsManager.h"
#import <CoreLocation/CoreLocation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/// @internal
struct RSDKA_SWIFT3_NAME(RSDKAnalyticsState.LoginMethod) RSDKAnalyticsLoginMethod { };

/**
 * Login with other method except input password and one tap.
 *
 * @note **Swift 3+:** This value is now called `RSDKAnalyticsState.LoginMethod.other`.
 */
RSDKA_EXPORT NSString *const RSDKAnalyticsOtherLoginMethod  RSDKA_SWIFT3_NAME(RSDKAnalyticsLoginMethod.other);

/**
 * Password Input Login.
 *
 * @note **Swift 3+:** This enum value is now called `RSDKAnalyticsState.LoginMethod.passwordInput`.
 */
RSDKA_EXPORT NSString *const RSDKAnalyticsPasswordInputLoginMethod  RSDKA_SWIFT3_NAME(RSDKAnalyticsLoginMethod.passwordInput);

/**
 * One Tap Login.
 *
 * @note **Swift 3+:** This enum value is now called `RSDKAnalyticsState.LoginMethod.oneTapLogin`.
 */
RSDKA_EXPORT NSString *const RSDKAnalyticsOneTapLoginLoginMethod  RSDKA_SWIFT3_NAME(RSDKAnalyticsLoginMethod.oneTapLogin);

/// @internal
struct RSDKA_SWIFT3_NAME(RSDKAnalyticsState.LogoutMethod) RSDKAnalyticsLogoutMethod { };

/**
 * Logout from the current app only.
 *
 * @note **Swift 3+:** This enum value is now called `RSDKAnalyticsState.LogoutMethod.local`.
 */
RSDKA_EXPORT NSString *const RSDKAnalyticsLocalLogoutMethod  RSDKA_SWIFT3_NAME(RSDKAnalyticsLogoutMethod.local);

/**
 * Logout from all Rakuten apps.
 *
 * @note **Swift 3+:** This enum value is now called `RSDKAnalyticsState.LogoutMethod.global`.
 */
RSDKA_EXPORT NSString *const RSDKAnalyticsGlobalLogoutMethod  RSDKA_SWIFT3_NAME(RSDKAnalyticsLogoutMethod.global);

typedef NS_ENUM(NSUInteger, RSDKAnalyticsOrigin)
{
    /**
     * The launch or visit originates from within the app itself.
     *
     * @note **Swift 3+:** This enum value is now called `RSDKAnalyticsState.Origin.internal`.
     */
    RSDKAnalyticsInternalOrigin RSDKA_SWIFT3_NAME(internal) = 0,

    /**
     * The launch or visit originates from another app (i.e. deep-linking).
     *
     * @note **Swift 3+:** This enum value is now called `RSDKAnalyticsState.Origin.external`.
     */
    RSDKAnalyticsExternalOrigin RSDKA_SWIFT3_NAME(external),

    /**
     * The launch or visit originates from a push notification.
     *
     * @note **Swift 3+:** This enum value is now called `RSDKAnalyticsState.Origin.push`.
     */
    RSDKAnalyticsPushOrigin RSDKA_SWIFT3_NAME(push),

    /**
     * The launch or visit originates from sources other than above.
     *
     * @note **Swift 3+:** This enum value is now called `RSDKAnalyticsState.Origin.other`.
     */
    RSDKAnalyticsOtherOrigin RSDKA_SWIFT3_NAME(other),
} RSDKA_SWIFT3_NAME(RSDKAnalyticsState.Origin);

/**
 * Composite state created every time an event is processed, 
 * and passed to each tracker's @ref RSDKAnalyticsTracker::processEvent: "-processEvent".
 *
 * @class RSDKAnalyticsState RSDKAnalyticsState.h <RSDKAnalytics/RSDKAnalyticsState.h>
 */
RSDKA_EXPORT RSDKA_SWIFT3_NAME(RSDKAnalyticsManager.State) @interface RSDKAnalyticsState : NSObject<NSCopying>

/*
 * Globally-unique string updated every time a new session starts.
 */
@property (nonatomic, readonly, copy) NSString *sessionIdentifier;

/*
 * Globally-unique string identifying the current device across all Rakuten applications.
 */
@property (nonatomic, readonly, copy) NSString *deviceIdentifier;

/*
 * Current app version.
 */
@property (nonatomic, readonly, copy) NSString *currentVersion;

/*
 * `CLLocation` object representing the last known location of the device.
 *
 * Only set if that information is available and AnalyticsManager.shouldTrackLastKnownLocation is `true`.
 */
@property (nonatomic, nullable, readonly, copy) CLLocation *lastKnownLocation;

/*
 * IDFA.
 *
 * Only set if AnalyticsManager.shouldTrackAdvertisingId is `true`.
 */
@property (nonatomic, nullable, readonly, copy) NSString *advertisingIdentifier;

/*
 * This property stores the date when a new session is started.
 */
@property (nonatomic, nullable, readonly, copy) NSDate *sessionStartDate;

/*
 * `true` if there's a user currently logged in, `false` otherwise.
 */
@property (nonatomic, readonly) BOOL loggedIn;

/*
 * String uniquely identifying the last logged-in user, if any.
 *
 * If `loggedIn` is `true`, then trackers can assume that user is
 * currently logged in.
 *
 * Note: for users logged in with RAE, this is the "encrypted easy id"
 * as returned by the `IdInformation/GetEncryptedEasyId/20140617` API.
 */
@property (nonatomic, nullable, readonly, copy) NSString *userIdentifier;

/*
 * String representing the login method for the last logged-in user,
 * if that information is known.
 */
@property (nonatomic, nullable, readonly, copy) NSString *loginMethod;

/*
 * String representing the logout method.
 */
@property (nonatomic, nullable, readonly, copy) NSString *logoutMethod;

/*
 * String identifying a tracking code sent by a referrer.
 */
@property (nonatomic, nullable, readonly, copy) NSString *linkIdentifier;

/*
 * String identifying the origin of the launch or visit, if it can be determined.
 */
@property (nonatomic, readonly) RSDKAnalyticsOrigin origin;

/*
 * Last visited view controller.
 */
@property (nonatomic, nullable, readonly) UIViewController *lastVisitedPage;

/*
 * Currently-visited view controller.
 */
@property (nonatomic, nullable, readonly) UIViewController *currentPage;

/*
 * Version of the app when it was last run.
 */
@property (nonatomic, nullable, readonly, copy) NSString *lastVersion;

/*
 * Number of times the last-run version was launched.
 */
@property (nonatomic, readonly)NSInteger lastVersionLaunches;

/*
 * Date the application was launched for the first time.
 * This is nil on the first launch.
 */
@property (nonatomic, nullable, readonly, copy) NSDate *initialLaunchDate;

/*
 * Date the application was installed.
 */
@property (nonatomic, nullable, readonly, copy) NSDate *installLaunchDate;

/*
 * Date the application was last launched (prior to this run).
 */
@property (nonatomic, nullable, readonly, copy) NSDate *lastLaunchDate;

/*
 * Date the last-run version was launched for the first time.
 */
@property (nonatomic, nullable, readonly, copy) NSDate *lastUpdateDate;

/**
 * Create a new state object.
 *
 * @param sessionIdentifier Globally-unique string updated every time a new session starts.
 * @param deviceIdentifier  Globally-unique string identifying the current device across all Rakuten applications.
 *
 * @return New RSDKAnalyticsEvent object.
 */
- (instancetype)initWithSessionIdentifier:(NSString *)sessionIdentifier
                         deviceIdentifier:(NSString *)deviceIdentifier NS_DESIGNATED_INITIALIZER;

@end

NS_ASSUME_NONNULL_END
