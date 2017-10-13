/*
 * © Rakuten, Inc.
 * authors: "Rakuten Ecosystem Mobile" <ecosystem-mobile@mail.rakuten.com>
 */
#import <RSDKAnalytics/RSDKAnalytics.h>
#import <CoreTelephony/CTCarrier.h>
#import <CoreTelephony/CTTelephonyNetworkInfo.h>
#import <CoreLocation/CoreLocation.h>
#import <SystemConfiguration/SystemConfiguration.h>
#import <WebKit/WebKit.h>
#import <RSDKDeviceInformation/RSDKDeviceInformation.h>
#import "_RSDKAnalyticsHelpers.h"
#import "_RSDKAnalyticsDatabase.h"

// Externs
NSString *const RATWillUploadNotification    = @"com.rakuten.esd.sdk.notifications.analytics.rat.will_upload";
NSString *const RATUploadFailureNotification = @"com.rakuten.esd.sdk.notifications.analytics.rat.upload_failed";
NSString *const RATUploadSuccessNotification = @"com.rakuten.esd.sdk.notifications.analytics.rat.upload_succeeded";

// Deprecated aliases
NSString *const RSDKAnalyticsWillUploadNotification    = @"com.rakuten.esd.sdk.notifications.analytics.rat.will_upload";
NSString *const RSDKAnalyticsUploadFailureNotification = @"com.rakuten.esd.sdk.notifications.analytics.rat.upload_failed";
NSString *const RSDKAnalyticsUploadSuccessNotification = @"com.rakuten.esd.sdk.notifications.analytics.rat.upload_succeeded";

NSString *const _RATEventPrefix      = @"rat.";
NSString *const _RATETypeParameter   = @"etype";
NSString *const _RATCPParameter      = @"cp";
NSString *const _RATGenericEventName = @"rat.generic";
NSString *const _RATPGNParameter     = @"pgn";
NSString *const _RATREFParameter     = @"ref";

// Recursively try to find a URL in a view hierarchy
static NSURL *findURLForView(UIView *view)
{
    NSURL *url = nil;

    if ([view isKindOfClass:[UIWebView class]])
    {
        url = ((UIWebView *)view).request.URL;
    }
    else if ([WKWebView class] && [view isKindOfClass:[WKWebView class]])
    {
        url = ((WKWebView *)view).URL;
    }

    if ((url = url.absoluteURL))
    {
        /*
         * If a URL is found, only keep a safe subpart of it (scheme+host+path) since
         * query parameters etc may have sensitive information (access tokens…).
         */
        NSURLComponents *fullComponents = [NSURLComponents componentsWithURL:url resolvingAgainstBaseURL:NO];
        NSURLComponents *components = [NSURLComponents new];
        components.scheme = fullComponents.scheme;
        components.host   = fullComponents.host;
        components.path   = fullComponents.path;
        url = components.URL.absoluteURL;
    }
    else
    {
        for (UIView *subview in view.subviews)
        {
            if ((url = findURLForView(subview))) break;
        }
    }

    return url;
}

NS_INLINE NSString *const _RATTableName()
{
    BOOL useStaging = [RSDKAnalyticsManager.sharedInstance shouldUseStagingEnvironment];
    return useStaging ? @"RAT_STAGING" : @"RAKUTEN_ANALYTICS_TABLE";
}
static const unsigned int    _RATTableBlobLimit = 5000u;
static const unsigned int    _RATBatchSize      = 16u;

////////////////////////////////////////////////////////////////////////////

// Private constants

/*
 * This maps the values for the otherwise-undocumented MOBILE_NETWORK_TYPE RAT parameter,
 * and adds an extra RSDKAnalyticsInvalidMobileNetworkType value we do not send.
 */
typedef NS_ENUM(NSUInteger, _RATMobileNetworkType)
{
    _RATMobileNetworkTypeWiFi    = 1,
    _RATMobileNetworkType3G      = 3,
    _RATMobileNetworkType4G      = 4,
};


/*
 * Reachability status.
 */
typedef NS_ENUM(NSUInteger, _RATReachabilityStatus)
{
    _RATReachabilityStatusOffline,
    _RATReachabilityStatusConnectedWithWWAN,
    _RATReachabilityStatusConnectedWithWiFi,
};

