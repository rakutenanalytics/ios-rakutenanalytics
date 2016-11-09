/*
 * © Rakuten, Inc.
 * authors: "Rakuten Ecosystem Mobile" <ecosystem-mobile@mail.rakuten.com>
 */
#import "_RSDKAnalyticsClassManipulator+UIViewController.h"
#import "_RSDKAnalyticsHelpers.h"
#import "_RSDKAnalyticsLaunchCollector.h"

@implementation _RSDKAnalyticsClassManipulator(UIViewController)

#pragma mark Added to UIViewController
- (void)_r_autotrack_viewDidAppear:(BOOL)animated
{
    RSDKAnalyticsDebugLog(@"View did appear for %@", self);

    [_RSDKAnalyticsLaunchCollector.sharedInstance didPresentViewController:(id)self];
    [self _r_autotrack_viewDidAppear:animated];
}

#pragma mark -
+ (void)load
{
    [_RSDKAnalyticsClassManipulator addMethodWithSelector:@selector(_r_autotrack_viewDidAppear:)
                                                  toClass:UIViewController.class
                                                replacing:@selector(viewDidAppear:)
                                            onlyIfPresent:YES];
    RSDKAnalyticsDebugLog(@"Installed auto-tracking hooks for UIViewController.");
}
@end
