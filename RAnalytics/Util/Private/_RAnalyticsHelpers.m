#import <RAnalytics/RAnalyticsManager.h>
#import "_RAnalyticsHelpers.h"
#import "SwiftHeader.h"

BOOL _RAnalyticsObjectsEqual(id objA, id objB)
{
    return [NSObject isNullableObjectEqual:objA to:objB];
}

NSURL *_RAnalyticsEndpointAddress(void)
{
    return [NSBundle.mainBundle endpointAddress];
}

NSBundle *_RAnalyticsAssetsBundle(void)
{
    return [NSBundle assetsBundle];
}

NSDictionary *_RAnalyticsSDKComponentMap(void)
{
    return [NSBundle sdkComponentMap];
}

inline BOOL _RAnalyticsUseDefaultSharedCookieStorage()
{
    return [NSBundle.mainBundle useDefaultSharedCookieStorage];
}

inline BOOL _RAnalyticsIsAppleClass(Class cls)
{
    return [NSObject isAppleClass:cls];
}

inline BOOL _RAnalyticsIsApplePrivateClass(Class cls)
{
    return [NSObject isApplePrivateClass:cls];
}

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
inline UIApplication *_RAnalyticsSharedApplication(void)
{
    return [UIApplication RAnalyticsSharedApplication];
}
#pragma clang diagnostic pop
