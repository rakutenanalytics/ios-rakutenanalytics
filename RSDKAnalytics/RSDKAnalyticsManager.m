/*
 * © Rakuten, Inc.
 * authors: "Rakuten Ecosystem Mobile" <ecosystem-mobile@mail.rakuten.com>
 */
@import Darwin.POSIX.sys;

#import <AdSupport/AdSupport.h>
#import <RSDKDeviceInformation/RSDKDeviceInformation.h>
#import <RSDKAnalytics/RSDKAnalytics.h>
#import "_RSDKAnalyticsHelpers.h"
#import "_RSDKAnalyticsLaunchCollector.h"
#import "_RSDKAnalyticsExternalCollector.h"

////////////////////////////////////////////////////////////////////////////

@interface RSDKAnalyticsState ()
@property (nonatomic, readwrite, copy) NSString *sessionIdentifier;
@property (nonatomic, readwrite, copy) NSString *deviceIdentifier;
@property (nonatomic, readwrite, copy) NSString *currentVersion;
@property (nonatomic, nullable, readwrite, copy) CLLocation *lastKnownLocation;
@property (nonatomic, nullable, readwrite, copy) NSString *advertisingIdentifier;
@property (nonatomic, nullable, readwrite, copy) NSDate *sessionStartDate;
@property (nonatomic, readwrite) BOOL loggedIn;
@property (nonatomic, readwrite, copy) NSString *userIdentifier;
@property (nonatomic) RSDKAnalyticsLoginMethod loginMethod;
@property (nonatomic, nullable, readwrite, copy) NSString *linkIdentifier;
@property (nonatomic, readwrite) RSDKAnalyticsOrigin origin;
@property (nonatomic, nullable, readwrite) UIViewController *lastVisitedPage;
@property (nonatomic, nullable, readwrite) UIViewController *currentPage;
@property (nonatomic, nullable, readwrite, copy) NSString *lastVersion;
@property (nonatomic) NSUInteger lastVersionLaunches;
@property (nonatomic, nullable, readwrite, copy) NSDate *initialLaunchDate;
@property (nonatomic, nullable, readwrite, copy) NSDate *installLaunchDate;
@property (nonatomic, nullable, readwrite, copy) NSDate *lastLaunchDate;
@property (nonatomic, nullable, readwrite, copy) NSDate *lastUpdateDate;
@end

@interface RSDKAnalyticsManager()<CLLocationManagerDelegate>
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
@property(nonatomic, strong) NSMutableSet RSDKA_GENERIC(id<RSDKAnalyticsTracker>) *trackers;

- (instancetype)initSharedInstance;
@end

////////////////////////////////////////////////////////////////////////////

@implementation RSDKAnalyticsManager

#pragma mark - Class methods

static RSDKAnalyticsManager *_instance = nil;

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

//--------------------------------------------------------------------------

+ (void)spoolRecord:(RSDKAnalyticsRecord *)record
{
    NSString *eventName = _RSDKAnalyticsGenericType;

    id parameters = record.propertiesDictionary;
    NSString *RATEType = parameters[@"etype"];
    if (RATEType.length)
    {
        eventName = [_RSDKAnalyticsPrefix stringByAppendingString:RATEType];
        parameters = [parameters mutableCopy];
        [parameters removeObjectForKey:RATEType];
    }

    [[RSDKAnalyticsEvent.alloc initWithName:eventName parameters:parameters] track];
}

//--------------------------------------------------------------------------

+ (NSURL*)endpointAddress
{
    return _RSDKAnalyticsEndpointAddress();
}

//--------------------------------------------------------------------------

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
        if (!_RSDKAnalyticsExternalCollector.sharedInstance ||
            !_RSDKAnalyticsLaunchCollector.sharedInstance)
        {
            NSAssert(NO, @"Failed to initialize the %@ singleton", NSStringFromClass(self.class));
            return nil;
        }

        _shouldTrackLastKnownLocation     = YES;
        _shouldTrackAdvertisingIdentifier = YES;

        _trackers = [NSMutableSet set];
        [self addTracker:RATTracker.sharedInstance];

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

