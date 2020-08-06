#import "_RAnalyticsClassManipulator+UNUserNotificationCenter.h"
#import "_RAnalyticsHelpers.h"
#import "_RAnalyticsLaunchCollector.h"
#import "_UNNotification+Trackable.h"

/* RSDKA_EXPORT */ BOOL _RAnalyticsNotificationsAreHandledByUNDelegate(void)
{
#ifdef RSDKA_BUILD_USER_NOTIFICATION_SUPPORT
    return [UNUserNotificationCenter.currentNotificationCenter.delegate
            respondsToSelector:@selector(userNotificationCenter:
                                         didReceiveNotificationResponse:
                                         withCompletionHandler:)];
#else
    return NO;
#endif
}
#ifdef RSDKA_BUILD_USER_NOTIFICATION_SUPPORT

@implementation _RAnalyticsClassManipulator(UNNotificationCenter)

#pragma mark Added to UNUserNotificationCenter
- (void)_r_autotrack_userNotificationCenter:(UNUserNotificationCenter *)center
             didReceiveNotificationResponse:(UNNotificationResponse *)response
                      withCompletionHandler:(void(^)(void))completionHandler
{
    [_RAnalyticsLaunchCollector.sharedInstance processPushNotificationResponse:response];

    if ([self respondsToSelector:@selector(_r_autotrack_userNotificationCenter:didReceiveNotificationResponse:withCompletionHandler:)])
    {
        [self _r_autotrack_userNotificationCenter:center
                   didReceiveNotificationResponse:response
                            withCompletionHandler:completionHandler];
    }
}

- (void)_r_autotrack_setUserNotificationCenterDelegate:(id<NSObject>)delegate
{
    RAnalyticsDebugLog(@"User notification center delegate is being set to %@", delegate);
    
    SEL swizzle_selector = @selector(_r_autotrack_userNotificationCenter:didReceiveNotificationResponse:withCompletionHandler:);
    SEL delegate_selector = @selector(userNotificationCenter:didReceiveNotificationResponse:withCompletionHandler:);
    
    // set swizzle if currently not swizzled
    if (delegate &&
        ![delegate respondsToSelector:swizzle_selector])
    {
        
        Class recipient = delegate.class;
        [_RAnalyticsClassManipulator addMethodWithSelector:swizzle_selector
                                                   toClass:recipient
                                                 replacing:delegate_selector
                                             onlyIfPresent:YES];
    }
    
    [self _r_autotrack_setUserNotificationCenterDelegate:delegate];
}

#pragma mark -
+ (void)load
{
    [_RAnalyticsClassManipulator addMethodWithSelector:@selector(_r_autotrack_setUserNotificationCenterDelegate:)
                                               toClass:UNUserNotificationCenter.class
                                             replacing:@selector(setDelegate:)
                                         onlyIfPresent:YES];
    
    RAnalyticsDebugLog(@"Installed auto-tracking hooks for UNNotificationCenter.");
}

@end
#endif
