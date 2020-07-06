@import XCTest;
#import <OCMock/OCMock.h>
#import <OHHTTPStubs/OHHTTPStubs.h>

#import "../../RAnalytics/Core/Private/_RAnalyticsDatabase.h"
#import "../../RAnalytics/Util/Private/_RAnalyticsHelpers.h"

#import "TrackerTests.h"

#pragma mark - Module Internals

@interface RAnalyticsState ()
@property (nonatomic, readwrite)                    RAnalyticsLoginMethod     loginMethod;
@property (nonatomic, readwrite)                    RAnalyticsOrigin          origin;
@end

@interface RAnalyticsRATTracker ()
@property (nonatomic) int64_t                   accountIdentifier;
@property (nonatomic) int64_t                   applicationIdentifier;
@property (nonatomic, copy, nullable) NSString *lastVisitedPageIdentifier;
@property (nonatomic, copy, nullable) NSNumber *carriedOverOrigin;
@property (nonatomic) RAnalyticsSender      *sender;
@property (nonatomic, nullable) NSNumber *reachabilityStatus;
@property (nonatomic) BOOL isUsingLTE;
- (instancetype)initInstance;
- (NSNumber *)positiveIntegerNumberWithObject:(id)object;
@end

@interface RAnalyticsSender ()
@property (nonatomic) NSTimeInterval            uploadTimerInterval;
@property (nonatomic) NSTimer                  *uploadTimer;
@end

@interface RAnalyticsManager ()
@property(nonatomic, strong) NSMutableSet<id<RAnalyticsTracker>> *trackers;
@end

#pragma mark - Unit Tests

@interface RATTrackerTests : TrackerTests
@end

@implementation RATTrackerTests

#pragma clang diagnostic ignored "-Wundeclared-selector"

- (void)setUp
{
    [super setUp];
    for(NSHTTPCookie *cookie in [[NSHTTPCookieStorage sharedHTTPCookieStorage] cookies])
    {
        [[NSHTTPCookieStorage sharedHTTPCookieStorage] deleteCookie:cookie];
    }
}

- (void)tearDown
{
    // Clear any still running timers because they can break our async batching delay tests
    for (id<RAnalyticsTracker> t in RAnalyticsManager.sharedInstance.trackers)
    {
        if ([t isKindOfClass:RAnalyticsRATTracker.class])
        {
            RAnalyticsRATTracker *rT = (RAnalyticsRATTracker *)t;
            [self invalidateTimerOfSender:rT.sender];
        }
    }
    [super tearDown];
}

#pragma mark TrackerTestConfiguration protocol
- (id<RAnalyticsTracker>)testedTracker
{
    return [RAnalyticsRATTracker.alloc initInstance];
}

#pragma mark Test initialisation and configuration

- (void)testAnalyticsRATTrackerSharedInstanceIsNotNil
{
    XCTAssertNotNil(RAnalyticsRATTracker.sharedInstance);
}

- (void)testAnalyticsRATTrackerSharedInstanceAreEqual
{
    XCTAssertEqualObjects(RAnalyticsRATTracker.sharedInstance, RAnalyticsRATTracker.sharedInstance);
}

- (void)testInitThrowsException
{
    XCTAssertThrowsSpecificNamed([RAnalyticsRATTracker new], NSException, NSInvalidArgumentException);
}

- (void)testEventWithTypeAndParameters
{
    NSDictionary *params = @{@"acc":@555};
    RAnalyticsEvent *event = [RAnalyticsRATTracker.sharedInstance eventWithEventType:@"login" parameters:params];
    XCTAssertNotNil(event);
    XCTAssertEqualObjects(event.name,       @"rat.login");
    XCTAssertEqualObjects(event.parameters, params);
}

- (void)testThatPlistAccountIdKeyIsUsedWhenSet
{
    // setUp() already mocks mainBundle so need to remove
    [self.mocks enumerateObjectsUsingBlock:^(id mock, __unused NSUInteger idx, __unused BOOL * stop) {
        [mock stopMocking];
    }];

    NSInteger expected = 10;
    id mockBundle = OCMPartialMock(NSBundle.mainBundle);
    OCMStub([mockBundle objectForInfoDictionaryKey:@"RATAccountIdentifier"]).andReturn([NSNumber numberWithLongLong:expected]);

    // need a freshly allocated instance so that the plist is read
    RAnalyticsRATTracker *tracker = [RAnalyticsRATTracker.alloc initInstance];

    XCTAssertEqual(tracker.accountIdentifier, expected);
}

