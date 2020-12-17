//
//  Use this file to import your target's public headers that you would like to expose to Swift.
//
#import <RAnalytics/RAnalytics.h>
#import "../../RAnalytics/Util/Private/_RAnalyticsHelpers.h"

@interface _RAnalyticsLaunchCollector ()
@property (nonatomic, readwrite)                    RAnalyticsOrigin     origin;
@property (nonatomic, nullable, readwrite, copy)    NSString                *pushTrackingIdentifier;
- (void)resetToDefaults;
@end
