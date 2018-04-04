@import Darwin.POSIX.sys;

#import <AdSupport/AdSupport.h>
#import <RDeviceIdentifier/RDeviceIdentifier.h>
#import <RAnalytics/RAnalytics.h>
#import "_RAnalyticsHelpers.h"
#import "_RAnalyticsLaunchCollector.h"
#import "_RAnalyticsExternalCollector.h"
#import "_SDKTracker.h"

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
@property(nonatomic, strong) NSMutableSet RSDKA_GENERIC(id<RAnalyticsTracker>) *trackers;

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
        if (!_RAnalyticsExternalCollector.sharedInstance ||
            !_RAnalyticsLaunchCollector.sharedInstance)
        {
            NSAssert(NO, @"Failed to initialize the %@ singleton", NSStringFromClass(self.class));
            return nil;
        }

        _shouldTrackLastKnownLocation     = YES;
        _shouldTrackAdvertisingIdentifier = YES;

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

//--------------------------------------------------------------------------

#pragma mark - CLLocationManagerDelegate

- (void)locationManager:(CLLocationManager * __unused)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status
{
    [self _startStopMonitoringLocationIfNeeded];
}

- (void)locationManagerDidPauseLocationUpdates:(CLLocationManager * __unused)manager
{
    RAnalyticsDebugLog(@"Location updates paused.");
}

- (void)locationManagerDidResumeLocationUpdates:(CLLocationManager * __unused)manager
{
    RAnalyticsDebugLog(@"Location updates resumed.");
}

- (void)locationManager:(CLLocationManager * __unused)manager didFinishDeferredUpdatesWithError:(NSError *)error
{
    RAnalyticsErrorLog(@"Failed to acquire device location: %@", error.localizedDescription);
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
        RAnalyticsDebugLog(@"Location services' authorization status changed to [%@].", statusString);
    }
#endif

    if (/* self.shouldTrackLastKnownLocation && */
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

    RAnalyticsDebugLog(@"Start monitoring location");
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

    RAnalyticsDebugLog(@"Stop monitoring location");
    [self.locationManager stopUpdatingLocation];
    self.locationManagerIsUpdating = NO;
}

- (void)process:(RAnalyticsEvent *)event
{
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
        RAnalyticsErrorLog(@"RDeviceIdentifier is not properly configured!");
    }

    RAnalyticsState *state = [RAnalyticsState.alloc initWithSessionIdentifier:sessionIdentifier
                                                                   deviceIdentifier:_deviceIdentifier];
    if (_shouldTrackAdvertisingIdentifier && ASIdentifierManager.sharedManager.isAdvertisingTrackingEnabled)
    {
        NSString *idfa = ASIdentifierManager.sharedManager.advertisingIdentifier.UUIDString;
        if (idfa.length)
        {
            if ([idfa stringByReplacingOccurrencesOfString:@"[0\\-]"
                                                withString:@""
                                                   options:NSRegularExpressionSearch
                                                     range:NSMakeRange(0, idfa.length)].length)
            {
                // User has not disabled tracking
                state.advertisingIdentifier = idfa;
            }
        }
    }
    state.lastKnownLocation = self.shouldTrackLastKnownLocation ? self.locationManager.location : nil;
    state.sessionStartDate = self.sessionStartDate ?: nil;

    // Update state with data from external collector
    _RAnalyticsExternalCollector *externalCollector = _RAnalyticsExternalCollector.sharedInstance;
    state.userIdentifier = externalCollector.trackingIdentifier;
    state.loginMethod = externalCollector.loginMethod;
    state.loggedIn = externalCollector.isLoggedIn;

    // Update state with data from launch collector
    _RAnalyticsLaunchCollector *launchCollector = _RAnalyticsLaunchCollector.sharedInstance;
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
        RAnalyticsDebugLog(@"Using tracker %@", tracker);

        if ([tracker processEvent:event state:state])
        {
            processed = YES;
        }
    }
    if (!processed)
    {
        RAnalyticsDebugLog(@"No tracker processed event %@",event.name);
    }
}

- (void)addTracker:(id<RAnalyticsTracker>)tracker
{
    @synchronized(self)
    {
        if (![_trackers containsObject:tracker])
        {
            [_trackers addObject:tracker];
            RAnalyticsDebugLog(@"Added tracker %@", tracker);
        }
    }
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

