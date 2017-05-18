/*
 * © Rakuten, Inc.
 * authors: "Rakuten Ecosystem Mobile" <ecosystem-mobile@mail.rakuten.com>
 */
@import XCTest;
#import <RSDKAnalytics/RSDKAnalytics.h>
#import <RSDKAnalytics/RSDKAnalyticsState.h>
#import "../RSDKAnalytics/Private/_RSDKAnalyticsHelpers.h"
#import "../RSDKAnalytics/Private/_RSDKAnalyticsDatabase.h"
#import <OCMock/OCMock.h>
#import <OHHTTPStubs/OHHTTPStubs.h>

#pragma mark - Database Mock 

@interface MockedDatabase : NSObject
@property (nonatomic) NSMutableOrderedSet *keys;
@property (nonatomic) NSMutableDictionary *rows;
@property (nonatomic) NSDictionary        *latestAddedJSON;
@end

@implementation MockedDatabase
- (instancetype)init
{
    if ((self = [super init]))
    {
        _keys = NSMutableOrderedSet.new;
        _rows = NSMutableDictionary.new;
    }
    return self;
}

- (void)insertBlobs:(NSArray RSDKA_GENERIC(NSData *) *)blobs
               into:(NSString *)table
              limit:(unsigned int)maximumNumberOfBlobs
               then:(dispatch_block_t)completion
{
    for (NSData *blob in blobs)
    {
        static unsigned row = 0;

        NSNumber *key = @(++row);
        [_keys addObject:key];
        _rows[key] = blob.copy;
        _latestAddedJSON = [NSJSONSerialization JSONObjectWithData:blob options:0 error:0];
    }

    if (completion)
    {
        NSOperationQueue * __weak callerQueue = NSOperationQueue.currentQueue;
        dispatch_async(dispatch_get_global_queue(0, 0), ^{
            typeof(callerQueue) __strong queue = callerQueue;
            [queue addOperationWithBlock:completion];
        });
    }
}

- (void)fetchBlobs:(unsigned int)maximumNumberOfBlobs
              from:(NSString *)table
              then:(void (^)(NSArray RSDKA_GENERIC(NSData *) *__nullable blobs, NSArray RSDKA_GENERIC(NSNumber *) *__nullable identifiers))completion
{
    NSMutableArray *blobs       = NSMutableArray.new;
    NSMutableArray *identifiers = NSMutableArray.new;

    NSArray *keys = _keys.array;
    if (keys.count)
    {
        keys = [keys subarrayWithRange:NSMakeRange(0, MIN(keys.count, maximumNumberOfBlobs))];
        for (NSNumber *key in keys)
        {
            [identifiers addObject:key];
            [blobs       addObject:_rows[key]];
        }
    }

    if (completion)
    {
        NSOperationQueue * __weak callerQueue = NSOperationQueue.currentQueue;
        dispatch_async(dispatch_get_global_queue(0, 0), ^{
            typeof(callerQueue) __strong queue = callerQueue;
            [queue addOperationWithBlock:^{
                completion(blobs.count ? blobs : nil, identifiers.count ? identifiers : nil);
            }];
        });
    }
}

- (void)fetchBlobs:(unsigned int)maximumNumberOfBlobs
              from:(NSString *)table sendingIdentifiers:(NSArray RSDKA_GENERIC(NSNumber *) *)sendingIdentifiers
              then:(void (^)(NSArray RSDKA_GENERIC(NSData *) *__nullable blobs, NSArray RSDKA_GENERIC(NSNumber *) *__nullable identifiers))completion
{
    NSMutableArray *blobs       = NSMutableArray.new;
    NSMutableArray *identifiers = NSMutableArray.new;

    NSArray *keys = _keys.array;
    if (keys.count)
    {
        keys = [keys subarrayWithRange:NSMakeRange(0, MIN(keys.count, maximumNumberOfBlobs))];
        for (NSNumber *key in keys)
        {
            [identifiers addObject:key];
            [blobs       addObject:_rows[key]];
        }
    }

    if (completion)
    {
        NSOperationQueue * __weak callerQueue = NSOperationQueue.currentQueue;
        dispatch_async(dispatch_get_global_queue(0, 0), ^{
            typeof(callerQueue) __strong queue = callerQueue;
            [queue addOperationWithBlock:^{
                completion(blobs.count ? blobs : nil, identifiers.count ? identifiers : nil);
            }];
        });
    }
}

