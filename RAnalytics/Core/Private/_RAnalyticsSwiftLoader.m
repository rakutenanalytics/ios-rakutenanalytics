#import "_RAnalyticsSwiftLoader.h"
#import "SwiftHeader.h"

@implementation _RAnalyticsSwiftLoader

+ (void)load {
    NSArray<Class> *classes = @[
        UIApplication.class,
        UIViewController.class,
        UNUserNotificationCenter.class,
    ];
    for (Class loadableClass in classes) {
        if ([loadableClass respondsToSelector:@selector(loadSwift)]) {
            [loadableClass loadSwift];
        }
    }
}

@end
