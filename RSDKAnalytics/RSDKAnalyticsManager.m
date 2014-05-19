//
//  RSDKAnalyticsManager.m
//  RSDKAnalytics
//
//  Created by Julien Cayzac on 5/19/14.
//  Copyright (c) 2014 Rakuten, Inc. All rights reserved.
//


@import CoreGraphics;
@import CoreLocation;
@import CoreTelephony;
@import Darwin.POSIX.sys;
@import ObjectiveC.runtime;
@import UIKit;

#import <sqlite3.h>

#import <RSDKSupport/NSData+RAExtensions.h>
#import <RSDKSupport/NSString+RAExtensions.h>
#import <RSDKSupport/RLoggingHelper.h>
#import <RSDKSupport/RSDKAssert.h>

#import <RSDKDeviceInformation/RSDKDeviceInformation.h>

#import <FXReachability/FXReachability.h>

#import "RSDKAnalytics.h"
#import "RSDKAnalyticsDatabase.h"


////////////////////////////////////////////////////////////////////////////

// Externs

NSString *const RSDKAnalyticsWillUploadNotification    = @"RSDKAnalyticsWillUploadNotification";
NSString *const RSDKAnalyticsUploadFailureNotification = @"RSDKAnalyticsUploadFailureNotification";
NSString *const RSDKAnalyticsUploadSuccessNotification = @"RSDKAnalyticsUploadSuccessNotification";
NSString *const RSDKAnalyticsErrorDomain               = @"RSDKAnalyticsErrorDomain";


////////////////////////////////////////////////////////////////////////////

// Private constants


/*
 * This maps the values for the otherwise-undocumented MOBILE_NETWORK_TYPE RAT parameter,
 * and adds an extra RSDKAnalyticsInvalidMobileNetworkType value we do not send.
 */

typedef NS_ENUM(NSInteger, RSDKAnalyticsMobileNetworkType)
{
    RSDKAnalyticsInvalidMobileNetworkType = 0,
    RSDKAnalyticsMobileNetworkTypeWiFi    = 1,
    RSDKAnalyticsMobileNetworkType2G      = 2,
    RSDKAnalyticsMobileNetworkType3G      = 3,
    RSDKAnalyticsMobileNetworkType4G      = 4,
};


/*
 * This pointer is used as the key for the associated object we set on
 * the class, that is returned by +startTime.
 */

static const void* RSDKAnalyticsStartTimeKey = &RSDKAnalyticsStartTimeKey;


/*
 * We wait at least a minute after an upload has been fully processed
 * before attempting to trigger a new one.
 */

const NSTimeInterval RSDKAnalyticsUploadInterval = 60.0;


/*
 * Any request that takes more than 30 seconds is canceled.
 */

const NSTimeInterval RSDKAnalyticsRequestTimeoutInterval = 30.0;



////////////////////////////////////////////////////////////////////////////

@interface RSDKAnalyticsManager()<CLLocationManagerDelegate>

@property(nonatomic, strong) CLLocationManager *locationManager;


/*
 * We need to keep an instance of CTTelephonyNetworkInfo around to track
 * changes in radio access technology, on iOS 7+.
 */

@property(nonatomic, strong) CTTelephonyNetworkInfo *telephonyNetworkInfo;
@property(nonatomic) BOOL isUsingLTE;


/*
 * uploadTimer is used to throttle uploads. A call to -_scheduleBackgroundUpload
 * will do nothing if uploadTimer is not nil.
 *
 * Since we don't want to start a new upload until the previous one has been fully
 * processed, though, we only invalidate that timer at the very end of the HTTP
 * request. That's why we also need uploadRequested, set by -_scheduleBackgroundUpload,
 * so that we know we have to restart our timer at that point.
 */

@property(nonatomic) BOOL uploadRequested;
@property(nonatomic, strong) NSTimer *uploadTimer;


/*
 * Session cookie. We use an UUID automatically created at startup and
 * regenerated when the app comes back from background, as per the
 * specifications.
 */

@property(nonatomic, copy) NSString *sessionCookie;

- (instancetype)initSharedInstance;
@end



////////////////////////////////////////////////////////////////////////////

