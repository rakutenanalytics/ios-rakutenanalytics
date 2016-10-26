/*
 * © Rakuten, Inc.
 * authors: "Rakuten Ecosystem Mobile" <ecosystem-mobile@mail.rakuten.com>
 */
#import "_RSDKAnalyticsLaunchCollector.h"
#import <RSDKAnalytics/RSDKAnalyticsEvent.h>
#import "_RSDKAnalyticsHelpers.h"

static NSString *const _RSDKAnalyticsInitialLaunchDateKey = @"com.rakuten.esd.sdk.properties.analytics.launchInformation.initialLaunchDate";
static NSString *const _RSDKAnalyticsInstallLaunchDateKey = @"com.rakuten.esd.sdk.properties.analytics.launchInformation.installLaunchDate";
static NSString *const _RSDKAnalyticsLastUpdateDateKey = @"com.rakuten.esd.sdk.properties.analytics.launchInformation.lastUpdateDate";
static NSString *const _RSDKAnalyticsLastLaunchDateKey = @"com.rakuten.esd.sdk.properties.analytics.launchInformation.lastLaunchDate";
static NSString *const _RSDKAnalyticsLastVersionKey = @"com.rakuten.esd.sdk.properties.analytics.launchInformation.lastVersion";
static NSString *const _RSDKAnalyticsLastVersionLaunchesKey = @"com.rakuten.esd.sdk.properties.analytics.launchInformation.lastVersionLaunches";

@interface _RSDKAnalyticsLaunchCollector ()
@property (nonatomic, nullable, readwrite, copy) NSDate *initialLaunchDate;
@property (nonatomic, nullable, readwrite, copy) NSDate *installLaunchDate;
@property (nonatomic, nullable, readwrite, copy) NSDate *lastUpdateDate;
@property (nonatomic, nullable, readwrite, copy) NSDate *lastLaunchDate;
@property (nonatomic, nullable, readwrite, copy) NSString *lastVersion;
@property (nonatomic, readwrite) NSUInteger lastVersionLaunches;
@property (nonatomic, readwrite) BOOL isInitialLaunch;
@property (nonatomic, readwrite) BOOL isInstallLaunch;
@property (nonatomic, readwrite) BOOL isUpdateLaunch;
@property (nonatomic, readwrite) RSDKAnalyticsOrigin origin;
@property (nonatomic, nullable, readwrite) UIViewController *lastVisitedPage;
@property (nonatomic, nullable, readwrite) UIViewController *currentPage;
@property (nonatomic, nullable, readwrite, copy) NSString *pushTrackingIdentifier;
@end

@implementation _RSDKAnalyticsLaunchCollector

+ (instancetype)sharedInstance
{
    static _RSDKAnalyticsLaunchCollector *instance = nil;
    static dispatch_once_t _RSDKAnalyticsLaunchCollectorOnceToken;
    dispatch_once(&_RSDKAnalyticsLaunchCollectorOnceToken, ^{
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
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(willResume:)
                                                     name:UIApplicationWillEnterForegroundNotification
                                                   object:nil];

        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(didSuspend:)
                                                     name:UIApplicationDidEnterBackgroundNotification
                                                   object:nil];

        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(didLaunch:)
                                                     name:UIApplicationDidFinishLaunchingNotification
                                                   object:nil];

        // check initLaunchDate exists in keychain
        NSMutableDictionary *query = NSMutableDictionary.new;
        query[(__bridge id)kSecClass]       = (__bridge id)kSecClassGenericPassword;
        query[(__bridge id)kSecAttrLabel]   = _RSDKAnalyticsInitialLaunchDateKey;
        query[(__bridge id)kSecReturnAttributes] = @YES;
        query[(__bridge id)kSecAttrAccessible] = (__bridge id)kSecAttrAccessibleWhenUnlockedThisDeviceOnly;
        CFTypeRef result;
        OSStatus status = SecItemCopyMatching((__bridge CFDictionaryRef)query, &result);

        if (status == errSecSuccess)
        {
            // keychain item exists
            NSDictionary *values = CFBridgingRelease(result);
            if (!values) return nil;
            _initialLaunchDate = values[(__bridge id)kSecAttrCreationDate];
            _isInitialLaunch = NO;
        }
        else
        {
            // no keychain item
            _initialLaunchDate = NSDate.date;
            query[(__bridge id)kSecAttrCreationDate] = _initialLaunchDate;
            status = SecItemAdd((__bridge CFDictionaryRef)query, 0);
            _isInitialLaunch = YES;
        }

        [self resetToDefaults];
        _isInstallLaunch = (_installLaunchDate) ? NO : YES;
        _isUpdateLaunch = ![_lastVersion isEqualToString:NSBundle.mainBundle.infoDictionary[@"CFBundleShortVersionString"]];
    }
    return self;
}

