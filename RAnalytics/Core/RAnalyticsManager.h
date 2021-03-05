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

typedef BOOL (^RAnalyticsShouldTrackEventCompletionBlock)(NSString *);

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
 * Process an event. The manager passes the event to each registered tracker, in turn.
 *
 * @param event  Event to track.
 *
 * @return A boolean value indicating if the event has been processed.
 */
- (BOOL)process:(RAnalyticsEvent *)event;

/**
 * Add a tracker to tracker list.
 *
 * @par Swift
 * This method is exposed as **.add()**.
 *
 * @param tracker  Any object that comforms to the @ref RAnalyticsTracker protocol.
 */
- (void)addTracker:(id<RAnalyticsTracker>)tracker RSDKA_SWIFT_NAME(add(_:));

/**
 * Set the user identifier of the logged in user.
 * @param userID  The user identifier. This can be the encrypted internal tracking ID.
 */
- (void)setUserIdentifier:(NSString * _Nullable)userID;

/**
 * Block to allow the app to set a custom domain on the app-to-web tracking cookie.
 *
 * @param cookieDomainBlock  The block returns the domain string to set on the cookie.
 */
- (void)setWebTrackingCookieDomainWithBlock:(WebTrackingCookieDomainBlock)cookieDomainBlock RSDKA_SWIFT_NAME(setWebTrackingCookieDomain(block:));

/**
 * Set the endpoint URL for all the trackers at runtime.
 * @warning If endpointURL is not nil, RATEndpoint defined in app's info.plist is ignored.
 * @warning If endpointURL is nil, RATEndpoint defined in app's info.plist is set.
 */
- (void)setEndpointURL:(NSURL * _Nullable)endpointURL RSDKA_SWIFT_NAME(set(endpointURL:));

/**
 * Control whether the SDK should track page views. Defaults to `YES`.
 * @deprecated RAnalyticsManager::shouldTrackEventHandler should be used instead
 */
@property (nonatomic) BOOL shouldTrackPageView DEPRECATED_MSG_ATTRIBUTE("RAnalyticsManager#shouldTrackEventHandler should be used instead.");

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
 * use the advertising identifier if it is set to a non-zeroed valid value.
 */
@property (nonatomic) BOOL shouldTrackAdvertisingIdentifier;

/**
 * Control whether the SDK should inject a tracking cookie into the WKWebView's cookie store.
 * The cookie enables tracking between mobile app and webviews. 
 *
 * This feature only works on iOS 11.0 and above.
 *
 * This property is set to `NO` by default
 */
@property (nonatomic) BOOL enableAppToWebTracking;

/**
 * Enable or disable the tracking of an event at runtime.
 *
 * For example, to disable `AnalyticsManager.Event.Name.sessionStart`:
 * `AnalyticsManager.shared().shouldTrackEventHandler = { eventName in eventName != AnalyticsManager.Event.Name.sessionStart }`
 * 
 * Note that it is also possible to disable events at build time in the `RAnalyticsConfiguration.plist` file:
 * 1) First create a `RAnalyticsConfiguration.plist` file and add it to your Xcode project.
 * 2) Then create a key `RATDisabledEventsList` and add the array of disabled events.
 *
 * For example, to disable all automatic tracking add the following to your `RAnalyticsConfiguration.plist` file:
 *
 * <key>RATDisabledEventsList</key>
 * <array>
 * <string>_rem_init_launch</string>
 * <string>_rem_launch</string>
 * <string>_rem_end_session</string>
 * <string>_rem_update</string>
 * <string>_rem_login</string>
 * <string>_rem_login_failure</string>
 * <string>_rem_logout</string>
 * <string>_rem_install</string>
 * <string>_rem_visit</string>
 * <string>_rem_push_notify</string>
 * <string>_rem_sso_credential_found</string>
 * <string>_rem_login_credential_found</string>
 * <string>_rem_credential_strategies</string>
 * <string>_analytics_custom</string>
 * </array>
 */
@property (nonatomic, copy) _Nullable RAnalyticsShouldTrackEventCompletionBlock shouldTrackEventHandler;

@end

NS_ASSUME_NONNULL_END