@implementation RSDKAnalyticsManager

#pragma mark - Class methods

+ (void)load
{
    /*
     * This class isn't supposed to be subclassed, but if it is,
     * then we don't want to run what follows for the subclasses.
     */

    if (self != RSDKAnalyticsManager.class)
    {
        return;
    }


    /*
     * We want to know the point in time at which the application was started,
     * not at which RSDKAnalyticsManager was first used, so we record that instant
     * in RSDKAnalyticsManager.startTime.
     */

    @autoreleasepool
    {

        /*
         * Using the following code would result in libICU being lazily loaded along with
         * its 16MB of data, and the latter would never get deallocated. No thanks, iOS!
         *
         * ```
         * NSDateFormatter *startTimeFormatter = NSDateFormatter.new;
         * startTimeFormatter.locale = [NSLocale localeWithLocaleIdentifier:@"en_US_POSIX"];
         * startTimeFormatter.timeZone = [NSTimeZone timeZoneForSecondsFromGMT:0];
         * startTimeFormatter.dateFormat = @"yyyy-MM-dd HH:mm:ss";
         * NSString *startTime = [startTimeFormatter stringFromDate:NSDate.date];
         * ```
         *
         * Think NSCalendar is the solution? No luck, it loads ICU too! Instead,
         * we just use a few lines of C, which allocate about 20KB. It's OK as we don't need
         * any fancy locale.
         */


        /*
         * The reason I don't use gettimeofday (2) is that it's a BSD 4.2 function, it's not part
         * of the standard C library, and I'm not sure how Apple feels about using those.
         *
         * -[NSDate timeIntervalSince1970] gives the same result anyway.
         */

        NSTimeInterval now = NSDate.date.timeIntervalSince1970;
        struct timeval tod;
        tod.tv_sec  = (long) ceil(now);
        tod.tv_usec = (int)  ceil((now - tod.tv_sec) * (double) NSEC_PER_MSEC);


        /*
         * localtime (3) reuses an internal buffer, so the pointer it returns must never get
         * free (3)'d. localtime (3) is ISO C90 so it's safe to use without having to worry
         * about Apple's wrath.
         */

        struct tm *time = localtime(&tod.tv_sec);


        /*
         * struct tm's epoc is 1900/1/1. Months start at 0.
         */

        NSString *startTime = [NSString stringWithFormat:@"%04u-%02u-%02u %02u:%02u:%02u",
                               1900 + time->tm_year,
                               1 + time->tm_mon,
                               time->tm_mday,
                               time->tm_hour,
                               time->tm_min,
                               time->tm_sec];

        objc_setAssociatedObject(self,
                                 RSDKAnalyticsStartTimeKey,
                                 startTime,
                                 OBJC_ASSOCIATION_COPY_NONATOMIC);
    }
}

//--------------------------------------------------------------------------

+ (NSString*)startTime
{
    return objc_getAssociatedObject(self, RSDKAnalyticsStartTimeKey);
}

//--------------------------------------------------------------------------

+ (instancetype)sharedInstance
{
    static id instance;
    static dispatch_once_t once;
    dispatch_once(&once, ^
    {
        instance = [self.alloc initSharedInstance];
    });

    return instance;
}

//--------------------------------------------------------------------------

+ (void)spoolRecord:(RSDKAnalyticsRecord *)record
{
    [self.sharedInstance spoolRecord_:record];
}

//--------------------------------------------------------------------------

+ (NSURL*)endpointAddress
{
    static NSURL *url;
    static dispatch_once_t once;
    dispatch_once(&once, ^
    {
        url = [NSURL URLWithString:@"https://rat.rakuten.co.jp/"];
    });
    return url;
}

//--------------------------------------------------------------------------

#pragma mark - Object life cycle

- (instancetype)init
{
    RSDKALWAYSASSERT(@"%1$@ is a singleton. Please use [%1$@ sharedInstance].", NSStringFromClass(self.class));
    return nil;
}

//--------------------------------------------------------------------------

