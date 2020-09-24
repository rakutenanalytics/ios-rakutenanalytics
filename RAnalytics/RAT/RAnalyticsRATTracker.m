#import <RAnalytics/RAnalytics.h>
#import <CoreTelephony/CTCarrier.h>
#import <CoreTelephony/CTTelephonyNetworkInfo.h>
#import <CoreLocation/CoreLocation.h>
#import <SystemConfiguration/SystemConfiguration.h>
#import <WebKit/WebKit.h>
#import <RDeviceIdentifier/RDeviceIdentifier.h>
#import "_RAnalyticsHelpers.h"
#import "_RAnalyticsCoreHelpers.h"
#import "RAnalyticsSender.h"
#import "RAnalyticsRpCookieFetcher.h"
#import "_RStatusBarOrientationHandler.h"
#import "_RLogger.h"

NSString *const _RATEventPrefix      = @"rat.";
NSString *const _RATETypeParameter   = @"etype";
NSString *const _RATCPParameter      = @"cp";
NSString *const _RATGenericEventName = @"rat.generic";
NSString *const _RATPGNParameter     = @"pgn";
NSString *const _RATREFParameter     = @"ref";

const char* _RATReachabilityHost = "8.8.8.8"; // Google DNS Server

static const NSTimeInterval _RATBatchingDelay = 1.0; // Batching delay is 1 second by default

// Recursively try to find a URL in a view hierarchy
static NSURL *findURLForView(UIView *view)
{
    NSURL *url = nil;

    if ([WKWebView class] && [view isKindOfClass:[WKWebView class]])
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

NSString* const _RATDatabaseName = @"RSDKAnalytics.db";
NSString* const _RATTableName = @"RAKUTEN_ANALYTICS_TABLE";

////////////////////////////////////////////////////////////////////////////

// Private constants

/*
 * This maps the values for the otherwise-undocumented MOBILE_NETWORK_TYPE RAT parameter.
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

@interface RAnalyticsRATTracker ()
@property (nonatomic) int64_t accountIdentifier;
@property (nonatomic) int64_t applicationIdentifier;

@property (nonatomic) RAnalyticsSender *sender;

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

@property (nonatomic, copy) NSString *startTime;

/*
 * RPCookie fetcher is used to retrieve the cookie details on initialize
*/

@property (nonatomic, strong) RAnalyticsRpCookieFetcher *rpCookieFetcher;

/*
 * _RStatusBarOrientationHandler is used to read the current status bar orientation
 */
@property (nonatomic) _RStatusBarOrientationHandler *statusBarOrientationHandler;

@end

@implementation RAnalyticsRATTracker

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

    [RAnalyticsRATTracker sharedInstance].reachabilityStatus = status;
}

#pragma mark - RAnalyticsTracker

+ (instancetype)sharedInstance
{
    static RAnalyticsRATTracker *instance = nil;
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
        _startTime = [RAnalyticsRATTracker stringWithDate:NSDate.date];

        /*
         * Attempt to read the IDs from the app's plist
         * If not found, use 477/1 as default values for account/application ID.
         */

        NSNumber *plistObj = [NSBundle.mainBundle objectForInfoDictionaryKey:@"RATAccountIdentifier"];
        _accountIdentifier = plistObj ? plistObj.longLongValue : 477; // int64_t is typedef'd long long

        plistObj = [NSBundle.mainBundle objectForInfoDictionaryKey:@"RATAppIdentifier"];
        _applicationIdentifier = plistObj ? plistObj.longLongValue : 1;

        /*
         * Keep track of reachability.
         */

        NSURL *endpoint = _RAnalyticsEndpointAddress();
        static SCNetworkReachabilityRef reachability;
        static dispatch_once_t oncet;
        dispatch_once(&oncet, ^{
            reachability = SCNetworkReachabilityCreateWithName(kCFAllocatorDefault, _RATReachabilityHost);
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

        // create a sender.
        _sender = [[RAnalyticsSender alloc] initWithEndpoint:endpoint
                                                databaseName:_RATDatabaseName
                                           databaseTableName:_RATTableName];
        [_sender setBatchingDelayBlock:^{return _RATBatchingDelay;}];

        _rpCookieFetcher = [[RAnalyticsRpCookieFetcher alloc] initWithCookieStorage:[NSHTTPCookieStorage sharedHTTPCookieStorage]];
        [_rpCookieFetcher getRpCookieCompletionHandler:^(NSHTTPCookie * _Nullable cookie, NSError * _Nullable error)
         {
             if (error)
             {
                 [_RLogger error:@"%@", error];
             }
         }];
        
        _statusBarOrientationHandler = _RStatusBarOrientationHandler.new;
        
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

            [NSNotificationCenter.defaultCenter addObserverForName:CTRadioAccessTechnologyDidChangeNotification
                                                            object:nil
                                                             queue:nil
                                                        usingBlock:^(NSNotification *note)
            {
               [self _checkLTE];
            }];
        }
        
        /*
         * Reallocate telephonyNetworkInfo when the app becomes active
         */
        
        [NSNotificationCenter.defaultCenter addObserverForName:UIApplicationDidBecomeActiveNotification
                                                        object:nil
                                                         queue:nil
                                                    usingBlock:^(NSNotification *note)
        {
            self.telephonyNetworkInfo  = CTTelephonyNetworkInfo.new;
        }];
    }
    return self;
}

