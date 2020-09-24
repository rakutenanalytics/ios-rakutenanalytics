#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

typedef NS_ENUM(NSUInteger, RLoggingLevel) {
    RLoggingLevelVerbose = 0,
    RLoggingLevelDebug = 1,
    RLoggingLevelInfo = 2,
    RLoggingLevelWarning = 3,
    RLoggingLevelError = 4,
    RLoggingLevelNone = 5
};

typedef NSTimeInterval(^BatchingDelayBlock)(void);

/*
 * Exports a global, setting the proper visibility attributes so that it does not
 * get stripped at linktime.
 */
#ifdef __cplusplus
#   define RSDKA_EXPORT extern "C" __attribute__((visibility ("default")))
#else
#   define RSDKA_EXPORT extern __attribute__((visibility ("default")))
#endif

/*
 * Support for exposing public parts of the API with Swift-friendly naming.
 */
#define RSDKA_SWIFT_NAME(n) __attribute__((swift_name(#n)))

/*
 * iOS 10 user notifications
 */
#if __has_include(<UserNotifications/UserNotifications.h>)
#import <UserNotifications/UserNotifications.h>
#define RSDKA_BUILD_USER_NOTIFICATION_SUPPORT
#endif
