/*
 Copyright: Copyright (C) 2012 Rakuten, Inc.  All Rights Reserved.
 
 
 File Name:  RGeoLocationManager.h
 
 Description: This class is used to get current GPS location and will provide location related functionalities.
 This class will register in CLLocationManager to get use of location related services. 
 location manager object provides support for the following location-related activities:
 1.altitude – type CLLocationDistance
 2.coordinate – type CLLocationCoordinate2D
 3.horizontalAccuracy – type CLLocationAccuracy
 4.speed – type CLLocationSpeed
 5.timestamp – type NSDate
 6.verticalAccuracy – type CLLocationAccuracy.   
 
 Author: Mandar Kadam
 
 Created: 5th-Jun-2012 
 
 Changed: 
 
 Version: 1.0
 
 *
 */

#import <CoreLocation/CoreLocation.h>
#import <Foundation/Foundation.h>

@interface  RGeoLocationManager : NSObject <CLLocationManagerDelegate> 
{
@private
    //CLLocationManager object is the entry point to the location service.
    CLLocationManager   *locationManager;
}
+ (RGeoLocationManager *)sharedInstance;

//Returns the current location
- (CLLocation *)getCurrentLocation;

//Starts the notifier for updating the location.
- (void)start;

//Stops the notifier for updating the location.
- (void)stop;

//Set the distance filter and desired accuracy.
- (void)setDistanceFilter:(CLLocationDistance)distance withAccuracy:(CLLocationAccuracy)accuracy;

//Checks whether the location services is enableed or not.
- (BOOL)isLocationKnown;
@end