////////////////////////////////////////////////////////////////////////////

@interface RATTracker ()<CLLocationManagerDelegate>
@property (nonatomic) int64_t accountIdentifier;
@property (nonatomic) int64_t applicationIdentifier;

@property (nonatomic, weak) id<RATDeliveryStrategy> deliveryStrategyProvider;

/*
 * We need to keep an instance of CTTelephonyNetworkInfo around to track
 * changes in radio access technology, on iOS 7+.
 */

@property (nonatomic) CTTelephonyNetworkInfo *telephonyNetworkInfo;
@property (nonatomic) BOOL isUsingLTE;


/*
 * Keep track of reachability.
 */

@property (nonatomic, nullable) NSNumber *reachabilityStatus;

/*
 * The identifer of the last-tracked visited page, if any.
 */
@property (nonatomic, copy, nullable) NSString *lastVisitedPageIdentifier;

/*
 * Carried-over origin, if the previous visit was skipped because it didn't qualify as a page for RAT.
 */
@property (nonatomic, copy, nullable) NSNumber *carriedOverOrigin;

/*
 * uploadTimer is used to throttle uploads. A call to -_scheduleBackgroundUpload
 * will do nothing if uploadTimer is not nil.
 *
 * Since we don't want to start a new upload until the previous one has been fully
 * processed, though, we only invalidate that timer at the very end of the HTTP
 * request. That's why we also need uploadRequested, set by -_scheduleBackgroundUpload,
 * so that we know we have to restart our timer at that point.
 */

@property (nonatomic) BOOL            uploadRequested;
@property (nonatomic) BOOL            zeroBatchingDelayUploadInProgress;
@property (nonatomic) NSTimer        *uploadTimer;
@property (nonatomic) NSTimeInterval  uploadTimerInterval;

@property (nonatomic, copy) NSString *startTime;
@end

@implementation RATTracker

static void _reachabilityCallback(SCNetworkReachabilityRef __unused target, SCNetworkReachabilityFlags flags, void __unused *info)
{
    NSNumber *status = nil;

    if (!(flags & kSCNetworkReachabilityFlagsReachable) || (flags & kSCNetworkReachabilityFlagsConnectionRequired))
    {
        status = @(_RATReachabilityStatusOffline);
    }
    else if ((flags & kSCNetworkReachabilityFlagsIsWWAN))
    {
        status = @(_RATReachabilityStatusConnectedWithWWAN);
    }
    else
    {
        status = @(_RATReachabilityStatusConnectedWithWiFi);
    }

    [RATTracker sharedInstance].reachabilityStatus = status;
}

- (void)setUploadTimerInterval:(NSTimeInterval)delay
{
    _uploadTimerInterval = (MIN(MAX(0, delay), 60)); // cap timer interval 0-60s
}

#pragma mark - RSDKAnalyticsTracker

