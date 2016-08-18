/*
 * © Rakuten, Inc.
 * authors: "Rakuten Ecosystem Mobile" <ecosystem-mobile@mail.rakuten.com>
 */
#import "_RSDKAnalyticsLaunchCollector.h"
#import <RSDKAnalytics/RSDKAnalyticsEvent.h>
#import <RSDKAnalytics/RSDKAnalyticsRATTracker.h>

static NSString *const _RSDKAnalyticsInitialLaunchDateKey = @"com.rakuten.esd.sdk.properties.analytics.launchInformation.initialLaunchDate";
static NSString *const _RSDKAnalyticsInstallLaunchDateKey = @"com.rakuten.esd.sdk.properties.analytics.launchInformation.installLaunchDate";
static NSString *const _RSDKAnalyticsLastUpdateDateKey = @"com.rakuten.esd.sdk.properties.analytics.launchInformation.lastUpdateDate";
static NSString *const _RSDKAnalyticsLastLaunchDateKey = @"com.rakuten.esd.sdk.properties.analytics.launchInformation.lastLaunchDate";
static NSString *const _RSDKAnalyticsLastVersionKey = @"com.rakuten.esd.sdk.properties.analytics.launchInformation.lastVersion";
static NSString *const _RSDKAnalyticsLastVersionLaunchesKey = @"com.rakuten.esd.sdk.properties.analytics.launchInformation.lastVersionLaunches";

@interface _RSDKAnalyticsLaunchCollector ()
{
    RSDKAnalyticsRATTracker *_tracker;
}
@property (nonatomic, nullable, copy) NSDate *initialLaunchDate;
@property (nonatomic, nullable, copy) NSDate *installLaunchDate;
@property (nonatomic, nullable, copy) NSDate *lastUpdateDate;
@property (nonatomic, nullable, copy) NSDate *lastLaunchDate;
@property (nonatomic, nullable, copy) NSString *lastVersion;
@property (nonatomic) int64_t lastVersionLaunches;
@property (nonatomic) BOOL isInitialLaunch;
@property (nonatomic) BOOL isInstallLaunch;
@property (nonatomic) BOOL isUpdateLaunch;
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
        _tracker = RSDKAnalyticsRATTracker.sharedInstance;
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
            _initialLaunchDate = NSDate.new;
            query[(__bridge id)kSecAttrCreationDate] = _initialLaunchDate;
            status = SecItemAdd((__bridge CFDictionaryRef)query, 0);
            _isInitialLaunch = YES;
        }

        NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
        NSString *currentVersion = NSBundle.mainBundle.infoDictionary[@"CFBundleShortVersionString"];
        _installLaunchDate = [defaults objectForKey:_RSDKAnalyticsInstallLaunchDateKey];
        _lastUpdateDate = [defaults objectForKey:_RSDKAnalyticsLastUpdateDateKey];
        _lastLaunchDate = [defaults objectForKey:_RSDKAnalyticsLastLaunchDateKey];
        _lastVersion = [defaults stringForKey:_RSDKAnalyticsLastVersionKey];
        _lastVersionLaunches = [defaults integerForKey:_RSDKAnalyticsLastVersionLaunchesKey];
        _isInstallLaunch = (_installLaunchDate) ? NO : YES;
        _isUpdateLaunch = ![_lastVersion isEqualToString:currentVersion];
    }
    return self;
}

- (void)willResume:(NSNotification *)notification
{
    [self update];
    [[_tracker eventWithEventType:RSDKAnalyticSsessionStartEvent parameters:nil] track];
}

- (void)didSuspend:(NSNotification *)notification
{
    [[_tracker eventWithEventType:RSDKAnalyticSsessionEndEvent parameters:nil] track];
}

- (void)didLaunch:(NSNotification *)notification
{
    [self update];

    // Equivalent to installation or reinstallation. Also triggers a session start.
    if (_isInitialLaunch)
    {
        [[_tracker eventWithEventType:RSDKAnalyticsInitialLaunchEvent parameters:nil] track];
        _isInitialLaunch = NO;
        return;
    }

    // Triggered on first run after app install with or without version change. Also triggers a session start.
    if (_isInstallLaunch)
    {
        [[_tracker eventWithEventType:RSDKAnalyticInstallEvent parameters:nil] track];
        _isInstallLaunch = NO;
        return;
    }

    // Triggered on first run after upgrade (anytime the version number changes). Also triggers a session start.
    if (_isUpdateLaunch)
    {
        [[_tracker eventWithEventType:RSDKAnalyticInstallEvent parameters:nil] track];
        [[_tracker eventWithEventType:RSDKAnalyticApplicationUpdateEvent parameters:nil] track];
        _isUpdateLaunch = NO;
        return;
    }
}

- (void)update
{
    NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
    _installLaunchDate = [defaults objectForKey:_RSDKAnalyticsInstallLaunchDateKey];
    _lastUpdateDate = [defaults objectForKey:_RSDKAnalyticsLastUpdateDateKey];
    _lastLaunchDate = [defaults objectForKey:_RSDKAnalyticsLastLaunchDateKey];
    _lastVersion = [defaults stringForKey:_RSDKAnalyticsLastVersionKey];
    _lastVersionLaunches = [defaults integerForKey:_RSDKAnalyticsLastVersionLaunchesKey];

    // Update values for the next run
    NSDate *now = NSDate.new;
    NSString *currentVersion = NSBundle.mainBundle.infoDictionary[@"CFBundleShortVersionString"];
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
        [defaults setInteger:_lastVersionLaunches forKey:_RSDKAnalyticsLastVersionLaunchesKey];
    }
    [defaults setObject:now forKey:_RSDKAnalyticsLastLaunchDateKey];
    [defaults synchronize];
}

@end