- (void)testThatDefaultAccountIdIsUsedWhenPlistKeyIsNotSet
{
    XCTAssertEqual(RAnalyticsRATTracker.sharedInstance.accountIdentifier, 477);
}

- (void)testThatPlistApplicationIdKeyIsUsedWhenSet
{
    // setUp() already mocks mainBundle so need to remove
    [self.mocks enumerateObjectsUsingBlock:^(id mock, __unused NSUInteger idx, __unused BOOL * stop) {
        [mock stopMocking];
    }];

    NSInteger expected = 10;
    id mockBundle = OCMPartialMock(NSBundle.mainBundle);
    OCMStub([mockBundle objectForInfoDictionaryKey:@"RATAppIdentifier"]).andReturn([NSNumber numberWithLongLong:expected]);

    // need a freshly allocated instance so that the plist is read
    RAnalyticsRATTracker *tracker = [RAnalyticsRATTracker.alloc initInstance];

    XCTAssertEqual(tracker.applicationIdentifier, expected);
}

- (void)testThatDefaultApplicationIdIsUsedWhenPlistKeyIsNotSet
{
    XCTAssertEqual(RAnalyticsRATTracker.sharedInstance.applicationIdentifier, 1);
}

#pragma mark Test processing events

- (void)testProcessValidRATEvent
{
    [self assertProcessEvent:self.defaultEvent state:self.defaultState expectType:@"defaultEvent"];
}

- (void)testProcessInitialLaunchEvent
{
    id event = [RAnalyticsEvent.alloc initWithName:RAnalyticsInitialLaunchEventName parameters:nil];
    [self assertProcessEvent:event state:self.defaultState expectType:RAnalyticsInitialLaunchEventName];
}

- (void)testProcessInstallEvent
{
    id event = [RAnalyticsEvent.alloc initWithName:RAnalyticsInstallEventName parameters:nil];
    id payload = [self assertProcessEvent:event state:self.defaultState expectType:RAnalyticsInstallEventName];
    id appInfo = [payload valueForKeyPath:@"cp.app_info"];
    XCTAssert([appInfo containsString:@"xcode"]);
    XCTAssert([appInfo containsString:@"iphonesimulator"]);
}


- (void)testProcessSessionStartEvent
{
    id event = [RAnalyticsEvent.alloc initWithName:RAnalyticsSessionStartEventName parameters:nil];
    id payload = [self assertProcessEvent:event state:self.defaultState expectType:RAnalyticsSessionStartEventName];

    NSInteger daysSinceFirstUse = [[payload valueForKeyPath:@"cp.days_since_first_use"] integerValue];
    NSInteger daysSinceLastUse  = [[payload valueForKeyPath:@"cp.days_since_last_use"] integerValue];
    XCTAssertGreaterThanOrEqual(daysSinceLastUse, 0);
    XCTAssertEqual(daysSinceLastUse, daysSinceFirstUse - 2);
}

- (void)testProcessSessionEndEvent
{
    id event = [RAnalyticsEvent.alloc initWithName:RAnalyticsSessionEndEventName parameters:nil];
    [self assertProcessEvent:event state:self.defaultState expectType:RAnalyticsSessionEndEventName];
}

- (void)testProcessApplicationUpdateEvent
{
    id event = [RAnalyticsEvent.alloc initWithName:RAnalyticsApplicationUpdateEventName parameters:nil];
    id payload = [self assertProcessEvent:event state:self.defaultState expectType:RAnalyticsApplicationUpdateEventName];

    NSInteger launchesSinceUpgrade = [[payload valueForKeyPath:@"cp.launches_since_last_upgrade"] integerValue];
    NSInteger daysSinceUpgrade     = [[payload valueForKeyPath:@"cp.days_since_last_upgrade"] integerValue];
    XCTAssertGreaterThan(launchesSinceUpgrade, 0);
    XCTAssertGreaterThan(daysSinceUpgrade,     0);
}

- (void)testProcessOneTapLoginEvent
{
    id event = [RAnalyticsEvent.alloc initWithName:RAnalyticsLoginEventName parameters:nil];
    id payload = [self assertProcessEvent:event state:self.defaultState expectType:RAnalyticsLoginEventName];
    XCTAssertEqualObjects([payload valueForKeyPath:@"cp.login_method"], @"one_tap_login");
}

