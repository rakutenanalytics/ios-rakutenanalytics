/*
 * © Rakuten, Inc.
 * authors: "Rakuten Ecosystem Mobile" <ecosystem-mobile@mail.rakuten.com>
 */
#import "_RSDKAnalyticsExternalCollector.h"
#import <RSDKAnalytics/RSDKAnalyticsEvent.h>
#import <RSDKAnalytics/RSDKAnalyticsState.h>

static NSString *const _RSDKAnalyticsLoginStateKey = @"com.rakuten.esd.sdk.properties.analytics.loginInformation.loginState";
static NSString *const _RSDKAnalyticsTrackingIdentifierKey = @"com.rakuten.esd.sdk.properties.analytics.loginInformation.trackingIdentifier";
static NSString *const _RSDKAnalyticsLoginMethodKey = @"com.rakuten.esd.sdk.properties.analytics.loginInformation.loginMethod";

static NSString *const _RSDKAnalyticsNotificationBaseName = @"com.rakuten.esd.sdk.events";

@interface _RSDKAnalyticsExternalCollector ()
@property (nonatomic) BOOL loggedIn;
@property (nonatomic, nullable, readwrite, copy) NSString *trackingIdentifier;
@property (nonatomic, nullable, readwrite, copy) NSString *loginMethod;
@property (nonatomic, nullable, readwrite, copy) NSString *logoutMethod;
@property (nonatomic, nullable) NSDictionary              *cardScannerEventMapping;
@end

@implementation _RSDKAnalyticsExternalCollector

+ (instancetype)sharedInstance
{
    static _RSDKAnalyticsExternalCollector *instance = nil;
    static dispatch_once_t _RSDKAnalyticsExternalCollectorOnceToken;
    dispatch_once(&_RSDKAnalyticsExternalCollectorOnceToken, ^{
        instance = [self.alloc initInstance];
    });
    return instance;
}

- (void)dealloc
{
    [NSNotificationCenter.defaultCenter removeObserver:self];
}

- (instancetype)init
{
    [self doesNotRecognizeSelector:_cmd];
    return nil;
}

- (instancetype)initInstance
{
    if (self = [super init])
    {
        [self addLoginObservers];
        [self addLogoutObservers];
        [self addCardScannerObservers];
        
        [self update];
    }
    return self;
}

#pragma mark - Add notification observers

- (void)addLoginObservers
{
    for (NSString *event in @[@"passsword", @"one_tap", @"other"])
    {
        NSString *eventName = [NSString stringWithFormat:@"%@.login.%@", _RSDKAnalyticsNotificationBaseName, event];
        [self addNotificationName:eventName selector:@selector(receiveLoginNotification:)];
    }
}

- (void)addLogoutObservers
{
    for (NSString *event in @[@"local", @"global"])
    {
        NSString *eventName = [NSString stringWithFormat:@"%@.logout.%@", _RSDKAnalyticsNotificationBaseName, event];
        [self addNotificationName:eventName selector:@selector(receiveLogoutNotification:)];
    }
}

- (void)addCardScannerObservers
{
    NSString *eventBase = [NSString stringWithFormat:@"%@.cardscanner.", _RSDKAnalyticsNotificationBaseName];
    
    _cardScannerEventMapping = @{
                                 @"user.visited"               : RSDKAnalyticsEventCardScannerVisit,
                                 @"scanui.user.started"        : RSDKAnalyticsEventCardScannerScanStarted,
                                 @"scanui.user.canceled"       : RSDKAnalyticsEventCardScannerScanCanceled,
                                 @"scanui.user.manual"         : RSDKAnalyticsEventCardScannerManual,
                                 @"number.scanned"             : RSDKAnalyticsEventCardScannerNumberScanned,
                                 @"number.scan.failed"         : RSDKAnalyticsEventCardScannerNumberScanFailed,
                                 @"number.modifed"             : RSDKAnalyticsEventCardScannerNumberModified,
                                 @"cardtype.identified"        : RSDKAnalyticsEventCardScannerCardTypeIdentified,
                                 @"cardtype.identify.failed"   : RSDKAnalyticsEventCardScannerCardTypeIdentifyFailed,
                                 @"cardtype.modifed"           : RSDKAnalyticsEventCardScannerCardTypeModified,
                                 @"expiry.scanned"             : RSDKAnalyticsEventCardScannerExpiryScanned,
                                 @"expiry.scan.failed"         : RSDKAnalyticsEventCardScannerExpiryScanFailed,
                                 @"expiry.modified"            : RSDKAnalyticsEventCardScannerExpiryModified
                                 };
    
    for (NSString *notification in _cardScannerEventMapping)
    {
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(receiveCardScannerNotification:)
                                                     name:[NSString stringWithFormat:@"%@%@", eventBase, notification]
                                                   object:nil];
    }
}

