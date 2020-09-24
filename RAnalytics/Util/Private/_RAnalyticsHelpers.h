#import <RAnalytics/RAnalyticsDefines.h>

RSDKA_EXPORT NSString *const _RATEventPrefix;
RSDKA_EXPORT NSString *const _RATETypeParameter;
RSDKA_EXPORT NSString *const _RATGenericEventName;

RSDKA_EXPORT BOOL _RAnalyticsObjectsEqual(id objA, id objB);
RSDKA_EXPORT NSURL *_RAnalyticsEndpointAddress(void);
RSDKA_EXPORT NSDictionary *_RAnalyticsSDKComponentMap(void);

NS_INLINE BOOL _RAnalyticsUseDefaultSharedCookieStorage()
{
    return ![[NSBundle.mainBundle objectForInfoDictionaryKey:@"RATDisableSharedCookieStorage"] boolValue];
}

NS_INLINE BOOL _RAnalyticsIsAppleClass(Class cls)
{
    // bundleForClass:nil used to return the NSBundle.mainBundle but since Xcode 10.1
    // it causes a EXC_BAD_ACCESS crash on device (not simulator). This workaround is
    // needed until Apple release a fix for https://bugs.swift.org/browse/SR-9188
    if (cls == Nil) {
        return NO;
    }
    
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
