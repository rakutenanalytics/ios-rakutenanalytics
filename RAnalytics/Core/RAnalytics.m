#import <RAnalytics/RAnalytics.h>

/**
 * Register a SDK module's version globally.
 */
#define RMSDK_REGISTER_MODULE_VERSION(module, version) static __attribute__((constructor)) void register_version() \
{ \
    @autoreleasepool \
    { \
        NSUserDefaults *defaults = NSUserDefaults.standardUserDefaults; \
        [defaults setObject:@ RMSDK_EXPAND_AND_QUOTE(version) forKey:@ "com.rakuten.remsdk.versions." #module]; \
        [defaults synchronize]; \
    } \
}
#define RMSDK_EXPAND_AND_QUOTE0(s) #s
#define RMSDK_EXPAND_AND_QUOTE(s) RMSDK_EXPAND_AND_QUOTE0(s)

#ifndef RMSDK_ANALYTICS_VERSION
#warning "RMSDK_ANALYTICS_VERSION not defined. Code that depends on it might fail."
#define RMSDK_ANALYTICS_VERSION 0.0.0
#endif

/* RMSDK_EXPORT */ const NSString* const RAnalyticsVersion = @ RMSDK_EXPAND_AND_QUOTE(RMSDK_ANALYTICS_VERSION);

RMSDK_REGISTER_MODULE_VERSION(RAnalytics, RMSDK_ANALYTICS_VERSION);
