/*
 * © Rakuten, Inc.
 * authors: "Rakuten Ecosystem Mobile" <ecosystem-mobile@mail.rakuten.com>
 */
#import <RSDKAnalytics/RSDKAnalyticsDefines.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * This class tracks login, logout and push events.
 * This class creates event corressponding to each event, sends it to RSDKAnalyticsManager's instance to process.
 */
RSDKA_EXPORT @interface _RSDKAnalyticsExternalCollector : NSObject

/*
 * The login state information is being stored in shared preferences.
 */
@property (nonatomic, readonly) BOOL loggedIn;

/*
 * The tracking identifier is being stored in shared preferences.
 */
@property (nonatomic, nullable, readonly, copy) NSString *trackingIdentifier;

/*
 * The login method is being stored in shared preferences.
 */
@property (nonatomic, nullable, readonly, copy) NSString *loginMethod;

/**
 * Retrieve the shared instance.
 *
 * @note **Swift 3+:** This method is now called `shared()`.
 *
 * @return The shared instance.
 */
+ (instancetype)sharedInstance RSDKA_SWIFT3_NAME(shared());

@end

NS_ASSUME_NONNULL_END
