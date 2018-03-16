#import "_RAnalyticsClassManipulator+UIApplication.h"
#import "_RAnalyticsClassManipulator+UNUserNotificationCenter.h"
#import "_RAnalyticsHelpers.h"
#import "_RAnalyticsLaunchCollector.h"

@interface _RAnalyticsLaunchCollector()
@property (nonatomic) RAnalyticsOrigin origin;
@end

@implementation _RAnalyticsClassManipulator(UIApplication)

#pragma mark Added to id<UIApplicationDelegate>
- (BOOL)_r_autotrack_application:(UIApplication *)application
   didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    RAnalyticsDebugLog(@"Application did finish launching with options = %@", launchOptions);

    _RAnalyticsLaunchCollector.sharedInstance.origin = RAnalyticsInternalOrigin;

    // Delegates may not implement the original method
    if ([self respondsToSelector:@selector(_r_autotrack_application:didFinishLaunchingWithOptions:)])
    {
        return [self _r_autotrack_application:application didFinishLaunchingWithOptions:launchOptions];
    }
    return YES;
}

/*
 * Methods below are only added if the delegate implements the original method.
 */
- (BOOL)_r_autotrack_application:(UIApplication *)application
                   handleOpenURL:(NSURL *)url
{
    RAnalyticsDebugLog(@"Application was asked to open URL %@", url.absoluteString);

    _RAnalyticsLaunchCollector.sharedInstance.origin = RAnalyticsExternalOrigin;

    // If we're executing this, the original method exists
    return [self _r_autotrack_application:application handleOpenURL:url];
}

- (BOOL)_r_autotrack_application:(UIApplication *)application
                         openURL:(NSURL *)url
                         options:(NSDictionary<NSString*, id> *)options
{
    RAnalyticsDebugLog(@"Application was asked to open URL %@ with options = %@", url.absoluteString, options);

    _RAnalyticsLaunchCollector.sharedInstance.origin = RAnalyticsExternalOrigin;

    // If we're executing this, the original method exists
    return [self _r_autotrack_application:application openURL:url options:options];
}

- (BOOL)_r_autotrack_application:(UIApplication *)application
                         openURL:(NSURL *)url
               sourceApplication:(NSString *)sourceApplication
                      annotation:(id)annotation
{
    RAnalyticsDebugLog(@"Application was asked by %@ to open URL %@ with annotation %@", sourceApplication, url.absoluteString, annotation);

    _RAnalyticsLaunchCollector.sharedInstance.origin = RAnalyticsExternalOrigin;

    // If we're executing this, the original method exists
    return [self _r_autotrack_application:application
                                  openURL:url
                        sourceApplication:sourceApplication
                               annotation:annotation];
}

- (BOOL)_r_autotrack_application:(UIApplication *)application
            continueUserActivity:(NSUserActivity *)userActivity
              restorationHandler:(void (^)(NSArray *restorableObjects))restorationHandler
{
    RAnalyticsDebugLog(@"Application was asked to continue user activity %@", userActivity.debugDescription);

    _RAnalyticsLaunchCollector.sharedInstance.origin = RAnalyticsExternalOrigin;

    // If we're executing this, the original method exists
    return [self _r_autotrack_application:application
                     continueUserActivity:userActivity
                       restorationHandler:restorationHandler];
}

- (void)_r_autotrack_application:(UIApplication *)application
    didReceiveRemoteNotification:(nonnull NSDictionary *)userInfo
{
    RAnalyticsDebugLog(@"Application did receive remote notification %@", userInfo);

    if (userInfo && !_RAnalyticsNotificationsAreHandledByUNDelegate())
    {
        [_RAnalyticsLaunchCollector.sharedInstance processPushNotificationPayload:userInfo
                                                                       userAction:nil
                                                                         userText:nil];
    }

    // If we're executing this, the original method exists
    [self _r_autotrack_application:application didReceiveRemoteNotification:userInfo];
}

- (void)_r_autotrack_application:(UIApplication *)application
    didReceiveRemoteNotification:(NSDictionary *)userInfo
          fetchCompletionHandler:(void (^)(UIBackgroundFetchResult result))completionHandler
{
    RAnalyticsDebugLog(@"Application did receive remote notification %@", userInfo);

    if (userInfo && !_RAnalyticsNotificationsAreHandledByUNDelegate())
    {
        [_RAnalyticsLaunchCollector.sharedInstance processPushNotificationPayload:userInfo
                                                                       userAction:nil
                                                                         userText:nil];
    }

    // If we're executing this, the original method exists
    [self _r_autotrack_application:application
      didReceiveRemoteNotification:userInfo
            fetchCompletionHandler:completionHandler];
}

#pragma mark Added to UIApplication
- (void)_r_autotrack_setApplicationDelegate:(id<UIApplicationDelegate>)delegate
{
    RAnalyticsDebugLog(@"Application delegate is being set to %@", delegate);

    if (!delegate || [delegate respondsToSelector:@selector(_r_autotrack_application:didFinishLaunchingWithOptions:)])
    {
        // This delegate has already been extended.
        return;
    }

    Class recipient = delegate.class;
    [_RAnalyticsClassManipulator addMethodWithSelector:@selector(_r_autotrack_application:didFinishLaunchingWithOptions:)
                                               toClass:recipient
                                             replacing:@selector(application:didFinishLaunchingWithOptions:)
                                         onlyIfPresent:NO];

    /*
     * Attention: The selectors below should _only_ be swizzled if the delegate responds to
     * them (i.e. onlyIfPresent = YES).
     */

    [_RAnalyticsClassManipulator addMethodWithSelector:@selector(_r_autotrack_application:handleOpenURL:)
                                               toClass:recipient
                                             replacing:@selector(application:handleOpenURL:)
                                         onlyIfPresent:YES];

    [_RAnalyticsClassManipulator addMethodWithSelector:@selector(_r_autotrack_application:openURL:options:)
                                               toClass:recipient
                                             replacing:@selector(application:openURL:options:)
                                         onlyIfPresent:YES];

    [_RAnalyticsClassManipulator addMethodWithSelector:@selector(_r_autotrack_application:openURL:sourceApplication:annotation:)
                                               toClass:recipient
                                             replacing:@selector(application:openURL:sourceApplication:annotation:)
                                         onlyIfPresent:YES];

    [_RAnalyticsClassManipulator addMethodWithSelector:@selector(_r_autotrack_application:continueUserActivity:restorationHandler:)
                                               toClass:recipient
                                             replacing:@selector(application:continueUserActivity:restorationHandler:)
                                         onlyIfPresent:YES];

    [_RAnalyticsClassManipulator addMethodWithSelector:@selector(_r_autotrack_application:didReceiveRemoteNotification:fetchCompletionHandler:)
                                               toClass:recipient
                                             replacing:@selector(application:didReceiveRemoteNotification:fetchCompletionHandler:)
                                         onlyIfPresent:YES];

    [_RAnalyticsClassManipulator addMethodWithSelector:@selector(_r_autotrack_application:didReceiveRemoteNotification:)
                                               toClass:recipient
                                             replacing:@selector(application:didReceiveRemoteNotification:)
                                         onlyIfPresent:YES];

    [self _r_autotrack_setApplicationDelegate:delegate];
}

#pragma mark -
+ (void)load
{
    [_RAnalyticsClassManipulator addMethodWithSelector:@selector(_r_autotrack_setApplicationDelegate:)
                                               toClass:UIApplication.class
                                             replacing:@selector(setDelegate:)
                                         onlyIfPresent:YES];
    RAnalyticsDebugLog(@"Installed auto-tracking hooks for UIApplication.");
}
@end
