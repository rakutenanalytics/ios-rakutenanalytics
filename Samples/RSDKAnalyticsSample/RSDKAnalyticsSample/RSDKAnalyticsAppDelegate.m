#import "RAnalytics.h"
#import "RSDKAnalyticsAppDelegate.h"

/////////////////////////////////////////////////////////////////

@implementation RSDKAnalyticsAppDelegate
@synthesize window;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
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
    
    [RAnalyticsRATTracker.sharedInstance setBatchingDelay:10];

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

