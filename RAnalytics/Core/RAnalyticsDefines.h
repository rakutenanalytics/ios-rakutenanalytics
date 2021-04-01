#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

/*
 * iOS 10 user notifications
 */
#if __has_include(<UserNotifications/UserNotifications.h>)
#import <UserNotifications/UserNotifications.h>
#define RSDKA_BUILD_USER_NOTIFICATION_SUPPORT
#endif

NS_ASSUME_NONNULL_BEGIN

typedef NSTimeInterval(^BatchingDelayBlock)(void);

typedef NSString *__nullable(^WebTrackingCookieDomainBlock)(void);

/*
 * Exports a global, setting the proper visibility attributes so that it does not
 * get stripped at linktime.
 */
#ifdef __cplusplus
#   define RSDKA_EXPORT extern "C" __attribute__((visibility ("default")))
#else
#   define RSDKA_EXPORT extern __attribute__((visibility ("default")))
#endif

NS_ASSUME_NONNULL_END