- (void)testProcessPasswordLoginEvent
{
    RAnalyticsState *state = self.defaultState.copy;
    state.loginMethod = RAnalyticsPasswordInputLoginMethod;

    id event = [RAnalyticsEvent.alloc initWithName:RAnalyticsLoginEventName parameters:nil];
    id payload = [self assertProcessEvent:event state:state expectType:RAnalyticsLoginEventName];
    XCTAssertEqualObjects([payload valueForKeyPath:@"cp.login_method"], @"password");
}

- (void)testProcessLocalLogoutEvent
{
    id event = [RAnalyticsEvent.alloc initWithName:RAnalyticsLogoutEventName parameters:@{RAnalyticsLogoutMethodEventParameter:RAnalyticsLocalLogoutMethod}];
    id payload = [self assertProcessEvent:event state:self.defaultState expectType:RAnalyticsLogoutEventName];
    XCTAssertEqualObjects([payload valueForKeyPath:@"cp.logout_method"], @"single");
}

- (void)testProcessGlobalLogoutEvent
{
    id event = [RAnalyticsEvent.alloc initWithName:RAnalyticsLogoutEventName parameters:@{RAnalyticsLogoutMethodEventParameter:RAnalyticsGlobalLogoutMethod}];
    id payload = [self assertProcessEvent:event state:self.defaultState expectType:RAnalyticsLogoutEventName];
    XCTAssertEqualObjects([payload valueForKeyPath:@"cp.logout_method"], @"all");
}

- (void)testProcessEmptyLogoutEvent
{
    id event = [RAnalyticsEvent.alloc initWithName:RAnalyticsLogoutEventName parameters:nil];
    id payload = [self assertProcessEvent:event state:self.defaultState expectType:RAnalyticsLogoutEventName];
    XCTAssertNil([payload valueForKeyPath:@"cp.logout_method"]);
}

- (void)testProcessPasswordLoginFailureEvent
{
    id event = [RAnalyticsEvent.alloc initWithName:RAnalyticsLoginFailureEventName parameters:@{@"type":@"password_login", @"rae_error" : @"invalid_grant"}];
    id payload = [self assertProcessEvent:event state:self.defaultState expectType:RAnalyticsLoginFailureEventName];
    XCTAssertEqualObjects([payload valueForKeyPath:@"cp.type"], @"password_login");
    XCTAssertEqualObjects([payload valueForKeyPath:@"cp.rae_error"], @"invalid_grant");
}

- (void)testProcessSSOLoginFailureEvent
{
    id event = [RAnalyticsEvent.alloc initWithName:RAnalyticsLoginFailureEventName parameters:@{@"type":@"sso_login", @"rae_error" : @"invalid_scope"}];
    id payload = [self assertProcessEvent:event state:self.defaultState expectType:RAnalyticsLoginFailureEventName];
    XCTAssertEqualObjects([payload valueForKeyPath:@"cp.type"], @"sso_login");
    XCTAssertEqualObjects([payload valueForKeyPath:@"cp.rae_error"], @"invalid_scope");
}

- (void)testProcessPageVisitEventWithPageId
{
    NSString *pageId = @"TestPage";
    id event = [RAnalyticsEvent.alloc initWithName:RAnalyticsPageVisitEventName parameters:@{@"page_id": pageId}];
    id payload = [self assertProcessEvent:event state:self.defaultState expectType:@"pv"];
    XCTAssertEqualObjects([payload valueForKeyPath:@"pgn"], pageId);
    XCTAssertEqualObjects([payload valueForKeyPath:@"cp.ref_type"], @"internal");
}

- (void)testProcessPageVisitEventWithoutPageId
{
    id event = [RAnalyticsEvent.alloc initWithName:RAnalyticsPageVisitEventName parameters:nil];
    id payload = [self assertProcessEvent:event state:self.defaultState expectType:@"pv"];
    XCTAssertEqualObjects([payload valueForKeyPath:@"pgn"], NSStringFromClass(CurrentPage.class));
    XCTAssertEqualObjects([payload valueForKeyPath:@"cp.ref_type"], @"internal");
}

