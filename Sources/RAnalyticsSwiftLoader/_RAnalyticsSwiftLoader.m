#import "_RAnalyticsSwiftLoader.h"
@import Foundation;
@import UIKit;
@import UserNotifications;

// Used if RAnalytics is built as a framework, use_frameworks! is used in Podfile
#if __has_include(<RAnalytics/RAnalytics-Swift.h>)
    #import <RAnalytics/RAnalytics-Swift.h>

// Used if RAnalytics is built as a static library, use_frameworks! is not used in Podfile
#elif __has_include("RAnalytics-Swift.h")
    #import "RAnalytics-Swift.h"
#endif

@implementation _RAnalyticsSwiftLoader

+ (void)load {
    NSMutableArray *mutableClassesArray = [NSMutableArray arrayWithArray:@[
        UIApplication.class,
        UIViewController.class,
        UNUserNotificationCenter.class
    ]];

    if (@available(iOS 13.0, *)) {
        [mutableClassesArray addObject:UIWindowScene.class];
    }

    for (Class loadableClass in mutableClassesArray) {
        if ([loadableClass respondsToSelector:@selector(loadSwift)]) {
            [loadableClass performSelector:@selector(loadSwift)];
        }
    }
}

@end
