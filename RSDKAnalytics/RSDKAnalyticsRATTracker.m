/*
 * © Rakuten, Inc.
 * authors: "Rakuten Ecosystem Mobile" <ecosystem-mobile@mail.rakuten.com>
 */
#import <RSDKAnalytics/RSDKAnalytics.h>
#import <CoreTelephony/CTCarrier.h>
#import <CoreTelephony/CTTelephonyNetworkInfo.h>
#import <CoreLocation/CoreLocation.h>
#import <SystemConfiguration/SystemConfiguration.h>
#import <RSDKDeviceInformation/RSDKDeviceInformation.h>
#import "_RSDKAnalyticsHelpers.h"
#import "_RSDKAnalyticsDatabase.h"

NSString *const _RSDKAnalyticsPrefix = @"rat.";
NSString *const _RSDKAnalyticsGenericType = @"rat.generic";

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
 * Reachability status.
 */

typedef NS_ENUM(NSInteger, RSDKAnalyticsReachabilityStatus)
{
    RSDKAnalyticsReachabilityStatusUnknown = 0,
    RSDKAnalyticsReachabilityStatusOffline,
    RSDKAnalyticsReachabilityStatusConnectedWithWWAN,
    RSDKAnalyticsReachabilityStatusConnectedWithWiFi,
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

@interface RSDKAnalyticsRATTracker ()<CLLocationManagerDelegate>
@property (nonatomic) int64_t accountIdentifier;
@property (nonatomic) int64_t applicationIdentifier;


/*
 * We need to keep an instance of CTTelephonyNetworkInfo around to track
 * changes in radio access technology, on iOS 7+.
 */

@property(nonatomic, strong) CTTelephonyNetworkInfo *telephonyNetworkInfo;
@property(nonatomic) BOOL isUsingLTE;


/*
 * Keep track of reachability.
 */

@property (nonatomic, assign) RSDKAnalyticsReachabilityStatus reachabilityStatus;

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


@property(nonatomic, copy) NSString *startTime;
@end

@implementation RSDKAnalyticsRATTracker

static void _reachabilityCallback(SCNetworkReachabilityRef __unused target, SCNetworkReachabilityFlags flags, void __unused *info)
{
    RSDKAnalyticsReachabilityStatus status;

    if ((flags & kSCNetworkReachabilityFlagsReachable) == 0 ||
        (flags & kSCNetworkReachabilityFlagsConnectionRequired) != 0)
    {
        status = RSDKAnalyticsReachabilityStatusOffline;
    }
    else if ((flags & kSCNetworkReachabilityFlagsIsWWAN) != 0)
    {

        status = RSDKAnalyticsReachabilityStatusConnectedWithWWAN;
    }
    else
    {
        status = RSDKAnalyticsReachabilityStatusConnectedWithWiFi;
    }

    [RSDKAnalyticsRATTracker sharedInstance].reachabilityStatus = status;
}

#pragma mark - RSDKAnalyticsTracker

+ (instancetype)sharedInstance
{
    static RSDKAnalyticsRATTracker *instance = nil;
    static dispatch_once_t ratTrackerOnceToken;
    dispatch_once(&ratTrackerOnceToken, ^{
        instance = [self.alloc initInstance];
    });
    return instance;
}

- (instancetype)init
{
    [self doesNotRecognizeSelector:_cmd];
    __builtin_unreachable();
}

- (instancetype)initInstance
{
    if (self = [super init])
    {
        _startTime = [RSDKAnalyticsRATTracker stringWithDate:NSDate.date];


        /*
         * Keep track of reachability.
         */

        NSURL *endpoint = _RSDKAnalyticsEndpointAddress();
        static SCNetworkReachabilityRef reachability;
        static dispatch_once_t oncet;
        dispatch_once(&oncet, ^{
            reachability = SCNetworkReachabilityCreateWithName(kCFAllocatorDefault, endpoint.host.UTF8String);
            SCNetworkReachabilitySetCallback(reachability, _reachabilityCallback, NULL);
            SCNetworkReachabilityScheduleWithRunLoop(reachability, CFRunLoopGetMain(), kCFRunLoopCommonModes);

            /*
             * We register for reachability updates, but to get the current reachability we need to query it,
             * so we do so from a background thread.
             */

            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
                SCNetworkReachabilityFlags flags;
                if (SCNetworkReachabilityGetFlags(reachability, &flags))
                {
                    _reachabilityCallback(reachability, flags, NULL);
                }
            });

            atexit_b(^
                     {
                         SCNetworkReachabilityUnscheduleFromRunLoop(reachability, CFRunLoopGetMain(), kCFRunLoopCommonModes);
                         CFRelease(reachability);
                     });
        });

        /*
         * Listen to changes in radio access technology, to detect LTE. Only iOS7+ sends these.
         */

        _telephonyNetworkInfo  = CTTelephonyNetworkInfo.new;
        if ([_telephonyNetworkInfo respondsToSelector:@selector(currentRadioAccessTechnology)])
        {
            /*
             * Check immediately, then listen to changes.
             */

            [self _checkLTE];
            
            [NSNotificationCenter.defaultCenter addObserver:self
                                                   selector:@selector(_checkLTE)
                                                       name:CTRadioAccessTechnologyDidChangeNotification
                                                     object:nil];
        }

        /*
         * Listen to new session start event
         */

        [NSNotificationCenter.defaultCenter addObserver:self
                                               selector:@selector(_startNewSessionEvent)
                                                   name:UIApplicationDidBecomeActiveNotification
                                                 object:nil];
    }
    return self;
}

