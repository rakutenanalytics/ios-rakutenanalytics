#import <RAnalytics/RAnalytics.h>
#import <CoreLocation/CoreLocation.h>
#import <RDeviceIdentifier/RDeviceIdentifier.h>
#import "_RAnalyticsHelpers.h"
#import "_RAnalyticsCoreHelpers.h"
#import <RLogger/RLogger.h>
#import "SwiftHeader.h"

NSString *const _RATEventPrefix      = @"rat.";
NSString *const _RATETypeParameter   = @"etype";
NSString *const _RATCPParameter      = @"cp";
NSString *const _RATGenericEventName = @"rat.generic";
NSString *const _RATPGNParameter     = @"pgn";
NSString *const _RATREFParameter     = @"ref";

NSString *const _RATReachabilityHost = @"8.8.8.8"; // Google DNS Server

static const NSTimeInterval _RATBatchingDelay = 1.0; // Batching delay is 1 second by default

NSString* const _RATDatabaseName = @"RSDKAnalytics.db";
NSString* const _RATTableName = @"RAKUTEN_ANALYTICS_TABLE";

////////////////////////////////////////////////////////////////////////////

////////////////////////////////////////////////////////////////////////////

@interface RAnalyticsRATTracker ()
@property (nonatomic) int64_t accountIdentifier;
@property (nonatomic) int64_t applicationIdentifier;

@property (nonatomic) RAnalyticsSender *sender;

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

@property (nonatomic, strong) TelephonyHandler *telephonyHandler;

@property (nonatomic, strong) DeviceHandler *deviceHandler;

@property (nonatomic, strong) UserAgentHandler *userAgentHandler;

@property (nonatomic, strong) ReachabilityNotifier * _Nullable reachabilityNotifier;

@end

@implementation RAnalyticsRATTracker

@synthesize endpointURL;

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
        _startTime = NSDate.date.toString;

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
        _reachabilityNotifier = [ReachabilityNotifier.alloc initWithHost:_RATReachabilityHost
                                                                callback:RAnalyticsRATTracker.reachabilityCallback];

        // create a sender.
        RAnalyticsDatabase *database = [RAnalyticsDatabase databaseWithConnection:[RAnalyticsDatabase mkAnalyticsDBConnectionWithName:_RATDatabaseName]];
        _sender = [RAnalyticsSender.alloc initWithEndpoint:_RAnalyticsEndpointAddress()
                                                  database:database
                                             databaseTable:_RATTableName];
        [_sender setBatchingDelayBlock:^{return _RATBatchingDelay;}];

        _rpCookieFetcher = [[RAnalyticsRpCookieFetcher alloc] initWithCookieStorage:[NSHTTPCookieStorage sharedHTTPCookieStorage]];
        [_rpCookieFetcher getRpCookieCompletionHandler:^(NSHTTPCookie * _Nullable cookie, NSError * _Nullable error)
         {
             if (error)
             {
                 [RLogger error:@"%@", error];
             }
         }];
        
        _telephonyHandler = [TelephonyHandler.alloc initWithTelephonyNetworkInfo:CTTelephonyNetworkInfo.new
                                                              notificationCenter:NSNotificationCenter.defaultCenter];
        
        // Reallocate telephonyNetworkInfo when the app becomes active
        [NSNotificationCenter.defaultCenter addObserverForName:UIApplicationDidBecomeActiveNotification
                                                        object:nil
                                                         queue:nil
                                                    usingBlock:^(NSNotification * _Nonnull note) {
            [self.telephonyHandler updateWithTelephonyNetworkInfo: CTTelephonyNetworkInfo.new];
        }];
        
        _deviceHandler = [DeviceHandler.alloc initWithDevice:UIDevice.currentDevice
                                                      screen:UIScreen.mainScreen];
        
        _userAgentHandler = [UserAgentHandler.alloc initWithBundle:NSBundle.mainBundle];
        
    }
    return self;
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

