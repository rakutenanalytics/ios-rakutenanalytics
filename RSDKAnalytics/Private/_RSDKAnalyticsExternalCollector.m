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
    NSDictionary *observe = @{
                              @"user.visited"               : NSStringFromSelector(@selector(receiveCardScannerVisitNotification:)),
                              @"scanui.user.started"        : NSStringFromSelector(@selector(receiveCardScannerScanStartedNotification:)),
                              @"scanui.user.canceled"       : NSStringFromSelector(@selector(receiveCardScannerScanCanceledNotification:)),
                              @"scanui.user.manual"         : NSStringFromSelector(@selector(receiveCardScannerScanManualNotification:)),
                              @"number.scanned"             : NSStringFromSelector(@selector(receiveCardScannerNumberScannedNotification:)),
                              @"number.scan.failed"         : NSStringFromSelector(@selector(receiveCardScannerNumberScanFailedNotification:)),
                              @"number.modifed"             : NSStringFromSelector(@selector(receiveCardScannerNumberModifiedNotification:)),
                              @"cardtype.identified"        : NSStringFromSelector(@selector(receiveCardScannerCardTypeIdentifiedNotification:)),
                              @"cardtype.identify.failed"   : NSStringFromSelector(@selector(receiveCardScannerCardTypeIdentifyFailedNotification:)),
                              @"cardtype.modifed"           : NSStringFromSelector(@selector(receiveCardScannerCardTypeModifiedNotification:)),
                              @"expiry.scanned"             : NSStringFromSelector(@selector(receiveCardScannerExpiryScannedNotification:)),
                              @"expiry.scan.failed"         : NSStringFromSelector(@selector(receiveCardScannerExpiryScanFailedNotification:)),
                              @"expiry.modified"            : NSStringFromSelector(@selector(receiveCardScannerExpiryModifiedNotification:))
                              };
    
    for (NSString *notification in observe)
    {
        [self addCardScannerNotificationName:notification selector:NSSelectorFromString(observe[notification])];
    }
}

- (void)addCardScannerNotificationName:(NSString *)name selector:(SEL)aSelector
{
    NSString *eventBase = [NSString stringWithFormat:@"%@.cardscanner.", _RSDKAnalyticsNotificationBaseName];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:aSelector
                                                 name:[NSString stringWithFormat:@"%@%@", eventBase, name]
                                               object:nil];
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
    
    NSString *base = [NSString stringWithFormat:@"%@.login", _RSDKAnalyticsNotificationBaseName];
    if ([notification.name isEqualToString:[NSString stringWithFormat:@"%@.password", base]])
    {
        [_RSDKAnalyticsExternalCollector sharedInstance].loginMethod = RSDKAnalyticsPasswordInputLoginMethod;
    }
    else if ([notification.name isEqualToString:[NSString stringWithFormat:@"%@.one_tap", base]])
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
    [[RSDKAnalyticsEvent.alloc initWithName:RSDKAnalyticsLogoutEventName parameters:params.copy] track];
}

- (void)receiveCardScannerVisitNotification:(NSNotification *)notification
{
    [self.class trackEvent:RSDKAnalyticsEventCardScannerVisit];
}

- (void)receiveCardScannerScanStartedNotification:(NSNotification *)notification
{
    [self.class trackEvent:RSDKAnalyticsEventCardScannerScanStarted];
}

- (void)receiveCardScannerScanCanceledNotification:(NSNotification *)notification
{
    [self.class trackEvent:RSDKAnalyticsEventCardScannerScanCanceled];
}

- (void)receiveCardScannerScanManualNotification:(NSNotification *)notification
{
    [self.class trackEvent:RSDKAnalyticsEventCardScannerManual];
}

- (void)receiveCardScannerNumberScannedNotification:(NSNotification *)notification
{
    [self.class trackEvent:RSDKAnalyticsEventCardScannerNumberScanned];
}

- (void)receiveCardScannerNumberScanFailedNotification:(NSNotification *)notification
{
    [self.class trackEvent:RSDKAnalyticsEventCardScannerNumberScanFailed];
}

- (void)receiveCardScannerNumberModifiedNotification:(NSNotification *)notification
{
    [self.class trackEvent:RSDKAnalyticsEventCardScannerNumberModified];
}

- (void)receiveCardScannerCardTypeIdentifiedNotification:(NSNotification *)notification
{
    [self.class trackEvent:RSDKAnalyticsEventCardScannerCardTypeIdentified];
}

- (void)receiveCardScannerCardTypeIdentifyFailedNotification:(NSNotification *)notification
{
    [self.class trackEvent:RSDKAnalyticsEventCardScannerCardTypeIdentifyFailed];
}

- (void)receiveCardScannerCardTypeModifiedNotification:(NSNotification *)notification
{
    [self.class trackEvent:RSDKAnalyticsEventCardScannerCardTypeModified];
}

- (void)receiveCardScannerExpiryScannedNotification:(NSNotification *)notification
{
    [self.class trackEvent:RSDKAnalyticsEventCardScannerExpiryScanned];
}

- (void)receiveCardScannerExpiryScanFailedNotification:(NSNotification *)notification
{
    [self.class trackEvent:RSDKAnalyticsEventCardScannerExpiryScanFailed];
}

- (void)receiveCardScannerExpiryModifiedNotification:(NSNotification *)notification
{
    [self.class trackEvent:RSDKAnalyticsEventCardScannerExpiryModified];
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
    [[RSDKAnalyticsEvent.alloc initWithName:eventName parameters:nil] track];
}

@end
