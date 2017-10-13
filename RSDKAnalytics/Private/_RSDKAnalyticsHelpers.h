/*
 * © Rakuten, Inc.
 * authors: "Rakuten Ecosystem Mobile" <ecosystem-mobile@mail.rakuten.com>
 */
#import <RSDKAnalytics/RSDKAnalyticsDefines.h>

#if DEBUG
#   define RSDKAnalyticsErrorLog(...) NSLog(@"[RMSDK] Analytics Error: %@", ([NSString stringWithFormat:__VA_ARGS__]))
#else
#   define RSDKAnalyticsErrorLog(...) do { } while(0)
#endif

#define RSDKAnalyticsDebugLog(...) {_RSDKAnalyticsDebugLog([NSString stringWithFormat:__VA_ARGS__]);}

RSDKA_EXPORT NSString *const _RATEventPrefix;
RSDKA_EXPORT NSString *const _RATETypeParameter;
RSDKA_EXPORT NSString *const _RATGenericEventName;

RSDKA_EXPORT BOOL _RSDKAnalyticsObjectsEqual(id objA, id objB);
RSDKA_EXPORT NSURL *_RSDKAnalyticsEndpointAddress(void);
RSDKA_EXPORT NSDictionary *_RSDKAnalyticsSDKComponentMap(void);

NS_INLINE void _RSDKAnalyticsDebugLog(NSString* log)
{
    if (DEBUG && [[[NSBundle mainBundle] objectForInfoDictionaryKey:@"RMSDKEnableDebugLogging"] boolValue])
    {
        NSLog(@"[RMSDK] Analytics Debug: %@", log);
    }
}

NS_INLINE BOOL _RSDKAnalyticsIsAppleClass(Class cls)
{
    return [[NSBundle bundleForClass:cls].bundleIdentifier hasPrefix:@"com.apple."];
}

NS_INLINE BOOL _RSDKAnalyticsIsApplePrivateClass(Class cls)
{
    return [NSStringFromClass(cls) hasPrefix:@"_"] && _RSDKAnalyticsIsAppleClass(cls);
}

