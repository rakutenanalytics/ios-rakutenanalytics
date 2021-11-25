#import "_RAnalyticsSwiftLoader.h"

// Used if RAnalytics is built as a framework, use_frameworks! is used in Podfile
#if __has_include(<RAnalytics/RAnalytics-Swift.h>)
    #import <RAnalytics/RAnalytics-Swift.h>

// Used if RAnalytics is built as a static library, use_frameworks! is not used in Podfile
#elif __has_include("RAnalytics-Swift.h")
    #import "RAnalytics-Swift.h"
#endif

@implementation _RAnalyticsSwiftLoader

+ (void)load {
    NSArray<Class> *classes = @[
        UIApplication.class,
        UIViewController.class,
        UNUserNotificationCenter.class
    ];
    for (Class loadableClass in classes) {
        if ([loadableClass respondsToSelector:@selector(loadSwift)]) {
            [loadableClass loadSwift];
        }
    }
}

@end
