#import "_RAnalyticsClassManipulator+UIApplication.h"
#import "_RAnalyticsClassManipulator+UNUserNotificationCenter.h"
#import "_RAnalyticsHelpers.h"
#import "_RAnalyticsLaunchCollector.h"
#import "_UNNotification+Trackable.h"
#import <RLogger/RLogger.h>

@interface _RAnalyticsLaunchCollector()
@property (nonatomic) RAnalyticsOrigin origin;
@end

@implementation _RAnalyticsClassManipulator(UIApplication)

#pragma mark Added to id<UIApplicationDelegate>
- (BOOL)_r_autotrack_application:(UIApplication *)application
   willFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    [_RLogger verbose:@"Application will finish launching with options = %@", launchOptions];

    _RAnalyticsLaunchCollector.sharedInstance.origin = RAnalyticsInternalOrigin;

    // Delegates may not implement the original method
    if ([self respondsToSelector:@selector(_r_autotrack_application:willFinishLaunchingWithOptions:)])
    {
        return [self _r_autotrack_application:application willFinishLaunchingWithOptions:launchOptions];
    }
    return YES;
}

- (BOOL)_r_autotrack_application:(UIApplication *)application
   didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    [_RLogger verbose:@"Application did finish launching with options = %@", launchOptions];

    _RAnalyticsLaunchCollector.sharedInstance.origin = RAnalyticsInternalOrigin;

    // Delegates may not implement the original method
    if ([self respondsToSelector:@selector(_r_autotrack_application:didFinishLaunchingWithOptions:)])
    {
        return [self _r_autotrack_application:application
                didFinishLaunchingWithOptions:launchOptions];
    }
    return YES;
}

/*
 * Methods below are only added if the delegate implements the original method.
 */
- (BOOL)_r_autotrack_application:(UIApplication *)application
                   handleOpenURL:(NSURL *)url
{
    [_RLogger verbose:@"Application was asked to open URL %@", url.absoluteString];

    _RAnalyticsLaunchCollector.sharedInstance.origin = RAnalyticsExternalOrigin;

    // If we're executing this, the original method exists
    return [self _r_autotrack_application:application
                            handleOpenURL:url];
}

- (BOOL)_r_autotrack_application:(UIApplication *)application
                         openURL:(NSURL *)url
                         options:(NSDictionary<NSString*, id> *)options
{
    [_RLogger verbose:@"Application was asked to open URL %@ with options = %@", url.absoluteString, options];

    _RAnalyticsLaunchCollector.sharedInstance.origin = RAnalyticsExternalOrigin;

    // If we're executing this, the original method exists
    return [self _r_autotrack_application:application
                                  openURL:url
                                  options:options];
}

- (BOOL)_r_autotrack_application:(UIApplication *)application
                         openURL:(NSURL *)url
               sourceApplication:(NSString *)sourceApplication
                      annotation:(id)annotation
{
    [_RLogger verbose:@"Application was asked by %@ to open URL %@ with annotation %@", sourceApplication, url.absoluteString, annotation];

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
    [_RLogger verbose:@"Application was asked to continue user activity %@", userActivity.debugDescription];

    _RAnalyticsLaunchCollector.sharedInstance.origin = RAnalyticsExternalOrigin;

    // If we're executing this, the original method exists
    return [self _r_autotrack_application:application
                     continueUserActivity:userActivity
                       restorationHandler:restorationHandler];
}
/**
 
    Swizzle didReceiveRemoteNotification. This was deprecated in iOS version 10.
 
    This won't be called if Application Delegate was implemented:
 
    application:didReceiveRemoteNotification:fetchCompletionHandler:
 
    or
 
    UNUserNotificationCenter delegate method was implemented:
        
    userNotificationCenter:didReceiveNotificationResponse:withCompletionHandler:
 
 */
- (void)_r_autotrack_application:(UIApplication *)application
    didReceiveRemoteNotification:(nonnull NSDictionary *)userInfo
{
    [_RLogger verbose:@"Application did receive remote notification %@", userInfo];
    
    [_RAnalyticsLaunchCollector.sharedInstance handleTapNonUNUserNotification:userInfo
                                                                     appState:application.applicationState];

    // If we're executing this, the original method exists
    [self _r_autotrack_application:application
      didReceiveRemoteNotification:userInfo];
}

/**
 
    Swizzle application:didReceiveRemoteNotification:fetchCompletionHandler:
 
    if UNUserNotificationCenter delegate was set
 
    - this will only be called for background or silent push notifications.
 
    else:
    
    - this will be called for all push notifications when the app is launched
*/
- (void)_r_autotrack_application:(UIApplication *)application
    didReceiveRemoteNotification:(NSDictionary *)userInfo
          fetchCompletionHandler:(void (^)(UIBackgroundFetchResult result))completionHandler
{
    [_RLogger verbose:@"Application did receive remote notification %@", userInfo];
    
    [_RAnalyticsLaunchCollector.sharedInstance handleTapNonUNUserNotification:userInfo
                                                                     appState:application.applicationState];

    // If we're executing this, the original method exists
    [self _r_autotrack_application:application
      didReceiveRemoteNotification:userInfo
            fetchCompletionHandler:completionHandler];
}

#pragma mark Added to UIApplication
- (void)_r_autotrack_setApplicationDelegate:(id<UIApplicationDelegate>)delegate
{
    [_RLogger verbose:@"Application delegate is being set to %@", delegate];
    
    if (!delegate
        || [delegate respondsToSelector:@selector(_r_autotrack_application:willFinishLaunchingWithOptions:)]
        || [delegate respondsToSelector:@selector(_r_autotrack_application:didFinishLaunchingWithOptions:)])
    {
        // This delegate has already been extended.
        return;
    }

    Class recipient = delegate.class;
    [_RAnalyticsClassManipulator addMethodWithSelector:@selector(_r_autotrack_application:willFinishLaunchingWithOptions:)
                                               toClass:recipient
                                             replacing:@selector(application:willFinishLaunchingWithOptions:)
                                         onlyIfPresent:NO];
    
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
    [_RLogger verbose:@"Installed auto-tracking hooks for UIApplication."];
}
@end
