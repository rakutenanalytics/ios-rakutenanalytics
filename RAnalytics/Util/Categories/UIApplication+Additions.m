#import "UIApplication+Additions.h"
#import "_RAnalyticsHelpers.h"

@implementation UIApplication(Additions)

+ (BOOL)_rat_respondsToSharedApplication
{
    return _RAnalyticsSharedApplication() != nil;
}

+ (UIInterfaceOrientation)_rat_statusBarOrientation
{
    return [_RAnalyticsSharedApplication() statusBarOrientation];
}

@end