- (void)getRpCookieCompletionHandler:(void (^)(NSHTTPCookie * _Nullable cookie, NSError * _Nullable error))completionHandler {
    [_rpCookieFetcher getRpCookieCompletionHandler:completionHandler];
}

- (void)dealloc
{
    [NSNotificationCenter.defaultCenter removeObserver:self];
}

- (void)setBatchingDelay:(NSTimeInterval)batchingDelay
{
    [_sender setBatchingDelayBlock:^{return batchingDelay;}];
}

- (void)setBatchingDelayWithBlock:(BatchingDelayBlock)batchingDelayBlock
{
    [_sender setBatchingDelayBlock:batchingDelayBlock];
}

- (RAnalyticsEvent *)eventWithEventType:(NSString *)eventType parameters:(NSDictionary<NSString *, id> * __nullable)parameters
{
    return [RAnalyticsEvent.alloc initWithName:[NSString stringWithFormat:@"%@%@", _RATEventPrefix, eventType] parameters:parameters];
}

+ (NSURL *)endpointAddress
{
    return _RAnalyticsEndpointAddress();
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

- (void)addAutomaticFields:(NSMutableDictionary *)payload state:(RAnalyticsState *)state
{
    static UIDevice *device;
    static NSString *screenResolution;
    static NSString *carrierName;
    static NSString *userAgent;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        CGSize screenSize = UIScreen.mainScreen.bounds.size;
        screenResolution = [NSString stringWithFormat:@"%ux%u", (unsigned) ceil(screenSize.width), (unsigned) ceil(screenSize.height)];

        /*
         * This is needed to enable access to the battery getters below.
         */
        device = UIDevice.currentDevice;
        device.batteryMonitoringEnabled = YES;


        /*
         * Build a user agent string of the form AppId/Version
         */

        NSBundle *bundle = NSBundle.mainBundle;
        userAgent = [NSString stringWithFormat:@"%@/%@", bundle.bundleIdentifier, state.currentVersion];


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
    NSNumber *acc = [self positiveIntegerNumberWithObject:payload[@"acc"]];
    if (acc)
    {
        payload[@"acc"] = acc;
    }
    else
    {
        if (self.accountIdentifier)
        {
            payload[@"acc"] = @(self.accountIdentifier);
        }
        else
        {
            [_RLogger error:@"There is no value for 'acc' field, please configure it by setting a 'RATAccountIdentifier' key to YOUR_RAT_ACCOUNT_ID in your app's Info.plist"];
        }
    }

    // MARK: aid
    NSNumber *aid = [self positiveIntegerNumberWithObject:payload[@"aid"]];
    if (aid)
    {
        payload[@"aid"] = aid;
    }
    else
    {
        if (self.applicationIdentifier)
        {
            payload[@"aid"] = @(self.applicationIdentifier);
        }
        else
        {
            [_RLogger error:@"There is no value for 'aid' field, please configure it by setting a 'RATAppIdentifier' key to YOUR_RAT_APPLICATION_ID in your app's Info.plist"];
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
    payload[@"mcn"] = carrierName.length ? carrierName : @"";

    // MARK: model
    payload[@"model"] = RDeviceIdentifier.modelIdentifier;

    // MARK: mnetw
    payload[@"mnetw"] = @"";
    
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
    payload[@"mori"] = @([self.statusBarOrientationHandler mori]);

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

    // MARK: res
    payload[@"res"] = screenResolution;

    // MARK: ltm
    payload[@"ltm"] = self.startTime;

    // MARK: cks
    payload[@"cks"] = state.sessionIdentifier;

    // MARK: tzo
    payload[@"tzo"] = @(NSTimeZone.localTimeZone.secondsFromGMT / 3600.0);

    // MARK: cka
    if (state.advertisingIdentifier.length)
    {
        payload[@"cka"] = state.advertisingIdentifier;
    }

    // MARK: userid
    if (state.userIdentifier.length && !((NSString *)payload[@"userid"]).length)
    {
        payload[@"userid"] = state.userIdentifier;
    }

    [payload addEntriesFromDictionary:_RAnalyticsSharedPayload(state)];
}

- (BOOL)processEvent:(RAnalyticsEvent *)event state:(RAnalyticsState *)state
{
    NSMutableDictionary *payload = NSMutableDictionary.new;
    NSMutableDictionary *extra   = NSMutableDictionary.new;

    payload[_RATETypeParameter] = event.name;

    /*
     * Core SDK events
     */

    if ([event.name isEqualToString:RAnalyticsInitialLaunchEventName])
    {
        // MARK: _rem_init_launch
    }
    else if ([event.name isEqualToString:RAnalyticsInstallEventName])
    {
        // MARK: _rem_install

        NSDictionary *appAndSDKDict = _RAnalyticsApplicationInfoAndSDKComponents();
        NSDictionary *appInfo = appAndSDKDict[_RAnalyticsAppInfoKey];
        NSDictionary *sdkInfo = appAndSDKDict[_RAnalyticsSDKInfoKey];
        NSMutableArray *sdkComponents = NSMutableArray.new;
        for (NSString *key in sdkInfo.allKeys)
        {
            [sdkComponents addObject:[NSString stringWithFormat:@"%@/%@", key, sdkInfo[key]]];
        }

        if (sdkComponents.count)
        {
            extra[@"sdk_info"] = [sdkComponents componentsJoinedByString:@"; "];
        }

        if (appInfo.count)
        {
            extra[@"app_info"] = [NSString.alloc initWithData:[NSJSONSerialization dataWithJSONObject:appInfo options:0 error:0] encoding:NSUTF8StringEncoding];
        }
    }
    else if ([event.name isEqualToString:RAnalyticsSessionStartEventName])
    {
        // MARK: _rem_launch
        extra[@"days_since_first_use"] = @([RAnalyticsRATTracker daysPassedSinceDate:state.installLaunchDate]);
        extra[@"days_since_last_use"] = @([RAnalyticsRATTracker daysPassedSinceDate:state.lastLaunchDate]);
    }
    else if ([event.name isEqualToString:RAnalyticsSessionEndEventName])
    {
        // MARK: _rem_end_session
    }
    else if ([event.name isEqualToString:RAnalyticsApplicationUpdateEventName])
    {
        // MARK: _rem_update

        if (state.lastVersion.length)
        {
            extra[@"previous_version"] = state.lastVersion;
        }
        extra[@"launches_since_last_upgrade"] = @(state.lastVersionLaunches);
        extra[@"days_since_last_upgrade"] = @([RAnalyticsRATTracker daysPassedSinceDate:state.lastUpdateDate]);
    }
    else if ([event.name isEqualToString:RAnalyticsLoginEventName])
    {
        // MARK: _rem_login
        NSString *loginMethod = nil;
        switch (state.loginMethod)
        {
            case RAnalyticsPasswordInputLoginMethod: loginMethod = @"password";      break;
            case RAnalyticsOneTapLoginLoginMethod:   loginMethod = @"one_tap_login"; break;
            default: break;
        }

        if (loginMethod) extra[@"login_method"] = loginMethod;
    }
    else if ([event.name isEqualToString:RAnalyticsLoginFailureEventName])
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
    else if ([event.name isEqualToString:RAnalyticsLogoutEventName])
    {
        // MARK: _rem_logout

        NSString *logoutMethod = event.parameters[RAnalyticsLogoutMethodEventParameter];
        if ([logoutMethod isEqualToString:RAnalyticsLocalLogoutMethod])
        {
            logoutMethod = @"single";
        }
        else if ([logoutMethod isEqualToString:RAnalyticsGlobalLogoutMethod])
        {
            logoutMethod = @"all";
        }
        else
        {
            logoutMethod = nil;
        }

        if (logoutMethod) extra[@"logout_method"] = logoutMethod;
    }
    else if ([event.name isEqualToString:RAnalyticsPageVisitEventName] &&
             [RAnalyticsManager sharedInstance].shouldTrackPageView)
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
            if (state.origin != RAnalyticsInternalOrigin)
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
        if (origin == RAnalyticsInternalOrigin && self.carriedOverOrigin)
        {
            origin = self.carriedOverOrigin.unsignedIntegerValue;
            self.carriedOverOrigin = nil;
        }

        switch (origin)
        {
            case RAnalyticsInternalOrigin: extra[@"ref_type"] = @"internal"; break;
            case RAnalyticsExternalOrigin: extra[@"ref_type"] = @"external"; break;
            case RAnalyticsPushOrigin:     extra[@"ref_type"] = @"push";     break;
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
    else if ([event.name isEqualToString:RAnalyticsPushNotificationEventName])
    {
        // MARK: _rem_push_notify
        NSString *trackingIdentifier = event.parameters[RAnalyticsPushNotificationTrackingIdentifierParameter];
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
    else if ([event.name isEqualToString:RAnalyticsSSOCredentialFoundEventName])
    {
        // MARK: _rem_sso_credential_found

        NSString *source = event.parameters[@"source"];
        if (source.length) extra[@"source"] = source;
    }
    else if ([event.name isEqualToString:RAnalyticsLoginCredentialFoundEventName])
    {
        // MARK: _rem_login_credential_found

        NSString *source = event.parameters[@"source"];
        if (source.length) extra[@"source"] = source;
    }
    else if ([event.name isEqualToString:RAnalyticsCredentialStrategiesEventName])
    {
        // MARK: _rem_credential_strategies

        NSDictionary *strategies = event.parameters[@"strategies"];
        if (strategies.count) extra[@"strategies"] = strategies;
    }
    else if ([event.name isEqualToString:RAnalyticsCustomEventName])
    {
        // MARK: _analytics_custom (wrapper for event name and its data)

        NSString *eventName = event.parameters[RAnalyticsCustomEventNameParameter];
        if (![eventName isKindOfClass:NSString.class] || !eventName.length) return NO;

        payload[_RATETypeParameter] = eventName;

        NSDictionary *topLevelObject = [event.parameters[RAnalyticsCustomEventTopLevelObjectParameter] copy];
        if ([topLevelObject isKindOfClass:NSDictionary.class] && topLevelObject.count) {
            [payload addEntriesFromDictionary:topLevelObject];
        }

        NSDictionary *parameters = [event.parameters[RAnalyticsCustomEventDataParameter] copy];
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
    [_sender sendJSONOject:payload];
    return YES;
}

//--------------------------------------------------------------------------

- (void)_checkLTE
{
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([self.telephonyNetworkInfo respondsToSelector:@selector(currentRadioAccessTechnology)])
        {
            self.isUsingLTE = [self.telephonyNetworkInfo.currentRadioAccessTechnology isEqualToString:CTRadioAccessTechnologyLTE];
        }
    });
}

- (NSNumber *)positiveIntegerNumberWithObject:(id)object
{
    if ([object isKindOfClass:NSNumber.class])
    {
        if((strcmp([object objCType], @encode(float))) != 0 && (strcmp([object objCType], @encode(double))) != 0 && [object longLongValue] > 0)
        {
            return object;
        }
    }
    else if ([object isKindOfClass:NSString.class])
    {
        NSString *text = object;
        NSCharacterSet *charSet = [NSCharacterSet characterSetWithCharactersInString:text];
        if([[NSCharacterSet decimalDigitCharacterSet] isSupersetOfSet: charSet] && [text characterAtIndex:0] != '0' && [text longLongValue] > 0)
        {
            return @(text.longLongValue);
        }
    }
    return nil;
}

@end