- (void)deleteBlobsWithIdentifiers:(NSArray RSDKA_GENERIC(NSNumber *) *)identifiers
                                in:(NSString *)table
                              then:(dispatch_block_t)completion
{
    [_keys removeObjectsInArray:identifiers];
    [_rows removeObjectsForKeys:identifiers];

    if (completion)
    {
        NSOperationQueue * __weak callerQueue = NSOperationQueue.currentQueue;
        dispatch_async(dispatch_get_global_queue(0, 0), ^{
            typeof(callerQueue) __strong queue = callerQueue;
            [queue addOperationWithBlock:completion];
        });
    };
}
@end

#pragma mark - Module Internals

@interface RSDKAnalyticsState ()
@property (nonatomic, readwrite, copy)              NSString                    *sessionIdentifier;
@property (nonatomic, readwrite, copy)              NSString                    *deviceIdentifier;
@property (nonatomic, readwrite, copy)              NSString                    *currentVersion;
@property (nonatomic, nullable, readwrite, copy)    CLLocation                  *lastKnownLocation;
@property (nonatomic, nullable, readwrite, copy)    NSString                    *advertisingIdentifier;
@property (nonatomic, nullable, readwrite, copy)    NSDate                      *sessionStartDate;
@property (nonatomic, readwrite, getter=isLoggedIn) BOOL                         loggedIn;
@property (nonatomic, nullable, readwrite, copy)    NSString                    *userIdentifier;
@property (nonatomic, readwrite)                    RSDKAnalyticsLoginMethod     loginMethod;
@property (nonatomic, readwrite)                    RSDKAnalyticsOrigin          origin;
@property (nonatomic, nullable, readwrite, copy)    NSString                    *lastVersion;
@property (nonatomic)                               NSUInteger                   lastVersionLaunches;
@property (nonatomic, nullable, readwrite, copy)    NSDate                      *initialLaunchDate;
@property (nonatomic, nullable, readwrite, copy)    NSDate                      *installLaunchDate;
@property (nonatomic, nullable, readwrite, copy)    NSDate                      *lastLaunchDate;
@property (nonatomic, nullable, readwrite, copy)    NSDate                      *lastUpdateDate;
@property (nonatomic, nullable, readwrite)          UIViewController            *currentPage;
@end

@interface RATTracker ()
@property (nonatomic) int64_t  accountIdentifier;
@property (nonatomic) int64_t  applicationIdentifier;
@property (nonatomic, copy, nullable) NSString *lastVisitedPageIdentifier;
@property (nonatomic, copy, nullable) NSNumber *carriedOverOrigin;
@property (nonatomic) NSTimer *uploadTimer;
@property (nonatomic) NSTimeInterval  uploadTimerInterval;
- (instancetype)initInstance;
@end

#pragma mark - Unit Tests

@interface AnalyticsRATTrackerTests : XCTestCase
@property (nonatomic)       MockedDatabase      *database;
@property (nonatomic)       RATTracker          *tracker;
@property (nonatomic)       NSMutableArray      *mocks;

@property (nonatomic, copy) RSDKAnalyticsEvent  *defaultEvent;
@property (nonatomic, copy) RSDKAnalyticsState  *defaultState;
@end

@interface CurrentPage: UIViewController
@end

@implementation CurrentPage
@end

@implementation AnalyticsRATTrackerTests

