#import <RAnalytics/RAnalyticsState.h>

NS_ASSUME_NONNULL_BEGIN

/*
 * This class tracks launch events.
 * It creates event corressponding to each event, sends it to RAnalyticsManager's instance to process.
 */
RSDKA_EXPORT @interface _RAnalyticsLaunchCollector : NSObject

/*
 * The initial launch date is being stored in keychain.
 */
@property (nonatomic, nullable, readonly, copy) NSDate *initialLaunchDate;

/*
 * The install launch date is being stored in shared preferences.
 */
@property (nonatomic, nullable, readonly, copy) NSDate *installLaunchDate;

/*
 * The last update date is being stored in shared preferences.
 */
@property (nonatomic, nullable, readonly, copy) NSDate *lastUpdateDate;

/*
 * The last launch date is being stored in shared preferences.
 */
@property (nonatomic, nullable, readonly, copy) NSDate *lastLaunchDate;

/*
 * The last version is being stored in shared preferences.
 */
@property (nonatomic, nullable, readonly, copy) NSString *lastVersion;

/*
 * The number of launches since last version is being stored in shared preferences.
 */
@property (nonatomic, readonly) NSUInteger lastVersionLaunches;

/*
 * String identifying the origin of the launch or visit, if it can be determined.
 */
@property (nonatomic, readonly) RAnalyticsOrigin origin;

/*
 * Currently-visited view controller.
 */
@property (nonatomic, nullable, readonly) UIViewController *currentPage;

/*
 * The identifier is computed from push payload.
 * It is used for tracking push notification. It is also sent together with a push notification event.
 */
@property (nonatomic, nullable, readonly) NSString *pushTrackingIdentifier;

/*
 * Retrieve the shared instance.
 *
 * @return The shared instance.
 */
+ (instancetype)sharedInstance;

/*
 * This method is called when the swizzling method _swizzled_viewDidAppear in _RAnalyticsTrackingPageView is called.
 * The _swizzled_viewDidAppear is called when the view of an UIViewController is shown.
 */
- (void)didPresentViewController:(UIViewController *)viewController;

#pragma mark - Push Notification


/*
 * For implementations that do NOT use the UNUserNotification Framework,  We need to distinguish between a tap of notification alert and
 * receiving a push notification.  This can be done by measuring the time since when this function was called and the next app life cycle "App did become active" event occuring.
 */
- (void)handleTapNonUNUserNotification:(NSDictionary *)userInfo
                              appState:(UIApplicationState)state;

/*
 * This method sends a push open notify event only if a tracking identifier can be pulled from the UNNotificationResponse
 */
- (void)processPushNotificationResponse:(UNNotificationResponse*)notificationResponse;

/*
 * This method sends a push open notify event only if a tracking identifier can be pulled from the push payload
 */
- (void)processPushNotificationPayload:(NSDictionary *)userInfo
                            userAction:(NSString *__nullable)userAction
                              userText:(NSString *__nullable)userText;

@end

NS_ASSUME_NONNULL_END
