@import Darwin.POSIX.sys;

#import <RDeviceIdentifier/RDeviceIdentifier.h>
#import <RAnalytics/RAnalytics.h>
#import <RLogger/RLogger.h>
#import "_RAnalyticsHelpers.h"
#import "_SDKTracker.h"
#import "SwiftHeader.h"
#import <WebKit/WebKit.h>

////////////////////////////////////////////////////////////////////////////

@interface RAnalyticsState ()
@property (nonatomic, readwrite, copy) NSString *sessionIdentifier;
@property (nonatomic, readwrite, copy) NSString *deviceIdentifier;
@property (nonatomic, readwrite, copy) NSString *currentVersion;
@property (nonatomic, nullable, readwrite, copy) CLLocation *lastKnownLocation;
@property (nonatomic, nullable, readwrite, copy) NSString *advertisingIdentifier;
@property (nonatomic, nullable, readwrite, copy) NSDate *sessionStartDate;
@property (nonatomic, readwrite) BOOL loggedIn;
@property (nonatomic, readwrite, copy) NSString *userIdentifier;
@property (nonatomic) RAnalyticsLoginMethod loginMethod;
@property (nonatomic, readwrite) RAnalyticsOrigin origin;
@property (nonatomic, nullable, readwrite, copy) NSString *lastVersion;
@property (nonatomic) NSUInteger lastVersionLaunches;
@property (nonatomic, nullable, readwrite, copy) NSDate *initialLaunchDate;
@property (nonatomic, nullable, readwrite, copy) NSDate *installLaunchDate;
@property (nonatomic, nullable, readwrite, copy) NSDate *lastLaunchDate;
@property (nonatomic, nullable, readwrite, copy) NSDate *lastUpdateDate;
@property (nonatomic, nullable, readwrite) UIViewController *currentPage;
@end

@interface RAnalyticsManager()<CLLocationManagerDelegate>
@property (nonatomic, strong) CLLocationManager *locationManager;
@property (nonatomic) BOOL locationManagerIsUpdating;
@property (nonatomic, nullable, copy) NSString *deviceIdentifier;

/*
 * Session cookie. We use an UUID automatically created at startup and
 * regenerated when the app comes back from background, as per the
 * specifications.
 */
@property(nonatomic, copy) NSString *sessionCookie;
@property (nonatomic, copy) NSDate *sessionStartDate;
@property(nonatomic, strong) NSMutableSet<id<RAnalyticsTracker>> *trackers;
@property (nonatomic, copy) WebTrackingCookieDomainBlock cookieDomainBlock;
@property (nonatomic, strong) AnyDependenciesContainer *dependenciesContainer;
@property (nonatomic, strong) RAdvertisingIdentifierHandler *advertisingIdentifierHandler;
@property (nonatomic, strong) RAnalyticsCookieInjector *analyticsCookieInjector;
@property (nonatomic, strong) EventChecker *eventChecker;
@property (nonatomic, strong) RAnalyticsLaunchCollector *analyticsLaunchCollector;
@property (nonatomic, strong) RAnalyticsExternalCollector *analyticsExternalCollector;
@property (nonatomic, strong) UserIdentifierSelector *userIdentifierSelector;

- (instancetype)initSharedInstance;
@end

////////////////////////////////////////////////////////////////////////////

@implementation RAnalyticsManager

#pragma mark - Class methods

static RAnalyticsManager *_instance = nil;

+ (void)load
{
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        _instance = [self.alloc initSharedInstance];
    });
}

//--------------------------------------------------------------------------

+ (instancetype)sharedInstance
{
    return _instance;
}

#pragma mark - Object life cycle

- (instancetype)init
{
    [self doesNotRecognizeSelector:_cmd];
    __builtin_unreachable();
}

//--------------------------------------------------------------------------

