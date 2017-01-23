/*
 * © Rakuten, Inc.
 * authors: "Rakuten Ecosystem Mobile" <ecosystem-mobile@mail.rakuten.com>
 */
#import "_RSDKAnalyticsClassManipulator.h"

#ifdef RSDKA_BUILD_USER_NOTIFICATION_SUPPORT

NS_ASSUME_NONNULL_BEGIN

@interface _RSDKAnalyticsClassManipulator(UNNotificationCenter)
@end

NS_ASSUME_NONNULL_END

#endif

RSDKA_EXPORT BOOL _RSDKAnalyticsNotificationsAreHandledByUNDelegate(void);