- (void)setUp
{
    [super setUp];
    _mocks = NSMutableArray.new;

    CLLocation *location = [[CLLocation alloc] initWithLatitude:-56.6462520 longitude:-36.6462520];
    CurrentPage *currentPage = [CurrentPage.alloc init];
    currentPage.view.frame = CGRectMake(0, 0, 100, 100);

    NSDateComponents *dateComponents = [NSDateComponents.alloc init];
    dateComponents.calendar = [NSCalendar calendarWithIdentifier:NSCalendarIdentifierGregorian];
    dateComponents.day    = 10;
    dateComponents.month  = 6;
    dateComponents.year   = 2016;
    dateComponents.hour   = 9;
    dateComponents.minute = 15;
    dateComponents.second = 30;
    NSDate *sessionStartDate = dateComponents.date;

    dateComponents.day = 1;
    NSDate *initialLaunchDate = dateComponents.date;

    dateComponents.day = 3;
    NSDate *lastLaunchDate = dateComponents.date;

    dateComponents.day = 2;
    NSDate *lastUpdateDate = dateComponents.date;

    _defaultState = [RSDKAnalyticsState.alloc initWithSessionIdentifier:@"CA7A88AB-82FE-40C9-A836-B1B3455DECAB"
                                                       deviceIdentifier:@"deviceId"];
    _defaultState.advertisingIdentifier = @"adId";
    _defaultState.lastKnownLocation     = location;
    _defaultState.sessionStartDate      = sessionStartDate;
    _defaultState.userIdentifier        = @"userId";
    _defaultState.loginMethod           = RSDKAnalyticsOneTapLoginLoginMethod;
    _defaultState.origin                = RSDKAnalyticsInternalOrigin;
    _defaultState.lastVersion           = @"1.0";
    _defaultState.initialLaunchDate     = initialLaunchDate;
    _defaultState.installLaunchDate     = [initialLaunchDate dateByAddingTimeInterval:-10];
    _defaultState.lastLaunchDate        = lastLaunchDate;
    _defaultState.lastUpdateDate        = lastUpdateDate;
    _defaultState.lastVersionLaunches   = 10;
    _defaultState.currentPage           = currentPage;

    _defaultEvent = [RSDKAnalyticsEvent.alloc initWithName:[_RATEventPrefix stringByAppendingString:@"defaultEvent"]
                                                parameters:@{@"param1": @"value1"}];

    // Mock the main bundle
    id bundleMock = OCMClassMock(NSBundle.class);
    [[[[bundleMock stub] classMethod] andReturn:[NSBundle bundleForClass:RATTracker.class]] mainBundle];
    [self addMock:bundleMock];

    // No request should be emitted to RAT unless it's properly mocked
    // in the relevant test
    [OHHTTPStubs stubRequestsPassingTest:^BOOL(NSURLRequest *request) {
        XCTAssertNotEqualObjects(request.URL.absoluteURL,
                                 RATTracker.endpointAddress,
                                 @"Missing HTTP mock!");
        [self description]; // capture self strongly for the assert above to work
        return NO;
    } withStubResponse:^OHHTTPStubsResponse *(NSURLRequest *request) {
        return nil;
    }];

    // Mock the database
    _database = MockedDatabase.new;
    id dbMock = OCMClassMock(_RSDKAnalyticsDatabase.class);

    [[[[[dbMock stub] classMethod] ignoringNonObjectArgs]
      andCall:@selector(insertBlobs:into:limit:then:) onObject:_database]
     insertBlobs:OCMOCK_ANY into:OCMOCK_ANY limit:0 then:OCMOCK_ANY];

    [[[[[dbMock stub] classMethod] ignoringNonObjectArgs]
      andCall:@selector(fetchBlobs:from:then:) onObject:_database]
     fetchBlobs:0 from:OCMOCK_ANY then:OCMOCK_ANY];

    [[[[[dbMock stub] classMethod] ignoringNonObjectArgs]
      andCall:@selector(fetchBlobs:from:sendingIdentifiers:then:) onObject:_database]
     fetchBlobs:0 from:OCMOCK_ANY sendingIdentifiers:@[] then:OCMOCK_ANY];

    [[[[[dbMock stub] classMethod] ignoringNonObjectArgs]
      andCall:@selector(deleteBlobsWithIdentifiers:in:then:) onObject:_database]
     deleteBlobsWithIdentifiers:OCMOCK_ANY in:OCMOCK_ANY then:OCMOCK_ANY];

    [self addMock:dbMock];

    // Mock the RATTracker singleton so that each test gets a fresh one
    _tracker = [RATTracker.alloc initInstance];
    _tracker.uploadTimerInterval = 2;
    id trackerMock = OCMClassMock(RATTracker.class);

    [[[[trackerMock stub] classMethod] andReturn:_tracker] sharedInstance];

    [self addMock:trackerMock];
}