- (instancetype)initSharedInstance
{
    if ((self = [super init]))
    {
        // Dependencies Container
        _dependenciesContainer = AnyDependenciesContainer.new;
        [_dependenciesContainer registerObject:NSNotificationCenter.defaultCenter];
        [_dependenciesContainer registerObject:NSUserDefaults.standardUserDefaults];
        [_dependenciesContainer registerObject:ASIdentifierManager.sharedManager];
        [_dependenciesContainer registerObject:WKWebsiteDataStore.defaultDataStore.httpCookieStore];
        [_dependenciesContainer registerObject:KeychainHandler.new];
        [_dependenciesContainer registerObject:AnalyticsTracker.new];

        // Inject the Dependencies Container
        _analyticsExternalCollector = [[RAnalyticsExternalCollector alloc] initWithDependenciesFactory:_dependenciesContainer];
        _analyticsLaunchCollector = [[RAnalyticsLaunchCollector alloc] initWithDependenciesFactory:_dependenciesContainer];
        
        if (!_analyticsExternalCollector ||
            !_analyticsLaunchCollector)
        {
            NSAssert(NO, @"Failed to initialize the %@ singleton", NSStringFromClass(self.class));
            return nil;
        }

        _shouldTrackLastKnownLocation     = YES;
        _shouldTrackAdvertisingIdentifier = YES;
        _shouldTrackPageView              = YES;

        // Inject the Dependencies Container
        _advertisingIdentifierHandler = [[RAdvertisingIdentifierHandler alloc] initWithDependenciesFactory:_dependenciesContainer];
        _analyticsCookieInjector = [[RAnalyticsCookieInjector alloc] initWithDependenciesFactory:_dependenciesContainer];
        _eventChecker = [[EventChecker alloc] initWithDisabledEventsAtBuildTime:[NSBundle disabledEventsAtBuildTime]];
        _userIdentifierSelector = [UserIdentifierSelector.alloc initWithUserIdentifiable:_analyticsExternalCollector];

        _trackers = [NSMutableSet set];
        [self addTracker:_SDKTracker.sharedInstance];

#if __has_include(<RAnalytics/RAnalyticsRATTracker.h>)
        // Due to https://github.com/CocoaPods/CocoaPods/issues/2774 we can't
        // always rely solely on header availability so we also do a runtime check

        Class ratTrackerClass = NSClassFromString(@"RAnalyticsRATTracker");
        SEL selector = NSSelectorFromString(@"sharedInstance");

        if ([ratTrackerClass respondsToSelector:selector])
        {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
            id ratTracker = [ratTrackerClass performSelector:selector];
            [self addTracker:ratTracker];
#pragma clang diagnostic pop
        }
#endif
        /*
         * Set up the location manager
         */

        _locationManager = CLLocationManager.new;
        _locationManager.desiredAccuracy = kCLLocationAccuracyKilometer;
        _locationManager.delegate = self;

        /*
         * Start a new session, and renew it every time the application goes back to the
         * foreground.
         */

        [self _startNewSession];

        NSNotificationCenter* notificationCenter = NSNotificationCenter.defaultCenter;

        [notificationCenter addObserver:self
                               selector:@selector(_startNewSession)
                                   name:UIApplicationDidBecomeActiveNotification
                                 object:nil];

        [notificationCenter addObserver:self
                               selector:@selector(_stopMonitoringLocationUnlessAlways)
                                   name:UIApplicationWillResignActiveNotification
                                 object:nil];
    }
    return self;
}

//--------------------------------------------------------------------------

- (void)dealloc
{
    [NSNotificationCenter.defaultCenter removeObserver:self];
    [self _stopMonitoringLocation];
}

//--------------------------------------------------------------------------

#pragma mark - Getters & setters
- (void)setShouldTrackLastKnownLocation:(BOOL)shouldTrackLastKnownLocation
{
    if (shouldTrackLastKnownLocation != _shouldTrackLastKnownLocation)
    {
        _shouldTrackLastKnownLocation = shouldTrackLastKnownLocation;

        // Update
        [self _startStopMonitoringLocationIfNeeded];
    }
}

- (void)setWebTrackingCookieDomainWithBlock:(WebTrackingCookieDomainBlock)cookieDomainBlock
{
    _cookieDomainBlock = cookieDomainBlock;
}

//--------------------------------------------------------------------------

#pragma mark - CLLocationManagerDelegate

// Only for iOS version <= 13.x
- (void)locationManager:(CLLocationManager * __unused)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status
{
    [self _startStopMonitoringLocationIfNeeded];
}

// Only for iOS version >= 14.0
- (void)locationManagerDidChangeAuthorization:(CLLocationManager *)manager
{
    [self _startStopMonitoringLocationIfNeeded];
}

