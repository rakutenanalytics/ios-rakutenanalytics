/*
 * © Rakuten, Inc.
 * authors: "Rakuten Ecosystem Mobile" <ecosystem-mobile@mail.rakuten.com>
 */
#import <UIKit/UIKit.h>
#import "_RSDKAnalyticsClassManipulator.h"

#if __has_include(<UserNotifications/UserNotifications.h>)
#import <UserNotifications/UserNotifications.h>
#define RSDKA_BUILD_USER_NOTIFICATION_SUPPORT

NS_ASSUME_NONNULL_BEGIN

@interface _RSDKAnalyticsClassManipulator(UNNotificationCenter)
@end

NS_ASSUME_NONNULL_END

#endif

RSDKA_EXPORT BOOL _RSDKAnalyticsNotificationsAreHandledByUNDelegate(void);
