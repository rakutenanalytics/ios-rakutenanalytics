@import Foundation;
@import UIKit;
#if !TARGET_OS_TV
@import UserNotifications;
#endif

NS_ASSUME_NONNULL_BEGIN

@interface _RAnalyticsSwiftLoader : NSObject

- (instancetype)init NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END

#if __has_include(<RAnalytics/RAnalytics-Swift.h>)
    #import <RAnalytics/RAnalytics-Swift.h>
#elif __has_include("RAnalytics-Swift.h")
    #import "RAnalytics-Swift.h"
#endif

@implementation _RAnalyticsSwiftLoader

+ (void)load {
#if TARGET_OS_TV
    NSMutableArray *mutableClassesArray = [NSMutableArray arrayWithArray:@[
        UIApplication.class,
        UIViewController.class,
        UIWindowScene.class
    ]];
#else
    NSMutableArray *mutableClassesArray = [NSMutableArray arrayWithArray:@[
        UIViewController.class,
        UNUserNotificationCenter.class,
        UIWindowScene.class
    ]];
#endif

    // `loadSwift` is declared by the Swift `RuntimeLoadable` protocol (@objc protocol guarantees
    // ObjC visibility). Suppress "-Wundeclared-selector" for builds where the generated Swift
    // header is not visible to this translation unit; "-Warc-performSelector-leaks" because
    // +loadSwift returns void and there is no leak.
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wundeclared-selector"
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
    for (Class loadableClass in mutableClassesArray) {
        if ([loadableClass respondsToSelector:@selector(loadSwift)]) {
            [loadableClass performSelector:@selector(loadSwift)];
        }
    }
#pragma clang diagnostic pop
}

@end