- (void)tearDown
{
    [OHHTTPStubs removeAllStubs];
    [_mocks enumerateObjectsUsingBlock:^(id mock, NSUInteger idx, BOOL *stop) {
        [mock stopMocking];
    }];

    _mocks    = nil;
    _tracker  = nil;
    _database = nil;
}

#pragma mark Helpers

- (void)addMock:(id)mock
{
    [_mocks addObject:mock];
}

- (NSDictionary *)assertProcessEvent:(RSDKAnalyticsEvent *)event
                               state:(RSDKAnalyticsState *)state
                          expectType:(NSString *)etype
{
    XCTAssertNotNil(event);
    XCTAssert([RATTracker.sharedInstance processEvent:event state:state]);
    id payload = _database.latestAddedJSON;
    XCTAssertNotNil(payload);
    if (etype) XCTAssertEqualObjects(payload[@"etype"], etype);
    return payload;
}

- (BOOL)assertExpectedNotification:(NSDictionary *)userInfo
{
    NSError *error = userInfo[NSUnderlyingErrorKey];
    XCTAssertEqualObjects(error.localizedDescription, @"invalid_response");
    return YES;
}

#pragma mark Tests

- (void)testAnalyticsRATTrackerSharedInstanceIsNotNil
{
    XCTAssertNotNil(RATTracker.sharedInstance);
}

- (void)testAnalyticsRATTrackerSharedInstanceAreEqual
{
    XCTAssertEqualObjects(RATTracker.sharedInstance, RATTracker.sharedInstance);
}

- (void)testInitThrowsException
{
    XCTAssertThrowsSpecificNamed([RATTracker new], NSException, NSInvalidArgumentException);
}

- (void)testEventWithTypeAndParameters
{
    NSDictionary *params = @{@"acc":@555};
    RSDKAnalyticsEvent *event = [RATTracker.sharedInstance eventWithEventType:@"login" parameters:params];
    XCTAssertNotNil(event);
    XCTAssertEqualObjects(event.name,       @"rat.login");
    XCTAssertEqualObjects(event.parameters, params);
}

- (void)testConfigureWithApplicationId
{
    [RATTracker.sharedInstance configureWithApplicationId:555];
    XCTAssertEqual(RATTracker.sharedInstance.applicationIdentifier, 555);
}

- (void)testConfigureWithAccountId
{
    [RATTracker.sharedInstance configureWithAccountId:333];
    XCTAssertEqual(RATTracker.sharedInstance.accountIdentifier, 333);
}

- (void)testProcessValidRATEvent
{
    [self assertProcessEvent:_defaultEvent state:_defaultState expectType:@"defaultEvent"];
}

- (void)testProcessInitialLaunchEvent
{
    id event = [RSDKAnalyticsEvent.alloc initWithName:RSDKAnalyticsInitialLaunchEventName parameters:nil];
    [self assertProcessEvent:event state:_defaultState expectType:RSDKAnalyticsInitialLaunchEventName];
}

- (void)testProcessInstallEvent
{
    id event = [RSDKAnalyticsEvent.alloc initWithName:RSDKAnalyticsInstallEventName parameters:nil];
    id payload = [self assertProcessEvent:event state:_defaultState expectType:RSDKAnalyticsInstallEventName];

    id appInfo = [payload valueForKeyPath:@"cp.app_info"];
    XCTAssert([appInfo containsString:@"xcode"]);
    XCTAssert([appInfo containsString:@"iphonesimulator"]);
}

