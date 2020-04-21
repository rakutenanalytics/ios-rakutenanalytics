#import "_RAnalyticsClassManipulator+UNUserNotificationCenter.h"
#import "_RAnalyticsHelpers.h"
#import "_RAnalyticsLaunchCollector.h"

/* RSDKA_EXPORT */ BOOL _RAnalyticsNotificationsAreHandledByUNDelegate(void)
{
#ifdef RSDKA_BUILD_USER_NOTIFICATION_SUPPORT
    return [UNUserNotificationCenter.currentNotificationCenter.delegate
            respondsToSelector:@selector(userNotificationCenter:didReceiveNotificationResponse:withCompletionHandler:)];
#else
    return NO;
#endif
}

#ifdef RSDKA_BUILD_USER_NOTIFICATION_SUPPORT
@implementation _RAnalyticsClassManipulator(UNNotificationCenter)

#pragma mark Added to id<UNUserNotificationCenterDelegate>
- (void)_r_autotrack_userNotificationCenter:(UNUserNotificationCenter *)center
             didReceiveNotificationResponse:(UNNotificationResponse *)response
                      withCompletionHandler:(void(^)(void))completionHandler
{
    UNNotificationRequest *request = response.notification.request;
    if ([request.trigger isKindOfClass:UNPushNotificationTrigger.class])
    {
        NSDictionary *payload = request.content.userInfo;
        NSString *userAction = nil, *userText = nil;

        if ([response isKindOfClass:UNTextInputNotificationResponse.class])
        {
            userText = [(UNTextInputNotificationResponse *)response userText];
        }

        if (response.actionIdentifier && ![response.actionIdentifier isEqualToString:UNNotificationDismissActionIdentifier])
        {
            userAction = response.actionIdentifier;
        }

        RAnalyticsDebugLog(@"Application did receive remote notification %@", payload);
        [_RAnalyticsLaunchCollector.sharedInstance processPushNotificationPayload:payload
                                                                       userAction:userAction
                                                                         userText:userText];
    }

    [self _r_autotrack_userNotificationCenter:center didReceiveNotificationResponse:response withCompletionHandler:completionHandler];
}

#pragma mark Added to UNUserNotificationCenter
- (void)_r_autotrack_setUserNotificationCenterDelegate:(id<NSObject>)delegate
{
    RAnalyticsDebugLog(@"User notification center delegate is being set to %@", delegate);
    if (!delegate) return;

    Class recipient = delegate.class;
    SEL   selector = @selector(_r_autotrack_userNotificationCenter:didReceiveNotificationResponse:withCompletionHandler:);
    if (![delegate respondsToSelector:selector])
    {
        [_RAnalyticsClassManipulator addMethodWithSelector:selector
                                                   toClass:recipient
                                                 replacing:@selector(userNotificationCenter:didReceiveNotificationResponse:withCompletionHandler:)
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
