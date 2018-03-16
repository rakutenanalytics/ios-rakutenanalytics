#import "_RAnalyticsClassManipulator.h"

#ifdef RSDKA_BUILD_USER_NOTIFICATION_SUPPORT

NS_ASSUME_NONNULL_BEGIN

@interface _RAnalyticsClassManipulator(UNNotificationCenter)
@end

NS_ASSUME_NONNULL_END

#endif

RSDKA_EXPORT BOOL _RAnalyticsNotificationsAreHandledByUNDelegate(void);
