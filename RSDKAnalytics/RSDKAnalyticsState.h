/*
 * © Rakuten, Inc.
 * authors: "Rakuten Ecosystem Mobile" <ecosystem-mobile@mail.rakuten.com>
 */
#import <RSDKAnalytics/RSDKAnalyticsDefines.h>
#import "RSDKAnalyticsManager.h"
#import <CoreLocation/CoreLocation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * Composite state created every time an event is processed, 
 * and passed to each tracker's @ref RSDKAnalyticsTracker::processEvent: "-processEvent".
 *
 * @class RSDKAnalyticsState RSDKAnalyticsState.h <RSDKAnalytics/RSDKAnalyticsState.h>
 */
RSDKA_EXPORT RSDKA_SWIFT3_NAME(RSDKAnalyticsManager.State) @interface RSDKAnalyticsState : NSObject<NSCopying>

/*
 * Globally-unique string updated every time a new session starts.
 */
@property (nonatomic, readonly, copy) NSString *sessionIdentifier;

/*
 * Globally-unique string identifying the current device across all Rakuten applications.
 */
@property (nonatomic, readonly, copy) NSString *deviceIdentifier;

/*
 * Current app version.
 */
@property (nonatomic, readonly, copy) NSString *currentVersion;

/*
 * `CLLocation` object representing the last known location of the device.
 *
 * Only set if that information is available and AnalyticsManager.shouldTrackLastKnownLocation is `true`.
 */
@property (nonatomic, nullable, readonly, copy) CLLocation *lastKnownLocation;

/*
 * IDFA.
 *
 * Only set if AnalyticsManager.shouldTrackAdvertisingId is `true`.
 */
@property (nonatomic, nullable, readonly, copy) NSString *advertisingIdentifier;

/*
 * This property stores the date when a new session is started.
 */
@property (nonatomic, nullable, readonly, copy) NSDate *sessionStartDate;

/**
 * Create a new state object.
 *
 * @param sessionIdentifier Globally-unique string updated every time a new session starts.
 * @param deviceIdentifier  Globally-unique string identifying the current device across all Rakuten applications.
 *
 * @return New RSDKAnalyticsEvent object.
 */
- (instancetype)initWithSessionIdentifier:(NSString *)sessionIdentifier
                         deviceIdentifier:(NSString *)deviceIdentifier NS_DESIGNATED_INITIALIZER;

@end

NS_ASSUME_NONNULL_END