- (instancetype)initSharedInstance
{
    if (self = [super init])
    {
        [self _startNewSession];


        /*
         * Set up the location manager
         */

        self.locationManager = CLLocationManager.new;
        self.locationManager.desiredAccuracy = kCLLocationAccuracyKilometer;
        self.locationManager.delegate = self;

        atexit_b(^
        {
            [self.locationManager stopUpdatingLocation];
        });



        /*
         * Register notification handlers.
         */

        NSNotificationCenter* notificationCenter = NSNotificationCenter.defaultCenter;
        atexit_b(^
        {
            [notificationCenter removeObserver:self];
        });


        /*
         * Renew the session cookie every time the application goes back to the
         * foreground.
         */

        [notificationCenter addObserver:self
                               selector:@selector(_startNewSession)
                                   name:UIApplicationDidBecomeActiveNotification
                                 object:nil];


        /*
         * Listen to changes in radio access technology, to detect LTE. Only iOS7+ sends these.
         */

        self.telephonyNetworkInfo  = CTTelephonyNetworkInfo.new;
        if ([self.telephonyNetworkInfo respondsToSelector:@selector(currentRadioAccessTechnology)])
        {
            /*
             * Check immediately, then listen to changes.
             */

            [self _checkLTE];

            [notificationCenter addObserver:self
                                   selector:@selector(_checkLTE)
                                       name:CTRadioAccessTechnologyDidChangeNotification
                                     object:nil];
        }
    }
    return self;
}

//--------------------------------------------------------------------------

#pragma mark - Getters & setters

- (void)setLocationTrackingEnabled:(BOOL)locationTrackingEnabled
{
    if (locationTrackingEnabled == _locationTrackingEnabled)
    {
        // No change
        return;
    }

    _locationTrackingEnabled = locationTrackingEnabled;

    if (!locationTrackingEnabled)
    {
        RDebugLog(@"Stop monitoring location");
        [self.locationManager stopUpdatingLocation];
    }
    else if (CLLocationManager.locationServicesEnabled && CLLocationManager.authorizationStatus == kCLAuthorizationStatusAuthorized)
    {
        RDebugLog(@"Start monitoring location");
        [self.locationManager startUpdatingLocation];
    }

}

//--------------------------------------------------------------------------

#pragma mark - CLLocationManagerDelegate

- (void)locationManager:(CLLocationManager * __unused)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status
{
    if (!self.locationTrackingEnabled)
    {
        return;
    }

    if (status == kCLAuthorizationStatusAuthorized && CLLocationManager.locationServicesEnabled)
    {
        RDebugLog(@"Start monitoring location");
        [self.locationManager startUpdatingLocation];
    }
    else
    {
        RDebugLog(@"Stop monitoring location");
        [self.locationManager stopUpdatingLocation];
    }
}

//--------------------------------------------------------------------------

- (void)locationManager:(CLLocationManager * __unused)manager didFinishDeferredUpdatesWithError:(NSError *)error
{
    // error is only used in Debug
    (void)error;

    RDebugLog(@"Failed to acquire device location: %@", error.localizedDescription);
}

//--------------------------------------------------------------------------

#pragma mark - Private methods

