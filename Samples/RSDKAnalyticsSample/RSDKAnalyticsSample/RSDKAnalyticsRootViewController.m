/*
 * © Rakuten, Inc.
 * authors: "Rakuten Mobile SDK Team | SDTD" <prj-rmsdk@mail.rakuten.com>
 */
#import "RSDKAnalyticsRootViewController.h"

/////////////////////////////////////////////////////////////////

@implementation RSDKAnalyticsRootViewController

- (void)awakeFromNib
{
    self.menuPreferredStatusBarStyle = UIStatusBarStyleDefault;
    self.contentViewShadowColor = UIColor.blackColor;
    self.contentViewShadowOffset = CGSizeMake(0, 0);
    self.contentViewShadowOpacity = 0.6;
    self.contentViewShadowRadius = 12;
    self.contentViewShadowEnabled = YES;

    self.contentViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"navigationController"];
    self.leftMenuViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"leftMenuViewController"];
    self.backgroundImage = [UIImage imageNamed:@"Background"];
    self.delegate = self;
}

@end

