#import "_RAnalyticsHelpers.h"
#import "SwiftHeader.h"

NSURL *_RAnalyticsEndpointAddress(void)
{
    return [NSBundle.mainBundle endpointAddress];
}

NSBundle *_RAnalyticsAssetsBundle(void)
{
    return [NSBundle assetsBundle];
}

inline BOOL _RAnalyticsUseDefaultSharedCookieStorage()
{
    return [NSBundle.mainBundle useDefaultSharedCookieStorage];
}

inline BOOL _RAnalyticsIsAppleClass(Class cls)
{
    return [NSObject isAppleClass:cls];
}

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
inline UIApplication *_RAnalyticsSharedApplication(void)
{
    return [UIApplication RAnalyticsSharedApplication];
}
#pragma clang diagnostic pop
