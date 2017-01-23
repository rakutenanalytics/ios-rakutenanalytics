/*
 * © Rakuten, Inc.
 * authors: "Rakuten Ecosystem Mobile" <ecosystem-mobile@mail.rakuten.com>
 */
#import <RSDKAnalytics/RSDKAnalyticsDefines.h>
#import <RSDKAnalytics/RSDKAnalyticsManager.h>
#import <CoreLocation/CoreLocation.h>

NS_ASSUME_NONNULL_BEGIN

@class UIViewController;

/**
 * Known login methods.
 *
 * @par Swift 3
 * This type is exposed as **AnalyticsManager.State.LoginMethod**.
 *
 * @see RSDKAnalyticsState.loginMethod
 * @enum RSDKAnalyticsLoginMethod
 * @ingroup AnalyticsConstants
 */
typedef NS_ENUM(NSUInteger, RSDKAnalyticsLoginMethod)
{
    /**
     * Login with other method except input password and one tap.
     *
     * @par Swift 3
     * This value is exposed as **AnalyticsManager.State.LoginMethod.other**.
     */
    RSDKAnalyticsOtherLoginMethod RSDKA_SWIFT3_NAME(RSDKAnalyticsLoginMethod.other) = 0,

    /**
     * Password Input Login.
     * The user had to manually input their credentials in order to login.
     *
     * @par Swift 3
     * This value is exposed as **AnalyticsManager.State.LoginMethod.passwordInput**.
     */
    RSDKAnalyticsPasswordInputLoginMethod RSDKA_SWIFT3_NAME(RSDKAnalyticsLoginMethod.passwordInput),

    /**
     * One Tap Login.
     * The user logged in by just tapping a button, as allowed by Single Sign-On.
     *
     * @par Swift 3
     * This value is exposed as **AnalyticsManager.State.LoginMethod.oneTapLogin**.
     */
    RSDKAnalyticsOneTapLoginLoginMethod RSDKA_SWIFT3_NAME(RSDKAnalyticsLoginMethod.oneTapLogin),
} RSDKA_SWIFT3_NAME(RSDKAnalyticsState.LoginMethod);

/**
 * Known launch origins.
 *
 * @par Swift 3
 * This type is exposed as **AnalyticsManager.State.Origin**.
 *
 * @see RSDKAnalyticsState.origin
 * @enum RSDKAnalyticsOrigin
 * @ingroup AnalyticsConstants
 */
typedef NS_ENUM(NSUInteger, RSDKAnalyticsOrigin)
{
    /**
     * The visit originates from within the app itself.
     *
     * @par Swift 3
     * This value is exposed as **AnalyticsManager.State.Origin.internal**.
     */
    RSDKAnalyticsInternalOrigin RSDKA_SWIFT3_NAME(internal) = 0,

    /**
     * The visit originates from another app (i.e. deep-linking).
     *
     * @par Swift 3
     * This value is exposed as **AnalyticsManager.State.Origin.external**.
     */
    RSDKAnalyticsExternalOrigin RSDKA_SWIFT3_NAME(external),

    /**
     * The visit originates from a push notification.
     *
     * @par Swift 3
     * This value is exposed as **AnalyticsManager.State.Origin.push**.
     */
    RSDKAnalyticsPushOrigin RSDKA_SWIFT3_NAME(push),
} RSDKA_SWIFT3_NAME(RSDKAnalyticsState.Origin);

/**
 * Composite state created every time an event is processed, 
 * and passed to each tracker's [processEvent(event, state)](protocol_r_s_d_k_analytics_tracker_01-p.html#abd4a093a74d3445fe72916f16685f5a3) method.
 *
 * @par Swift 3
 * This class is exposed as **AnalyticsManager.State**.
 *
 * @class RSDKAnalyticsState RSDKAnalyticsState.h <RSDKAnalytics/RSDKAnalyticsState.h>
 * @ingroup AnalyticsCore
 */
RSDKA_EXPORT RSDKA_SWIFT3_NAME(RSDKAnalyticsManager.State) @interface RSDKAnalyticsState : NSObject<NSCopying>

/**
 * Globally-unique string updated every time a new session starts.
 */
@property (nonatomic, readonly, copy) NSString *sessionIdentifier;

/**
 * Globally-unique string identifying the current device across all Rakuten applications.
 */
@property (nonatomic, readonly, copy) NSString *deviceIdentifier;

/**
 * Current app version.
 */
@property (nonatomic, readonly, copy) NSString *currentVersion;

/**
 * `CLLocation` object representing the last known location of the device.
 *
 * Only set if that information is available and AnalyticsManager.shouldTrackLastKnownLocation is `true`.
 */
@property (nonatomic, nullable, readonly, copy) CLLocation *lastKnownLocation;

/**
 * IDFA.
 *
 * Only set if AnalyticsManager.shouldTrackAdvertisingId is `true`.
 */
@property (nonatomic, nullable, readonly, copy) NSString *advertisingIdentifier;

/**
 * This property stores the date when a new session is started.
 */
@property (nonatomic, nullable, readonly, copy) NSDate *sessionStartDate;

/**
 * `true` if there's a user currently logged in, `false` otherwise.
 */
@property (nonatomic, readonly) BOOL isLoggedIn;

/**
 * String uniquely identifying the last logged-in user, if any.
 *
 * If `loggedIn` is `true`, then trackers can assume that user is
 * currently logged in.
 *
 * Note: for users logged in with RAE, this is the "encrypted easy id"
 * as returned by the `IdInformation/GetEncryptedEasyId/20140617` API.
 */
@property (nonatomic, nullable, readonly, copy) NSString *userIdentifier;

/**
 * The login method for the last logged-in user.
 */
@property (nonatomic, readonly) RSDKAnalyticsLoginMethod loginMethod;

/**
 * String identifying the origin of the launch or visit, if it can be determined.
 */
@property (nonatomic, readonly) RSDKAnalyticsOrigin origin;

/**
 * Version of the app when it was last run.
 */
@property (nonatomic, nullable, readonly, copy) NSString *lastVersion;

/**
 * Number of times the last-run version was launched.
 */
@property (nonatomic, readonly) NSUInteger lastVersionLaunches;

/**
 * Date the application was launched for the first time.
 * This is nil on the first launch.
 */
@property (nonatomic, nullable, readonly, copy) NSDate *initialLaunchDate;

/**
 * Date the application was installed.
 */
@property (nonatomic, nullable, readonly, copy) NSDate *installLaunchDate;

/**
 * Date the application was last launched (prior to this run).
 */
@property (nonatomic, nullable, readonly, copy) NSDate *lastLaunchDate;

/**
 * Date the last-run version was launched for the first time.
 */
@property (nonatomic, nullable, readonly, copy) NSDate *lastUpdateDate;

/**
 * Last visited view controller.
 */
@property (nonatomic, nullable, readonly) UIViewController *lastVisitedPage;

/**
 * Currently-visited view controller.
 */
@property (nonatomic, nullable, readonly) UIViewController *currentPage;

/**
 * @internal
 */
- (instancetype)init NS_UNAVAILABLE;

/**
 * Create a new state object.
 *
 * @param sessionIdentifier Globally-unique string updated every time a new session starts.
 * @param deviceIdentifier  Globally-unique string identifying the current device across all Rakuten applications.
 *
 * @return New RSDKAnalyticsState object.
 */
- (instancetype)initWithSessionIdentifier:(NSString *)sessionIdentifier
                         deviceIdentifier:(NSString *)deviceIdentifier NS_DESIGNATED_INITIALIZER;

@end

NS_ASSUME_NONNULL_END