- (void)testProcessSessionStartEvent
{
    id event = [RSDKAnalyticsEvent.alloc initWithName:RSDKAnalyticsSessionStartEventName parameters:nil];
    id payload = [self assertProcessEvent:event state:_defaultState expectType:RSDKAnalyticsSessionStartEventName];

    NSInteger daysSinceFirstUse = [[payload valueForKeyPath:@"cp.days_since_first_use"] integerValue];
    NSInteger daysSinceLastUse  = [[payload valueForKeyPath:@"cp.days_since_last_use"] integerValue];
    XCTAssertGreaterThanOrEqual(daysSinceLastUse, 0);
    XCTAssertEqual(daysSinceLastUse, daysSinceFirstUse - 2);
}

- (void)testProcessSessionEndEvent
{
    id event = [RSDKAnalyticsEvent.alloc initWithName:RSDKAnalyticsSessionEndEventName parameters:nil];
    [self assertProcessEvent:event state:_defaultState expectType:RSDKAnalyticsSessionEndEventName];
}

- (void)testProcessApplicationUpdateEvent
{
    id event = [RSDKAnalyticsEvent.alloc initWithName:RSDKAnalyticsApplicationUpdateEventName parameters:nil];
    id payload = [self assertProcessEvent:event state:_defaultState expectType:RSDKAnalyticsApplicationUpdateEventName];

    NSInteger launchesSinceUpgrade = [[payload valueForKeyPath:@"cp.launches_since_last_upgrade"] integerValue];
    NSInteger daysSinceUpgrade     = [[payload valueForKeyPath:@"cp.days_since_last_upgrade"] integerValue];
    XCTAssertGreaterThan(launchesSinceUpgrade, 0);
    XCTAssertGreaterThan(daysSinceUpgrade,     0);
}

- (void)testProcessOneTapLoginEvent
{
    id event = [RSDKAnalyticsEvent.alloc initWithName:RSDKAnalyticsLoginEventName parameters:nil];
    id payload = [self assertProcessEvent:event state:_defaultState expectType:RSDKAnalyticsLoginEventName];
    XCTAssertEqualObjects([payload valueForKeyPath:@"cp.login_method"], @"one_tap_login");
}

- (void)testProcessPasswordLoginEvent
{
    RSDKAnalyticsState *state = _defaultState.copy;
    state.loginMethod = RSDKAnalyticsPasswordInputLoginMethod;

    id event = [RSDKAnalyticsEvent.alloc initWithName:RSDKAnalyticsLoginEventName parameters:nil];
    id payload = [self assertProcessEvent:event state:state expectType:RSDKAnalyticsLoginEventName];
    XCTAssertEqualObjects([payload valueForKeyPath:@"cp.login_method"], @"password");
}

- (void)testProcessLocalLogoutEvent
{
    id event = [RSDKAnalyticsEvent.alloc initWithName:RSDKAnalyticsLogoutEventName parameters:@{RSDKAnalyticsLogoutMethodEventParameter:RSDKAnalyticsLocalLogoutMethod}];
    id payload = [self assertProcessEvent:event state:_defaultState expectType:RSDKAnalyticsLogoutEventName];
    XCTAssertEqualObjects([payload valueForKeyPath:@"cp.logout_method"], @"single");
}

- (void)testProcessGlobalLogoutEvent
{
    id event = [RSDKAnalyticsEvent.alloc initWithName:RSDKAnalyticsLogoutEventName parameters:@{RSDKAnalyticsLogoutMethodEventParameter:RSDKAnalyticsGlobalLogoutMethod}];
    id payload = [self assertProcessEvent:event state:_defaultState expectType:RSDKAnalyticsLogoutEventName];
    XCTAssertEqualObjects([payload valueForKeyPath:@"cp.logout_method"], @"all");
}

- (void)testProcessEmptyLogoutEvent
{
    id event = [RSDKAnalyticsEvent.alloc initWithName:RSDKAnalyticsLogoutEventName parameters:nil];
    id payload = [self assertProcessEvent:event state:_defaultState expectType:RSDKAnalyticsLogoutEventName];
    XCTAssertNil([payload valueForKeyPath:@"cp.logout_method"]);
}

