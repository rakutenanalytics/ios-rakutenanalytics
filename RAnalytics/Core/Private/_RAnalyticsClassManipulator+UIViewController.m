#import "_RAnalyticsClassManipulator+UIViewController.h"
#import "_RAnalyticsHelpers.h"
#import "_RAnalyticsLaunchCollector.h"

@implementation _RAnalyticsClassManipulator(UIViewController)

#pragma mark Added to UIViewController
- (void)_r_autotrack_viewDidAppear:(BOOL)animated
{
    RAnalyticsDebugLog(@"View did appear for %@", self);

    [_RAnalyticsLaunchCollector.sharedInstance didPresentViewController:(id)self];
    [self _r_autotrack_viewDidAppear:animated];
}

#pragma mark -
+ (void)load
{
    [_RAnalyticsClassManipulator addMethodWithSelector:@selector(_r_autotrack_viewDidAppear:)
                                               toClass:UIViewController.class
                                             replacing:@selector(viewDidAppear:)
                                         onlyIfPresent:YES];
    RAnalyticsDebugLog(@"Installed auto-tracking hooks for UIViewController.");
}
@end
