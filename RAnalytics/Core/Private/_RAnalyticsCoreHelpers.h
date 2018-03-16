#import <RAnalytics/RAnalyticsDefines.h>
#import <RAnalytics/RAnalytics.h>

RSDKA_EXPORT NSString *const _RAnalyticsAppInfoKey;
RSDKA_EXPORT NSString *const _RAnalyticsSDKInfoKey;

RSDKA_EXPORT NSDictionary *_RAnalyticsSharedPayload(RAnalyticsState * state);
RSDKA_EXPORT NSDictionary *_RAnalyticsApplicationInfoAndSDKComponents(void);