- (void)testProcessPageVisitEventWithPageId
{
    NSString *pageId = @"TestPage";
    id event = [RSDKAnalyticsEvent.alloc initWithName:RSDKAnalyticsPageVisitEventName parameters:@{@"page_id": pageId}];
    id payload = [self assertProcessEvent:event state:_defaultState expectType:@"pv"];
    XCTAssertEqualObjects([payload valueForKeyPath:@"pgn"], pageId);
    XCTAssertEqualObjects([payload valueForKeyPath:@"cp.ref_type"], @"internal");
}

- (void)testProcessPageVisitEventWithoutPageId
{
    id event = [RSDKAnalyticsEvent.alloc initWithName:RSDKAnalyticsPageVisitEventName parameters:nil];
    id payload = [self assertProcessEvent:event state:_defaultState expectType:@"pv"];
    XCTAssertEqualObjects([payload valueForKeyPath:@"pgn"], NSStringFromClass(CurrentPage.class));
    XCTAssertEqualObjects([payload valueForKeyPath:@"cp.ref_type"], @"internal");
}

- (void)testProcessPageWithRef
{
    NSString *firstPage  = @"FirstPage",
             *secondPage = @"SecondPage";

    id event = [RSDKAnalyticsEvent.alloc initWithName:RSDKAnalyticsPageVisitEventName parameters:@{@"page_id": firstPage}];
    id payload = [self assertProcessEvent:event state:_defaultState expectType:@"pv"];
    XCTAssertEqualObjects([payload valueForKeyPath:@"pgn"], firstPage);
    XCTAssertNil([payload valueForKeyPath:@"ref"]);

    event = [RSDKAnalyticsEvent.alloc initWithName:RSDKAnalyticsPageVisitEventName parameters:@{@"page_id": secondPage}];
    payload = [self assertProcessEvent:event state:_defaultState expectType:@"pv"];
    XCTAssertEqualObjects([payload valueForKeyPath:@"pgn"], secondPage);
    XCTAssertEqualObjects([payload valueForKeyPath:@"ref"], firstPage);
}

- (void)testProcessExternalPageVisitEvent
{
    NSString *pageId = @"TestPage";
    RSDKAnalyticsState *state = _defaultState.copy;
    state.origin = RSDKAnalyticsExternalOrigin;

    id event = [RSDKAnalyticsEvent.alloc initWithName:RSDKAnalyticsPageVisitEventName parameters:@{@"page_id": pageId}];
    id payload = [self assertProcessEvent:event state:state expectType:@"pv"];
    XCTAssertEqualObjects([payload valueForKeyPath:@"pgn"], pageId);
    XCTAssertEqualObjects([payload valueForKeyPath:@"cp.ref_type"], @"external");
}

- (void)testProcessPushPageVisitEvent
{
    NSString *pageId = @"TestPage";
    RSDKAnalyticsState *state = _defaultState.copy;
    state.origin = RSDKAnalyticsPushOrigin;

    id event = [RSDKAnalyticsEvent.alloc initWithName:RSDKAnalyticsPageVisitEventName parameters:@{@"page_id": pageId}];
    id payload = [self assertProcessEvent:event state:state expectType:@"pv"];
    XCTAssertEqualObjects([payload valueForKeyPath:@"pgn"], pageId);
    XCTAssertEqualObjects([payload valueForKeyPath:@"cp.ref_type"], @"push");
}

- (void)testProcessPushEvent
{
    NSString *trackingIdentifier = @"trackingIdentifier";
    id event = [RSDKAnalyticsEvent.alloc initWithName:RSDKAnalyticsPushNotificationEventName
                                           parameters:@{RSDKAnalyticPushNotificationTrackingIdentifierParameter: trackingIdentifier}];
    id payload = [self assertProcessEvent:event state:_defaultState expectType:RSDKAnalyticsPushNotificationEventName];
    XCTAssertEqualObjects([payload valueForKeyPath:@"cp.push_notify_value"], trackingIdentifier);
}

- (void)testProcessDiscoverEvent
{
    NSString *discoverEvent = @"_rem_discover_event";
    NSString *appName       = @"appName";
    NSString *storeURL      = @"storeUrl";
    
    id event = [RSDKAnalyticsEvent.alloc initWithName:discoverEvent
                                           parameters:@{@"prApp" : appName, @"prStoreUrl": storeURL}];
    id payload = [self assertProcessEvent:event state:_defaultState expectType:discoverEvent];
    XCTAssertEqualObjects([payload valueForKeyPath:@"cp.prApp"], appName);
    XCTAssertEqualObjects([payload valueForKeyPath:@"cp.prStoreUrl"], storeURL);
}