- (void)willResume:(NSNotification *)notification
{
    [self update];
    [[RSDKAnalyticsEvent.alloc initWithName:RSDKAnalyticsSessionStartEventName parameters:nil] track];
}

- (void)didSuspend:(NSNotification *)notification
{
    [[RSDKAnalyticsEvent.alloc initWithName:RSDKAnalyticsSessionEndEventName parameters:nil] track];
}

- (void)didLaunch:(NSNotification *)notification
{
    [self update];

    // Equivalent to installation or reinstallation. Also triggers a session start.
    if (_isInitialLaunch)
    {
        [[RSDKAnalyticsEvent.alloc initWithName:RSDKAnalyticsInitialLaunchEventName parameters:nil] track];
        [[RSDKAnalyticsEvent.alloc initWithName:RSDKAnalyticsSessionStartEventName parameters:nil] track];
        _isInitialLaunch = NO;
        return;
    }

    // Triggered on first run after app install with or without version change. Also triggers a session start.
    if (_isInstallLaunch)
    {
        [[RSDKAnalyticsEvent.alloc initWithName:RSDKAnalyticsInstallEventName parameters:nil] track];
        [[RSDKAnalyticsEvent.alloc initWithName:RSDKAnalyticsSessionStartEventName parameters:nil] track];
        _isInstallLaunch = NO;
        return;
    }

    // Triggered on first run after upgrade (anytime the version number changes). Also triggers a session start.
    if (_isUpdateLaunch)
    {
        [[RSDKAnalyticsEvent.alloc initWithName:RSDKAnalyticsInstallEventName parameters:nil] track];
        [[RSDKAnalyticsEvent.alloc initWithName:RSDKAnalyticsApplicationUpdateEventName parameters:nil] track];
        [[RSDKAnalyticsEvent.alloc initWithName:RSDKAnalyticsSessionStartEventName parameters:nil] track];
        _isUpdateLaunch = NO;
        return;
    }
}

- (void)didVisitPage:(UIViewController *)page
{
    if (_currentPage)
    {
        _RSDKAnalyticsLaunchCollector.sharedInstance.lastVisitedPage = _currentPage;
    }
    _currentPage = page;
    [[RSDKAnalyticsEvent.alloc initWithName:RSDKAnalyticsPageVisitEventName parameters:nil] track];

    // For push event, after the _rem_visit event is triggered, a _rem_push_notify event will be triggered.
    if (_origin == RSDKAnalyticsPushOrigin)
    {
        [self triggerPushEvent];
    }
    // Reset the origin to RSDKAnalyticsInternalOrigin for the next page visit after each external call or push notification.
    _origin = RSDKAnalyticsInternalOrigin;
}

- (void)triggerPushEvent
{
    if (_pushTrackingIdentifier.length)
    {
        [[RSDKAnalyticsEvent.alloc initWithName:RSDKAnalyticsPushNotificationEventName parameters:@{RSDKAnalyticPushNotificationTrackingIdentifierParameter:_pushTrackingIdentifier}] track];
    }
}