+ (instancetype)sharedInstance
{
    static RATTracker *instance = nil;
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
        _startTime = [RATTracker stringWithDate:NSDate.date];
        _uploadTimerInterval = 60.0; // default is 60 seconds

        /*
         * Default values for account/application should be 477/1.
         */

        _accountIdentifier = 477;
        _applicationIdentifier = 1;

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

- (void)configureWithDeliveryStrategy:(id<RATDeliveryStrategy>)deliveryStrategy
{
    self.deliveryStrategyProvider = deliveryStrategy;
}

- (RSDKAnalyticsEvent *)eventWithEventType:(NSString *)eventType parameters:(NSDictionary RSDKA_GENERIC(NSString *, id) * __nullable)parameters
{
    return [RSDKAnalyticsEvent.alloc initWithName:[NSString stringWithFormat:@"%@%@", _RATEventPrefix, eventType] parameters:parameters];
}

+ (NSURL *)endpointAddress
{
    return _RSDKAnalyticsEndpointAddress();
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

    return NSStringFromClass([page class]);
}

+ (int64_t)daysPassedSinceDate:(NSDate *)date
{
    if (!date)
    {
        return 0;
    }
    NSCalendar *calendar = [NSCalendar.alloc initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
    return [calendar components:NSCalendarUnitDay fromDate:date toDate:NSDate.date options:0].day;
}

- (void)addAutomaticFields:(NSMutableDictionary *)payload state:(RSDKAnalyticsState *)state
{
    static NSString *osVersion;
    static UIDevice *device;
    static NSString *screenResolution;
    static NSString *carrierName;
    static NSString *userAgent;
    static NSString *applicationName;
    static NSString *bundleVersion;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        CGSize screenSize = UIScreen.mainScreen.bounds.size;
        screenResolution = [NSString stringWithFormat:@"%ux%u", (unsigned) ceil(screenSize.width), (unsigned) ceil(screenSize.height)];

        device = UIDevice.currentDevice;
        osVersion = [NSString stringWithFormat:@"%@ %@", device.systemName, device.systemVersion];

        /*
         * This is needed to enable access to the battery getters below.
         */

        device.batteryMonitoringEnabled = YES;


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

        void (^assignCarrierName)(CTCarrier *) = ^(CTCarrier *carrier) {
            carrierName = carrier.carrierName.copy;
            carrierName = [carrierName substringToIndex:MIN(32ul, carrierName.length)];

            if (!carrierName.length || !carrier.mobileNetworkCode.length)
            {
                carrierName = nil;
            }
        };

        CTTelephonyNetworkInfo *telephonyNetworkInfo = self.telephonyNetworkInfo;
        assignCarrierName(telephonyNetworkInfo.subscriberCellularProvider);
        telephonyNetworkInfo.subscriberCellularProviderDidUpdateNotifier = ^(CTCarrier *carrier) {
            assignCarrierName(carrier);
        };
    });

    // MARK: acc
    if (!payload[@"acc"])
    {
        if (self.accountIdentifier)
        {
            payload[@"acc"] = @(self.accountIdentifier);
        }
        else
        {
            RSDKAnalyticsErrorLog(@"There is no value for 'acc' field, please configure it by using configureWithAccountId: method");
        }
    }

    // MARK: aid
    if (!payload[@"aid"])
    {
        if (self.applicationIdentifier)
        {
            payload[@"aid"] = @(self.applicationIdentifier);
        }
        else
        {
            RSDKAnalyticsErrorLog(@"There is no value for 'aid' field, please configure it by using configureWithApplicationId: method");
        }
    }

    if (device.batteryState != UIDeviceBatteryStateUnknown)
    {
        // MARK: powerstatus
        payload[@"powerstatus"] = @(device.batteryState != UIDeviceBatteryStateUnplugged ? 1 : 0);

        // MARK: mbat
        payload[@"mbat"] = [NSString stringWithFormat:@"%0.f", device.batteryLevel * 100];
    }

    // MARK: dln
    NSString *preferredLocaleLanguage = NSLocale.preferredLanguages.firstObject;
    NSString *localeLanguageCode = [[NSLocale localeWithLocaleIdentifier:preferredLocaleLanguage] objectForKey:NSLocaleLanguageCode];

    NSString *preferredLocalizationLanguage = NSBundle.mainBundle.preferredLocalizations.firstObject;
    NSString *bundleLanguageCode = [[NSLocale localeWithLocaleIdentifier:preferredLocalizationLanguage] objectForKey:NSLocaleLanguageCode];
    payload[@"dln"] = bundleLanguageCode ?: localeLanguageCode;

    // MARK: loc
    CLLocationCoordinate2D coordinate = kCLLocationCoordinate2DInvalid;
    CLLocation *location = state.lastKnownLocation;
    if (location)
    {
        coordinate = location.coordinate;
    }
    if (CLLocationCoordinate2DIsValid(coordinate))
    {
        id locationDic = [NSMutableDictionary dictionary];

        // MARK: loc.accu
        locationDic[@"accu"] = @(MAX(0.0, location.horizontalAccuracy));

        // MARK: loc.altitude
        locationDic[@"altitude"] = @(location.altitude);

        // MARK: loc.tms
        locationDic[@"tms"] = @(MAX(0ll, (int64_t) round(location.timestamp.timeIntervalSince1970 * 1000.0)));

        // MARK: loc.lat
        locationDic[@"lat"] = @(MIN(90.0, MAX(-90.0, coordinate.latitude)));

        // MARK: loc.long
        locationDic[@"long"] = @(MIN(180.0, MAX(-180.0, coordinate.longitude)));

        // MARK: loc.speed
        locationDic[@"speed"] = @(MAX(0.0, location.speed));

        payload[@"loc"] = locationDic;
    }

    // MARK: mcn
    if (carrierName)
    {
        payload[@"mcn"] = carrierName;
    }

    // MARK: model
    payload[@"model"] = RSDKDeviceInformation.modelIdentifier;

    // MARK: mnetw
    if (_reachabilityStatus)
    {
        switch (_reachabilityStatus.unsignedIntegerValue)
        {
            case _RATReachabilityStatusConnectedWithWiFi:
                payload[@"mnetw"] = @(_RATMobileNetworkTypeWiFi);
                break;

            case _RATReachabilityStatusConnectedWithWWAN:
                payload[@"mnetw"] = @(self.isUsingLTE ? _RATMobileNetworkType4G : _RATMobileNetworkType3G);
                break;

            default:
                break;
        }
    }

    // MARK: mori
    payload[@"mori"] = @(UIDeviceOrientationIsLandscape(device.orientation) ? 2 : 1);

    // MARK: mos
    payload[@"mos"] = osVersion;

    // MARK: online
    if (_reachabilityStatus)
    {
        payload[@"online"] = (_reachabilityStatus.unsignedIntegerValue != _RATReachabilityStatusOffline) ? @YES : @NO;
    }

    // MARK: ckp
    if (state.deviceIdentifier)
    {
        payload[@"ckp"] = state.deviceIdentifier;
    }

    // MARK: ua
    payload[@"ua"] = userAgent;

    // MARK: app_name
    payload[@"app_name"] = applicationName;

    // MARK: app_ver
    payload[@"app_ver"] = bundleVersion;

    // MARK: res
    payload[@"res"] = screenResolution;

    // MARK: ltm
    payload[@"ltm"] = self.startTime;

    // MARK: cks
    payload[@"cks"] = state.sessionIdentifier;

    // MARK: ts1
    payload[@"ts1"] = @(MAX(0ll, (int64_t) round(NSDate.date.timeIntervalSince1970)));

    // MARK: tzo
    payload[@"tzo"] = @(NSTimeZone.localTimeZone.secondsFromGMT / 3600.0);

    // MARK: ver
    payload[@"ver"] = RSDKAnalyticsVersion;

    // MARK: cka
    if ([RSDKAnalyticsManager sharedInstance].shouldTrackAdvertisingIdentifier && state.advertisingIdentifier.length)
    {
        payload[@"cka"] = state.advertisingIdentifier;
    }

    // MARK: userid
    if (state.userIdentifier.length && !((NSString *)payload[@"userid"]).length)
    {
        payload[@"userid"] = state.userIdentifier;
    }
}