- (void)spoolRecord_:(RSDKAnalyticsRecord *)record
{
    if (!record)
    {
        // Nothing to do
        return;
    }


    /*
     * Gather all the data that never changes while the app is running:
     */

    static NSString *osVersion;
    static UIDevice *device;
    static NSString *screenResolution;
    static NSString *carrierName;
    static NSString *userAgent;
    static dispatch_once_t once;
    dispatch_once(&once, ^
    {
        CGSize screenSize = UIScreen.mainScreen.bounds.size;
        screenResolution = [NSString stringWithFormat:@"%0.fx%0.f", screenSize.width, screenSize.height];

        device = UIDevice.currentDevice;
        osVersion = [NSString stringWithFormat:@"%@ %@", device.systemName, device.systemVersion];


        /*
         * This is needed to enable access to the battery getters below.
         */

        if (!device.isBatteryMonitoringEnabled)
        {
            device.batteryMonitoringEnabled = YES;
        }


        /*
         * Build a user agent string of the form AppId/Version
         */
        NSBundle *bundle = NSBundle.mainBundle;
        userAgent = [NSString stringWithFormat:@"%@/%@", bundle.bundleIdentifier, [bundle objectForInfoDictionaryKey:@"CFBundleVersion"]];


        /*
         * Listen to changes in carrier.
         */

        void (^assignCarrierName)(CTCarrier *) = ^(CTCarrier *carrier){
            carrierName = carrier.carrierName.copy;
            carrierName = [carrierName substringToIndex:MIN(32ul, carrierName.length)];

            if (!carrierName.length)
            {
                carrierName = nil;
            }
        };

        CTTelephonyNetworkInfo *telephonyNetworkInfo = self.telephonyNetworkInfo;
        assignCarrierName(telephonyNetworkInfo.subscriberCellularProvider);
        telephonyNetworkInfo.subscriberCellularProviderDidUpdateNotifier = ^(CTCarrier *carrier)
        {
            assignCarrierName(carrier);
        };
    });


    id jsonDic = record.propertiesDictionary.mutableCopy;

    if (device.batteryState != UIDeviceBatteryStateUnknown)
    {
        // {name: "powerstatus", longName: "BATTERY_CHARGING_STATUS", fieldType: "INT", definitionLevel: "APP", validValues: [0, 1 ], userSettable: true}
        jsonDic[@"powerstatus"] = @(device.batteryState != UIDeviceBatteryStateUnplugged ? 1 : 0);

        // {name: "mbat", longName: "BATTERY_USAGE", fieldType: "STRING", definitionLevel: "APP", maxLength: 32, minLength: 0, userSettable: true}
        jsonDic[@"mbat"] = [NSString stringWithFormat:@"%0.f", MIN(0, device.batteryLevel) * 100];
    }

    // {name: "dln", longName: "DEVICE_LANGUAGE", fieldType: "STRING", definitionLevel: "APP", maxLength: 16, minLength: 0, userSettable: true}
    jsonDic[@"dln"] = [NSLocale.currentLocale objectForKey:NSLocaleLanguageCode];

    // {name: "loc", longName: "LOCATION", fieldType: "JSON"}
    if (self.locationTrackingEnabled &&
        CLLocationManager.locationServicesEnabled &&
        CLLocationManager.authorizationStatus == kCLAuthorizationStatusAuthorized)
    {
        // Last known location
        CLLocation *location = self.locationManager.location;

        if (location && CLLocationCoordinate2DIsValid(location.coordinate))
        {
            id locationDic = NSMutableDictionary.new;

            // {name: "accu", longName: "ACCURACY", fieldType: "DOUBLE", minValue: 0.0, userSettable: false}
            // According to RAL.js, unit is metre.
            locationDic[@"accu"] = @(MAX(0.0, location.horizontalAccuracy));

            // {name: "altitude", longName: "ALTITUDE", fieldType: "DOUBLE", userSettable: false}
            locationDic[@"altitude"] = @(location.altitude);

            // {name: "tms", longName: "GPS_TIMESTAMP", fieldType: "INT", minValue: 0, userSettable: false}
            // According to RAL.js it's in milliseconds since the unix epoch
            locationDic[@"tms"] = @(MAX(0ll, (int64_t) round(location.timestamp.timeIntervalSince1970 * 1000.0)));

            // {name: "lat", longName: "LATITUDE", fieldType: "DOUBLE", minValue: -90.0, maxValue: 90.0, userSettable: false}
            locationDic[@"lat"] = @(MIN(90.0, MAX(-90.0, location.coordinate.latitude)));

            // {name: "long", longName: "LONGITUDE", fieldType: "DOUBLE", minValue: -180.0, maxValue: 180.0, userSettable: false}
            locationDic[@"long"] = @(MIN(180.0, MAX(-180.0, location.coordinate.longitude)));

            // {name: "speed", longName: "SPEED", fieldType: "DOUBLE", minValue: 0.0, userSettable: false}
            locationDic[@"speed"] = @(MAX(0.0, location.speed));

            //{name: "loc", longName: "LOCATION", fieldType: "JSON", comment: "Location related field group"}
            jsonDic[@"loc"] = locationDic;
        }
    }

    // {name: "mcn", longName: "MOBILE_CARRIER_NAME", fieldType: "STRING", definitionLevel: "APP", maxLength: 32, minLength: 0, userSettable: true}
    if (carrierName)
    {
        jsonDic[@"mcn"] = carrierName;
    }

    // {name: "model", longName: "MOBILE_DEVICE_BRAND_MODEL", fieldType: "STRING", definitionLevel: "APP", maxLength: 48, minLength: 0, userSettable: true}
    jsonDic[@"model"] = RSDKDeviceInformation.modelIdentifier;

    // {name: "mnetw", longName: "MOBILE_NETWORK_TYPE", fieldType: "INT", definitionLevel: "APP", validValues: [1, 2, 3, 4], userSettable: true}
    RSDKAnalyticsMobileNetworkType mobileNetworkType;

    switch (FXReachability.sharedInstance.status)
    {
        case FXReachabilityStatusReachableViaWiFi:
            mobileNetworkType = RSDKAnalyticsMobileNetworkTypeWiFi;
            break;

        case FXReachabilityStatusReachableViaWWAN:
            mobileNetworkType = self.isUsingLTE ? RSDKAnalyticsMobileNetworkType4G : RSDKAnalyticsMobileNetworkType3G;
            break;

        default:
            mobileNetworkType = RSDKAnalyticsInvalidMobileNetworkType;
            break;
    }

    if (mobileNetworkType != RSDKAnalyticsInvalidMobileNetworkType)
    {
        jsonDic[@"mnetw"] = @(mobileNetworkType);
    }

    // {name: "mori", longName: "MOBILE_ORIENTATION", fieldType: "INT", definitionLevel: "APP", validValues: [1, 2], userSettable: true}
    UIDeviceOrientation deviceOrientation = device.orientation;

    if (deviceOrientation == UIDeviceOrientationPortrait || deviceOrientation == UIDeviceOrientationPortraitUpsideDown)
    {
        jsonDic[@"mori"] = @1;
    }
    else if (deviceOrientation == UIDeviceOrientationLandscapeLeft || deviceOrientation == UIDeviceOrientationLandscapeRight)
    {
        jsonDic[@"mori"] = @2;
    }

    // {name: "mos", longName: "MOBILE_OS", fieldType: "STRING", definitionLevel: "APP", maxLength: 32, minLength: 0, userSettable: true}
    jsonDic[@"mos"] = osVersion;

    // {name: "online", longName: "ONLINE_STATUS", fieldType: "BOOLEAN", userSettable: false}
    jsonDic[@"online"] = FXReachability.sharedInstance.status != FXReachabilityStatusNotReachable ? @YES : @NO;

    // {name: "ckp", longName: "PERSISTENT_COOKIE", definitionLevel: "TrackingServer", fieldType: "STRING", maxLength: 1024, minLength: 0, userSettable: true}
    NSString *uniqueDeviceId = RSDKDeviceInformation.uniqueDeviceIdentifier;
    // This can be nil if the device is locked and the value hasn't been retrieved yet
    if (uniqueDeviceId)
    {
        jsonDic[@"ckp"] = uniqueDeviceId;
    }

    // {name: "ua", longName: "USER_AGENT", definitionLevel: "TrackingServer", fieldType: "STRING", maxLength: 1024, minLength: 0, userSettable: false}
    jsonDic[@"ua"] = userAgent;

    // {name: "res", longName: "RESOLUTION", fieldType: "STRING", maxLength: 12, minLength: 0, userSettable: false }
    jsonDic[@"res"] = screenResolution;

    // {name: "ltm", longName: "SCRIPT_START_TIME", fieldType: "STRING", maxLength: 20, minLength: 0, regex: "\\d\\d\\d\\d-\\d\\d\\-\\d\\d \\d\\d:\\d\\d:\\d\\d", userSettable: false}
    jsonDic[@"ltm"] = self.class.startTime;

    // {name: "cks", longName: "SESSION_COOKIE", definitionLevel: "TrackingServer", fieldType: "STRING", maxLength: 1024, minLength: 0, userSettable: true}
    jsonDic[@"cks"] = self.sessionCookie;

    // FIXME: fill the description below once the IDL has "ts1".
    // {name: "ts1", ...
    jsonDic[@"ts1"] = @(MAX(0ll, (int64_t) round(NSDate.date.timeIntervalSince1970 * 1000.0)));

    // {name: "tzo", longName: "TIMEZONE", fieldType: "DOUBLE", minValue: -12.0, maxValue: 12.0, userSettable: false}
    jsonDic[@"tzo"] = @(NSTimeZone.localTimeZone.secondsFromGMT / 3600.0);

    // {name: "ver", longName: "VERSION", fieldType: "STRING", maxLength: 32, minLength: 0,userSettable: false}
    jsonDic[@"ver"] = RSDKAnalyticsVersion;

    // Add record to database and schedule an upload
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:jsonDic options:0 error:0];
    RSDKASSERTIFNOT(jsonData, @"Failed to serialize to JSON: %@", jsonDic);

    typeof(self) __weak weakSelf = self;
    [RSDKAnalyticsDatabase addRecord:jsonData completion:^
    {
        typeof(weakSelf) __strong strongSelf = weakSelf;
        [strongSelf _scheduleBackgroundUpload];
    }];
}