// Deprecated
- (BOOL)isLocationTrackingEnabled
{
    return self.shouldTrackLastKnownLocation;
}

- (void)setLocationTrackingEnabled:(BOOL)locationTrackingEnabled
{
    self.shouldTrackLastKnownLocation = locationTrackingEnabled;
}

//--------------------------------------------------------------------------

#pragma mark - CLLocationManagerDelegate

- (void)locationManager:(CLLocationManager * __unused)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status
{
    [self _startStopMonitoringLocationIfNeeded];
}

- (void)locationManagerDidPauseLocationUpdates:(CLLocationManager * __unused)manager
{
    RSDKAnalyticsDebugLog(@"Location updates paused.");
}

- (void)locationManagerDidResumeLocationUpdates:(CLLocationManager * __unused)manager
{
    RSDKAnalyticsDebugLog(@"Location updates resumed.");
}

- (void)locationManager:(CLLocationManager * __unused)manager didFinishDeferredUpdatesWithError:(NSError *)error
{
    RSDKAnalyticsDebugLog(@"Failed to acquire device location: %@", error.localizedDescription);
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
        RSDKAnalyticsDebugLog(@"Location services' authorization status changed to [%@].", statusString);
    }
#endif

    if (self.shouldTrackLastKnownLocation &&
        CLLocationManager.locationServicesEnabled &&
        (status == kCLAuthorizationStatusAuthorizedAlways ||
         (status == kCLAuthorizationStatusAuthorizedWhenInUse && UIApplication.sharedApplication.applicationState == UIApplicationStateActive)
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

    RSDKAnalyticsDebugLog(@"Start monitoring location");
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

    RSDKAnalyticsDebugLog(@"Stop monitoring location");
    [self.locationManager stopUpdatingLocation];
    self.locationManagerIsUpdating = NO;
}

- (void)process:(RSDKAnalyticsEvent *)event
{
    NSString *sessionIdentifier = self.sessionCookie;
    if (!_deviceIdentifier)
    {
        @try
        {
            _deviceIdentifier = RSDKDeviceInformation.uniqueDeviceIdentifier;
        }
        @catch (NSException *__unused exception) { }
    }
    NSAssert(_deviceIdentifier, @"RSDKDeviceInformation is not properly configured!");

    RSDKAnalyticsState *state = [RSDKAnalyticsState.alloc initWithSessionIdentifier:sessionIdentifier
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
    _RSDKAnalyticsExternalCollector *externalCollector = _RSDKAnalyticsExternalCollector.sharedInstance;
    state.userIdentifier = externalCollector.trackingIdentifier;
    state.loginMethod = externalCollector.loginMethod;
    state.loggedIn = externalCollector.isLoggedIn;

    // Update state with data from launch collector
    _RSDKAnalyticsLaunchCollector *launchCollector = _RSDKAnalyticsLaunchCollector.sharedInstance;
    state.initialLaunchDate = launchCollector.initialLaunchDate;
    state.installLaunchDate = launchCollector.installLaunchDate;
    state.lastUpdateDate = launchCollector.lastUpdateDate;
    state.lastLaunchDate = launchCollector.lastLaunchDate;
    state.lastVersion = launchCollector.lastVersion;
    state.lastVersionLaunches = launchCollector.lastVersionLaunches;

    BOOL processed = NO;
    for (id<RSDKAnalyticsTracker> tracker in self.trackers)
    {
        RSDKAnalyticsDebugLog(@"Using tracker %@", tracker);

        if ([tracker processEvent:event state:state])
        {
            processed = TRUE;
        }
    }
    if (!processed)
    {
        RSDKAnalyticsDebugLog(@"No tracker processed event %@",event.name);
    }
}

- (void)addTracker:(id<RSDKAnalyticsTracker>)tracker
{
    @synchronized(self)
    {
        if (![_trackers containsObject:tracker])
        {
            [_trackers addObject:tracker];
            RSDKAnalyticsDebugLog(@"Added tracker %@", tracker);
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

