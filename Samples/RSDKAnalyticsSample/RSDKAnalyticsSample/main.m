//
//  main.m
//  RSDKAnalyticsSample
//
//  Created by Julien Cayzac on 5/22/14.
//  Copyright (c) 2014 Rakuten, Inc. All rights reserved.
//

@import UIKit;

#import <TestFlightSDK/TestFlight.h>

#import "RSDKAnalyticsAppDelegate.h"

int main(int argc, char *argv[])
{
    @autoreleasepool {
        [TestFlight takeOff:@"901cffe9-6a9c-492f-868a-80f7ecc535c4"];
        return UIApplicationMain(argc, argv, nil, NSStringFromClass(RSDKAnalyticsAppDelegate.class));
    }
}

