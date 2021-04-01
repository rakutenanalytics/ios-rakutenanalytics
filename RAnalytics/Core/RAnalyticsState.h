#import <RAnalytics/RAnalyticsDefines.h>
#import <RAnalytics/RAnalyticsManager.h>
#import <CoreLocation/CoreLocation.h>

NS_ASSUME_NONNULL_BEGIN

@class UIViewController;

/**
 * Known login methods.
 *
 * @par Swift
 * This type is exposed as **AnalyticsManager.State.LoginMethod**.
 *
 * @see RAnalyticsState.loginMethod
 * @enum RAnalyticsLoginMethod
 * @ingroup AnalyticsConstants
 */
typedef NS_ENUM(NSUInteger, RAnalyticsLoginMethod)
{
    /**
     * Login with other method except input password and one tap.
     *
     * @par Swift
     * This value is exposed as **AnalyticsManager.State.LoginMethod.other**.
     */
    RAnalyticsOtherLoginMethod NS_SWIFT_NAME(RAnalyticsLoginMethod.other) = 0,

    /**
     * Password Input Login.
     * The user had to manually input their credentials in order to login.
     *
     * @par Swift
     * This value is exposed as **AnalyticsManager.State.LoginMethod.passwordInput**.
     */
    RAnalyticsPasswordInputLoginMethod NS_SWIFT_NAME(RAnalyticsLoginMethod.passwordInput),

    /**
     * One Tap Login.
     * The user logged in by just tapping a button, as allowed by Single Sign-On.
     *
     * @par Swift
     * This value is exposed as **AnalyticsManager.State.LoginMethod.oneTapLogin**.
     */
    RAnalyticsOneTapLoginLoginMethod NS_SWIFT_NAME(RAnalyticsLoginMethod.oneTapLogin),
} NS_SWIFT_NAME(RAnalyticsState.LoginMethod);

/**
 * Known launch origins.
 *
 * @par Swift
 * This type is exposed as **AnalyticsManager.State.Origin**.
 *
 * @see RAnalyticsState.origin
 * @enum RAnalyticsOrigin
 * @ingroup AnalyticsConstants
 */
typedef NS_ENUM(NSUInteger, RAnalyticsOrigin)
{
    /**
     * The visit originates from within the app itself.
     *
     * @par Swift
     * This value is exposed as **AnalyticsManager.State.Origin.internal**.
     */
    RAnalyticsInternalOrigin NS_SWIFT_NAME(internal) = 0,

    /**
     * The visit originates from another app (i.e. deep-linking).
     *
     * @par Swift
     * This value is exposed as **AnalyticsManager.State.Origin.external**.
     */
    RAnalyticsExternalOrigin NS_SWIFT_NAME(external),

    /**
     * The visit originates from a push notification.
     *
     * @par Swift
     * This value is exposed as **AnalyticsManager.State.Origin.push**.
     */
    RAnalyticsPushOrigin NS_SWIFT_NAME(push),
} NS_SWIFT_NAME(RAnalyticsState.Origin);

/**
 * Composite state created every time an event is processed, 
 * and passed to each tracker's `processEvent(event, state)` method.
 *
 * @par Swift
 * This class is exposed as **AnalyticsManager.State**.
 *
 * @class RAnalyticsState RAnalyticsState.h <RAnalytics/RAnalyticsState.h>
 * @ingroup AnalyticsCore
 */
RSDKA_EXPORT NS_SWIFT_NAME(RAnalyticsManager.State) @interface RAnalyticsState : NSObject<NSCopying>

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
 * Note: for users logged in with Rakuten, this is the encrypted user
 * tracking identifier.
 */
@property (nonatomic, nullable, readonly, copy) NSString *userIdentifier;

/**
 * The login method for the last logged-in user.
 */
@property (nonatomic, readonly) RAnalyticsLoginMethod loginMethod;

/**
 * String identifying the origin of the launch or visit, if it can be determined.
 */
@property (nonatomic, readonly) RAnalyticsOrigin origin;

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
 * @param deviceIdentifier  Globally-unique string identifying the current device across all Rakuten applications. Optional, because the app may not have enabled keychain sharing.
 *
 * @return New RAnalyticsState object.
 */
- (instancetype)initWithSessionIdentifier:(NSString *)sessionIdentifier
                         deviceIdentifier:(NSString *__nullable)deviceIdentifier NS_DESIGNATED_INITIALIZER;

@end

NS_ASSUME_NONNULL_END