- (BOOL)processEvent:(RSDKAnalyticsEvent *)event state:(RSDKAnalyticsState *)state
{
    NSMutableDictionary *payload = NSMutableDictionary.new;
    NSMutableDictionary *extra   = NSMutableDictionary.new;

    payload[_RATETypeParameter] = event.name;

    /*
     * Core SDK events
     */

    if ([event.name isEqualToString:RSDKAnalyticsInitialLaunchEventName])
    {
        // MARK: _rem_init_launch
    }
    else if ([event.name isEqualToString:RSDKAnalyticsInstallEventName])
    {
        // MARK: _rem_install

        // Collect build environment (Xcode version and build SDK)
        NSDictionary *info = NSBundle.mainBundle.infoDictionary;
        NSString *xcodeVersion = info[@"DTXcode"];
        NSString *xcodeBuild   = info[@"DTXcodeBuild"];
        if (xcodeBuild)
        {
            xcodeVersion = [xcodeVersion stringByAppendingFormat:@".%@", xcodeBuild];
        }

        NSString *buildSDK = info[@"DTSDKName"];
        if (!buildSDK)
        {
            buildSDK = info[@"DTPlatformName"];
            NSString *version = info[@"DTPlatformVersion"];
            if (version)
            {
                buildSDK = [buildSDK stringByAppendingString:version];
            }
        }

        // Collect information on frameworks shipping with the app
        NSDictionary *sdkComponentMap = _RSDKAnalyticsSDKComponentMap();
        NSMutableArray *sdkComponents = [NSMutableArray array];
        NSMutableDictionary *otherFrameworks = [NSMutableDictionary dictionary];
        for (NSBundle *bundle in NSBundle.allFrameworks)
        {
            NSString *identifier = bundle.bundleIdentifier;

            if (!identifier || [identifier hasPrefix:@"com.apple."]) continue;

            NSString *version = [bundle objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
            if ([sdkComponentMap objectForKey:identifier])
            {
                [sdkComponents addObject:[NSString stringWithFormat:@"%@/%@", sdkComponentMap[identifier], version]];
            }
            else
            {
                otherFrameworks[identifier] = version;
            }
        }

        NSMutableDictionary *appInfo = [NSMutableDictionary dictionary];
        if (xcodeVersion.length)       appInfo[@"xcode"] = xcodeVersion;
        if (buildSDK.length)           appInfo[@"sdk"] = buildSDK;
        if (otherFrameworks.count)     appInfo[@"frameworks"] = otherFrameworks;
        if (info[@"MinimumOSVersion"]) appInfo[@"deployment_target"] = info[@"MinimumOSVersion"];


        if (sdkComponents.count)
        {
            extra[@"sdk_info"] = [sdkComponents componentsJoinedByString:@"; "];
        }


        if (appInfo.count)
        {
            extra[@"app_info"] = [NSString.alloc initWithData:[NSJSONSerialization dataWithJSONObject:appInfo options:0 error:0] encoding:NSUTF8StringEncoding];
        }
    }
    else if ([event.name isEqualToString:RSDKAnalyticsSessionStartEventName])
    {
        // MARK: _rem_launch
        extra[@"days_since_first_use"] = @([RATTracker daysPassedSinceDate:state.installLaunchDate]);
        extra[@"days_since_last_use"] = @([RATTracker daysPassedSinceDate:state.lastLaunchDate]);
    }
    else if ([event.name isEqualToString:RSDKAnalyticsSessionEndEventName])
    {
        // MARK: _rem_end_session
    }
    else if ([event.name isEqualToString:RSDKAnalyticsApplicationUpdateEventName])
    {
        // MARK: _rem_update

        if (state.lastVersion.length)
        {
            extra[@"previous_version"] = state.lastVersion;
        }
        extra[@"launches_since_last_upgrade"] = @(state.lastVersionLaunches);
        extra[@"days_since_last_upgrade"] = @([RATTracker daysPassedSinceDate:state.lastUpdateDate]);
    }
    else if ([event.name isEqualToString:RSDKAnalyticsLoginEventName])
    {
        // MARK: _rem_login
        NSString *loginMethod = nil;
        switch (state.loginMethod)
        {
            case RSDKAnalyticsPasswordInputLoginMethod: loginMethod = @"password";      break;
            case RSDKAnalyticsOneTapLoginLoginMethod:   loginMethod = @"one_tap_login"; break;
            default: break;
        }

        if (loginMethod) extra[@"login_method"] = loginMethod;
    }
    else if ([event.name isEqualToString:RSDKAnalyticsLoginFailureEventName])
    {
        // MARK: _rem_login_Failure
        NSString *loginType = nil;
        NSString *errorMessage = nil;
        NSString *failureReason = nil;
        NSString *loginFailureType = event.parameters[@"type"];
        NSString *loginError = event.parameters[@"rae_error"];
        NSString *loginFailureReason = event.parameters[@"rae_error_message"];
        if ([loginFailureType isKindOfClass:NSString.class] && loginFailureType.length)
        {
            loginType = loginFailureType;
        }
        if ([loginError isKindOfClass:NSString.class] && loginError.length)
        {
            errorMessage = loginError;
        }
        if ([loginFailureReason isKindOfClass:NSString.class] && loginFailureReason.length)
        {
            failureReason = loginFailureReason;
        }
        
        if (loginType) extra[@"type"] = loginType;
        if (errorMessage) extra[@"rae_error"] = errorMessage;
        if (failureReason) extra[@"rae_error_message"] = failureReason;
    
    }
    else if ([event.name isEqualToString:RSDKAnalyticsLogoutEventName])
    {
        // MARK: _rem_logout

        NSString *logoutMethod = event.parameters[RSDKAnalyticsLogoutMethodEventParameter];
        if ([logoutMethod isEqualToString:RSDKAnalyticsLocalLogoutMethod])
        {
            logoutMethod = @"single";
        }
        else if ([logoutMethod isEqualToString:RSDKAnalyticsGlobalLogoutMethod])
        {
            logoutMethod = @"all";
        }
        else
        {
            logoutMethod = nil;
        }

        if (logoutMethod) extra[@"logout_method"] = logoutMethod;
    }
    else if ([event.name isEqualToString:RSDKAnalyticsPageVisitEventName])
    {
        // MARK: _rem_visit

        // Override etype
        payload[_RATETypeParameter] = @"pv";

        UIViewController *currentPage = state.currentPage;
        if (!currentPage) return NO;

        Class     pageClass      = currentPage.class;
        NSString *pageIdentifier = (NSString *)event.parameters[@"page_id"];
        NSString *pageTitle      = currentPage.navigationItem.title ?: currentPage.title;
        NSURL    *pageURL        = findURLForView(currentPage.view).absoluteURL;

        pageIdentifier = pageIdentifier.length ? pageIdentifier : nil;
        pageTitle      = pageTitle.length      ? pageTitle      : nil;

        if (!pageIdentifier)
        {
            if ([[NSBundle bundleForClass:pageClass].bundleIdentifier hasPrefix:@"com.apple."] &&
                     !pageURL && !pageTitle)
            {
                // Apple class with no title and no URL −should not count as a page visit.
                pageIdentifier = nil;
            }
            else
            {
                // Custom view controller class with no title.
                pageIdentifier = NSStringFromClass(currentPage.class);
            }
        }

        // If no page id was found, simply ignore this view controller.
        if (!pageIdentifier.length)
        {
            // If this originated from a push notification or an inbound URL, keep that for next call.
            if (state.origin != RSDKAnalyticsInternalOrigin)
            {
                self.carriedOverOrigin = @(state.origin);
            }
            return NO;
        }

        payload[_RATPGNParameter] = pageIdentifier;

        NSString *lastVisitedPageIdentifier = self.lastVisitedPageIdentifier;
        if (lastVisitedPageIdentifier.length) payload[_RATREFParameter] = lastVisitedPageIdentifier;
        self.lastVisitedPageIdentifier = pageIdentifier;

        /*
         * If this transition was internal but a previous (skipped) transition
         * originated from a push notification or an inbound URL, use the correct origin.
         */
        NSUInteger origin = state.origin;
        if (origin == RSDKAnalyticsInternalOrigin && self.carriedOverOrigin)
        {
            origin = self.carriedOverOrigin.unsignedIntegerValue;
            self.carriedOverOrigin = nil;
        }

        switch (origin)
        {
            case RSDKAnalyticsInternalOrigin: extra[@"ref_type"] = @"internal"; break;
            case RSDKAnalyticsExternalOrigin: extra[@"ref_type"] = @"external"; break;
            case RSDKAnalyticsPushOrigin:     extra[@"ref_type"] = @"push";     break;
        }

        if (pageTitle)
        {
            extra[@"title"] = pageTitle;
        }

        if (pageURL)
        {
            extra[@"url"] = pageURL.absoluteString;
        }
    }
    else if ([event.name isEqualToString:RSDKAnalyticsPushNotificationEventName])
    {
        // MARK: _rem_push_notify
        NSString *trackingIdentifier = event.parameters[RSDKAnalyticPushNotificationTrackingIdentifierParameter];
        if (!trackingIdentifier.length) return NO;

        extra[@"push_notify_value"] = trackingIdentifier;
    }
    else if ([event.name hasPrefix:@"_rem_discover_"])
    {
        // MARK: _rem_discover_＊

        NSString *prApp = event.parameters[@"prApp"];
        if (prApp.length) extra[@"prApp"] = prApp;

        NSString *prStoreUrl = event.parameters[@"prStoreUrl"];
        if (prStoreUrl.length) extra[@"prStoreUrl"] = prStoreUrl;
    }
    else if ([event.name isEqualToString:RSDKAnalyticsSSOCredentialFoundEventName])
    {
        // MARK: _rem_sso_credential_found
        
        NSString *source = event.parameters[@"source"];
        if (source.length) extra[@"source"] = source;
    }
    else if ([event.name isEqualToString:RSDKAnalyticsLoginCredentialFoundEventName])
    {
        // MARK: _rem_login_credential_found
        
        NSString *source = event.parameters[@"source"];
        if (source.length) extra[@"source"] = source;
    }
    else if ([event.name isEqualToString:RSDKAnalyticsCredentialStrategiesEventName])
    {
        // MARK: _rem_credential_strategies
        
        NSDictionary *strategies = event.parameters[@"strategies"];
        if (strategies.count) extra[@"strategies"] = strategies;
    }
    else if ([event.name isEqualToString:RSDKAnalyticsCustomEventName])
    {
        // MARK: _analytics_custom (wrapper for event name and its data)
        
        NSString *eventName = event.parameters[RSDKAnalyticsCustomEventNameParameter];
        if (![eventName isKindOfClass:NSString.class] || !eventName.length) return NO;
        
        payload[_RATETypeParameter] = eventName;
        
        NSDictionary *parameters = [event.parameters[RSDKAnalyticsCustomEventDataParameter] copy];
        
        if ([parameters isKindOfClass:NSDictionary.class] && parameters.count)
        {
            [extra addEntriesFromDictionary:parameters];
        }
    }

    /*
     * Alpha modules events
     */

    else if ([event.name hasPrefix:@"_rem_cardinfo_"])
    {
        // MARK: _rem_cardinfo_＊
    }

    /*
     * RAT-specific events
     */

    // MARK: rat.＊
    else if ([event.name hasPrefix:_RATEventPrefix])
    {
        if (event.parameters.count) [payload addEntriesFromDictionary:event.parameters];

        NSString *etype = event.parameters[_RATETypeParameter];
        if (!etype.length && ![event.name isEqualToString:_RATGenericEventName])
        {
            etype = [event.name substringFromIndex:_RATEventPrefix.length];
        }

        if (!etype.length) return NO;

        payload[_RATETypeParameter] = etype;
    }

    /*
     * Unsupported events
     */
    else
    {
        return NO;
    }

    if (extra.count)
    {
        // If the event already had a 'cp' field, those values take precedence
        if (payload[_RATCPParameter])
        {
            [extra addEntriesFromDictionary:payload[_RATCPParameter]];
        }

        payload[_RATCPParameter] = extra;
    }

    [self addAutomaticFields:payload state:state];

    // Add record to database and schedule an upload
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:payload options:NSJSONWritingPrettyPrinted error:0];
    RSDKAnalyticsDebugLog(@"Spooling record with the following payload: %@", [NSString.alloc initWithData:jsonData encoding:NSUTF8StringEncoding]);
    
    [self _storeAndSendEventData:jsonData];
    
    return YES;
}