- (void)locationManagerDidPauseLocationUpdates:(CLLocationManager * __unused)manager
{
    [RLogger verbose:@"Location updates paused."];
}

- (void)locationManagerDidResumeLocationUpdates:(CLLocationManager * __unused)manager
{
    [RLogger verbose:@"Location updates resumed."];
}

- (void)locationManager:(CLLocationManager * __unused)manager didFinishDeferredUpdatesWithError:(NSError *)error
{
    [RLogger error:@"Failed to acquire device location: %@", error.localizedDescription];
}

//--------------------------------------------------------------------------

#pragma mark - Logging Level method

- (void)setLoggingLevel:(RAnalyticsLoggingLevel)loggingLevel
{
    switch (loggingLevel)
    {
        case RAnalyticsLoggingLevelVerbose:
            RLogger.loggingLevel = RLoggingLevelVerbose;
            break;
        case RAnalyticsLoggingLevelDebug:
            RLogger.loggingLevel = RLoggingLevelDebug;
            break;
        case RAnalyticsLoggingLevelInfo:
            RLogger.loggingLevel = RLoggingLevelInfo;
            break;
        case RAnalyticsLoggingLevelWarning:
            RLogger.loggingLevel = RLoggingLevelWarning;
            break;
        case RAnalyticsLoggingLevelError:
            RLogger.loggingLevel = RLoggingLevelError;
            break;
        case RAnalyticsLoggingLevelNone:
            RLogger.loggingLevel = RLoggingLevelNone;
            break;
    }
}

#pragma mark - Endpoint

- (void)setEndpointURL:(NSURL * _Nullable)endpointURL
{
    [_trackers enumerateObjectsUsingBlock:^(id<RAnalyticsTracker>  _Nonnull tracker, BOOL * _Nonnull stop) {
        if ([tracker respondsToSelector:@selector(setEndpointURL:)]) {
            [tracker setEndpointURL:endpointURL ?: _RAnalyticsEndpointAddress()];
        }
    }];
}

//--------------------------------------------------------------------------

#pragma mark - Private methods

- (void)_startStopMonitoringLocationIfNeeded
{
    CLAuthorizationStatus status = CLLocationManager.authorizationStatus;

#if DEBUG
    static CLAuthorizationStatus lastStatus = -1;
    BOOL updated = NO;
    @synchronized(self)
    {
        updated = status != lastStatus;
        if (updated)
        {
            lastStatus = status;
        }
    }

    if (updated)
    {
        NSString *statusString;
        switch (status)
        {
            case kCLAuthorizationStatusNotDetermined:       statusString = @"Not Determined";         break;
            case kCLAuthorizationStatusRestricted:          statusString = @"Restricted";             break;
            case kCLAuthorizationStatusDenied:              statusString = @"Denied";                 break;
            case kCLAuthorizationStatusAuthorizedAlways:    statusString = @"Authorized Always";      break;
            case kCLAuthorizationStatusAuthorizedWhenInUse: statusString = @"Authorized When In Use"; break;
            default: statusString = [NSString stringWithFormat:@"Value (%i)", status];
        }
        [RLogger debug:@"Location services' authorization status changed to [%@].", statusString];
    }
#endif

    if (self.shouldTrackLastKnownLocation &&
        CLLocationManager.locationServicesEnabled &&
        (status == kCLAuthorizationStatusAuthorizedAlways ||
        (status == kCLAuthorizationStatusAuthorizedWhenInUse && _RAnalyticsSharedApplication().applicationState == UIApplicationStateActive)
        ))
    {
        [self _startMonitoringLocation];
    }
    else
    {
        [self _stopMonitoringLocation];
    }
}

- (void)_startMonitoringLocation
{
    if (self.locationManagerIsUpdating)
    {
        // Nothing to do.
        return;
    }

    [RLogger verbose:@"Start monitoring location"];
    [self.locationManager startUpdatingLocation];
    self.locationManagerIsUpdating = YES;
}

- (void)_stopMonitoringLocation
{
    if (!self.locationManagerIsUpdating)
    {
        // Nothing to do.
        return;
    }

    [RLogger verbose:@"Stop monitoring location"];
    [self.locationManager stopUpdatingLocation];
    self.locationManagerIsUpdating = NO;
}

#pragma mark - Should Track Event

