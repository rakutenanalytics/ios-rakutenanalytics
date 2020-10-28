#import <RAnalytics/RAnalyticsDefines.h>

NS_ASSUME_NONNULL_BEGIN

@class RAnalyticsEvent;
@protocol RAnalyticsTracker;

typedef NS_ENUM(NSUInteger, RAnalyticsLoggingLevel) {
    RAnalyticsLoggingLevelVerbose = 0,
    RAnalyticsLoggingLevelDebug = 1,
    RAnalyticsLoggingLevelInfo = 2,
    RAnalyticsLoggingLevelWarning = 3,
    RAnalyticsLoggingLevelError = 4,
    RAnalyticsLoggingLevelNone = 5
};

/**
 * Main class of the module.
 *
 *
 * @par Swift
 * This class is exposed as **AnalyticsManager**.
 *
 * @class RAnalyticsManager RAnalyticsManager.h <RAnalytics/RAnalyticsManager.h>
 * @ingroup AnalyticsCore
 */
RSDKA_EXPORT RSDKA_SWIFT_NAME(AnalyticsManager) @interface RAnalyticsManager : NSObject

/**
 * Retrieve the shared instance.
 *
 * @par Swift
 * This method is exposed as **AnalyticsManager.shared()**.
 *
 * @return The shared instance.
 */
+ (instancetype)sharedInstance RSDKA_SWIFT_NAME(shared());

/**
 * Set logging level
 *
 * @param loggingLevel  The logging level type.
 */
- (void)setLoggingLevel:(RAnalyticsLoggingLevel)loggingLevel RSDKA_SWIFT_NAME(set(loggingLevel:));

/**
 * Process an event. The manager passes the event to each registered trackers, in turn.
 *
 * @param event  An event will be sent to RAT server.
 */
- (void)process:(RAnalyticsEvent *)event;

/**
 * Add a tracker to tracker list.
 *
 * @par Swift
 * This method is exposed as **.add()**.
 *
 * @param tracker  Any object that comforms to the @ref RAnalyticsTracker protocol.
 */
- (void)addTracker:(id<RAnalyticsTracker>)tracker;

/**
 * Set the user identifier of the logged in user.
 * @param userID  The user identifier. This can be an encrypted easy ID.
 */
- (void)setUserIdentifier:(NSString * _Nullable)userID;

/**
 * Block to allow the app to set a custom domain on the app-to-web tracking cookie.
 *
 * @param cookieDomainBlock  The block returns the domain string to set on the cookie.
 */
- (void)setWebTrackingCookieDomainWithBlock:(WebTrackingCookieDomainBlock)cookieDomainBlock RSDKA_SWIFT_NAME(setWebTrackingCookieDomain(block:));
/**
 * Control whether the SDK should track page views. Defaults to `YES`.
 */
@property (nonatomic) BOOL shouldTrackPageView;

/**
 * Control whether the SDK should track the device's location or not.
 *
 * This property is set to `YES` by default, which means @ref RAnalyticsManager will
 * use the device's location.
 *
 * @warning If the application has not already requested access to the location
 * information, trying to set this property to `YES` has no effect. Please refer
 * to the [Location and Maps Programming Guide](https://developer.apple.com/library/ios/documentation/UserExperience/Conceptual/LocationAwarenessPG/)
 * for more information.
 */
@property (nonatomic) BOOL shouldTrackLastKnownLocation;

/**
 * Control whether the SDK should track the [advertising identifier (IDFA)](https://developer.apple.com/reference/adsupport/asidentifiermanager) or not.
 *
 * This property is set to `YES` by default, which means @ref RAnalyticsManager will
 * use the advertising identifier.
 */
@property (nonatomic) BOOL shouldTrackAdvertisingIdentifier;

/**
 * Control whether the SDK should inject a special tracking cookie `ra_uid` into WKWebView's cookie store.
 * The cookie enables tracking between mobile app and webviews. This feature only works on iOS 11.0 and above.
 *
 * This property is set to `NO` by default
 */
@property (nonatomic) BOOL enableAppToWebTracking;

@end

NS_ASSUME_NONNULL_END