- (void)_storeAndSendEventData:(NSData *)jsonData
{
    typeof(self) __weak weakSelf = self;
    [_RSDKAnalyticsDatabase insertBlob:jsonData
                                  into:_RATTableName()
                                 limit:_RATTableBlobLimit
                                  then:^{
    
        typeof(weakSelf) __strong strongSelf = weakSelf;
        [strongSelf _scheduleUploadOrPerformImmediately];
    }];
}

- (void)_scheduleUploadOrPerformImmediately
{
    if ([self.deliveryStrategyProvider respondsToSelector:@selector(batchingDelay)])
    {
        _uploadTimerInterval = [self.deliveryStrategyProvider batchingDelay];
    }
    
    /*
     * Upload immediately if batching delay is 0 and a request isn't in progress.
     * Otherwise, schedule the upload in background.
     */
    if (_uploadTimerInterval <= 0 &&
        !_uploadTimer.isValid &&
        !_zeroBatchingDelayUploadInProgress)
    {
        _zeroBatchingDelayUploadInProgress = YES;
        dispatch_async(dispatch_get_main_queue(), ^{ [self _doBackgroundUpload]; });
    }
    else
    {
        [self _scheduleBackgroundUpload];
    }
}

//--------------------------------------------------------------------------

/*
 * Schedule a new background upload, if none has already been scheduled or is
 * currently being processed. Otherwise it just sets 'uploadRequested' to YES
 * so that scheduling happens next time -_backgroundUploadEnded gets called.
 */