//--------------------------------------------------------------------------

/*
 * Schedule a new background upload, if none has already been scheduled or is
 * currently being processed. Otherwise it just sets 'uploadRequested' to YES
 * so that scheduling happens next time -_backgroupUploadEnded gets called.
 */
- (void)_scheduleBackgroundUpload
{
    @synchronized(self)
    {
        // If a background upload has already been scheduled or is underway,
        // just set uploadRequested to YES and return
        if (self.uploadTimer)
        {
            self.uploadRequested = YES;
            return;
        }

        self.uploadTimer = [NSTimer scheduledTimerWithTimeInterval:RSDKAnalyticsUploadInterval
                                                            target:self
                                                          selector:@selector(_doBackgroundUpload)
                                                          userInfo:nil
                                                           repeats:NO];
        self.uploadRequested = NO;
    }
}

//--------------------------------------------------------------------------

/*
 * This method is called whenever a background upload ends, successfully or not.
 * If uploadRequested has been set, it schedules another upload.
 */
- (void)_backgroupUploadEnded
{
    @synchronized(self)
    {
        // It's time to invalidate our timer to clear the way for new uploads to get scheduled.
        [self.uploadTimer invalidate];
        self.uploadTimer = nil;

        // If another upload has been requested, schedule it
        if (!self.uploadRequested)
        {
            return;
        }
    }

    [self _scheduleBackgroundUpload];
}