- (void)testProcessPageWithRef
{
    NSString *firstPage  = @"FirstPage",
             *secondPage = @"SecondPage";

    id event = [RAnalyticsEvent.alloc initWithName:RAnalyticsPageVisitEventName parameters:@{@"page_id": firstPage}];
    id payload = [self assertProcessEvent:event state:self.defaultState expectType:@"pv"];
    XCTAssertEqualObjects([payload valueForKeyPath:@"pgn"], firstPage);
    XCTAssertNil([payload valueForKeyPath:@"ref"]);

    event = [RAnalyticsEvent.alloc initWithName:RAnalyticsPageVisitEventName parameters:@{@"page_id": secondPage}];
    payload = [self assertProcessEvent:event state:self.defaultState expectType:@"pv"];
    XCTAssertEqualObjects([payload valueForKeyPath:@"pgn"], secondPage);
    XCTAssertEqualObjects([payload valueForKeyPath:@"ref"], firstPage);
}

- (void)testProcessExternalPageVisitEvent
{
    NSString *pageId = @"TestPage";
    RAnalyticsState *state = self.defaultState.copy;
    state.origin = RAnalyticsExternalOrigin;

    id event = [RAnalyticsEvent.alloc initWithName:RAnalyticsPageVisitEventName parameters:@{@"page_id": pageId}];
    id payload = [self assertProcessEvent:event state:state expectType:@"pv"];
    XCTAssertEqualObjects([payload valueForKeyPath:@"pgn"], pageId);
    XCTAssertEqualObjects([payload valueForKeyPath:@"cp.ref_type"], @"external");
}

- (void)testProcessPushPageVisitEvent
{
    NSString *pageId = @"TestPage";
    RAnalyticsState *state = self.defaultState.copy;
    state.origin = RAnalyticsPushOrigin;

    id event = [RAnalyticsEvent.alloc initWithName:RAnalyticsPageVisitEventName parameters:@{@"page_id": pageId}];
    id payload = [self assertProcessEvent:event state:state expectType:@"pv"];
    XCTAssertEqualObjects([payload valueForKeyPath:@"pgn"], pageId);
    XCTAssertEqualObjects([payload valueForKeyPath:@"cp.ref_type"], @"push");
}

- (void)testProcessPushEvent
{
    NSString *trackingIdentifier = @"trackingIdentifier";
    id event = [RAnalyticsEvent.alloc initWithName:RAnalyticsPushNotificationEventName
                                           parameters:@{RAnalyticsPushNotificationTrackingIdentifierParameter: trackingIdentifier}];
    id payload = [self assertProcessEvent:event state:self.defaultState expectType:RAnalyticsPushNotificationEventName];
    XCTAssertEqualObjects([payload valueForKeyPath:@"cp.push_notify_value"], trackingIdentifier);
}

- (void)testProcessDiscoverEvent
{
    NSString *discoverEvent = @"_rem_discover_event";
    NSString *appName       = @"appName";
    NSString *storeURL      = @"storeUrl";

    id event = [RAnalyticsEvent.alloc initWithName:discoverEvent
                                           parameters:@{@"prApp" : appName, @"prStoreUrl": storeURL}];
    id payload = [self assertProcessEvent:event state:self.defaultState expectType:discoverEvent];
    XCTAssertEqualObjects([payload valueForKeyPath:@"cp.prApp"], appName);
    XCTAssertEqualObjects([payload valueForKeyPath:@"cp.prStoreUrl"], storeURL);
}

- (void)testProcessCardInfoEvent
{
    NSString *cardInfoEvent = @"_rem_cardinfo_event";
    id event = [RAnalyticsEvent.alloc initWithName:cardInfoEvent parameters:nil];
    [self assertProcessEvent:event state:self.defaultState expectType:cardInfoEvent];
}

- (void)testProcessSSOCredentialFoundEvent
{
    id event = [RAnalyticsEvent.alloc initWithName:RAnalyticsSSOCredentialFoundEventName parameters:@{@"source":@"device"}];
    [self assertProcessEvent:event state:self.defaultState expectType:RAnalyticsSSOCredentialFoundEventName];
}

- (void)testProcessLoginCredentialFoundIcloudEvent
{
    id event = [RAnalyticsEvent.alloc initWithName:RAnalyticsLoginCredentialFoundEventName parameters:@{@"source":@"icloud"}];
    [self assertProcessEvent:event state:self.defaultState expectType:RAnalyticsLoginCredentialFoundEventName];
}

- (void)testProcessLoginCredentialFoundPwEvent
{
    id event = [RAnalyticsEvent.alloc initWithName:RAnalyticsLoginCredentialFoundEventName parameters:@{@"source":@"password-manager"}];
    [self assertProcessEvent:event state:self.defaultState expectType:RAnalyticsLoginCredentialFoundEventName];
}