- (void)dealloc
{
    [NSNotificationCenter.defaultCenter removeObserver:self];
}

- (void)configureWithAccountId:(int64_t)accountIdentifier
{
    self.accountIdentifier = accountIdentifier;
}

- (void)configureWithApplicationId:(int64_t)applicationIdentifier
{
    self.applicationIdentifier = applicationIdentifier;
}

- (RSDKAnalyticsEvent *)eventWithEventType:(NSString *)eventType parameters:(NSDictionary RSDKA_GENERIC(NSString *, id) * __nullable)parameters
{
    return [RSDKAnalyticsEvent.alloc initWithName:[NSString stringWithFormat:@"%@%@",_RSDKAnalyticsPrefix,eventType] parameters:parameters];
}

+ (NSString *)stringWithDate:(NSDate *)date
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
    NSTimeInterval timeInterval = date.timeIntervalSince1970;
    struct timeval tod;
    tod.tv_sec  = (long) ceil(timeInterval);
    tod.tv_usec = (int)  ceil((timeInterval - tod.tv_sec) * (double) NSEC_PER_MSEC);


    /*
     * localtime (3) reuses an internal buffer, so the pointer it returns must never get
     * free (3)'d. localtime (3) is ISO C90 so it's safe to use without having to worry
     * about Apple's wrath.
     */

    struct tm *time = localtime(&tod.tv_sec);


    /*
     * struct tm's epoc is 1900/1/1. Months start at 0.
     */

     return [[NSString stringWithFormat:@"%04u-%02u-%02u %02u:%02u:%02u",
                                        1900 + time->tm_year,
                                        1 + time->tm_mon,
                                        time->tm_mday,
                                        time->tm_hour,
                                        time->tm_min,
                                        time->tm_sec] copy];
}

+ (NSString *)nameWithPage:(UIViewController *)page
{
    if (!page)
    {
        return nil;
    }
    /*
     * FIXME: should we allow developers to give view controllers distinctive
     * names just for analytics?
     */

    /*
     * FIXME (2): For UIWebView, WKWebView and SFSafariViewController, the
     * current page's URL should be used instead.
     */
    return NSStringFromClass([page class]);
}

