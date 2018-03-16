#import <RAnalytics/RAnalyticsDefines.h>
#import <RAnalytics/RAnalyticsTracker.h>

NS_ASSUME_NONNULL_BEGIN

RSDKA_EXPORT @interface _SDKTracker : NSObject<RAnalyticsTracker>
+ (instancetype)sharedInstance;
@end

NS_ASSUME_NONNULL_END
