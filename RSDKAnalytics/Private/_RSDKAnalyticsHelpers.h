/*
 * © Rakuten, Inc.
 * authors: "Rakuten Ecosystem Mobile" <ecosystem-mobile@mail.rakuten.com>
 */
#import <RSDKAnalytics/RSDKAnalyticsDefines.h>

#if DEBUG
#   define RSDKAnalyticsDebugLog(...) NSLog(@"[RMSDK] Analytics: %@", ([NSString stringWithFormat:__VA_ARGS__]))
#else
#   define RSDKAnalyticsDebugLog(...) do { } while(0)
#endif

RSDKA_EXPORT NSString *const _RSDKAnalyticsPrefix;
RSDKA_EXPORT NSString *const _RSDKAnalyticsGenericType;

RSDKA_EXPORT BOOL _RSDKAnalyticsObjects_equal(id objA, id objB);
RSDKA_EXPORT NSURL *_RSDKAnalyticsEndpointAddress();
