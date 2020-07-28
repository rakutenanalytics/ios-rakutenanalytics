#import <RAnalytics/RAnalyticsState.h>

NS_ASSUME_NONNULL_BEGIN

/*
 * This class tracks login, logout and push events.
 * It creates event corressponding to each event, sends it to RAnalyticsManager's instance to process.
 */
RSDKA_EXPORT @interface _RAnalyticsExternalCollector : NSObject

/*
 * The login state information is being stored in shared preferences.
 */
@property (nonatomic, readonly) BOOL isLoggedIn;

/*
 * The tracking identifier is being stored in shared preferences.
 */
@property (nonatomic, nullable, readonly, copy) NSString *trackingIdentifier;

/*
 * The user identifier is being stored in shared preferences.
 */
@property (nonatomic, nullable, copy) NSString *userIdentifier;

/*
 * The login method is being stored in shared preferences.
 */
@property (nonatomic, readonly) RAnalyticsLoginMethod loginMethod;

/*
 * Retrieve the shared instance.
 *
 * @return The shared instance.
 */
+ (instancetype)sharedInstance;

@end

NS_ASSUME_NONNULL_END
