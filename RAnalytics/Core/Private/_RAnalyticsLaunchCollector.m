#import <CommonCrypto/CommonDigest.h>
#import <RAnalytics/RAnalyticsEvent.h>
#import "_RAnalyticsLaunchCollector.h"
#import "_RAnalyticsHelpers.h"

static NSString *const _RAnalyticsInitialLaunchDateKey = @"com.rakuten.esd.sdk.properties.analytics.launchInformation.initialLaunchDate";
static NSString *const _RAnalyticsInstallLaunchDateKey = @"com.rakuten.esd.sdk.properties.analytics.launchInformation.installLaunchDate";
static NSString *const _RAnalyticsLastUpdateDateKey = @"com.rakuten.esd.sdk.properties.analytics.launchInformation.lastUpdateDate";
static NSString *const _RAnalyticsLastLaunchDateKey = @"com.rakuten.esd.sdk.properties.analytics.launchInformation.lastLaunchDate";
static NSString *const _RAnalyticsLastVersionKey = @"com.rakuten.esd.sdk.properties.analytics.launchInformation.lastVersion";
static NSString *const _RAnalyticsLastVersionLaunchesKey = @"com.rakuten.esd.sdk.properties.analytics.launchInformation.lastVersionLaunches";

@interface _RAnalyticsLaunchCollector ()
@property (nonatomic, nullable, readwrite, copy) NSDate *initialLaunchDate;
@property (nonatomic, nullable, readwrite, copy) NSDate *installLaunchDate;
@property (nonatomic, nullable, readwrite, copy) NSDate *lastUpdateDate;
@property (nonatomic, nullable, readwrite, copy) NSDate *lastLaunchDate;
@property (nonatomic, nullable, readwrite, copy) NSString *lastVersion;
@property (nonatomic, readwrite) NSUInteger lastVersionLaunches;
@property (nonatomic, readwrite) BOOL isInitialLaunch;
@property (nonatomic, readwrite) BOOL isInstallLaunch;
@property (nonatomic, readwrite) BOOL isUpdateLaunch;
@property (nonatomic, readwrite) RAnalyticsOrigin origin;
@property (nonatomic, nullable, readwrite) UIViewController *currentPage;
@property (nonatomic, nullable, readwrite, copy) NSString *pushTrackingIdentifier;
@end

@implementation _RAnalyticsLaunchCollector

