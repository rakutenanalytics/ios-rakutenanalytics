#import <RAnalytics/RAnalyticsEvent.h>
#import "_RAnalyticsExternalCollector.h"
#import "_RAnalyticsHelpers.h"
#import <RAnalytics/RAnalytics-Swift.h>

static NSString *const _RAnalyticsLoginStateKey = @"com.rakuten.esd.sdk.properties.analytics.loginInformation.loginState";
static NSString *const _RAnalyticsTrackingIdentifierKey = @"com.rakuten.esd.sdk.properties.analytics.loginInformation.trackingIdentifier";
static NSString *const _RAnalyticsUserIdentifierKey = @"com.rakuten.esd.sdk.properties.analytics.loginInformation.userIdentifier";
static NSString *const _RAnalyticsLoginMethodKey = @"com.rakuten.esd.sdk.properties.analytics.loginInformation.loginMethod";

static NSString *const _RAnalyticsNotificationBaseName = @"com.rakuten.esd.sdk.events";

@interface _RAnalyticsExternalCollector ()
/*
 * Mutable properties
 */
@property (nonatomic, readwrite, getter=isLoggedIn) BOOL   loggedIn;
@property (nonatomic, nullable, readwrite, copy) NSString *trackingIdentifier;
@property (nonatomic, readwrite) RAnalyticsLoginMethod  loginMethod;
@property (nonatomic, nullable, readwrite, copy) NSString *logoutMethod;

/*
 * Private properties
 */
@property (nonatomic) NSDictionary                        *cardInfoEventMapping;
@property (nonatomic) NSDictionary                        *discoverEventMapping;
@end

@implementation _RAnalyticsExternalCollector

+ (instancetype)sharedInstance
{
    static _RAnalyticsExternalCollector *instance = nil;
    static dispatch_once_t _RAnalyticsExternalCollectorOnceToken;
    dispatch_once(&_RAnalyticsExternalCollectorOnceToken, ^{
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
    __builtin_unreachable();
}

- (instancetype)initInstance
{
    if (self = [super init])
    {
        [self addLoginObservers];
        [self addLoginFailureObservers];
        [self addLogoutObservers];
        [self addDiscoverObservers];
        [self addSSODialogObservers];
        [self addCredentialsObservers];
        [self addCustomEventObserver];
        
        [self update];
    }
    return self;
}

#pragma mark - Notification observers

- (void)addLoginObservers
{
    for (NSString *event in @[@"password", @"one_tap", @"other"])
    {
        NSString *eventName = [NSString stringWithFormat:@"%@.login.%@", _RAnalyticsNotificationBaseName, event];
        [self addNotificationName:eventName selector:@selector(receiveLoginNotification:)];
    }
}

- (void)addLoginFailureObservers
{
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(receiveLoginFailureNotification:)
                                                 name:[_RAnalyticsNotificationBaseName stringByAppendingString:@".login.failure"]
                                               object:nil];
}

- (void)addLogoutObservers
{
    for (NSString *event in @[@"local", @"global"])
    {
        NSString *eventName = [NSString stringWithFormat:@"%@.logout.%@", _RAnalyticsNotificationBaseName, event];
        [self addNotificationName:eventName selector:@selector(receiveLogoutNotification:)];
    }
}

- (void)addDiscoverObservers
{
    NSString *eventBase = [NSString stringWithFormat:@"%@.discover.", _RAnalyticsNotificationBaseName];
    
    _discoverEventMapping =  @{
                              @"visitPreview"           : NSNotification.discoverPreviewVisit,
                              @"tapPreview"             : NSNotification.discoverPreviewTap,
                              @"redirectPreview"        : NSNotification.discoverPreviewRedirect,
                              @"tapShowMore"            : NSNotification.discoverPreviewShowMore,
                              @"visitPage"              : NSNotification.discoverPageVisit,
                              @"tapPage"                : NSNotification.discoverPageTap,
                              @"redirectPage"           : NSNotification.discoverPageRedirect
                              };
    
    for (NSString *notification in _discoverEventMapping)
    {
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(receiveDiscoverNotification:)
                                                     name:[NSString stringWithFormat:@"%@%@", eventBase, notification]
                                                   object:nil];
    }
}

- (void)addSSODialogObservers
{
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(receiveSSODialogNotification:)
                                                 name:[_RAnalyticsNotificationBaseName stringByAppendingString:@".ssodialog"]
                                               object:nil];
}