- (void)_scheduleBackgroundUpload
{
    /*
     * REMI-1105: Using NSTimer.scheduledTimer() won't work from the background
     *            queue we're executing on. We could use NSTimer's designated
     *            initializer instead, and manually add the timer to the main
     *            run loop, but the documentation of NSRunLoop state its methods
     *            should always be called from the main thread because the class
     *            is not thread safe.
     */

    dispatch_async(dispatch_get_main_queue(), ^{
        
        // If a background upload has already been scheduled or is underway,
        // just set uploadRequested to YES and return
        if (self.uploadTimer.isValid)
        {
            self.uploadRequested = YES;
            return;
        }
        
        // If timer interval is zero and we got here it means that there is an upload in progress.
        // Therefore, schedule a timer with a 10s delay which is short-ish but long enough that the
        // in progress upload will likely complete before the timer fires.
        self.uploadTimer = [NSTimer scheduledTimerWithTimeInterval:self.uploadTimerInterval == 0 ? 10.0 : self.uploadTimerInterval
                                                            target:self
                                                          selector:@selector(_doBackgroundUpload)
                                                          userInfo:nil
                                                           repeats:NO];
        self.uploadRequested = NO;
    });
}

//--------------------------------------------------------------------------

/*
 * This method is called whenever a background upload ends, successfully or not.
 * If uploadRequested has been set, it schedules another upload.
 */

