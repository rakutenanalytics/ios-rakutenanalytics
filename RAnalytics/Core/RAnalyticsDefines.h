#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

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
 * Support for exposing public parts of the API with Swift3-specific names.
 * Note: We assume Xcode 9 won't support Swift 2 anymore.
 */
#if __has_attribute(swift_name) && ((__apple_build_version__ >= 9000000) || ((__apple_build_version__ >= 8000000) && (SWIFT_SDK_OVERLAY_DISPATCH_EPOCH >= 2)))
#  define RSDKA_SWIFT3_NAME(n) __attribute__((swift_name(#n)))
#else
#  define RSDKA_SWIFT3_NAME(n)
#endif

/*
 * Xcode 6-compatible generics support
 */
#if __has_feature(objc_generics)
#   define RSDKA_GENERIC(...) <__VA_ARGS__>
#else
#   define RSDKA_GENERIC(...)
#endif

/*
 * iOS 10 user notifications
 */
#if __has_include(<UserNotifications/UserNotifications.h>)
#import <UserNotifications/UserNotifications.h>
#define RSDKA_BUILD_USER_NOTIFICATION_SUPPORT
#endif
