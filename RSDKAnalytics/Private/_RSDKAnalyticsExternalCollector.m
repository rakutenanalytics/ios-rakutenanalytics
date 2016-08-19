/*
 * © Rakuten, Inc.
 * authors: "Rakuten Ecosystem Mobile" <ecosystem-mobile@mail.rakuten.com>
 */
#import "_RSDKAnalyticsExternalCollector.h"
#import <RSDKAnalytics/RSDKAnalyticsEvent.h>
#import <RSDKAnalytics/RSDKAnalyticsState.h>

static NSString *const _RSDKAnalyticsLoginStateKey = @"com.rakuten.esd.sdk.properties.analytics.loginInformation.loginState";
static NSString *const _RSDKAnalyticsTrackingIdentifierKey = @"com.rakuten.esd.sdk.properties.analytics.loginInformation.trackingIdentifier";

@interface _RSDKAnalyticsExternalCollector ()
@property (nonatomic) BOOL loggedIn;
@property (nonatomic, nullable, copy) NSString *trackingIdentifier;

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
        [self addNotificationName:@"com.rakuten.esd.sdk.events.login.password" selector:@selector(receiveLoginNotification:)];
        [self addNotificationName:@"com.rakuten.esd.sdk.events.login.one_tap" selector:@selector(receiveLoginNotification:)];
        [self addNotificationName:@"com.rakuten.esd.sdk.events.login.other" selector:@selector(receiveLoginNotification:)];
        [self addNotificationName:@"com.rakuten.esd.sdk.events.logout.local" selector:@selector(receiveLogoutNotification:)];
        [self addNotificationName:@"com.rakuten.esd.sdk.events.logout.global" selector:@selector(receiveLogoutNotification:)];
        [self update];
    }
    return self;
}

- (void)addNotificationName:(NSString *)name selector:(SEL)aSelector
{
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:aSelector
                                                 name:name
                                               object:nil];
}

- (void)receiveLoginNotification:(NSNotification *)notification
{
    [self update];
    if (![_RSDKAnalyticsExternalCollector sharedInstance].loggedIn)
    {
        [_RSDKAnalyticsExternalCollector sharedInstance].loggedIn = YES;
    }
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    if ([notification.name isEqualToString:@"com.rakuten.esd.sdk.events.login.password"])
    {
        params[@"login_method"] = @(RSDKAnalyticsPasswordInputLoginMethod);
    } else if ([notification.name isEqualToString:@"com.rakuten.esd.sdk.events.login.one_tap"])
    {
        params[@"login_method"] = @(RSDKAnalyticsOneTapLoginLoginMethod);
    } else
    {
        params[@"login_method"] = @(RSDKAnalyticsOtherLoginMethod);
    }
    [[RSDKAnalyticsEvent.alloc initWithName:RSDKAnalyticsLoginEvent parameters:params.copy] track];
}

- (void)receiveLogoutNotification:(NSNotification *)notification
{
    [self update];
    if ([_RSDKAnalyticsExternalCollector sharedInstance].loggedIn)
    {
        [_RSDKAnalyticsExternalCollector sharedInstance].loggedIn = NO;
    }
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    if ([notification.name isEqualToString:@"com.rakuten.esd.sdk.events.logout.local"])
    {
        params[@"logout_method"] = @(RSDKAnalyticsLocalLogoutMethod);
    } else
    {
        params[@"logout_method"] = @(RSDKAnalyticsGlobalLogoutMethod);
    }
    [[RSDKAnalyticsEvent.alloc initWithName:RSDKAnalyticsLogoutEvent parameters:params.copy] track];
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

@end