- (void)setEndpointURL:(NSURL *)endpointURL
{
    _sender.endpointURL = endpointURL;
    _rpCookieFetcher.endpointURL = endpointURL;
}

- (NSURL *)endpointURL
{
    return _sender.endpointURL;
}

+ (NSURL *)endpointAddress
{
    return RAnalyticsRATTracker.sharedInstance.sender.endpointURL;
}

- (void)addAutomaticFields:(NSMutableDictionary *)payload state:(RAnalyticsState *)state
{
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
            [RLogger error:@"There is no value for 'acc' field, please configure it by setting a 'RATAccountIdentifier' key to YOUR_RAT_ACCOUNT_ID in your app's Info.plist"];
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
            [RLogger error:@"There is no value for 'aid' field, please configure it by setting a 'RATAppIdentifier' key to YOUR_RAT_APPLICATION_ID in your app's Info.plist"];
        }
    }

    if (_deviceHandler.batteryState != UIDeviceBatteryStateUnknown)
    {
        // MARK: powerstatus
        payload[@"powerstatus"] = @(_deviceHandler.batteryState != UIDeviceBatteryStateUnplugged ? 1 : 0);

        // MARK: mbat
        payload[@"mbat"] = [NSString stringWithFormat:@"%0.f", _deviceHandler.batteryLevel * 100];
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
    
    _telephonyHandler.reachabilityStatus = _reachabilityStatus;

    // MARK: mcn
    payload[@"mcn"] = _telephonyHandler.mcn;

    // MARK: model
    payload[@"model"] = RDeviceIdentifier.modelIdentifier;

    // MARK: mnetw
    payload[@"mnetw"] = _telephonyHandler.mnetw ?: @"";

    // MARK: mori
    RStatusBarOrientationHandler *statusBarOrientationHandler = [[RStatusBarOrientationHandler alloc] initWithApplication:_RAnalyticsSharedApplication()];
    payload[@"mori"] = @([statusBarOrientationHandler mori]);

    // MARK: online
    if (_reachabilityStatus)
    {
        payload[@"online"] = (_reachabilityStatus.unsignedIntegerValue != RATReachabilityStatusOffline) ? @YES : @NO;
    }

    // MARK: ckp
    if (state.deviceIdentifier)
    {
        payload[@"ckp"] = state.deviceIdentifier;
    }

    // MARK: ua
    payload[@"ua"] = [_userAgentHandler valueFor:state];

    // MARK: res
    payload[@"res"] = _deviceHandler.screenResolution;

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
    
    // MARK: easyid
    if (state.easyIdentifier.length && !((NSString *)payload[@"easyid"]).length)
    {
        payload[@"easyid"] = state.easyIdentifier;
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
        NSDictionary *appInfo = appAndSDKDict[RAnalyticsConstants.RAnalyticsAppInfoKey];
        NSDictionary *sdkInfo = appAndSDKDict[RAnalyticsConstants.RAnalyticsSDKInfoKey];
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
        extra[@"days_since_first_use"] = @([NSDate daysPassedSinceDate:state.installLaunchDate]);
        extra[@"days_since_last_use"] = @([NSDate daysPassedSinceDate:state.lastLaunchDate]);
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
        extra[@"days_since_last_upgrade"] = @([NSDate daysPassedSinceDate:state.lastUpdateDate]);
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
        NSDictionary *loginFailureDictionary = event.loginFailureParameters;
        if (loginFailureDictionary) {
            [extra addEntriesFromDictionary:loginFailureDictionary];
        }
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
        NSURL    *pageURL        = [currentPage.view getWebViewURL].absoluteURL;

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
    [_sender sendJSONObject:payload];
    return YES;
}

//--------------------------------------------------------------------------

- (NSNumber *)positiveIntegerNumberWithObject:(id)object
{
    return [object positiveIntegerNumber];
}

@end
