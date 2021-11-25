#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

/*
 * iOS 10 user notifications
 */
#if __has_include(<UserNotifications/UserNotifications.h>)
#import <UserNotifications/UserNotifications.h>
#define RSDKA_BUILD_USER_NOTIFICATION_SUPPORT
#endif

/*
 * This declaration is needed for retrieving the RAnalyticsEvent.h constants in Swift.
 */
@class RAnalyticsEvent;

NS_ASSUME_NONNULL_BEGIN

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
