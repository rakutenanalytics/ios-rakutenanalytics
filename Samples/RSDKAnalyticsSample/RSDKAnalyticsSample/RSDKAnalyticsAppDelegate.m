/*
 * © Rakuten, Inc.
 * authors: "Rakuten Mobile SDK Team | SDTD" <prj-rmsdk@mail.rakuten.com>
 */
#import "RSDKAnalytics.h"
#import "RSDKAnalyticsAppDelegate.h"
// INTERNAL ONLY BEGINS
#import <HockeySDK/HockeySDK.h>
// INTERNAL ONLY ENDS

/////////////////////////////////////////////////////////////////

@implementation RSDKAnalyticsAppDelegate
@synthesize window;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
	// INTERNAL ONLY BEGINS
    BITHockeyManager *hockey = BITHockeyManager.sharedHockeyManager;
    [hockey configureWithIdentifier:@"4645a14dfa63a030b68454d8aea8bbb9"];
    [hockey startManager];
    [hockey.authenticator authenticateInstallation];
	// INTERNAL ONLY ENDS
    
    // Fixes navigation bar on iOS<7
    if (![UINavigationBar instancesRespondToSelector:@selector(barTintColor)])
    {
        // The value is copied from the storyboard
        [UINavigationBar appearance].tintColor = [UIColor colorWithRed:0.74901960784314
                                                                       green:0
                                                                        blue:0
                                                                       alpha:1];

        [[UIBarButtonItem appearanceWhenContainedIn:UINavigationBar.class, nil] setBackgroundImage:UIImage.new
                                                                                          forState:UIControlStateNormal
                                                                                        barMetrics:UIBarMetricsDefault];
    }

    // Application looks better with this :-)
    application.statusBarStyle = UIStatusBarStyleLightContent;

    // Turn on location tracking
    CLLocationManager *locationManager = CLLocationManager.new;
    locationManager.desiredAccuracy = kCLLocationAccuracyThreeKilometers;
    if ([locationManager respondsToSelector:@selector(requestAlwaysAuthorization)])
    {
        // iOS8+
        [locationManager requestAlwaysAuthorization];
    }
    self.locationManager = locationManager;

    return YES;
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    [self.locationManager startUpdatingLocation];
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    [self.locationManager stopUpdatingLocation];
}

@end