- (void)processPushNotificationPayload:(NSDictionary *)userInfo
{
    // Compute push tracking identifier
    NSMutableDictionary *filterResult = NSMutableDictionary.new;
    _RSDKAnalyticsTraverseObjectWithSearchKeys(userInfo, @[@"rid", @"notification_id", @"message", @"title"], filterResult);

    NSString *pushTrackingIdentifier = nil;
    if (_RSDKAnalyticsStringWithObject(filterResult[@"rid"]).length)
    {
        pushTrackingIdentifier = [NSString stringWithFormat:@"rid:%@",_RSDKAnalyticsStringWithObject(filterResult[@"rid"])];
    }
    else if (_RSDKAnalyticsStringWithObject(filterResult[@"notification_id"]).length)
    {
        pushTrackingIdentifier = [NSString stringWithFormat:@"nid:%@",_RSDKAnalyticsStringWithObject(filterResult[@"notification_id"])];
    }
    else if (_RSDKAnalyticsStringWithObject(filterResult[@"message"]).length)
    {
        pushTrackingIdentifier = [NSString stringWithFormat:@"msg:%@",_RSDKAnalyticsStringWithObject(filterResult[@"message"])];
    }
    else if (_RSDKAnalyticsStringWithObject(filterResult[@"title"]).length)
    {
        pushTrackingIdentifier = [NSString stringWithFormat:@"msg:%@",_RSDKAnalyticsStringWithObject(filterResult[@"title"])];
    }

    _pushTrackingIdentifier = pushTrackingIdentifier;

    // If the app is already in foreground before user tap on the notification, emit a _rem_push_notify right away. The next _rem_visit event will not have a push type.
    UIApplicationState state = [UIApplication sharedApplication].applicationState;
    if (state == UIApplicationStateActive)
    {
        // emit push_event
        [_RSDKAnalyticsLaunchCollector.sharedInstance triggerPushEvent];
    }
    else
    {
        // set the origin to push type for the next _rem_visit event
        _RSDKAnalyticsLaunchCollector.sharedInstance.origin = RSDKAnalyticsPushOrigin;
    }
}

- (void)resetToDefaults
{
    NSUserDefaults* defaults = NSUserDefaults.standardUserDefaults;

    id object = [defaults objectForKey:_RSDKAnalyticsInstallLaunchDateKey];
    _installLaunchDate = [object isKindOfClass:NSDate.class] ? object : nil;

    object = [defaults objectForKey:_RSDKAnalyticsLastUpdateDateKey];
    _lastUpdateDate = [object isKindOfClass:NSDate.class] ? object : nil;

    object = [defaults objectForKey:_RSDKAnalyticsLastLaunchDateKey];
    _lastLaunchDate = [object isKindOfClass:NSDate.class] ? object : nil;

    _lastVersion = [defaults stringForKey:_RSDKAnalyticsLastVersionKey];

    object = [defaults objectForKey:_RSDKAnalyticsLastVersionLaunchesKey];
    _lastVersionLaunches = [object isKindOfClass:NSNumber.class] ? [(NSNumber*)object unsignedIntegerValue] : 0;
}

- (void)update
{
    [self resetToDefaults];

    // Update values for the next run
    NSDate *now = NSDate.date;
    NSString *currentVersion = NSBundle.mainBundle.infoDictionary[@"CFBundleShortVersionString"];
    NSUserDefaults* defaults = NSUserDefaults.standardUserDefaults;

    if (!_isInitialLaunch && !_installLaunchDate)
    {
        _isInstallLaunch = YES;
        [defaults setObject:now forKey:_RSDKAnalyticsInstallLaunchDateKey];
    }
    if (![_lastVersion isEqualToString:currentVersion])
    {
        _isUpdateLaunch = YES;
        [defaults setObject:currentVersion forKey:_RSDKAnalyticsLastVersionKey];
        [defaults setObject:now forKey:_RSDKAnalyticsLastUpdateDateKey];
        [defaults setInteger:1 forKey:_RSDKAnalyticsLastVersionLaunchesKey];
    }
    else
    {
        _lastVersionLaunches += 1;
        [defaults setObject:@(_lastVersionLaunches) forKey:_RSDKAnalyticsLastVersionLaunchesKey];
    }
    [defaults setObject:now forKey:_RSDKAnalyticsLastLaunchDateKey];
    [defaults synchronize];
}

@end
