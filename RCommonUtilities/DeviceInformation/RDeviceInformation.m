/*
 Copyright: Copyright (C) 2012 Rakuten, Inc.  All Rights Reserved.
 
 
 File Name:  RADeviceInformation.m
 
 Description: This class is responsible for getting the device information.
 
 Author: Mandar Kadam
 
 Created: 2nd-May-2012
 
 Changed:
 
 Version: 1.0
 
 *
 */

#import "RDeviceInformation.h"
#import "RUtilLogger.h"

NSInteger const portrait = 1;
NSInteger const landscape = 2;

@interface RDeviceInformation (Private)
- (void)getBatteryLevel;
- (void)detectOrientation;
- (void)getPowerStatus;
- (void)getDeviceLanguageInfo;
@end

@implementation RDeviceInformation

@synthesize orientation;
@synthesize systemVersion;
@synthesize res;
@synthesize batteryLevel;
@synthesize isDevicePluggedToPower;
@synthesize deviceLanguage;
/*!
 @function		init
 @discussion	Initializes the device manager class
 @param			none
 @return		DeviceManager
 */
- (id)init
{
    if((self = [super init]))
    {
        [[UIDevice currentDevice] setBatteryMonitoringEnabled:YES];
        self.deviceLanguage = nil;
        self.isDevicePluggedToPower = NO;
        self.orientation = 1;
        self.systemVersion = [[UIDevice currentDevice] systemVersion]; 
        CGRect rect = [[UIScreen mainScreen] bounds];
        self.res = [NSString stringWithFormat:@"%dX%d", (int)rect.size.width, (int)rect.size.height];
    }
    return self;
}

/*!
 @function      fetchDeviceInformation
 @discussion    Initialies all the device parameters consisting of all the details of the device
 @param         nil
 @return        nil
 */
- (void)fetchDeviceInformation
{
    [self getBatteryLevel];
    [self detectOrientation];
    [self getPowerStatus];
    [self getDeviceLanguageInfo];
}

/*!
 @function      getBatteryLevel
 @discussion    Gets the battery level of the device
 @param         nil
 @return        nil
 */
- (void)getBatteryLevel
{
    self.batteryLevel = ( [[UIDevice currentDevice] batteryLevel] * 100.00 );
}

/*!
 @function      getPowerStatus
 @discussion    Initialises the variable isDevicepluggedToPower, by checking the battery state of the device.
 @param         nil
 @return        nil
 */
- (void)getPowerStatus
{
    UIDeviceBatteryState currentState = [[UIDevice currentDevice] batteryState];
    if (currentState == UIDeviceBatteryStateCharging)
        // The battery is either charging, or connected to a charger
        self.isDevicePluggedToPower = YES;
    else
        self.isDevicePluggedToPower = NO;
}

/*!
 @function      detectOrientation
 @discussion    intialises device orientation changes.
 @param         nil
 @return        nil
 */
- (void)detectOrientation
{
    int deviceOrientation = [[UIDevice currentDevice] orientation];
    if( deviceOrientation == UIDeviceOrientationFaceUp || deviceOrientation == UIDeviceOrientationFaceDown ||
       deviceOrientation == UIDeviceOrientationLandscapeLeft || deviceOrientation == UIDeviceOrientationLandscapeRight )
    {
        deviceOrientation = landscape;
    }
    else
    {
        deviceOrientation = portrait;
    }
    self.orientation = deviceOrientation;
}

/*!
 @function      getDeviceLangaugeInfo
 @discussion    Intialises device langauge.
 @param         nil
 @return        nil
 */
- (void)getDeviceLanguageInfo
{
    self.deviceLanguage = [[NSLocale currentLocale] localeIdentifier];
}

- (void)dealloc
{
    [[UIDevice currentDevice] setBatteryMonitoringEnabled:NO];
    self.systemVersion = nil;
    self.res = nil;
    self.deviceLanguage = nil;
}

/*!
 @function      isRoaming
 @discussion    Checks roaming is supported is ON or OFF.
 @param         nil
 @return        nil
 */
- (BOOL)isRoaming
{
    RULog(@"Not supported");
    return NO;
}
@end