- (void)testProcessCardInfoEvent
{
    NSString *cardInfoEvent = @"_rem_cardinfo_event";
    id event = [RSDKAnalyticsEvent.alloc initWithName:cardInfoEvent parameters:nil];
    [self assertProcessEvent:event state:_defaultState expectType:cardInfoEvent];
}

- (void)testProcessInvalidEventFails
{
    RSDKAnalyticsEvent *event = [RSDKAnalyticsEvent.alloc initWithName:@"unknown" parameters:nil];
    XCTAssertFalse([RATTracker.sharedInstance processEvent:event state:[self defaultState]]);
}

- (void)testDeviceBatteryStateReportedInJSON
{
    id deviceSpy = OCMPartialMock(UIDevice.currentDevice);
    [self addMock:deviceSpy];
    
    OCMStub([deviceSpy batteryState]).andReturn(UIDeviceBatteryStateUnplugged);
    OCMStub([deviceSpy batteryLevel]).andReturn(0.5);
    
    id payload = [self assertProcessEvent:_defaultEvent state:_defaultState expectType:nil];
    NSNumber *powerstatus = payload[@"powerstatus"],
             *mbat        = payload[@"mbat"];

    XCTAssertNotNil(powerstatus);
    XCTAssertNotNil(mbat);

    XCTAssert([powerstatus isKindOfClass:NSNumber.class]);
    XCTAssert([mbat        isKindOfClass:NSString.class]);

    XCTAssertEqual(powerstatus.integerValue, 0);
    XCTAssertEqual(mbat.floatValue,          50);
}

- (void)testSendEventToRAT
{
    __block XCTestExpectation *sent = [self expectationWithDescription:@"sent"];
    [OHHTTPStubs stubRequestsPassingTest:^BOOL(NSURLRequest *request) {
        return [request.URL.absoluteString isEqualToString:RATTracker.endpointAddress.absoluteString];
    } withStubResponse:^OHHTTPStubsResponse * _Nonnull(NSURLRequest * _Nonnull request) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [sent fulfill];
            sent = nil;
        });
        return [OHHTTPStubsResponse responseWithData:[NSData data] statusCode:200 headers:nil];
    }];

    [RATTracker.sharedInstance processEvent:[self defaultEvent] state:[self defaultState]];
    [self waitForExpectationsWithTimeout:5.0 handler:nil];
}


- (void)testSendEventToRATServerError
{
    __block XCTestExpectation *sent = [self expectationWithDescription:@"sent"];
    [OHHTTPStubs stubRequestsPassingTest:^BOOL(NSURLRequest *request) {
        return [request.URL.absoluteString isEqualToString:RATTracker.endpointAddress.absoluteString];
    } withStubResponse:^OHHTTPStubsResponse * _Nonnull(NSURLRequest * _Nonnull request) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [sent fulfill];
            sent = nil;
        });
        return [OHHTTPStubsResponse responseWithData:[NSData data] statusCode:500 headers:nil];
    }];

    __block XCTestExpectation *notified = [self expectationWithDescription:@"notified"];
    NSOperationQueue *queue = [NSOperationQueue new];
    id cb = [NSNotificationCenter.defaultCenter addObserverForName:RATUploadFailureNotification
                                                            object:nil
                                                             queue:queue
                                                        usingBlock:^(NSNotification *note)
    {
        NSError *error = note.userInfo[NSUnderlyingErrorKey];
        XCTAssertEqualObjects(error.localizedDescription, @"invalid_response");
        [notified fulfill];
        notified = nil;
    }];

    [RATTracker.sharedInstance processEvent:[self defaultEvent] state:[self defaultState]];
    [self waitForExpectationsWithTimeout:5.0 handler:nil];
    [NSNotificationCenter.defaultCenter removeObserver:cb];
}

@end