- (void)testProcessCredentialStrategiesEvent
{
    id event = [RAnalyticsEvent.alloc initWithName:RAnalyticsCredentialStrategiesEventName parameters:@{@"strategies":@{@"password-manager":@"true"}}];
    [self assertProcessEvent:event state:self.defaultState expectType:RAnalyticsCredentialStrategiesEventName];
}

- (void)testProcessCustomEvent
{
    id event = [RAnalyticsEvent.alloc initWithName:RAnalyticsCustomEventName parameters:@{@"eventName":@"etypeName", @"eventData":@{@"foo":@"bar"}}];
    NSDictionary *payload = [self assertProcessEvent:event state:self.defaultState expectType:@"etypeName"];
    XCTAssertEqualObjects(payload[@"cp"][@"foo"], @"bar");
}

- (void)testProcessCustomEventNoData
{
    id event = [RAnalyticsEvent.alloc initWithName:RAnalyticsCustomEventName parameters:@{@"eventName":@"etypeName"}];
    NSDictionary *payload = [self assertProcessEvent:event state:self.defaultState expectType:@"etypeName"];
    XCTAssertNil(payload[@"cp"]);
}

- (void)testProcessInvalidCustomEventFails
{
    RAnalyticsEvent *event = [RAnalyticsEvent.alloc initWithName:RAnalyticsCustomEventName parameters:@{@"blah":@"name", @"eventData":@{@"foo":@"bar"}}];
    XCTAssertFalse([RAnalyticsRATTracker.sharedInstance processEvent:event state:[self defaultState]]);
}

- (void)testProcessInvalidEventFails
{
    RAnalyticsEvent *event = [RAnalyticsEvent.alloc initWithName:@"unknown" parameters:nil];
    XCTAssertFalse([RAnalyticsRATTracker.sharedInstance processEvent:event state:[self defaultState]]);
}

- (void)testDeviceBatteryStateReportedInJSON
{
    id deviceSpy = OCMPartialMock(UIDevice.currentDevice);
    [self addMock:deviceSpy];

    OCMStub([deviceSpy batteryState]).andReturn(UIDeviceBatteryStateUnplugged);
    OCMStub([deviceSpy batteryLevel]).andReturn(0.5);

    id payload = [self assertProcessEvent:self.defaultEvent state:self.defaultState expectType:nil];
    NSNumber *powerstatus = payload[@"powerstatus"],
             *mbat        = payload[@"mbat"];

    XCTAssertNotNil(powerstatus);
    XCTAssertNotNil(mbat);

    XCTAssert([powerstatus isKindOfClass:NSNumber.class]);
    XCTAssert([mbat        isKindOfClass:NSString.class]);

    XCTAssertEqual(powerstatus.integerValue, 0);
    XCTAssertEqual(mbat.floatValue,          50);
}

- (void)test_givenNetworkIsWiFi_whenEventIsProcessed_thenJsonMcnValueIsEmptyString
{
    // Given (network is WiFi because tests run on simulator)

    // When
    id payload = [self assertProcessEvent:self.defaultEvent state:self.defaultState expectType:nil];

    // Then
    XCTAssertEqualObjects(payload[@"mcn"], @"");
}

- (void)test_givenNetworkOffline_whenEventIsProcessed_thenJsonMnetwValueIsEmptyString
{
    // Given
    RAnalyticsRATTracker.sharedInstance.reachabilityStatus = @(0); // _RATReachabilityStatusOffline

    // When
    id payload = [self assertProcessEvent:self.defaultEvent state:self.defaultState expectType:nil];

    // Then
    XCTAssertEqualObjects(payload[@"mnetw"], @"");
}

- (void)test_givenNetworkIsWifi_whenEventIsProcessed_thenJsonMnetwValueIsWiFi
{
    // Given
    RAnalyticsRATTracker.sharedInstance.reachabilityStatus = @(2); // _RATReachabilityStatusConnectedWithWiFi

    // When
    id payload = [self assertProcessEvent:self.defaultEvent state:self.defaultState expectType:nil];

    // Then
    XCTAssertEqualObjects(payload[@"mnetw"], @(1)); // _RATMobileNetworkTypeWiFi
}