- (void)_backgroundUploadEnded
{
    @synchronized(self)
    {
        // It's time to invalidate our timer to clear the way for new uploads to get scheduled.
        [self.uploadTimer invalidate];
        self.uploadTimer = nil;
        
        self.zeroBatchingDelayUploadInProgress = NO;

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


    [NSNotificationCenter.defaultCenter postNotificationName:RATWillUploadNotification
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
                                                       timeoutInterval:30];


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
#if DEBUG
                NSMutableString *logMessage = [NSMutableString stringWithCapacity:20];
                [logMessage appendString:[NSString stringWithFormat:@"Successfully sent events to RAT from Tracker %@:",strongSelf.description]];
                
                [recordGroup enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                    [logMessage appendFormat:@"\n%@ %@", @(idx), obj];
                }];
                
                RSDKAnalyticsDebugLog(logMessage);
#endif

                [NSNotificationCenter.defaultCenter postNotificationName:RATUploadSuccessNotification
                                                                  object:recordGroup];


                /*
                 * Delete the records from the local database.
                 */

                [_RSDKAnalyticsDatabase deleteBlobsWithIdentifiers:identifiers
                                                                in:_RATTableName()
                                                              then:^{
                    // To throttle uploads, we schedule a new upload to send the rest of the records.
                    typeof(weakSelf) __strong strongSelf = weakSelf;
                    
                    [strongSelf _scheduleUploadOrPerformImmediately];
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

        [NSNotificationCenter.defaultCenter postNotificationName:RATUploadFailureNotification
                                                          object:recordGroup
                                                        userInfo:userInfo];

        [strongSelf _backgroundUploadEnded];
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
    [_RSDKAnalyticsDatabase fetchBlobs:_RATBatchSize
                                  from:_RATTableName()
                                  then:^(NSArray<NSData *> *__nullable blobs, NSArray<NSNumber *> *__nullable identifiers) {
        typeof(weakSelf) __strong strongSelf = weakSelf;
        if (blobs)
        {
            RSDKAnalyticsDebugLog(@"Records fetched from DB, now upload them");
            [strongSelf _doBackgroundUploadWithRecords:blobs identifiers:identifiers];
        }
        else
        {
            RSDKAnalyticsDebugLog(@"No records found in DB so end upload");
            [strongSelf _backgroundUploadEnded];
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
    
    // FIXME: when the LaunchCollector spools its launch/resume events, a background upload will
    // be scheduled so we possibly no longer need this here
    [self _scheduleUploadOrPerformImmediately];
}

@end