- (void)addNotificationName:(NSString *)name selector:(SEL)aSelector
{
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:aSelector
                                                 name:name
                                               object:nil];
}

#pragma mark - Handle notifications

- (void)receiveLoginNotification:(NSNotification *)notification
{
    [self update];
    
    if ([notification.object isKindOfClass:[NSString class]])
    {
        NSString *trackingIdentifier = [notification object];
        [_RSDKAnalyticsExternalCollector sharedInstance].trackingIdentifier = trackingIdentifier;
    }
    
    if (![_RSDKAnalyticsExternalCollector sharedInstance].loggedIn)
    {
        [_RSDKAnalyticsExternalCollector sharedInstance].loggedIn = YES;
    }
    
    // For login we want to provide the logged-in state with each event, and each event tracker can know how the user logged in, so the loginMethod should be persisted.
    
    NSString *base = [NSString stringWithFormat:@"%@.login.", _RSDKAnalyticsNotificationBaseName];
    if ([notification.name isEqualToString:[NSString stringWithFormat:@"%@password", base]])
    {
        [_RSDKAnalyticsExternalCollector sharedInstance].loginMethod = RSDKAnalyticsPasswordInputLoginMethod;
    }
    else if ([notification.name isEqualToString:[NSString stringWithFormat:@"%@one_tap", base]])
    {
        [_RSDKAnalyticsExternalCollector sharedInstance].loginMethod = RSDKAnalyticsOneTapLoginLoginMethod;
    }
    else
    {
        [_RSDKAnalyticsExternalCollector sharedInstance].loginMethod = RSDKAnalyticsOtherLoginMethod;
    }
    [self.class trackEvent:RSDKAnalyticsLoginEventName];
}

- (void)receiveLogoutNotification:(NSNotification *)notification
{
    [self update];
    if ([_RSDKAnalyticsExternalCollector sharedInstance].loggedIn)
    {
        [_RSDKAnalyticsExternalCollector sharedInstance].loggedIn = NO;
    }
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    if ([notification.name isEqualToString:[NSString stringWithFormat:@"%@.logout.local", _RSDKAnalyticsNotificationBaseName]])
    {
        params[@"logout_method"] = RSDKAnalyticsLocalLogoutMethodParameter;
    }
    else
    {
        params[@"logout_method"] = RSDKAnalyticsGlobalLogoutMethodParameter;
    }
    [self.class trackEvent:RSDKAnalyticsLogoutEventName parameters:params.copy];
}

- (void)receiveCardScannerNotification:(NSNotification *)notification
{
    NSString *key = [notification.name substringFromIndex:[NSString stringWithFormat:@"%@.cardscanner.", _RSDKAnalyticsNotificationBaseName].length];
    [self.class trackEvent:_cardScannerEventMapping[key]];
}

#pragma mark - store & retrieve login/logout state & tracking identifier.

- (void)update
{
    NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
    _loggedIn = [defaults boolForKey:_RSDKAnalyticsLoginStateKey];
    _trackingIdentifier = [defaults stringForKey:_RSDKAnalyticsTrackingIdentifierKey];
}

- (void)setLoggedIn:(BOOL)loggedIn
{
    _loggedIn = loggedIn;
    NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
    [defaults setBool:loggedIn forKey:_RSDKAnalyticsLoginStateKey];
    [defaults synchronize];
}

- (void)setTrackingIdentifier:(NSString *)trackingIdentifier
{
    _trackingIdentifier = trackingIdentifier;
    NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
    if (trackingIdentifier.length)
    {
        [defaults setObject:trackingIdentifier forKey:_RSDKAnalyticsTrackingIdentifierKey];
    }
    else
    {
        [defaults removeObjectForKey:_RSDKAnalyticsTrackingIdentifierKey];
    }
    [defaults synchronize];
}

- (void)setLoginMethod:(NSString *)loginMethod
{
    _loginMethod = loginMethod;
    NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
    if (loginMethod.length)
    {
        [defaults setObject:loginMethod forKey:_RSDKAnalyticsLoginMethodKey];
    }
    else
    {
        [defaults removeObjectForKey:_RSDKAnalyticsLoginMethodKey];
    }
    [defaults synchronize];
}

#pragma mark - Tracking helpers

+ (void)trackEvent:(NSString *)eventName
{
    [self.class trackEvent:eventName parameters:nil];
}

+ (void)trackEvent:(NSString *)eventName parameters:(NSDictionary RSDKA_GENERIC(NSString *, id) *)parameters
{
    [[RSDKAnalyticsEvent.alloc initWithName:eventName parameters:parameters] track];
}

@end