- (void)addCredentialsObservers
{
    for (NSString *notification in
         @[@"ssocredentialfound",
           @"logincredentialfound"])
    {
        NSString *eventName = [NSString stringWithFormat:@"%@.%@", _RAnalyticsNotificationBaseName, notification];
        [self addNotificationName:eventName selector:@selector(receiveCredentialsNotification:)];
    }
}

- (void)addCustomEventObserver
{
    NSString *eventName = [_RAnalyticsNotificationBaseName stringByAppendingString:@".custom"];
    [self addNotificationName:eventName selector:@selector(receiveCustomEventNotification:)];
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
        self.trackingIdentifier = trackingIdentifier;
    }
    
    self.loggedIn = YES;

    // For login we want to provide the logged-in state with each event, and each event tracker can know how the user logged in, so the loginMethod should be persisted.
    
    NSString *base = [NSString stringWithFormat:@"%@.login.", _RAnalyticsNotificationBaseName];
    if ([notification.name isEqualToString:[NSString stringWithFormat:@"%@password", base]])
    {
        self.loginMethod = RAnalyticsPasswordInputLoginMethod;
    }
    else if ([notification.name isEqualToString:[NSString stringWithFormat:@"%@one_tap", base]])
    {
        self.loginMethod = RAnalyticsOneTapLoginLoginMethod;
    }
    else
    {
        self.loginMethod = RAnalyticsOtherLoginMethod;
    }
    [self.class trackEvent:RAnalyticsLoginEventName];
}
- (void)receiveLoginFailureNotification:(NSNotification *)notification
{
    [self update];
    if ([notification.name isEqualToString:[_RAnalyticsNotificationBaseName stringByAppendingString:@".login.failure"]])
    {
        self.loggedIn = NO;
        self.trackingIdentifier = nil;
        NSMutableDictionary *parameters = [NSMutableDictionary new];
        
        if([notification.object isKindOfClass:[NSDictionary class]])
        {
            parameters[@"rae_error"] = notification.object[@"rae_error"];
            parameters[@"type"] = notification.object[@"type"];
            if (notification.object[@"rae_error_message"])
            {
                parameters[@"rae_error_message"] = notification.object[@"rae_error_message"];
            }
        }
        
        [self.class trackEvent:RAnalyticsLoginFailureEventName parameters:parameters.count ? parameters : nil];
    }
}

- (void)receiveLogoutNotification:(NSNotification *)notification
{
    [self update];
    self.loggedIn = NO;
    self.trackingIdentifier = nil;
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    if ([notification.name isEqualToString:[NSString stringWithFormat:@"%@.logout.local", _RAnalyticsNotificationBaseName]])
    {
        params[RAnalyticsLogoutMethodEventParameter] = RAnalyticsLocalLogoutMethod;
    }
    else
    {
        params[RAnalyticsLogoutMethodEventParameter] = RAnalyticsGlobalLogoutMethod;
    }
    [self.class trackEvent:RAnalyticsLogoutEventName parameters:params.copy];
}

- (void)receiveCardInfoNotification:(NSNotification *)notification
{
    NSString *key = [notification.name substringFromIndex:[NSString stringWithFormat:@"%@.cardinfo.", _RAnalyticsNotificationBaseName].length];
    [self.class trackEvent:_cardInfoEventMapping[key]];
}

- (void)receiveDiscoverNotification:(NSNotification *)notification
{
    NSString *eventSuffix = [notification.name substringFromIndex:[NSString stringWithFormat:@"%@.discover.", _RAnalyticsNotificationBaseName].length];
    
    NSArray *eventsRequiringOnlyIdentifier = @[@"tapPage", @"tapPreview"];
    NSArray *eventsRequiringIdentifierAndRedirectString = @[@"redirectPage", @"redirectPreview"];
    
    NSMutableDictionary *parameters = [NSMutableDictionary dictionaryWithCapacity:2];
    
    if ([eventsRequiringIdentifierAndRedirectString containsObject:eventSuffix] &&
             [notification.object isKindOfClass:NSDictionary.class] &&
             [notification.object[@"identifier"] isKindOfClass:NSString.class] &&
             [notification.object[@"url"] isKindOfClass:NSString.class])
    {
        parameters[@"prApp"] = notification.object[@"identifier"];
        parameters[@"prStoreUrl"] = notification.object[@"url"];
    }
    else if ([eventsRequiringOnlyIdentifier containsObject:eventSuffix] &&
             [notification.object isKindOfClass:NSString.class] &&
             ((NSString *)notification.object).length)
    {
        parameters[@"prApp"] = notification.object;
    }
    
    [self.class trackEvent:_discoverEventMapping[eventSuffix] parameters:parameters.count ? parameters : nil];
}