//--------------------------------------------------------------------------

/*
 * Called by -_doBackgroundUpload only if previously-saved records were found.
 */
- (void)doBackgroundUploadWithRecords_:(NSArray *)records identifiers:(NSArray *)identifiers
{
    /*
     * When you make changes here, always check the server-side program will
     * accept it. The source code is at
     * https://git.dev.rakuten.com/projects/RATR/repos/receiver/browse/receiver.c
     */


    /*
     * We'll be doing asynchronous stuff, but we will enventually
     * end up calling -_backgroupUploadEnded. Let's make a block now
     * that takes care of that so we don't need to strongify weakSelf
     * all over the place.
     */

    typeof(self) __weak weakSelf = self;
    void (^completion)() = ^
    {
        typeof(weakSelf) __strong strongSelf = weakSelf;
        [strongSelf _backgroupUploadEnded];
    };


    /*
     * Prepare the body of our POST request. It's a JSON-formatted array
     * of records. Note that the server doesn't accept pretty-formatted JSON.
     *
     * We could append 'record' NSData instances to 'postBody' in turn, separating
     * each with a comma, but we'll need an array of deserialized objects anyway
     * for using within the notifications we're sending.
     */

    NSArray *recordGroup = (
    {
        NSMutableArray *builder = [NSMutableArray arrayWithCapacity:records.count];
        for (NSData *recordData in records)
        {
            [builder addObject:[NSJSONSerialization JSONObjectWithData:recordData
                                                               options:0
                                                                 error:NULL]];
        }
        builder.copy;
    });

    [NSNotificationCenter.defaultCenter postNotificationName:RSDKAnalyticsWillUploadNotification
                                                      object:recordGroup];

    NSMutableData *postBody = NSMutableData.new;
    [postBody appendData:[@"cpkg_none=" dataUsingEncoding:NSUTF8StringEncoding]];
    [postBody appendData:[NSJSONSerialization dataWithJSONObject:recordGroup
                                                         options:0
                                                           error:NULL]];


    /*
     * Prepare and send the request.
     *
     * We only delete the records from our database if server returns a 200 HTTP status.
     */

    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:self.class.endpointAddress
                                                           cachePolicy:NSURLRequestReloadIgnoringCacheData
                                                       timeoutInterval:RSDKAnalyticsRequestTimeoutInterval];


    /*
     * For historical reasons we don't send the JSON as JSON but as some
     * weird non-urlEncoded x-www-form-urlencoded, passed as text/plain.
     *
     * The backend also doesn't accept a charset value (but assumes UTF-8).
     */

    [request setValue:@"text/plain" forHTTPHeaderField:@"Content-Type"];


    /*
     * Set the content length, as the backend needs it.
     */

    [request setValue:[NSString stringWithFormat:@"%lu", (unsigned long)postBody.length] forHTTPHeaderField:@"Content-Length"];

    request.HTTPMethod = @"POST";
    request.HTTPBody = postBody;

    [NSURLConnection sendAsynchronousRequest:request
                                       queue:NSOperationQueue.currentQueue
                           completionHandler:^(NSURLResponse *response,
                                               NSData * __unused data,
                                               NSError *connectionError)
    {
        NSError *error = connectionError;

        if (connectionError)
        {
            /*
             * Connection failed. Request a new attempt before calling the completion.
             */

            typeof(weakSelf) __strong strongSelf = weakSelf;
            if (strongSelf)
            {
                @synchronized(strongSelf)
                {
                    strongSelf.uploadRequested = YES;
                }
            }
        }
        else if ([response isKindOfClass:NSHTTPURLResponse.class])
        {
            NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *) response;
            if (httpResponse.statusCode == 200)
            {
                /*
                 * Success!
                 */

                [NSNotificationCenter.defaultCenter postNotificationName:RSDKAnalyticsUploadSuccessNotification
                                                                  object:recordGroup];


                /*
                 * Delete the records from the local database.
                 */

                [RSDKAnalyticsDatabase deleteRecordsWithIdentifiers:identifiers
                                                         completion:completion];
                return;
            }

            error = [NSError errorWithDomain:RSDKAnalyticsErrorDomain
                                        code:RSDKAnalyticsErrorWrongResponseStatus
                                    userInfo:@{NSURLErrorFailingURLErrorKey: response.URL,
                                               NSLocalizedDescriptionKey: [NSString stringWithFormat:@"Expected status code == 200, got %ld", (long)httpResponse.statusCode]
                                               }];
        }

        id userInfo = nil;
        if (error)
        {
            userInfo = @{NSUnderlyingErrorKey: error};
        }

        [NSNotificationCenter.defaultCenter postNotificationName:RSDKAnalyticsUploadFailureNotification
                                                          object:recordGroup
                                                        userInfo:userInfo];

        completion();
    }];
}

//--------------------------------------------------------------------------

- (void)_doBackgroundUpload
{
    /*
     * Get a group of records and start uploading them.
     */

    typeof(self) __weak weakSelf = self;
    [RSDKAnalyticsDatabase fetchRecordGroup:^(NSArray *records, NSArray *identifiers)
    {
        typeof(weakSelf) __strong strongSelf = weakSelf;

        if (records.count)
        {
            [strongSelf doBackgroundUploadWithRecords_:records identifiers:identifiers];
        }
        else
        {
            [strongSelf _backgroupUploadEnded];
        }
    }];
}

//--------------------------------------------------------------------------

- (void)_startNewSession
{
    self.sessionCookie = NSString.stringWithUUID;


    /*
     * Schedule a background upload attempt when the app becomes
     * active.
     */

    [self _scheduleBackgroundUpload];
}

//--------------------------------------------------------------------------

- (void)_checkLTE
{
    self.isUsingLTE = [self.telephonyNetworkInfo.currentRadioAccessTechnology isEqualToString:CTRadioAccessTechnologyLTE];
}


@end