+ (instancetype)sharedInstance
{
    static _RAnalyticsLaunchCollector *instance = nil;
    static dispatch_once_t _RAnalyticsLaunchCollectorOnceToken;
    dispatch_once(&_RAnalyticsLaunchCollectorOnceToken, ^{
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
        query[(__bridge id)kSecAttrLabel]   = _RAnalyticsInitialLaunchDateKey;
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
    [[RAnalyticsEvent.alloc initWithName:RAnalyticsSessionStartEventName parameters:nil] track];
}

- (void)didSuspend:(NSNotification *)notification
{
    [[RAnalyticsEvent.alloc initWithName:RAnalyticsSessionEndEventName parameters:nil] track];
}

- (void)didLaunch:(NSNotification *)notification
{
    [self update];

    // Equivalent to installation or reinstallation.
    if (_isInitialLaunch)
    {
        [[RAnalyticsEvent.alloc initWithName:RAnalyticsInitialLaunchEventName parameters:nil] track];
        _isInitialLaunch = NO;
    }

    // Triggered on first run after app install with or without version change.
    else if (_isInstallLaunch)
    {
        [[RAnalyticsEvent.alloc initWithName:RAnalyticsInstallEventName parameters:nil] track];
        _isInstallLaunch = NO;
    }

    // Triggered on first run after upgrade (anytime the version number changes).
    else if (_isUpdateLaunch)
    {
        [[RAnalyticsEvent.alloc initWithName:RAnalyticsInstallEventName parameters:nil] track];
        [[RAnalyticsEvent.alloc initWithName:RAnalyticsApplicationUpdateEventName parameters:nil] track];
        _isUpdateLaunch = NO;
    }

    // Trigger a session start.
    [[RAnalyticsEvent.alloc initWithName:RAnalyticsSessionStartEventName parameters:nil] track];

    // Track the credentials status.
    NSDictionary *parameters = @{@"strategies":@{@"password-manager":[self isPasswordExtensionAvailable] ? @"true" : @"false"}};
    [[RAnalyticsEvent.alloc initWithName:RAnalyticsCredentialStrategiesEventName parameters:parameters] track];
}

- (void)didPresentViewController:(UIViewController *)viewController
{
    UIView   *view   = viewController.view;
    UIWindow *window = view.window;

    /*
     * Don't treat as pages view controllers known to be just
     * content-less chromes around other view controllers.
     * Note: won't catch third-party content-less containers.
     */
    if ([viewController isKindOfClass:[UINavigationController class]] ||
        [viewController isKindOfClass:[UISplitViewController class]] ||
        [viewController isKindOfClass:[UIPageViewController class]] ||
        [viewController isKindOfClass:[UITabBarController class]])
    {
        return;
    }
    
    /*
     * Don't treat system popups as pages.
     */
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated"
    if ([view isKindOfClass:UIAlertView.class] ||
        [view isKindOfClass:UIActionSheet.class] ||
        ([UIAlertController class] && [viewController isKindOfClass:[UIAlertController class]]))
    {
        return;
    }
#pragma clang diagnostic pop

    /*
     * Don't treat private classes as pages if they come from system frameworks.
     * Note: Won't catch private class not adhering to the _ prefix standard.
     */
    if (_RAnalyticsIsApplePrivateClass(viewController.class) ||
        _RAnalyticsIsApplePrivateClass(view.class) ||
        _RAnalyticsIsApplePrivateClass(window.class))
    {
        return;
    }

    /*
     * Allow UIWindow subclasses except those from system frameworks
     * (so that view controllers presented in e.g. UITextEffectWindow are not
     * counting as pages).
     * This catches most keyboard windows.
     */
    if (![window isMemberOfClass:UIWindow.class] && _RAnalyticsIsAppleClass(window.class))
    {
        return;
    }

    /*
     * Keep a strong reference to the view controller in the launch collector only for the
     * time the event is being processed. Note that it will be carried on by the analytics
     * manager state, too.
     */
    _currentPage = viewController;
    [[RAnalyticsEvent.alloc initWithName:RAnalyticsPageVisitEventName parameters:nil] track];
    _currentPage = nil;

    /*
     * Reset the origin to RAnalyticsInternalOrigin for the next page visit after each external
     * call or push notification.
     */
    _origin = RAnalyticsInternalOrigin;
}

- (void)triggerPushEvent
{
    if (_pushTrackingIdentifier.length)
    {
        [[RAnalyticsEvent.alloc initWithName:RAnalyticsPushNotificationEventName parameters:@{RAnalyticsPushNotificationTrackingIdentifierParameter:_pushTrackingIdentifier}] track];
    }
}

- (void)processPushNotificationPayload:(NSDictionary *)userInfo
                            userAction:(NSString *)userAction
                              userText:(NSString *)userText
{
    id aps = userInfo[@"aps"];
    if (![aps isKindOfClass:NSDictionary.class]) aps = nil;

    /*
     * First, look for a string at .rid
     */
    NSString *rid = userInfo[@"rid"];
    if ([rid isKindOfClass:NSString.class])
    {
        _pushTrackingIdentifier = [NSString stringWithFormat:@"rid:%@", rid];
    }
    else
    {
        /*
         * If not found, look for a string at .notification_id
         */
        NSString *nid = userInfo[@"notification_id"];
        if ([nid isKindOfClass:NSString.class])
        {
            _pushTrackingIdentifier = [NSString stringWithFormat:@"nid:%@", nid];
        }
        else
        {
            /*
             * Otherwise, fallback to .aps.alert if that's a string, or, if that's
             * a dictionary, for either .aps.alert.body or .aps.alert.title
             */
            NSString *msg = aps[@"alert"];
            if ([msg isKindOfClass:NSDictionary.class])
            {
                id content = (id)msg;
                msg = content[@"body"] ?: content[@"title"];
            }

            if (![msg isKindOfClass:NSString.class])
            {
                // Could not determine a tracking id, so bailing out…
                return;
            }

            NSData *data = [msg dataUsingEncoding:NSUTF8StringEncoding];
            NSMutableData *digest = [NSMutableData dataWithLength:CC_SHA256_DIGEST_LENGTH];
            CC_SHA256(data.bytes, (CC_LONG) data.length, digest.mutableBytes);

            NSMutableString *hexDigest = [NSMutableString stringWithCapacity:digest.length * 2];
            const unsigned char *bytes = digest.bytes;
            for (NSUInteger byteIndex = 0; byteIndex < digest.length; ++byteIndex) {
                [hexDigest appendFormat:@"%02x", (unsigned int) bytes[byteIndex]];
            }
            _pushTrackingIdentifier = [NSString stringWithFormat:@"msg:%@", hexDigest];
        }
    }

    // TODO: track user action & text
    (void)userAction;
    (void)userText;

    /*
     * If the app is already in foreground (state is active or inactive), emit a _rem_push_notify right away.
     * And if user tap on the notification, the state of application changes from background to inactive. 
     * In this case, the origin will be set to push. 
     * And the next _rem_visit event will have a push type.
     */
    UIApplicationState state = _RAnalyticsSharedApplication().applicationState;
    if (state == UIApplicationStateActive || state == UIApplicationStateInactive)
    {
        // emit push_event
        [self triggerPushEvent];
    }
    if (state != UIApplicationStateActive)
    {
        // set the origin to push type for the next _rem_visit event
        self.origin = RAnalyticsPushOrigin;
    }
}

- (void)resetToDefaults
{
    NSUserDefaults* defaults = NSUserDefaults.standardUserDefaults;

    id object = [defaults objectForKey:_RAnalyticsInstallLaunchDateKey];
    _installLaunchDate = [object isKindOfClass:NSDate.class] ? object : nil;

    object = [defaults objectForKey:_RAnalyticsLastUpdateDateKey];
    _lastUpdateDate = [object isKindOfClass:NSDate.class] ? object : nil;

    object = [defaults objectForKey:_RAnalyticsLastLaunchDateKey];
    _lastLaunchDate = [object isKindOfClass:NSDate.class] ? object : nil;

    _lastVersion = [defaults stringForKey:_RAnalyticsLastVersionKey];

    object = [defaults objectForKey:_RAnalyticsLastVersionLaunchesKey];
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
        [defaults setObject:now forKey:_RAnalyticsInstallLaunchDateKey];
    }
    if (![_lastVersion isEqualToString:currentVersion])
    {
        _isUpdateLaunch = YES;
        [defaults setObject:currentVersion forKey:_RAnalyticsLastVersionKey];
        [defaults setObject:now forKey:_RAnalyticsLastUpdateDateKey];
        [defaults setInteger:1 forKey:_RAnalyticsLastVersionLaunchesKey];
    }
    else
    {
        _lastVersionLaunches += 1;
        [defaults setObject:@(_lastVersionLaunches) forKey:_RAnalyticsLastVersionLaunchesKey];
    }
    [defaults setObject:now forKey:_RAnalyticsLastLaunchDateKey];
    [defaults synchronize];
}

- (BOOL)isPasswordExtensionAvailable
{
    if ([NSExtensionItem class]) {
        NSArray*  schemes = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"LSApplicationQueriesSchemes"];
        if( schemes && [schemes isKindOfClass:NSArray.class]) {
            for ( NSString* scheme in schemes) {
                if([scheme isEqualToString:@"org-appextension-feature-password-management"]) {
                    return [_RAnalyticsSharedApplication() canOpenURL:[NSURL URLWithString:@"org-appextension-feature-password-management://"]];
                }
            }
        }
    }
    return NO;
}

@end