- (void)test_givenNetworkIsWifi_whenEventIsProcessed_thenJsonMnetwValueIs4G
{
    // Given
    RAnalyticsRATTracker.sharedInstance.reachabilityStatus = @(1); // _RATReachabilityStatusConnectedWithWWAN
    RAnalyticsRATTracker.sharedInstance.isUsingLTE = YES;

    // When
    id payload = [self assertProcessEvent:self.defaultEvent state:self.defaultState expectType:nil];

    // Then
    XCTAssertEqualObjects(payload[@"mnetw"], @(4)); // _RATMobileNetworkType4G
}

- (void)test_givenNetworkIsWifi_whenEventIsProcessed_thenJsonMnetwValueIs3G
{
    // Given
    RAnalyticsRATTracker.sharedInstance.reachabilityStatus = @(1); // _RATReachabilityStatusConnectedWithWWAN
    RAnalyticsRATTracker.sharedInstance.isUsingLTE = NO;

    // When
    id payload = [self assertProcessEvent:self.defaultEvent state:self.defaultState expectType:nil];

    // Then
    XCTAssertEqualObjects(payload[@"mnetw"], @(3)); // _RATMobileNetworkType3G
}

#pragma mark Test batch delay handling and setting delivery strategy

- (void)testRATTrackerDefaultBatchingDelay {
    
    BatchingDelayBlock defaultBatchingDelay = [RAnalyticsRATTracker.sharedInstance.sender performSelector:@selector(batchingDelayBlock)];
    XCTAssertEqual(defaultBatchingDelay(), 1.0);
}

- (void)testRATTrackerWithBatchingDelay
{
    XCTestExpectation *wait = [self expectationWithDescription:@"wait"];

    [self stubRATResponseWithStatusCode:200 completionHandler:nil];

    [RAnalyticsRATTracker.sharedInstance setBatchingDelay:15.0];

    [RAnalyticsRATTracker.sharedInstance processEvent:self.defaultEvent state:self.defaultState];

    // Wait for Sender to check delivery strategy batching delay
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{

        [wait fulfill];
        NSTimeInterval expectedDelay = 15.0;
        XCTAssertEqual(RAnalyticsRATTracker.sharedInstance.sender.uploadTimerInterval, expectedDelay);
    });

    [self waitForExpectationsWithTimeout:3.0 handler:nil];
}

- (void)testRATTrackerWithBatchingDelayBlock
{
    XCTestExpectation *wait = [self expectationWithDescription:@"wait"];

    [self stubRATResponseWithStatusCode:200 completionHandler:nil];

    [RAnalyticsRATTracker.sharedInstance setBatchingDelayWithBlock:^NSTimeInterval{
        return 10.0;
    }];

    [RAnalyticsRATTracker.sharedInstance processEvent:self.defaultEvent state:self.defaultState];

    // Wait for Sender to check delivery strategy batching delay
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{

        [wait fulfill];
        NSTimeInterval expectedDelay = 10.0;
        XCTAssertEqual(RAnalyticsRATTracker.sharedInstance.sender.uploadTimerInterval, expectedDelay);
    });

    [self waitForExpectationsWithTimeout:3.0 handler:nil];
}

#pragma mark Test number validation
- (void)testNumberValidationWithNil
{
    XCTAssertNil([RAnalyticsRATTracker.sharedInstance positiveIntegerNumberWithObject:nil]);
}

- (void)testNumberValidationWithIntegerNumber
{
    NSInteger num = 123;
    NSNumber *integerNumber = [NSNumber numberWithInteger:num];
    NSNumber *number = [RAnalyticsRATTracker.sharedInstance positiveIntegerNumberWithObject:integerNumber];
    XCTAssertNotNil(number);
    XCTAssertTrue([number isEqualToNumber:@(123)]);
}

- (void)testNumberValidationWithChar
{
    char num = 'a';
    NSNumber *integerNumber = [NSNumber numberWithChar:num];
    NSNumber *number = [RAnalyticsRATTracker.sharedInstance positiveIntegerNumberWithObject:integerNumber];
    XCTAssertNotNil(number);
    XCTAssertTrue([number isEqualToNumber:@(97)]);
}

- (void)testNumberValidationWithPositiveInt16Number
{
    int16_t num = 123;
    NSNumber *integerNumber = [NSNumber numberWithShort:num];
    NSNumber *number = [RAnalyticsRATTracker.sharedInstance positiveIntegerNumberWithObject:integerNumber];
    XCTAssertNotNil(number);
    XCTAssertTrue([number isEqualToNumber:@(123)]);
}

