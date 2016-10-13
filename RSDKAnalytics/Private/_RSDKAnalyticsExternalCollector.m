/*
 * © Rakuten, Inc.
 * authors: "Rakuten Ecosystem Mobile" <ecosystem-mobile@mail.rakuten.com>
 */
#import "_RSDKAnalyticsExternalCollector.h"
#import <RSDKAnalytics/RSDKAnalyticsEvent.h>
#import <RSDKAnalytics/_RSDKAnalyticsPrivateEvents.h>
#import <RSDKAnalytics/RSDKAnalyticsState.h>
#import "_RSDKAnalyticsHelpers.h"

static NSString *const _RSDKAnalyticsLoginStateKey = @"com.rakuten.esd.sdk.properties.analytics.loginInformation.loginState";
static NSString *const _RSDKAnalyticsTrackingIdentifierKey = @"com.rakuten.esd.sdk.properties.analytics.loginInformation.trackingIdentifier";
static NSString *const _RSDKAnalyticsLoginMethodKey = @"com.rakuten.esd.sdk.properties.analytics.loginInformation.loginMethod";

static NSString *const _RSDKAnalyticsNotificationBaseName = @"com.rakuten.esd.sdk.events";

@interface _RSDKAnalyticsExternalCollector ()
@property (nonatomic, readwrite, getter=isLoggedIn) BOOL      loggedIn;
@property (nonatomic, nullable, readwrite, copy) NSString     *trackingIdentifier;
@property (nonatomic, readwrite) RSDKAnalyticsLoginMethod     loginMethod;
@property (nonatomic, nullable, readwrite, copy) NSString     *logoutMethod;
@property (nonatomic) NSDictionary                            *cardInfoEventMapping;
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
        [self addCardInfoObservers];
        
        [self update];
    }
    return self;
}

#pragma mark - Add notification observers

- (void)addLoginObservers
{
    for (NSString *event in @[@"password", @"one_tap", @"other"])
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

- (void)addCardInfoObservers
{
    NSString *eventBase = [NSString stringWithFormat:@"%@.cardinfo.", _RSDKAnalyticsNotificationBaseName];
    
    _cardInfoEventMapping = @{
                                 @"scanui.user.started"        : _RSDKAnalyticsPrivateEventCardInfoScanStarted,
                                 @"scanui.user.canceled"       : _RSDKAnalyticsPrivateEventCardInfoScanCanceled,
                                 @"scanui.user.manual"         : _RSDKAnalyticsPrivateEventCardInfoManual,
                                 @"number.scanned"             : _RSDKAnalyticsPrivateEventCardInfoNumberScanned,
                                 @"number.scan.failed"         : _RSDKAnalyticsPrivateEventCardInfoNumberScanFailed,
                                 @"number.modifed"             : _RSDKAnalyticsPrivateEventCardInfoNumberModified,
                                 @"cardtype.identified"        : _RSDKAnalyticsPrivateEventCardInfoCardTypeIdentified,
                                 @"cardtype.identify.failed"   : _RSDKAnalyticsPrivateEventCardInfoCardTypeIdentifyFailed,
                                 @"cardtype.modifed"           : _RSDKAnalyticsPrivateEventCardInfoCardTypeModified,
                                 @"expiry.scanned"             : _RSDKAnalyticsPrivateEventCardInfoExpiryScanned,
                                 @"expiry.scan.failed"         : _RSDKAnalyticsPrivateEventCardInfoExpiryScanFailed,
                                 @"expiry.modified"            : _RSDKAnalyticsPrivateEventCardInfoExpiryModified
                                 };
    
    for (NSString *notification in _cardInfoEventMapping)
    {
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(receiveCardInfoNotification:)
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
        [_RSDKAnalyticsExternalCollector sharedInstance].trackingIdentifier = nil;
    }
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    if ([notification.name isEqualToString:[NSString stringWithFormat:@"%@.logout.local", _RSDKAnalyticsNotificationBaseName]])
    {
        params[RSDKAnalyticsLogoutMethodEventParameter] = RSDKAnalyticsLocalLogoutMethod;
    }
    else
    {
        params[RSDKAnalyticsLogoutMethodEventParameter] = RSDKAnalyticsGlobalLogoutMethod;
    }
    [self.class trackEvent:RSDKAnalyticsLogoutEventName parameters:params.copy];
}

- (void)receiveCardInfoNotification:(NSNotification *)notification
{
    NSString *key = [notification.name substringFromIndex:[NSString stringWithFormat:@"%@.cardinfo.", _RSDKAnalyticsNotificationBaseName].length];
    [self.class trackEvent:_cardInfoEventMapping[key]];
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

- (void)setLoginMethod:(RSDKAnalyticsLoginMethod)loginMethod
{
    _loginMethod = loginMethod;
    NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:@(loginMethod) forKey:_RSDKAnalyticsLoginMethodKey];
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
