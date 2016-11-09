/*
 * © Rakuten, Inc.
 * authors: "Rakuten Ecosystem Mobile" <ecosystem-mobile@mail.rakuten.com>
 */
#import <RSDKAnalytics/RSDKAnalyticsDefines.h>
#import <RSDKAnalytics/RSDKAnalyticsState.h>

NS_ASSUME_NONNULL_BEGIN

/*
 * This class tracks launch events.
 * It creates event corressponding to each event, sends it to RSDKAnalyticsManager's instance to process.
 */
RSDKA_EXPORT @interface _RSDKAnalyticsLaunchCollector : NSObject

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
 * This method is called when the swizzling method _swizzled_viewDidAppear in _RSDKAnalyticsTrackingPageView is called.
 * The _swizzled_viewDidAppear is called when the view of an UIViewController is shown.
 */
- (void)didPresentViewController:(UIViewController *)viewController;

/*
 * When the remote notification arrives, this method will compute the tracking identifier from the push payload. 
 * If the application is in foreground this method will emit the push event with the computed tracking identifier.
 * If the application is not in foreground, this method will store the computed tracking identifier on memory, and set the origin to push type.
 * The push event will be triggerred with the tracking identifier after the next _rem_visit event is triggerred.
 */
- (void)processPushNotificationPayload:(NSDictionary *)userInfo
                            userAction:(NSString *__nullable)userAction
                              userText:(NSString *__nullable)userText;

@end

NS_ASSUME_NONNULL_END