- (void)testNumberValidationWithPositiveInt32Number
{
    int32_t num = 123;
    NSNumber *integerNumber = [NSNumber numberWithLong:num];
    NSNumber *number = [RAnalyticsRATTracker.sharedInstance positiveIntegerNumberWithObject:integerNumber];
    XCTAssertNotNil(number);
    XCTAssertTrue([number isEqualToNumber:@(123)]);
}

- (void)testNumberValidationWithPositiveInt64Number
{
    int64_t num = 123;
    NSNumber *integerNumber = [NSNumber numberWithLong:num];
    NSNumber *number = [RAnalyticsRATTracker.sharedInstance positiveIntegerNumberWithObject:integerNumber];
    XCTAssertNotNil(number);
    XCTAssertTrue([number isEqualToNumber:@(123)]);
}

- (void)testNumberValidationWithSignedChar
{
    int8_t num = -6;
    NSNumber *integerNumber = [NSNumber numberWithChar:num];
    NSNumber *number = [RAnalyticsRATTracker.sharedInstance positiveIntegerNumberWithObject:integerNumber];
    XCTAssertNil(number);
}

- (void)testNumberValidationWithNegativeInt16Number
{
    int16_t num = -123;
    NSNumber *integerNumber = [NSNumber numberWithShort:num];
    NSNumber *number = [RAnalyticsRATTracker.sharedInstance positiveIntegerNumberWithObject:integerNumber];
    XCTAssertNil(number);
}

- (void)testNumberValidationWithNegativeInt32Number
{
    int32_t num = -123;
    NSNumber *integerNumber = [NSNumber numberWithLong:num];
    NSNumber *number = [RAnalyticsRATTracker.sharedInstance positiveIntegerNumberWithObject:integerNumber];
    XCTAssertNil(number);
}

- (void)testNumberValidationWithNegativeInt64Number
{
    int64_t num = -123;
    NSNumber *integerNumber = [NSNumber numberWithLong:num];
    NSNumber *number = [RAnalyticsRATTracker.sharedInstance positiveIntegerNumberWithObject:integerNumber];
    XCTAssertNil(number);
}

- (void)testNumberValidationWithZeroNumber
{
    int64_t num = 0;
    NSNumber *integerNumber = [NSNumber numberWithLong:num];
    NSNumber *number = [RAnalyticsRATTracker.sharedInstance positiveIntegerNumberWithObject:integerNumber];
    XCTAssertNil(number);
}

- (void)testNumberValidationWithFloatNumber
{
    NSNumber *number = [RAnalyticsRATTracker.sharedInstance positiveIntegerNumberWithObject:@(123.4)];
    XCTAssertNil(number);
}

- (void)testNumberValidationWithString
{
    NSNumber *number = [RAnalyticsRATTracker.sharedInstance positiveIntegerNumberWithObject:@"123"];
    XCTAssertNotNil(number);
    XCTAssertTrue([number isEqualToNumber:@(123)]);
}

- (void)testNumberValidationWithStringIncludingWhiteSpace
{
    NSNumber *number = [RAnalyticsRATTracker.sharedInstance positiveIntegerNumberWithObject:@"12 3"];
    XCTAssertNil(number);
}

- (void)testNumberValidationWithStringLikeAFloatNumber
{
    NSNumber *number = [RAnalyticsRATTracker.sharedInstance positiveIntegerNumberWithObject:@"12.3"];
    XCTAssertNil(number);
}

- (void)testNumberValidationWithStringLikeZeroNumber
{
    NSNumber *number = [RAnalyticsRATTracker.sharedInstance positiveIntegerNumberWithObject:@"0"];
    XCTAssertNil(number);
}

- (void)testNumberValidationWithStringLikeNegativeNumber
{
    NSNumber *number = [RAnalyticsRATTracker.sharedInstance positiveIntegerNumberWithObject:@"-10"];
    XCTAssertNil(number);
}

- (void)testNumberValidationWithStringLeadingByZero
{
    NSNumber *number = [RAnalyticsRATTracker.sharedInstance positiveIntegerNumberWithObject:@"01"];
    XCTAssertNil(number);
}

- (void)testNumberValidationWithStringIncludingCharacter
{
    NSNumber *number = [RAnalyticsRATTracker.sharedInstance positiveIntegerNumberWithObject:@"12e3"];
    XCTAssertNil(number);
}

@end