- (void)receiveSSODialogNotification:(NSNotification *)notification
{
    NSString *pageIdentifier = nil;
    if ([notification.object isKindOfClass:[NSString class]])
    {
        pageIdentifier = [notification object];
    }

    NSMutableDictionary *parameters = NSMutableDictionary.new;
    if (pageIdentifier.length)
    {
        parameters[@"page_id"] = pageIdentifier;
    }
    [self.class trackEvent:RAnalyticsPageVisitEventName parameters:parameters];
}

- (void)receiveCredentialsNotification:(NSNotification *)notification
{
    NSString *eventName = nil;
    NSMutableDictionary *parameters = NSMutableDictionary.new;
    
    if ([notification.name isEqualToString:[_RAnalyticsNotificationBaseName stringByAppendingString:@".ssocredentialfound"]])
    {
        eventName = RAnalyticsSSOCredentialFoundEventName;
    }
    else
    {
        eventName = RAnalyticsLoginCredentialFoundEventName;
    }
    
    if ([notification.object isKindOfClass:NSDictionary.class] &&
        [notification.object[@"source"] isKindOfClass:NSString.class])
    {
        parameters[@"source"] = notification.object[@"source"];
    }
    
    [self.class trackEvent:eventName parameters:parameters];
}

- (void)receiveCustomEventNotification:(NSNotification *)notification
{
    NSDictionary *object = notification.object;
    if (![object isKindOfClass:NSDictionary.class]) return;

    [self.class trackEvent:RAnalyticsCustomEventName parameters:notification.object];
}

#pragma mark - store & retrieve login/logout state & tracking identifier.

- (void)update
{
    NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
    _loggedIn           = [defaults boolForKey:_RAnalyticsLoginStateKey];
    _loginMethod        = [(NSNumber *)[defaults objectForKey:_RAnalyticsLoginMethodKey] unsignedIntegerValue];
    _trackingIdentifier = [defaults stringForKey:_RAnalyticsTrackingIdentifierKey];
    _userIdentifier = [defaults stringForKey:_RAnalyticsUserIdentifierKey];
}

- (void)setLoggedIn:(BOOL)loggedIn
{
    if (loggedIn != _loggedIn)
    {
        _loggedIn = loggedIn;
        NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
        [defaults setBool:loggedIn forKey:_RAnalyticsLoginStateKey];
        [defaults synchronize];
    }
}

- (void)setUserIdentifier:(NSString *)userIdentifier
{
    if (_RAnalyticsObjectsEqual(userIdentifier, _userIdentifier))
    {
        return;
    }
    
    _userIdentifier = userIdentifier.copy;
    NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
    if (userIdentifier.length)
    {
        [defaults setObject:userIdentifier forKey:_RAnalyticsUserIdentifierKey];
    }
    else
    {
        [defaults removeObjectForKey:_RAnalyticsUserIdentifierKey];
    }
    [defaults synchronize];
}

- (void)setTrackingIdentifier:(NSString *)trackingIdentifier
{
    if (!_RAnalyticsObjectsEqual(trackingIdentifier, _trackingIdentifier))
    {
        _trackingIdentifier = trackingIdentifier.copy;
        NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
        if (trackingIdentifier.length)
        {
            [defaults setObject:trackingIdentifier forKey:_RAnalyticsTrackingIdentifierKey];
        }
        else
        {
            [defaults removeObjectForKey:_RAnalyticsTrackingIdentifierKey];
        }
        [defaults synchronize];
    }
}

- (void)setLoginMethod:(RAnalyticsLoginMethod)loginMethod
{
    if (loginMethod != _loginMethod)
    {
        _loginMethod = loginMethod;
        NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
        [defaults setObject:@(loginMethod) forKey:_RAnalyticsLoginMethodKey];
        [defaults synchronize];
    }
}

#pragma mark - Helpers

+ (void)trackEvent:(NSString *)eventName
{
    [self.class trackEvent:eventName parameters:nil];
}

+ (void)trackEvent:(NSString *)eventName parameters:(NSDictionary<NSString *, id> *)parameters
{
    [[RAnalyticsEvent.alloc initWithName:eventName parameters:parameters] track];
}
@end
