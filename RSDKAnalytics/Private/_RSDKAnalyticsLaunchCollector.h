/*
 * © Rakuten, Inc.
 * authors: "Rakuten Ecosystem Mobile" <ecosystem-mobile@mail.rakuten.com>
 */
#import <RSDKAnalytics/RSDKAnalyticsDefines.h>

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
 * Retrieve the shared instance.
 *
 * @return The shared instance.
 */
+ (instancetype)sharedInstance;

@end

NS_ASSUME_NONNULL_END