+ (int64_t)daysPassedSinceDate:(NSDate *)date
{
    if (!date)
    {
        return 0;
    }
    NSCalendar *calendar = [NSCalendar.alloc initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
    return [calendar components:NSDayCalendarUnit fromDate:date toDate:NSDate.date options:0].day;
}

+ (NSDictionary *)dictionaryWithEvent:(RSDKAnalyticsEvent *)event state:(RSDKAnalyticsState *)state
{
    NSMutableDictionary *json = [NSMutableDictionary dictionary];

    // RATTracker only processes event which prefix with "rat."
    if (![event.name hasPrefix:_RSDKAnalyticsPrefix])
    {
        return NO;
    }

    NSString *eventName = [event.name substringFromIndex:_RSDKAnalyticsPrefix.length];
    if ([eventName isEqualToString:RSDKAnalyticsInitialLaunchEvent])
    {
        json[@"etype"] = @"_rem_init_launch";
        NSMutableDictionary *cp = [NSMutableDictionary dictionary];
        cp[@"first_install_date"] = [RSDKAnalyticsRATTracker stringWithDate:state.initialLaunchDate];
        json[@"cp"] = cp.copy;
    }
    else if ([eventName isEqualToString:RSDKAnalyticsInstallEvent])
    {
        json[@"etype"] = @"_rem_install";
    }
    else if ([eventName isEqualToString:RSDKAnalyticsSessionStartEvent])
    {
        json[@"etype"] = @"_rem_launch";
        NSMutableDictionary *cp = [NSMutableDictionary dictionary];
        cp[@"days_since_first_use"] = @([RSDKAnalyticsRATTracker daysPassedSinceDate:state.installLaunchDate]);
        cp[@"days_since_last_use"] = @([RSDKAnalyticsRATTracker daysPassedSinceDate:state.lastLaunchDate]);
        cp[@"logged_in"] = @(state.loggedIn);
        json[@"cp"] = cp.copy;
    }
    else if ([eventName isEqualToString:RSDKAnalyticsSessionEndEvent])
    {
        json[@"etype"] = @"_rem_end_session";
    }
    else if ([eventName isEqualToString:RSDKAnalyticsPageVisitEvent])
    {
        json[@"etype"] = @"_rem_visit";
        json[@"ref"] = [RSDKAnalyticsRATTracker nameWithPage:state.lastVisitedPage];
        json[@"pgn"] = [RSDKAnalyticsRATTracker nameWithPage:state.currentPage];
        NSMutableDictionary *cp = [NSMutableDictionary dictionary];
        switch (state.origin)
        {
            case RSDKAnalyticsInternalOrigin:
                cp[@"ref_type"] = @"internal";
                break;
            case RSDKAnalyticsExternalOrigin:
                cp[@"ref_type"] = @"external";
                break;
            case RSDKAnalyticsPushOrigin:
                cp[@"ref_type"] = @"push";
                break;
            default:
                cp[@"ref_type"] = @"other";
                break;
        }
        cp[@"linkid"] = state.linkIdentifier;
        cp[@"logged_in"] = @(state.loggedIn);
        json[@"cp"] = cp.copy;
    }
    else if ([eventName isEqualToString:RSDKAnalyticsApplicationUpdateEvent])
    {
        json[@"etype"] = @"_rem_update";
        NSMutableDictionary *cp = [NSMutableDictionary dictionary];
        cp[@"previous_version"] = state.lastVersion;
        cp[@"launches_since_last_upgrade"] = @(state.lastVersionLaunches);
        cp[@"days_since_last_upgrade"] = @([RSDKAnalyticsRATTracker daysPassedSinceDate:state.lastUpdateDate]);
        json[@"cp"] = cp.copy;
    }
    else if ([eventName isEqualToString:RSDKAnalyticsCrashEvent])
    {
        json[@"etype"] = @"_rem_crash";
    }
    else if ([eventName isEqualToString:RSDKAnalyticsLoginEvent])
    {
        json[@"etype"] = @"_rem_login";
        NSString *loginMethod;
        switch (state.loginMethod)
        {
            case RSDKAnalyticsPasswordInputLoginMethod:
                loginMethod = @"password";
                break;
            case RSDKAnalyticsOneTapLoginLoginMethod:
                loginMethod = @"one_tap_login";
                break;
            default:
                loginMethod = @"other";
                break;
        }
        NSMutableDictionary *cp = [NSMutableDictionary dictionary];
        cp[@"login_method"] = loginMethod;
        json[@"cp"] = cp.copy;
    }
    else if ([eventName isEqualToString:RSDKAnalyticsLogoutEvent])
    {
        json[@"etype"] = @"_rem_logout";
        NSString *logoutMethod;
        switch (state.logoutMethod)
        {
            case RSDKAnalyticsLocalLogoutMethod:
                logoutMethod = @"single";
                break;
            default:
                logoutMethod = @"all";
                break;
        }
        NSMutableDictionary *cp = [NSMutableDictionary dictionary];
        cp[@"logout_method"] = logoutMethod;
        json[@"cp"] = cp.copy;
    }
    else if ([eventName isEqualToString:RSDKAnalyticsPushNotificationEvent])
    {
        json[@"etype"] = @"_rem_push_notify";
    }
    else
    {
        // only set json["etype"] if the event name is not rat.generic
        if (![eventName hasPrefix:[_RSDKAnalyticsGenericType substringFromIndex:_RSDKAnalyticsPrefix.length]])
        {
            json[@"etype"] = eventName;
        }
    }
    return json.copy;
}

- (BOOL)processEvent:(RSDKAnalyticsEvent *)event state:(RSDKAnalyticsState *)state
{
    static NSString *osVersion;
    static UIDevice *device;
    static NSString *screenResolution;
    static NSString *carrierName;
    static NSString *userAgent;
    static NSString *applicationName;
    static NSString *bundleVersion;
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
        applicationName = bundle.bundleIdentifier;
        bundleVersion = state.currentVersion;
        userAgent = [NSString stringWithFormat:@"%@/%@", applicationName, bundleVersion];


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

    id json = [[RSDKAnalyticsRATTracker dictionaryWithEvent:event state:state] mutableCopy];

    if (event.parameters.count)
    {
        [json addEntriesFromDictionary:event.parameters];
    }

    if (!json[@"acc"])
    {
        if (self.accountIdentifier)
        {
            json[@"acc"] = @(self.accountIdentifier);
        }
        else
        {
            RSDKAnalyticsDebugLog(@"There is no value for 'acc' field, please configure it by using configureWithAccountId: method");
        }
    }

    if (!json[@"aid"])
    {
        if (self.applicationIdentifier)
        {
            json[@"aid"] = @(self.applicationIdentifier);
        }
        else
        {
            RSDKAnalyticsDebugLog(@"There is no value for 'aid' field, please configure it by using configureWithApplicationId: method");
        }
    }

    // Add all the other automatic parameters
    if (device.batteryState != UIDeviceBatteryStateUnknown)
    {
        // {name: "powerstatus", longName: "BATTERY_CHARGING_STATUS", fieldType: "INT", definitionLevel: "APP", validValues: [0, 1 ], userSettable: true}
        json[@"powerstatus"] = @(device.batteryState != UIDeviceBatteryStateUnplugged ? 1 : 0);

        // {name: "mbat", longName: "BATTERY_USAGE", fieldType: "STRING", definitionLevel: "APP", maxLength: 32, minLength: 0, userSettable: true}
        json[@"mbat"] = [NSString stringWithFormat:@"%0.f", device.batteryLevel * 100];
    }

    // {name: "dln", longName: "DEVICE_LANGUAGE", fieldType: "STRING", definitionLevel: "APP", maxLength: 16, minLength: 0, userSettable: true}
    NSString *preferredLocaleLanguage = NSLocale.preferredLanguages.firstObject;
    NSString *localeLanguageCode = [[NSLocale localeWithLocaleIdentifier:preferredLocaleLanguage] objectForKey:NSLocaleLanguageCode];

    NSString *preferredLocalizationLanguage = NSBundle.mainBundle.preferredLocalizations.firstObject;
    NSString *bundleLanguageCode = [[NSLocale localeWithLocaleIdentifier:preferredLocalizationLanguage] objectForKey:NSLocaleLanguageCode];
    json[@"dln"] = bundleLanguageCode ?: localeLanguageCode;

    // {name: "loc", longName: "LOCATION", fieldType: "JSON"}
    CLLocationCoordinate2D coordinate = kCLLocationCoordinate2DInvalid;
    CLLocation *location = state.lastKnownLocation;
    if (location)
    {
        coordinate = location.coordinate;
    }
    if (CLLocationCoordinate2DIsValid(coordinate))
    {
        id locationDic = [NSMutableDictionary dictionary];

        // {name: "accu", longName: "ACCURACY", fieldType: "DOUBLE", minValue: 0.0, userSettable: false}
        // According to RAL.js, unit is metre.
        locationDic[@"accu"] = @(MAX(0.0, location.horizontalAccuracy));

        // {name: "altitude", longName: "ALTITUDE", fieldType: "DOUBLE", userSettable: false}
        locationDic[@"altitude"] = @(location.altitude);

        // {name: "tms", longName: "GPS_TIMESTAMP", fieldType: "INT", minValue: 0, userSettable: false}
        // According to RAL.js it's in milliseconds since the unix epoch
        locationDic[@"tms"] = @(MAX(0ll, (int64_t) round(location.timestamp.timeIntervalSince1970 * 1000.0)));

        // {name: "lat", longName: "LATITUDE", fieldType: "DOUBLE", minValue: -90.0, maxValue: 90.0, userSettable: false}
        locationDic[@"lat"] = @(MIN(90.0, MAX(-90.0, coordinate.latitude)));

        // {name: "long", longName: "LONGITUDE", fieldType: "DOUBLE", minValue: -180.0, maxValue: 180.0, userSettable: false}
        locationDic[@"long"] = @(MIN(180.0, MAX(-180.0, coordinate.longitude)));

        // {name: "speed", longName: "SPEED", fieldType: "DOUBLE", minValue: 0.0, userSettable: false}
        locationDic[@"speed"] = @(MAX(0.0, location.speed));

        //{name: "loc", longName: "LOCATION", fieldType: "JSON", comment: "Location related field group"}
        json[@"loc"] = locationDic;
    }

    // {name: "mcn", longName: "MOBILE_CARRIER_NAME", fieldType: "STRING", definitionLevel: "APP", maxLength: 32, minLength: 0, userSettable: true}
    if (carrierName)
    {
        json[@"mcn"] = carrierName;
    }

    // {name: "model", longName: "MOBILE_DEVICE_BRAND_MODEL", fieldType: "STRING", definitionLevel: "APP", maxLength: 48, minLength: 0, userSettable: true}
    json[@"model"] = RSDKDeviceInformation.modelIdentifier;

    // {name: "mnetw", longName: "MOBILE_NETWORK_TYPE", fieldType: "INT", definitionLevel: "APP", validValues: [1, 2, 3, 4], userSettable: true}
    RSDKAnalyticsMobileNetworkType mobileNetworkType;

    switch (self.reachabilityStatus)
    {
        case RSDKAnalyticsReachabilityStatusConnectedWithWiFi:
            mobileNetworkType = RSDKAnalyticsMobileNetworkTypeWiFi;
            break;

        case RSDKAnalyticsReachabilityStatusConnectedWithWWAN:
            mobileNetworkType = self.isUsingLTE ? RSDKAnalyticsMobileNetworkType4G : RSDKAnalyticsMobileNetworkType3G;
            break;

        default:
            mobileNetworkType = RSDKAnalyticsInvalidMobileNetworkType;
            break;
    }

    if (mobileNetworkType != RSDKAnalyticsInvalidMobileNetworkType)
    {
        json[@"mnetw"] = @(mobileNetworkType);
    }

    // {name: "mori", longName: "MOBILE_ORIENTATION", fieldType: "INT", definitionLevel: "APP", validValues: [1, 2], userSettable: true}
    json[@"mori"] = @(UIDeviceOrientationIsLandscape(device.orientation) ? 2 : 1);

    // {name: "mos", longName: "MOBILE_OS", fieldType: "STRING", definitionLevel: "APP", maxLength: 32, minLength: 0, userSettable: true}
    json[@"mos"] = osVersion;

    // {name: "online", longName: "ONLINE_STATUS", fieldType: "BOOLEAN", userSettable: false}
    if (self.reachabilityStatus != RSDKAnalyticsReachabilityStatusUnknown)
    {
        json[@"online"] = (self.reachabilityStatus != RSDKAnalyticsReachabilityStatusOffline) ? @YES : @NO;
    }

    // {name: "ckp", longName: "PERSISTENT_COOKIE", definitionLevel: "TrackingServer", fieldType: "STRING", maxLength: 1024, minLength: 0, userSettable: true}
    if (state.deviceIdentifier) {
        json[@"ckp"] = state.deviceIdentifier;
    }

    // {name: "ua", longName: "USER_AGENT", definitionLevel: "TrackingServer", fieldType: "STRING", maxLength: 1024, minLength: 0, userSettable: false}
    json[@"ua"] = userAgent;

    // {name: "app_name", longName: "APPLICATION_NAME", definitionLevel: "TrackingServer", fieldType: "STRING", maxLength: 1024, minLength: 0, userSettable: false}
    json[@"app_name"] = applicationName;

    // {name: "app_ver", longName: "APPLICATION_VERSION", definitionLevel: "TrackingServer", fieldType: "STRING", maxLength: 1024, minLength: 0, userSettable: false}
    json[@"app_ver"] = bundleVersion;

    // {name: "res", longName: "RESOLUTION", fieldType: "STRING", maxLength: 12, minLength: 0, userSettable: false }
    json[@"res"] = screenResolution;

    // {name: "ltm", longName: "SCRIPT_START_TIME", fieldType: "STRING", maxLength: 20, minLength: 0, regex: "\\d\\d\\d\\d-\\d\\d\\-\\d\\d \\d\\d:\\d\\d:\\d\\d", userSettable: false}
    json[@"ltm"] = self.startTime;

    // {name: "cks", longName: "SESSION_COOKIE", definitionLevel: "TrackingServer", fieldType: "STRING", maxLength: 1024, minLength: 0, userSettable: true}
    json[@"cks"] = state.sessionIdentifier;

    // {name: "ts1", longName: "CLIENT_PROVIDED_TIMESTAMP", definitionLevel: "APP", fieldType: "INT", minValue: 0, userSettable: true}
    // Unit is seconds. Up to version 2.1.0 it was milliseconds.
    json[@"ts1"] = @(MAX(0ll, (int64_t) round(NSDate.date.timeIntervalSince1970)));

    // {name: "tzo", longName: "TIMEZONE", fieldType: "DOUBLE", minValue: -12.0, maxValue: 12.0, userSettable: false}
    json[@"tzo"] = @(NSTimeZone.localTimeZone.secondsFromGMT / 3600.0);

    // {name: "ver", longName: "VERSION", fieldType: "STRING", maxLength: 32, minLength: 0, userSettable: false}
    json[@"ver"] = RSDKAnalyticsVersion;

    // {name: "cka", longName: "COOKIE_ADVERTISING", fieldType: "STRING", userSettable: false}
    if ([RSDKAnalyticsManager sharedInstance].shouldTrackAdvertisingIdentifier) {
        if (state.advertisingIdentifier.length)
        {
            json[@"cka"] = state.advertisingIdentifier;
        }
    }

    // Add record to database and schedule an upload
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:json options:0 error:0];
    RSDKAnalyticsDebugLog(@"Spooling record with the following payload: %@", [NSString.alloc initWithData:jsonData encoding:NSUTF8StringEncoding]);

    typeof(self) __weak weakSelf = self;
    [_RSDKAnalyticsDatabase addRecord:jsonData completion:^
     {
         typeof(weakSelf) __strong strongSelf = weakSelf;
         [strongSelf _scheduleBackgroundUpload];
     }];
    return YES;
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
        if (self.uploadTimer.isValid)
        {
            self.uploadRequested = YES;
            return;
        }

        /*
         * REMI-1105: Using NSTimer.scheduledTimer() won't work from the background
         *            queue we're executing on. We could use NSTimer's designated
         *            initializer instead, and manually add the timer to the main
         *            run loop, but the documentation of NSRunLoop state its methods
         *            should always be called from the main thread because the class
         *            is not thread safe.
         */

        dispatch_async(dispatch_get_main_queue(), ^{
            self.uploadTimer = [NSTimer scheduledTimerWithTimeInterval:RSDKAnalyticsUploadInterval
                                                                target:self
                                                              selector:@selector(_doBackgroundUpload)
                                                              userInfo:nil
                                                               repeats:NO];
        });

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

- (void)_doBackgroundUploadWithRecords:(NSArray *)records identifiers:(NSArray *)identifiers
{
    /*
     * When you make changes here, always check the server-side program will
     * accept it. The source code is at
     * https://git.rakuten-it.com/projects/RATR/repos/receiver/browse/receiver.c
     */
    
    typeof(self) __weak weakSelf = self;

    /*
     * Prepare the body of our POST request. It's a JSON-formatted array
     * of records. Note that the server doesn't accept pretty-formatted JSON.
     *
     * We could append 'record' NSData instances to 'postBody' in turn, separating
     * each with a comma, but we'll need an array of deserialized objects anyway
     * for using within the notifications we're sending.
     */

    NSArray *recordGroup = ({
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

    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:_RSDKAnalyticsEndpointAddress()
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

    NSURLSessionDataTask *dataTask = [NSURLSession.sharedSession dataTaskWithRequest:request
                                                                   completionHandler:^(NSData * __nullable data, NSURLResponse * __nullable response, NSError * __nullable error)
    {
        typeof(weakSelf) __strong strongSelf = weakSelf;

        if (error)
        {
            /*
             * Connection failed. Request a new attempt before calling the completion.
             */

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

                [_RSDKAnalyticsDatabase deleteRecordsWithIdentifiers:identifiers
                                                          completion:^
                 {
                     // Send the rest of records
                     typeof(weakSelf) __strong strongSelf = weakSelf;
                     [strongSelf _doBackgroundUpload];
                 }];
                return;
            }

            error = [NSError errorWithDomain:NSURLErrorDomain
                                        code:NSURLErrorUnknown
                                    userInfo:@{NSLocalizedDescriptionKey: @"invalid_response",
                                               NSLocalizedFailureReasonErrorKey: [NSString stringWithFormat:@"Expected status code == 200, got %ld", (long)httpResponse.statusCode]}];
        }

        id userInfo = nil;
        if (error)
        {
            userInfo = @{NSUnderlyingErrorKey: error};
        }

        [NSNotificationCenter.defaultCenter postNotificationName:RSDKAnalyticsUploadFailureNotification
                                                          object:recordGroup
                                                        userInfo:userInfo];

        [strongSelf _backgroupUploadEnded];
    }];
    [dataTask resume];
}

//--------------------------------------------------------------------------

- (void)_doBackgroundUpload
{
    /*
     * Get a group of records and start uploading them.
     */

    typeof(self) __weak weakSelf = self;
    [_RSDKAnalyticsDatabase fetchRecordGroup:^(NSArray *records, NSArray *identifiers)
     {
         typeof(weakSelf) __strong strongSelf = weakSelf;
         if (records.count)
         {
             [strongSelf _doBackgroundUploadWithRecords:records identifiers:identifiers];
         }
         else
         {
             [strongSelf _backgroupUploadEnded];
         }
     }];
}

//--------------------------------------------------------------------------

- (void)_checkLTE
{
    self.isUsingLTE = [self.telephonyNetworkInfo.currentRadioAccessTechnology isEqualToString:CTRadioAccessTechnologyLTE];
}

//--------------------------------------------------------------------------

- (void)_startNewSessionEvent
{
   /*
    * Schedule a background upload attempt when the app becomes
    * active.
    */

    [self _scheduleBackgroundUpload];
}

@end