- (void)setShouldTrackEventHandler:(RAnalyticsShouldTrackEventCompletionBlock)shouldTrackEventHandler
{
    _eventChecker.shouldTrackEventHandler = shouldTrackEventHandler;
}

- (RAnalyticsShouldTrackEventCompletionBlock)shouldTrackEventHandler
{
    return _eventChecker.shouldTrackEventHandler;
}

#pragma mark - Process Event

- (BOOL)process:(RAnalyticsEvent *)event
{
    if (![_eventChecker shouldProcess:event.name]) {
        return NO;
    }

    NSString *sessionIdentifier = self.sessionCookie;
    if (!_deviceIdentifier)
    {
        @try
        {
            _deviceIdentifier = RDeviceIdentifier.uniqueDeviceIdentifier;
        }
        @catch (NSException *__unused exception) { }
    }
    if (!_deviceIdentifier)
    {
        [RLogger error:@"RDeviceIdentifier is not properly configured! See 'Configuring the keychain' in the README for instructions"];
    }

    RAnalyticsState *state = [RAnalyticsState.alloc initWithSessionIdentifier:sessionIdentifier
                                                                   deviceIdentifier:_deviceIdentifier];

    if (_shouldTrackAdvertisingIdentifier) {
        NSString *advertisingIdentifier = _advertisingIdentifierHandler.idfa;

        if (advertisingIdentifier) {
            // User has not disabled tracking
            state.advertisingIdentifier = advertisingIdentifier;
        }
    }

    if (_enableAppToWebTracking) {
        NSString *domain = nil;
        if (_cookieDomainBlock) {
            domain = _cookieDomainBlock();
        }

        [_analyticsCookieInjector injectAppToWebTrackingCookieWithDomain:domain
                                                        deviceIdentifier:_deviceIdentifier
                                                       completionHandler:nil];
    }

    state.lastKnownLocation = self.shouldTrackLastKnownLocation ? self.locationManager.location : nil;
    state.sessionStartDate = self.sessionStartDate ?: nil;

    // Update state with data from external collector
    state.userIdentifier = _userIdentifierSelector.selectedTrackingIdentifier;
    state.loginMethod = _analyticsExternalCollector.loginMethod;
    state.loggedIn = _analyticsExternalCollector.isLoggedIn;

    // Update state with data from launch collector
    RAnalyticsLaunchCollector *launchCollector = _analyticsLaunchCollector;
    state.initialLaunchDate = launchCollector.initialLaunchDate;
    state.installLaunchDate = launchCollector.installLaunchDate;
    state.lastUpdateDate = launchCollector.lastUpdateDate;
    state.lastLaunchDate = launchCollector.lastLaunchDate;
    state.lastVersion = launchCollector.lastVersion;
    state.lastVersionLaunches = launchCollector.lastVersionLaunches;
    state.currentPage = launchCollector.currentPage;
    state.origin = launchCollector.origin;

    BOOL processed = NO;
    for (id<RAnalyticsTracker> tracker in self.trackers)
    {
        [RLogger debug:@"Using tracker %@", tracker];

        if ([tracker processEvent:event state:state])
        {
            processed = YES;
        }
    }
    if (!processed)
    {
        [RLogger debug:@"No tracker processed event %@", event.name];
    }
    return processed;
}

- (void)addTracker:(id<RAnalyticsTracker>)tracker
{
    @synchronized(self)
    {
        if (![_trackers containsObject:tracker])
        {
            [_trackers addObject:tracker];
            [RLogger debug:@"Added tracker %@", tracker];
        }
    }
}

- (void)setUserIdentifier:(NSString * _Nullable)userID
{
    _analyticsExternalCollector.userIdentifier = userID;
}

//--------------------------------------------------------------------------

- (void)_startNewSession
{
    self.sessionCookie = NSUUID.UUID.UUIDString;
    self.sessionStartDate = [NSDate date];

    /*
     * Resume location updates if needed.
     */

    [self _startStopMonitoringLocationIfNeeded];
}

//--------------------------------------------------------------------------

- (void)_stopMonitoringLocationUnlessAlways
{
    if (CLLocationManager.authorizationStatus != kCLAuthorizationStatusAuthorizedAlways)
    {
        [self _stopMonitoringLocation];
    }
}

@end
