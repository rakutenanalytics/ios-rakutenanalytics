/*
 * © Rakuten, Inc.
 * authors: "Rakuten Ecosystem Mobile" <ecosystem-mobile@mail.rakuten.com>
 */
#import <RSDKAnalytics/RSDKAnalytics.h>

NS_ASSUME_NONNULL_BEGIN

/*
 * This class tracks login, logout and push events.
 * It creates event corressponding to each event, sends it to RSDKAnalyticsManager's instance to process.
 */
RSDKA_EXPORT @interface _RSDKAnalyticsExternalCollector : NSObject

/*
 * The login state information is being stored in shared preferences.
 */
@property (nonatomic, readonly) BOOL isLoggedIn;

/*
 * The tracking identifier is being stored in shared preferences.
 */
@property (nonatomic, nullable, readonly, copy) NSString *trackingIdentifier;

/*
 * The login method is being stored in shared preferences.
 */
@property (nonatomic, readonly) RSDKAnalyticsLoginMethod loginMethod;

/*
 * The payload from remote push notification is being stored in shared preferences.
 */
@property (nonatomic, readonly) NSDictionary *pushNotificationPayload;

/*
 * Retrieve the shared instance.
 *
 * @return The shared instance.
 */
+ (instancetype)sharedInstance;

/*
 * When the when the remote notification arrives, if the application is in foreground this method will be called.
 * If the application is not in foreground, this method will be called after the next _rem_vist event is triggerred.
 */
- (void)triggerPushEvent;

@end

NS_ASSUME_NONNULL_END
