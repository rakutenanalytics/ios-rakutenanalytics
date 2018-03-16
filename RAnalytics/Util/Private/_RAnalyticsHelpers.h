#import <RAnalytics/RAnalyticsDefines.h>

#if DEBUG
#   define RAnalyticsErrorLog(...) NSLog(@"[REMSDK] Analytics Error: %@", ([NSString stringWithFormat:__VA_ARGS__]))
#   define RAnalyticsDebugLog(...) {if (_RAnalyticsEnableDebugLogging()) NSLog(@"[REMSDK] Analytics: %@", ([NSString stringWithFormat:__VA_ARGS__]));}
#else
#   define RAnalyticsErrorLog(...) do { } while(0)
#   define RAnalyticsDebugLog(...) do { } while(0)
#endif

RSDKA_EXPORT NSString *const _RATEventPrefix;
RSDKA_EXPORT NSString *const _RATETypeParameter;
RSDKA_EXPORT NSString *const _RATGenericEventName;

RSDKA_EXPORT BOOL _RAnalyticsObjectsEqual(id objA, id objB);
RSDKA_EXPORT NSURL *_RAnalyticsEndpointAddress(void);
RSDKA_EXPORT NSDictionary *_RAnalyticsSDKComponentMap(void);

NS_INLINE BOOL _RAnalyticsEnableDebugLogging()
{
    return [[[NSBundle mainBundle] objectForInfoDictionaryKey:@"RMSDKEnableDebugLogging"] boolValue];
}

NS_INLINE BOOL _RAnalyticsIsAppleClass(Class cls)
{
    return [[NSBundle bundleForClass:cls].bundleIdentifier hasPrefix:@"com.apple."];
}

NS_INLINE BOOL _RAnalyticsIsApplePrivateClass(Class cls)
{
    return [NSStringFromClass(cls) hasPrefix:@"_"] && _RAnalyticsIsAppleClass(cls);
}

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
NS_INLINE UIApplication *_RAnalyticsSharedApplication(void)
{
    Class UIApplicationClass = [UIApplication class];
    SEL sharedApplicationSelector = @selector(sharedApplication);
    if ([UIApplicationClass respondsToSelector:sharedApplicationSelector])
    {
        return [UIApplicationClass performSelector:sharedApplicationSelector];
    }
    return nil;
}
#pragma clang diagnostic pop
