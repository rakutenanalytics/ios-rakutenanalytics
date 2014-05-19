//
//  RSDKAnalyticsAppDelegate.m
//  RSDKAnalyticsSample
//
//  Created by Julien Cayzac on 5/22/14.
//  Copyright (c) 2014 Rakuten, Inc. All rights reserved.
//

#import "RSDKAnalytics.h"
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
    self.locationManager = CLLocationManager.new;
    self.locationManager.desiredAccuracy = kCLLocationAccuracyThreeKilometers;

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

