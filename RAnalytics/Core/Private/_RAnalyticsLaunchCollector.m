#import <CommonCrypto/CommonDigest.h>
#import <RAnalytics/RAnalyticsEvent.h>
#import "_RAnalyticsLaunchCollector.h"
#import "_RAnalyticsHelpers.h"
#import <UserNotifications/UserNotifications.h>
#import "RAnalyticsPushTrackingUtility.h"
#import "_RAnalyticsClassManipulator+UNUserNotificationCenter.h"

static NSString *const _RAnalyticsInitialLaunchDateKey = @"com.rakuten.esd.sdk.properties.analytics.launchInformation.initialLaunchDate";
static NSString *const _RAnalyticsInstallLaunchDateKey = @"com.rakuten.esd.sdk.properties.analytics.launchInformation.installLaunchDate";
static NSString *const _RAnalyticsLastUpdateDateKey = @"com.rakuten.esd.sdk.properties.analytics.launchInformation.lastUpdateDate";
static NSString *const _RAnalyticsLastLaunchDateKey = @"com.rakuten.esd.sdk.properties.analytics.launchInformation.lastLaunchDate";
static NSString *const _RAnalyticsLastVersionKey = @"com.rakuten.esd.sdk.properties.analytics.launchInformation.lastVersion";
static NSString *const _RAnalyticsLastVersionLaunchesKey = @"com.rakuten.esd.sdk.properties.analytics.launchInformation.lastVersionLaunches";
static NSTimeInterval const _RAnalyticsPushTapEventTimeLimit = 0.75;

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
@property (nonatomic, nullable) NSDate *pushTapTrackingDate;
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
                                                 selector:@selector(didBecomeActive:)
                                                     name:UIApplicationDidBecomeActiveNotification
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

#pragma mark - App Life Cycle Observers

- (void)willResume:(NSNotification *)notification
{
    [self update];
    [[RAnalyticsEvent.alloc initWithName:RAnalyticsSessionStartEventName parameters:nil] track];
}

- (void)didSuspend:(NSNotification *)notification
{
    [[RAnalyticsEvent.alloc initWithName:RAnalyticsSessionEndEventName parameters:nil] track];
}

- (void)didBecomeActive:(NSNotification *) notification
{
    [self _sendTapNonUNUserNotification];
}

- (void)didLaunch:(NSNotification *) notification
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

#pragma mark - Push Notification

- (void)handleTapNonUNUserNotification: (NSDictionary *) userInfo
                              appState: (UIApplicationState) state
{
    if (_RAnalyticsNotificationsAreHandledByUNDelegate())
    {
        return;
    }
    
    switch (state) {
        case UIApplicationStateBackground:
        case UIApplicationStateInactive:
            _pushTrackingIdentifier = [RAnalyticsPushTrackingUtility trackingIdentifierFromPayload:userInfo];
            _pushTapTrackingDate = [NSDate date];
            break;
        default:
            break;
    }
}

- (void)_sendTapNonUNUserNotification
{
    if (_RAnalyticsNotificationsAreHandledByUNDelegate())
    {
        return;
    }
    
    if (_pushTapTrackingDate != nil &&
        _pushTrackingIdentifier != nil &&
        (fabs(_pushTapTrackingDate.timeIntervalSinceNow) < _RAnalyticsPushTapEventTimeLimit) &&
        ![RAnalyticsPushTrackingUtility analyticsEventHasBeenSentWith:_pushTrackingIdentifier])
    {
        [[RAnalyticsEvent.alloc initWithName:RAnalyticsPushNotificationEventName
                                  parameters:@{RAnalyticsPushNotificationTrackingIdentifierParameter:_pushTrackingIdentifier}] track];
    }
    _pushTrackingIdentifier = nil;
    _pushTapTrackingDate = nil;
}

- (void)processPushNotificationResponse: (UNNotificationResponse*) notificationResponse
{
    UNNotificationTrigger * _Nullable trigger = notificationResponse.notification.request.trigger;
    if (!trigger ||
        ![trigger isKindOfClass:UNPushNotificationTrigger.class]) {
        return;
    }
    
    NSString * _Nullable userText = nil;
    
    if ([trigger isKindOfClass:UNTextInputNotificationResponse.class] &&
        ((UNTextInputNotificationResponse*)trigger).userText.length > 0)
    {
        userText = ((UNTextInputNotificationResponse*)trigger).userText;
    }
    
    [self processPushNotificationPayload:notificationResponse.notification.request.content.userInfo
                              userAction:notificationResponse.actionIdentifier
                                userText:userText];
    
}

- (void)processPushNotificationPayload: (NSDictionary *) userInfo
                            userAction: (NSString *__nullable) userAction
                              userText: (NSString *__nullable) userText
{
    NSString * _Nullable trackingId = [RAnalyticsPushTrackingUtility trackingIdentifierFromPayload:userInfo];
    
    if (trackingId &&
        ![RAnalyticsPushTrackingUtility analyticsEventHasBeenSentWith:trackingId])
    {
        _pushTrackingIdentifier = trackingId;
        [[RAnalyticsEvent.alloc initWithName:RAnalyticsPushNotificationEventName
                                  parameters:@{RAnalyticsPushNotificationTrackingIdentifierParameter:trackingId}] track];
    }
    
    if (_RAnalyticsSharedApplication().applicationState != UIApplicationStateActive)
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
