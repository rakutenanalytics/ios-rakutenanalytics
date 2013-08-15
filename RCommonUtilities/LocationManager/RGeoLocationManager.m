/*
 Copyright: Copyright (C) 2012 Rakuten, Inc.  All Rights Reserved.
 
 
 File Name:  RGeoLocationManager.m
 
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

#import "RGeoLocationManager.h"
#import "RUtilLogger.h"

@interface RGeoLocationManager ()

//CLLocation object contains information about the current location(latitude, longitude, speed, altitude, horizontal accuracy, vertical accuracy, timestamp
@property (nonatomic, strong) CLLocation          *currentLocation;

- (void)setDefaultLocation:(CLLocation *)location;
@end

@implementation RGeoLocationManager
@synthesize currentLocation;

const float kDefaultFloatValue = -1.0f;
//distance filter for getting location details
const float kDistanceFilter = 100.0f;

/*!
 @function		sharedInstance
 @discussion	This is singleton implementation of LocationController provides details information about current location
 @param			none 
 @result		LocationController
 */
+ (RGeoLocationManager *)sharedInstance {
    
    static dispatch_once_t pred;
    static RGeoLocationManager *shared = nil;
    dispatch_once(&pred, ^{
        shared = [[RGeoLocationManager alloc] init];
    });
    return shared;
}

/*!
 @function		init
 @discussion	This function initializes CLLocationManager object.
 @param			none 
 @result		id ehich is self of LocationController
 */
- (id)init {
    @try {
        if ((self = [super init])) {
            locationManager = [[CLLocationManager alloc] init];
            locationManager.delegate = self;
            
            
            // Temporary set default location lat and long as hardcoded.
            [self setDefaultLocation:nil];
            
            /* Pinpoint our location with the following accuracy:
             *
             *     kCLLocationAccuracyBestForNavigation  highest + sensor data
             *     kCLLocationAccuracyBest               highest     
             *     kCLLocationAccuracyNearestTenMeters   10 meters   
             *     kCLLocationAccuracyHundredMeters      100 meters
             *     kCLLocationAccuracyKilometer          1000 meters 
             *     kCLLocationAccuracyThreeKilometers    3000 meters
             */
            locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters;
            
            /* Notify changes when device has moved x meters.
             * Default value is kCLDistanceFilterNone: all movements are reported.
             */
            locationManager.distanceFilter = kDistanceFilter;
            
            [self start];
        }        
	}
	@catch (NSException * exception) {
        locationManager = nil;
        self.currentLocation = nil;
        RULog(@"%@",exception.description);
	}
    
    return self;
}

/*!
 @function		setDistanceFilter: withAccuracy:
 @discussion	This function sets the location desired accuracy and distance filter.
 @param1        distance of type CLLocationDistance
 @param2        accuracy of type CLLocationAccuracy
 @result		void
 */
- (void)setDistanceFilter:(CLLocationDistance)distance withAccuracy:(CLLocationAccuracy)accuracy
{
    if( locationManager )
    {
        [self stop];
        locationManager.desiredAccuracy = accuracy;
        locationManager.distanceFilter = distance;
        [self start];
    }
}
/*!
 @function		start
 @discussion	This function register itself to get location.
 @param			none 
 @result		void
 */
- (void)start {
#if TARGET_IPHONE_SIMULATOR
    //onceLocationUpdated = TRUE;
#else
    if( [CLLocationManager respondsToSelector:@selector(locationServicesEnabled)] )
    {
        // iOS 4.x
        BOOL locationAccessAllowed = [CLLocationManager locationServicesEnabled] ;
        if( locationAccessAllowed )
        {
            [locationManager startUpdatingLocation];
        }
    }
#endif
}


/*!
 @function		isLocationKnown
 @abstract		Determins whether location manager got location or not.
 @discussion	Determins whether location manager got location or not.
 @param			none
 @result		bool
 */
- (BOOL)isLocationKnown {
    
    BOOL locationServiceStatus = NO;
    
    @try {
        if(![CLLocationManager locationServicesEnabled])
        {
            return locationServiceStatus;
        }
        
        switch ([CLLocationManager authorizationStatus])
        {
            case kCLAuthorizationStatusNotDetermined: // User has not yet made a choice with regards to this application
                
                break;
            case kCLAuthorizationStatusRestricted:  // This application is not authorized to use location services.  Due
                break;                              // to active restrictions on location services, the user cannot change
                // this status, and may not have personally denied authorization
                
            case kCLAuthorizationStatusDenied:  // User has explicitly denied authorization for this application, or
                break;                          // location services are disabled in Settings
                
            case kCLAuthorizationStatusAuthorized: // User has authorized this application to use location services
                locationServiceStatus = YES;
                break;
        }
	}
	@catch (NSException * exception) {
		RULog(@"%@", exception.description);
        locationServiceStatus = NO;
	}
    return locationServiceStatus;
}

/*!
 @function		stop
 @discussion	This function cancels registration for updating location.
 @param			none 
 @result		void
 */
- (void)stop {
    [locationManager stopUpdatingLocation];
}

/*!
 @function		locationManager
 @discussion	This is a call back method when CLLocation manager fetch new location value.
 This will also return old location value.
 @param			manager		-	CLLocationmanger object
 @param			newLocation	-	
 @param			oldLocation	-	
 @result		void
 */
- (void)locationManager:(CLLocationManager *)manager 
    didUpdateToLocation:(CLLocation *)newLocation 
           fromLocation:(CLLocation *)oldLocation 
{
    [self setDefaultLocation:newLocation];
}

/*!
 @function		locationManager
 @discussion	This is call back method, if any error occurs while fetching current 
 geo location.
 @param			manager		-	CLLocationmanger object
 @param			error		-	Error object having code description in it.
 @result		void
 */
- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error {  
    
    // Temporary set default location lat and long as hardcoded.
    [self setDefaultLocation:nil];
	
}

/*!
 @function		setDefaultLocation
 @discussion	Sets the lat and longitude address pointer and initialize the 
 currentLocation object. Current location object consists of  
 latitude   - current latitude 
 longitude  - current longitude
 altitude   - current altitude
 hAccuracy  - current horizontal Accuracy
 vAccuracy  - current vertical Accuracy
 timeStamp  - current timestamp of the location 
 speed      - speed at the current location
 @result		void
 */
- (void)setDefaultLocation:(CLLocation *)location
{    
    if( location )
    {
        self.currentLocation = location;
    }
    else
    {
        CLLocationCoordinate2D cord;
        cord.latitude = -1.0;
        cord.longitude = -1.0;
        CLLocation *location = [[CLLocation alloc] initWithCoordinate:cord altitude:-1.0 horizontalAccuracy:-1.0 verticalAccuracy:-1.0 timestamp:nil];
        self.currentLocation = location;
    }
}

/*!
 @function		currentLocation
 @discussion	This set the current location and returns.
 @param			nil
 @result		void
 */
- (CLLocation*)getCurrentLocation
{
    return self.currentLocation;
}

-(void)dealloc{
    [self stop];
    self.currentLocation = nil;
}

@end