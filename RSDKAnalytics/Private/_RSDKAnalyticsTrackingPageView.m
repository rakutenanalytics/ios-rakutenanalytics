/*
 * © Rakuten, Inc.
 * authors: "Rakuten Ecosystem Mobile" <ecosystem-mobile@mail.rakuten.com>
 */

#import "_RSDKAnalyticsTrackingPageView.h"
#import "_RSDKAnalyticsLaunchCollector.h"
#import <UIKit/UIKit.h>

@interface _RSDKAnalyticsLaunchCollector ()
@property (nonatomic, readwrite) RSDKAnalyticsOrigin origin;
@end

@implementation _RSDKAnalyticsSwizzleBaseClass
+ (void)swizzleSelector:(SEL)swizzleSelector targetSelector:(SEL)targetSelector class:(Class)class
{
    SEL childSelector = targetSelector;

    Method swizzleMethod = class_getInstanceMethod(self, swizzleSelector);
    Method targetMethod = class_getInstanceMethod(class, targetSelector);
    if (targetMethod)
    {
        method_exchangeImplementations(swizzleMethod, targetMethod);
        childSelector = swizzleSelector;
    }

    if (!class_getInstanceMethod(class, childSelector))
    {
        class_addMethod(class, childSelector, method_getImplementation(swizzleMethod), method_getTypeEncoding(swizzleMethod));
    }
}
@end

@implementation _RSDKAnalyticsTrackingPageView
#pragma mark - UIViewController swizzled methods

- (void)_swizzled_viewDidAppear:(BOOL)animated
{
    if ([self isKindOfClass:[UINavigationController class]] || [self isKindOfClass:[UISplitViewController class]] || [self isKindOfClass:[UIPageViewController class]])
    {
        return;
    }

    if ([self isKindOfClass:[UIViewController class]] && [self respondsToSelector:@selector(_swizzled_viewDidAppear:)])
    {
        [_RSDKAnalyticsLaunchCollector.sharedInstance didVisitPage:(UIViewController *)self];
        [self _swizzled_viewDidAppear:animated];
    }
}

#pragma mark - UIApplicationDelegate swizzled methods

- (BOOL)_swizzled_application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    BOOL ret = YES;
    _RSDKAnalyticsLaunchCollector.sharedInstance.origin = RSDKAnalyticsInternalOrigin;
    if ([self respondsToSelector:@selector(_swizzled_application:didFinishLaunchingWithOptions:)])
    {
        ret = [self _swizzled_application:application didFinishLaunchingWithOptions:launchOptions];
    }
    return ret;
}

- (BOOL)_swizzled_application:(UIApplication *)application openURL:(NSURL *)url options:(NSDictionary<NSString*, id> *)options
{
    BOOL ret = YES;
    _RSDKAnalyticsLaunchCollector.sharedInstance.origin = RSDKAnalyticsExternalOrigin;
    if ([self respondsToSelector:@selector(_swizzled_application:openURL:options:)])
    {
        ret = [self _swizzled_application:application openURL:url options:options];
    }
    return ret;
}

- (BOOL)_swizzled_application:(UIApplication *)application continueUserActivity:(NSUserActivity *)userActivity restorationHandler:(void (^)(NSArray *restorableObjects))restorationHandler
{
    BOOL ret = YES;
    _RSDKAnalyticsLaunchCollector.sharedInstance.origin = RSDKAnalyticsExternalOrigin;
    if ([self respondsToSelector:@selector(_swizzled_application:continueUserActivity:restorationHandler:)])
    {
        ret = [self _swizzled_application:application continueUserActivity:userActivity restorationHandler:restorationHandler];
    }
    return ret;
}

- (void)_swizzled_application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo fetchCompletionHandler:(void (^)(UIBackgroundFetchResult result))completionHandler
{

    if (userInfo)
    {
        [_RSDKAnalyticsLaunchCollector.sharedInstance processPushNotificationPayload:userInfo];
    }

    if ([self respondsToSelector:@selector(_swizzled_application:didReceiveRemoteNotification:fetchCompletionHandler:)])
    {
        [self _swizzled_application:application didReceiveRemoteNotification:userInfo fetchCompletionHandler:completionHandler];
    }
}

#pragma mark - UIApplication swizzled methods

- (void)_swizzled_setApplicationDelegate:(id<UIApplicationDelegate>)delegate {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        Class cls = delegate.class;

        [_RSDKAnalyticsTrackingPageView swizzleSelector:@selector(_swizzled_application:didFinishLaunchingWithOptions:)
                                         targetSelector:@selector(application:didFinishLaunchingWithOptions:)
                                                  class:cls];

        [_RSDKAnalyticsTrackingPageView swizzleSelector:@selector(_swizzled_application:openURL:options:)
                                         targetSelector:@selector(application:openURL:options:)
                                                  class:cls];

        [_RSDKAnalyticsTrackingPageView swizzleSelector:@selector(_swizzled_application:continueUserActivity:restorationHandler:)
                                         targetSelector:@selector(application:continueUserActivity:restorationHandler:)
                                                  class:cls];

        [_RSDKAnalyticsTrackingPageView swizzleSelector:@selector(_swizzled_application:didReceiveRemoteNotification:fetchCompletionHandler:)
                                         targetSelector:@selector(application:didReceiveRemoteNotification:fetchCompletionHandler:)
                                                  class:cls];
    });

    [self _swizzled_setApplicationDelegate:delegate];
}

+ (void)load {
    [_RSDKAnalyticsTrackingPageView swizzleSelector:@selector(_swizzled_setApplicationDelegate:)
                                     targetSelector:@selector(setDelegate:)
                                              class:UIApplication.class];

    [_RSDKAnalyticsTrackingPageView swizzleSelector:@selector(_swizzled_viewDidAppear:)
                                     targetSelector:@selector(viewDidAppear:)
                                              class:UIViewController.class];
}

@end
