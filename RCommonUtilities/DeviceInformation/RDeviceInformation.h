/*
 Copyright: Copyright (C) 2012 Rakuten, Inc.  All Rights Reserved.
 
 
 File Name:  RDeviceInformation.h
 
 Description: This class is responsible for getting the device information.
 
 Author: Mandar Kadam
 
 Created: 2nd-May-2012
 
 Changed:
 
 Version: 1.0
 
 *
 */

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface RDeviceInformation : NSObject
{
@private
    // stores the device orientation information
    int         orientation;
    
    //Stores the OS version of the device
    NSString    *systemVersion;
    
    //Stores resolution of device for eg: 320X480
    NSString    *res;
    
    //Stores the battery level i.e amount of battery available
    float       batteryLevel;
    
    
}
@property(nonatomic, assign) int        orientation;
@property(nonatomic, assign) float      batteryLevel;
@property(nonatomic, copy)   NSString   *systemVersion;
@property(nonatomic, copy)   NSString   *res;
@property(nonatomic, assign) BOOL       isDevicePluggedToPower;
@property(nonatomic, copy)   NSString   *deviceLanguage;

//Intialises all device related information such as: orientation, system version, resolution and battery level
-(void)fetchDeviceInformation;

//Check device in roaming state or not 
- (BOOL)isRoaming;
@end
