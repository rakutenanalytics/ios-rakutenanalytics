/*
 * © Rakuten, Inc.
 * authors: "Rakuten Ecosystem Mobile" <ecosystem-mobile@mail.rakuten.com>
 */
#import <RSDKAnalytics/RSDKAnalyticsEvent.h>
#import "_RSDKAnalyticsLaunchCollector.h"
#import "_RSDKAnalyticsHelpers.h"

#import <CommonCrypto/CommonDigest.h>

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

- (void)didPresentViewController:(UIViewController *)viewController
{
    /*
     * Only consider as "pages" view controllers that are not known shells used
     * only for presenting other view controllers:
     */
    if ([viewController isKindOfClass:[UINavigationController class]] ||
        [viewController isKindOfClass:[UISplitViewController class]] ||
        [viewController isKindOfClass:[UIPageViewController class]])
    {
        return;
    }

    if (_currentPage)
    {
        self.lastVisitedPage = _currentPage;
    }
    _currentPage = viewController;
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
                            userAction:(NSString *)userAction
                              userText:(NSString *)userText
{
    // Compute push tracking identifier
    NSMutableDictionary *values = NSMutableDictionary.new;
    _RSDKAnalyticsTraverseObjectWithSearchKeys(userInfo, @[@"rid", @"notification_id", @"message", @"title"], values);

    NSString *value;
    if ((value = _RSDKAnalyticsStringWithObject(values[@"rid"])))
    {
        _pushTrackingIdentifier = [NSString stringWithFormat:@"rid:%@", value];
    }
    else if ((value = _RSDKAnalyticsStringWithObject(values[@"notification_id"])))
    {
        _pushTrackingIdentifier = [NSString stringWithFormat:@"nid:%@", value];
    }
    else if ((value = _RSDKAnalyticsStringWithObject(values[@"message"]) ?: _RSDKAnalyticsStringWithObject(values[@"title"])))
    {
        NSData *data = [value dataUsingEncoding:NSUTF8StringEncoding];
        NSMutableData *digest = [NSMutableData dataWithLength:CC_SHA256_DIGEST_LENGTH];
        CC_SHA256(data.bytes, (CC_LONG) data.length, digest.mutableBytes);

        NSMutableString *hexDigest = [NSMutableString stringWithCapacity:digest.length * 2];
        const unsigned char *bytes = digest.bytes;
        for (NSUInteger byteIndex = 0; byteIndex < digest.length; ++byteIndex) {
            [hexDigest appendFormat:@"%02x", (unsigned int) bytes[byteIndex]];
        }
        _pushTrackingIdentifier = [NSString stringWithFormat:@"msg:%@", hexDigest];
    }

    // TODO: track user action & text
    (void)userAction;
    (void)userText;

    // If the app is already in foreground before user tap on the notification, emit a _rem_push_notify right away. The next _rem_visit event will not have a push type.
    UIApplicationState state = [UIApplication sharedApplication].applicationState;
    if (state == UIApplicationStateActive || state == UIApplicationStateInactive)
    {
        // emit push_event
        [self triggerPushEvent];
    }
    else
    {
        // set the origin to push type for the next _rem_visit event
        self.origin = RSDKAnalyticsPushOrigin;
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
