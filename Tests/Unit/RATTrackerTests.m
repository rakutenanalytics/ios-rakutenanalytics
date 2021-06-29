@import XCTest;
#import <OCMock/OCMock.h>

#import "../../RAnalytics/Util/Private/_RAnalyticsHelpers.h"

#import "TrackerTests.h"
#import <RAnalytics/RAnalytics-Swift.h>
#import "UnitTests-Swift.h"

#import <Kiwi/Kiwi.h>

#pragma mark - Module Internals

@interface TelephonyHandler ()
@property (nonatomic, strong) NSString *mnetw;
@end

@interface RAnalyticsRATTracker ()
@property (nonatomic) int64_t                   accountIdentifier;
@property (nonatomic) int64_t                   applicationIdentifier;
@property (nonatomic, copy, nullable) NSString *lastVisitedPageIdentifier;
@property (nonatomic, copy, nullable) NSNumber *carriedOverOrigin;
@property (nonatomic) RAnalyticsSender      *sender;
@property (nonatomic, nullable) NSNumber *reachabilityStatus;
@property (nonatomic, strong) TelephonyHandler *telephonyHandler;
- (instancetype)initInstance;
- (NSNumber *)positiveIntegerNumberWithObject:(id)object;
@end

@interface RAnalyticsManager ()
@property(nonatomic, strong) NSMutableSet<id<RAnalyticsTracker>> *trackers;
@end

#pragma mark - Unit Tests

const NSTimeInterval DEFAULT_BATCHING_DELAY = 1.0;

static NSString * const sessionIdentifier = @"CA7A88AB-82FE-40C9-A836-B1B3455DECAB";

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
    // Create in-memory DB and init tracker
    self.connection = [DatabaseTestUtils openRegularConnection];
    self.database = [DatabaseTestUtils mkDatabaseWithConnection:self.connection];
    self.databaseTableName = @"RATTrackerTests_Table";
    RAnalyticsRATTracker *tracker = [RAnalyticsRATTracker.alloc initInstance];
    tracker.sender = [[RAnalyticsSender alloc] initWithEndpoint:[NSURL URLWithString:@"https://endpoint.co.jp/"]
                                                       database:self.database
                                                  databaseTable:self.databaseTableName];
    [tracker setBatchingDelayWithBlock:^NSTimeInterval{
       return DEFAULT_BATCHING_DELAY;
    }];
    return tracker;
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
    [self assertProcessEvent:event state:self.defaultState expectEtype:RAnalyticsInstallEventName assertBlock:^(id  _Nonnull payload) {
        id appInfo = [payload valueForKeyPath:@"cp.app_info"];
        XCTAssert([appInfo containsString:@"xcode"]);
        XCTAssert([appInfo containsString:@"iphonesimulator"]);
    }];
}


- (void)testProcessSessionStartEvent
{
    id event = [RAnalyticsEvent.alloc initWithName:RAnalyticsSessionStartEventName parameters:nil];
    [self assertProcessEvent:event state:self.defaultState expectEtype:RAnalyticsSessionStartEventName assertBlock:^(id  _Nonnull payload) {
        NSInteger daysSinceFirstUse = [[payload valueForKeyPath:@"cp.days_since_first_use"] integerValue];
        NSInteger daysSinceLastUse  = [[payload valueForKeyPath:@"cp.days_since_last_use"] integerValue];
        XCTAssertGreaterThanOrEqual(daysSinceLastUse, 0);
        XCTAssertEqual(daysSinceLastUse, daysSinceFirstUse - 2);
    }];
}

- (void)testProcessSessionEndEvent
{
    id event = [RAnalyticsEvent.alloc initWithName:RAnalyticsSessionEndEventName parameters:nil];
    [self assertProcessEvent:event state:self.defaultState expectType:RAnalyticsSessionEndEventName];
}

- (void)testProcessApplicationUpdateEvent
{
    id event = [RAnalyticsEvent.alloc initWithName:RAnalyticsApplicationUpdateEventName parameters:nil];
    [self assertProcessEvent:event state:self.defaultState expectEtype:RAnalyticsApplicationUpdateEventName assertBlock:^(id  _Nonnull payload) {
        NSInteger launchesSinceUpgrade = [[payload valueForKeyPath:@"cp.launches_since_last_upgrade"] integerValue];
        NSInteger daysSinceUpgrade     = [[payload valueForKeyPath:@"cp.days_since_last_upgrade"] integerValue];
        XCTAssertGreaterThan(launchesSinceUpgrade, 0);
        XCTAssertGreaterThan(daysSinceUpgrade,     0);
    }];
}

- (void)testProcessOneTapLoginEvent
{
    id event = [RAnalyticsEvent.alloc initWithName:RAnalyticsLoginEventName parameters:nil];
    [self assertProcessEvent:event state:self.defaultState expectEtype:RAnalyticsLoginEventName assertBlock:^(id  _Nonnull payload) {
        XCTAssertEqualObjects([payload valueForKeyPath:@"cp.login_method"], @"one_tap_login");
    }];
}

- (void)testProcessPasswordLoginEvent
{
    RAnalyticsState *state = self.defaultState.copy;
    state.loginMethod = RAnalyticsPasswordInputLoginMethod;

    id event = [RAnalyticsEvent.alloc initWithName:RAnalyticsLoginEventName parameters:nil];
    [self assertProcessEvent:event state:state expectEtype:RAnalyticsLoginEventName assertBlock:^(id  _Nonnull payload) {
        XCTAssertEqualObjects([payload valueForKeyPath:@"cp.login_method"], @"password");
    }];
}

- (void)testProcessLocalLogoutEvent
{
    id event = [RAnalyticsEvent.alloc initWithName:RAnalyticsLogoutEventName parameters:@{RAnalyticsLogoutMethodEventParameter:RAnalyticsLocalLogoutMethod}];
    [self assertProcessEvent:event state:self.defaultState expectEtype:RAnalyticsLogoutEventName assertBlock:^(id  _Nonnull payload) {
        XCTAssertEqualObjects([payload valueForKeyPath:@"cp.logout_method"], @"single");
    }];
}

- (void)testProcessGlobalLogoutEvent
{
    id event = [RAnalyticsEvent.alloc initWithName:RAnalyticsLogoutEventName parameters:@{RAnalyticsLogoutMethodEventParameter:RAnalyticsGlobalLogoutMethod}];
    [self assertProcessEvent:event state:self.defaultState expectEtype:RAnalyticsLogoutEventName assertBlock:^(id  _Nonnull payload) {
        XCTAssertEqualObjects([payload valueForKeyPath:@"cp.logout_method"], @"all");
    }];
}

- (void)testProcessEmptyLogoutEvent
{
    id event = [RAnalyticsEvent.alloc initWithName:RAnalyticsLogoutEventName parameters:nil];
    [self assertProcessEvent:event state:self.defaultState expectEtype:RAnalyticsLogoutEventName assertBlock:^(id  _Nonnull payload) {
        XCTAssertNil([payload valueForKeyPath:@"cp.logout_method"]);
    }];
}

- (void)testProcessPasswordLoginFailureEvent
{
    id event = [RAnalyticsEvent.alloc initWithName:RAnalyticsLoginFailureEventName parameters:@{@"type":@"password_login", @"rae_error" : @"invalid_grant"}];
    [self assertProcessEvent:event state:self.defaultState expectEtype:RAnalyticsLoginFailureEventName assertBlock:^(id  _Nonnull payload) {
        XCTAssertEqualObjects([payload valueForKeyPath:@"cp.type"], @"password_login");
        XCTAssertEqualObjects([payload valueForKeyPath:@"cp.rae_error"], @"invalid_grant");
    }];
}

- (void)testProcessSSOLoginFailureEvent
{
    id event = [RAnalyticsEvent.alloc initWithName:RAnalyticsLoginFailureEventName parameters:@{@"type":@"sso_login", @"rae_error" : @"invalid_scope"}];
    [self assertProcessEvent:event state:self.defaultState expectEtype:RAnalyticsLoginFailureEventName assertBlock:^(id  _Nonnull payload) {
        XCTAssertEqualObjects([payload valueForKeyPath:@"cp.type"], @"sso_login");
        XCTAssertEqualObjects([payload valueForKeyPath:@"cp.rae_error"], @"invalid_scope");
    }];
}

- (void)testProcessLoginFailureEventForIDSDK
{
    id event = [RAnalyticsEvent.alloc initWithName:RAnalyticsLoginFailureEventName
                                        parameters:@{@"idsdk_error" : @"IDSDK Login Error", @"idsdk_error_message" : @"Network Error"}];
    [self assertProcessEvent:event state:self.defaultState expectEtype:RAnalyticsLoginFailureEventName assertBlock:^(id  _Nonnull payload) {
        XCTAssertEqualObjects([payload valueForKeyPath:@"cp.idsdk_error"], @"IDSDK Login Error");
        XCTAssertEqualObjects([payload valueForKeyPath:@"cp.idsdk_error_message"], @"Network Error");
    }];
}

- (void)testProcessPageVisitEventWithPageId
{
    NSString *pageId = @"TestPage";
    id event = [RAnalyticsEvent.alloc initWithName:RAnalyticsPageVisitEventName parameters:@{@"page_id": pageId}];
    [self assertProcessEvent:event state:self.defaultState expectEtype:@"pv" assertBlock:^(id  _Nonnull payload) {
        XCTAssertEqualObjects([payload valueForKeyPath:@"pgn"], pageId);
        XCTAssertEqualObjects([payload valueForKeyPath:@"cp.ref_type"], @"internal");
    }];
}

- (void)testProcessPageVisitEventWithoutPageId
{
    id event = [RAnalyticsEvent.alloc initWithName:RAnalyticsPageVisitEventName parameters:nil];
    [self assertProcessEvent:event state:self.defaultState expectEtype:@"pv" assertBlock:^(id  _Nonnull payload) {
        XCTAssertEqualObjects([payload valueForKeyPath:@"pgn"], NSStringFromClass(CurrentPage.class));
        XCTAssertEqualObjects([payload valueForKeyPath:@"cp.ref_type"], @"internal");
    }];
}

- (void)testProcessPageWithRef
{
    // Given
    XCTestExpectation *wait = [self expectationWithDescription:@"wait"];
    NSString *firstPage = @"FirstPage";
    NSString *secondPage = @"SecondPage";

    id firstEvent = [RAnalyticsEvent.alloc initWithName:RAnalyticsPageVisitEventName parameters:@{@"page_id": firstPage}];
    id secondEvent = [RAnalyticsEvent.alloc initWithName:RAnalyticsPageVisitEventName parameters:@{@"page_id": secondPage}];

    // When
    [self.tracker processEvent:firstEvent state:self.defaultState];
    [self.tracker processEvent:secondEvent state:self.defaultState];

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        NSData *data = [DatabaseTestUtils fetchTableContents:self.databaseTableName connection:self.connection].lastObject;
        NSDictionary *payload = [NSJSONSerialization JSONObjectWithData:data options:0 error:0];
        XCTAssertNotNil(payload);
        XCTAssertEqualObjects(payload[@"pgn"], secondPage);
        XCTAssertEqualObjects(payload[@"ref"], firstPage);
        [wait fulfill];
    });

    // Then
    [self waitForExpectationsWithTimeout:1.0 handler:nil];
}

- (void)testProcessExternalPageVisitEvent
{
    NSString *pageId = @"TestPage";
    RAnalyticsState *state = self.defaultState.copy;
    state.origin = RAnalyticsExternalOrigin;

    id event = [RAnalyticsEvent.alloc initWithName:RAnalyticsPageVisitEventName parameters:@{@"page_id": pageId}];
    [self assertProcessEvent:event state:state expectEtype:@"pv" assertBlock:^(id  _Nonnull payload) {
        XCTAssertEqualObjects([payload valueForKeyPath:@"pgn"], pageId);
        XCTAssertEqualObjects([payload valueForKeyPath:@"cp.ref_type"], @"external");
    }];
}

- (void)testProcessPushPageVisitEvent
{
    NSString *pageId = @"TestPage";
    RAnalyticsState *state = self.defaultState.copy;
    state.origin = RAnalyticsPushOrigin;

    id event = [RAnalyticsEvent.alloc initWithName:RAnalyticsPageVisitEventName parameters:@{@"page_id": pageId}];
    [self assertProcessEvent:event state:state expectEtype:@"pv" assertBlock:^(id  _Nonnull payload) {
        XCTAssertEqualObjects([payload valueForKeyPath:@"pgn"], pageId);
        XCTAssertEqualObjects([payload valueForKeyPath:@"cp.ref_type"], @"push");
    }];
}

- (void)testProcessPushEvent
{
    NSString *trackingIdentifier = @"trackingIdentifier";
    id event = [RAnalyticsEvent.alloc initWithName:RAnalyticsPushNotificationEventName
                                           parameters:@{RAnalyticsPushNotificationTrackingIdentifierParameter: trackingIdentifier}];
    [self assertProcessEvent:event state:self.defaultState expectEtype:RAnalyticsPushNotificationEventName assertBlock:^(id  _Nonnull payload) {
        XCTAssertEqualObjects([payload valueForKeyPath:@"cp.push_notify_value"], trackingIdentifier);
    }];
}

- (void)testProcessInitWithPushEvent
{
    id event = [RAnalyticsEvent.alloc initWithPushNotificationPayload:@{@"rid":@"123456"}];
    [self assertProcessEvent:event state:self.defaultState expectEtype:RAnalyticsPushNotificationEventName assertBlock:^(id  _Nonnull payload) {
        XCTAssertEqualObjects([payload valueForKeyPath:@"cp.push_notify_value"], @"rid:123456");
    }];
}

- (void)testProcessDiscoverEvent
{
    NSString *discoverEvent = @"_rem_discover_event";
    NSString *appName       = @"appName";
    NSString *storeURL      = @"storeUrl";

    id event = [RAnalyticsEvent.alloc initWithName:discoverEvent
                                           parameters:@{@"prApp" : appName, @"prStoreUrl": storeURL}];
    [self assertProcessEvent:event state:self.defaultState expectEtype:discoverEvent assertBlock:^(id  _Nonnull payload) {
        XCTAssertEqualObjects([payload valueForKeyPath:@"cp.prApp"], appName);
        XCTAssertEqualObjects([payload valueForKeyPath:@"cp.prStoreUrl"], storeURL);
    }];
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
    [self assertProcessEvent:event state:self.defaultState expectEtype:@"etypeName" assertBlock:^(id  _Nonnull payload) {
        XCTAssertEqualObjects(payload[@"cp"][@"foo"], @"bar");
    }];
}

- (void)testProcessCustomEventNoData
{
    id event = [RAnalyticsEvent.alloc initWithName:RAnalyticsCustomEventName parameters:@{@"eventName":@"etypeName"}];
    [self assertProcessEvent:event state:self.defaultState expectEtype:@"etypeName" assertBlock:^(id  _Nonnull payload) {
        XCTAssertNil(payload[@"cp"]);
    }];
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

    [self assertProcessEvent:self.defaultEvent state:self.defaultState expectEtype:nil assertBlock:^(id  _Nonnull payload) {
        NSNumber *powerstatus = payload[@"powerstatus"],
                 *mbat        = payload[@"mbat"];

        XCTAssertNotNil(powerstatus);
        XCTAssertNotNil(mbat);

        XCTAssert([powerstatus isKindOfClass:NSNumber.class]);
        XCTAssert([mbat        isKindOfClass:NSString.class]);

        XCTAssertEqual(powerstatus.integerValue, 0);
        XCTAssertEqual(mbat.floatValue,          50);
    }];
}

#pragma mark mcn and mcnd

- (void)test_givenNoCarrier_whenEventIsProcessed_thenJsonMcnAmdMcndValuesAreEmptyString
{
    // Given
    id telephonyHandlerMock = OCMPartialMock(RAnalyticsRATTracker.sharedInstance.telephonyHandler);
    OCMStub([telephonyHandlerMock mcn]).andReturn(@"");
    OCMStub([telephonyHandlerMock mcnd]).andReturn(@"");
    
    [self assertProcessEvent:self.defaultEvent state:self.defaultState assertBlock:^(id  _Nonnull payload) {
        XCTAssertEqualObjects(payload[@"mcn"], @"");
        XCTAssertEqualObjects(payload[@"mcnd"], @"");
    }];
}

- (void)test_givenCarriers_whenEventIsProcessed_thenJsonMcnAndMcndValuesAreNotEmptyString
{
    // Given
    id telephonyHandlerMock = OCMPartialMock(RAnalyticsRATTracker.sharedInstance.telephonyHandler);
    OCMStub([telephonyHandlerMock mcn]).andReturn(@"Carrier1");
    OCMStub([telephonyHandlerMock mcnd]).andReturn(@"Carrier2");
    
    [self assertProcessEvent:self.defaultEvent state:self.defaultState assertBlock:^(id  _Nonnull payload) {
        XCTAssertEqualObjects(payload[@"mcn"], @"Carrier1");
        XCTAssertEqualObjects(payload[@"mcnd"], @"Carrier2");
    }];
}

#pragma mark mnetw and mnetwd

- (void)test_givenNetworkIsOffline_whenEventIsProcessed_thenJsonMnetwAndMnetwdValuesAreEmptyString
{
    // Given
    RAnalyticsRATTracker.sharedInstance.reachabilityStatus = @(RATReachabilityStatusOffline);

    // When
    [self assertProcessEvent:self.defaultEvent state:self.defaultState assertBlock:^(id  _Nonnull payload) {
        // Then
        XCTAssertEqualObjects(payload[@"mnetw"], @"");
        XCTAssertEqualObjects(payload[@"mnetwd"], @"");
    }];
}

- (void)test_givenNetworkIsWifi_whenEventIsProcessed_thenJsonMnetwAndMnetwdValuesAreWiFi
{
    // Given
    RAnalyticsRATTracker.sharedInstance.reachabilityStatus = @(RATReachabilityStatusWifi);

    // When
    [self assertProcessEvent:self.defaultEvent state:self.defaultState assertBlock:^(id  _Nonnull payload) {
        // Then
        XCTAssertEqualObjects(payload[@"mnetw"], @(RATMobileNetworkTypeWifi));
        XCTAssertEqualObjects(payload[@"mnetwd"], @(RATMobileNetworkTypeWifi));
    }];
}

- (void)test_givenNetworkIsWWANAndPhysicalSimNetworkIsLTE_whenEventIsProcessed_thenJsonMnetwValueIsLTE
{
    // Given
    RAnalyticsRATTracker.sharedInstance.reachabilityStatus = @(RATReachabilityStatusWwan);
    
    id telephonyHandlerMock = OCMPartialMock(RAnalyticsRATTracker.sharedInstance.telephonyHandler);
    OCMStub([telephonyHandlerMock mnetw]).andReturn(@(RATMobileNetworkTypeCellularLTE));
    
    // When
    [self assertProcessEvent:self.defaultEvent state:self.defaultState assertBlock:^(id  _Nonnull payload) {
        // Then
        XCTAssertEqualObjects(payload[@"mnetw"], @(RATMobileNetworkTypeCellularLTE));
    }];
}

- (void)test_givenNetworkIsWWANAndPhysicalSimNetworkIs5G_whenEventIsProcessed_thenJsonMnetwValueIs5G
{
    // Given
    RAnalyticsRATTracker.sharedInstance.reachabilityStatus = @(RATReachabilityStatusWwan);
    
    id telephonyHandlerMock = OCMPartialMock(RAnalyticsRATTracker.sharedInstance.telephonyHandler);
    OCMStub([telephonyHandlerMock mnetw]).andReturn(@(RATMobileNetworkTypeCellular5G));
    
    // When
    [self assertProcessEvent:self.defaultEvent state:self.defaultState assertBlock:^(id  _Nonnull payload) {
        // Then
        XCTAssertEqualObjects(payload[@"mnetw"], @(RATMobileNetworkTypeCellular5G));
    }];
}

- (void)test_givenNetworkIsWWANAndPhysicalSimNetworkIsNonLTE_whenEventIsProcessed_thenJsonMnetwValueIsNonLTE
{
    // Given
    RAnalyticsRATTracker.sharedInstance.reachabilityStatus = @(RATReachabilityStatusWwan);
    
    id telephonyHandlerMock = OCMPartialMock(RAnalyticsRATTracker.sharedInstance.telephonyHandler);
    OCMStub([telephonyHandlerMock mnetw]).andReturn(@(RATMobileNetworkTypeCellularOther));

    // When
    [self assertProcessEvent:self.defaultEvent state:self.defaultState assertBlock:^(id  _Nonnull payload) {
        // Then
        XCTAssertEqualObjects(payload[@"mnetw"], @(RATMobileNetworkTypeCellularOther));
    }];
}

- (void)test_givenNetworkIsWWANAndeSimNetworkIsLTE_whenEventIsProcessed_thenJsonMnetwdValueIsLTE
{
    // Given
    RAnalyticsRATTracker.sharedInstance.reachabilityStatus = @(RATReachabilityStatusWwan);
    
    id telephonyHandlerMock = OCMPartialMock(RAnalyticsRATTracker.sharedInstance.telephonyHandler);
    OCMStub([telephonyHandlerMock mnetwd]).andReturn(@(RATMobileNetworkTypeCellularLTE));
    
    // When
    [self assertProcessEvent:self.defaultEvent state:self.defaultState assertBlock:^(id  _Nonnull payload) {
        // Then
        XCTAssertEqualObjects(payload[@"mnetwd"], @(RATMobileNetworkTypeCellularLTE));
    }];
}

- (void)test_givenNetworkIsWWANAndeSimNetworkIs5G_whenEventIsProcessed_thenJsonMnetwdValueIs5G
{
    // Given
    RAnalyticsRATTracker.sharedInstance.reachabilityStatus = @(RATReachabilityStatusWwan);
    
    id telephonyHandlerMock = OCMPartialMock(RAnalyticsRATTracker.sharedInstance.telephonyHandler);
    OCMStub([telephonyHandlerMock mnetwd]).andReturn(@(RATMobileNetworkTypeCellular5G));
    
    // When
    [self assertProcessEvent:self.defaultEvent state:self.defaultState assertBlock:^(id  _Nonnull payload) {
        // Then
        XCTAssertEqualObjects(payload[@"mnetwd"], @(RATMobileNetworkTypeCellular5G));
    }];
}

- (void)test_givenNetworkIsWWANAndeSimNetworkIsNonLTE_whenEventIsProcessed_thenJsonMnetwdValueIsNonLTE
{
    // Given
    RAnalyticsRATTracker.sharedInstance.reachabilityStatus = @(RATReachabilityStatusWwan);
    
    id telephonyHandlerMock = OCMPartialMock(RAnalyticsRATTracker.sharedInstance.telephonyHandler);
    OCMStub([telephonyHandlerMock mnetwd]).andReturn(@(RATMobileNetworkTypeCellularOther));

    // When
    [self assertProcessEvent:self.defaultEvent state:self.defaultState assertBlock:^(id  _Nonnull payload) {
        // Then
        XCTAssertEqualObjects(payload[@"mnetwd"], @(RATMobileNetworkTypeCellularOther));
    }];
}

#pragma mark Test batch delay handling and setting delivery strategy

- (void)testRATTrackerDefaultBatchingDelay {

    BatchingDelayBlock defaultBatchingDelay = [RAnalyticsRATTracker.sharedInstance.sender performSelector:@selector(batchingDelayBlock)];
    XCTAssertEqual(defaultBatchingDelay(), DEFAULT_BATCHING_DELAY);
}

- (void)testRATTrackerWithBatchingDelay
{
    XCTestExpectation *wait = [self expectationWithDescription:@"wait"];

    [self stubRATResponseWithStatusCode:200 completionHandler:nil];

    [RAnalyticsRATTracker.sharedInstance setBatchingDelay:15.0];

    [RAnalyticsRATTracker.sharedInstance processEvent:self.defaultEvent state:self.defaultState];

    // Wait for Sender to check delivery strategy batching delay
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{

        NSTimeInterval expectedDelay = 15.0;
        XCTAssertEqual(RAnalyticsRATTracker.sharedInstance.sender.uploadTimerInterval, expectedDelay);
        [wait fulfill];
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

        NSTimeInterval expectedDelay = 10.0;
        XCTAssertEqual(RAnalyticsRATTracker.sharedInstance.sender.uploadTimerInterval, expectedDelay);
        [wait fulfill];
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
    XCTAssertEqualObjects(number, @1);
}

- (void)testNumberValidationWithStringIncludingCharacter
{
    NSNumber *number = [RAnalyticsRATTracker.sharedInstance positiveIntegerNumberWithObject:@"12e3"];
    XCTAssertNil(number);
}

#pragma mark Mori - Interface Orientations

- (void)assertMori:(NSInteger)mori interfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    id classMockApplication = OCMPartialMock(UIApplication.sharedApplication);
    OCMStub([classMockApplication performSelector:@selector(analyticsStatusBarOrientation)]).andReturn(interfaceOrientation);
    RAnalyticsEvent *event = [RAnalyticsEvent.alloc initWithName:RAnalyticsInstallEventName parameters:nil];
    [self assertProcessEvent:event
                       state:self.defaultState
                 expectEtype:RAnalyticsInstallEventName
                 assertBlock:^(id  _Nonnull payload) {
        XCTAssertEqual([payload[@"mori"] intValue], mori);
    }];
    [classMockApplication stopMocking];
}

- (void)testMoriIfUIApplicationReturnsOrientationPortrait
{
    [self assertMori:1 interfaceOrientation:UIInterfaceOrientationPortrait];
}

- (void)testMoriIfUIApplicationReturnsOrientationPortraitUpsideDown
{
    [self assertMori:1 interfaceOrientation:UIInterfaceOrientationPortraitUpsideDown];
}

- (void)testMoriIfUIApplicationReturnsOrientationLandscapeLeft
{
    [self assertMori:2 interfaceOrientation:UIInterfaceOrientationLandscapeLeft];
}

- (void)testMoriIfUIApplicationReturnsOrientationLandscapeRight
{
    [self assertMori:2 interfaceOrientation:UIInterfaceOrientationLandscapeRight];
}

- (void)testMoriIfUIApplicationReturnsOrientationUnknown
{
    [self assertMori:1 interfaceOrientation:UIInterfaceOrientationUnknown];
}

- (void)testMoriIfUIApplicationDoesNotRespondToSharedApplication
{
    id classMockApplication = OCMClassMock(UIApplication.class);
    OCMStub([classMockApplication performSelector:@selector(sharedApplication)]).andReturn(nil);
    RAnalyticsEvent *event = [RAnalyticsEvent.alloc initWithName:RAnalyticsInstallEventName parameters:nil];
    
    [self assertProcessEvent:event state:self.defaultState expectEtype:RAnalyticsInstallEventName assertBlock:^(id  _Nonnull payload) {
        XCTAssertEqual([payload[@"mori"] intValue], 1);
        [classMockApplication stopMocking];
    }];
}

#pragma mark User Identifier

- (void)testPayloadUserIdentifierWithDefaultState
{
    RAnalyticsEvent *event = [RAnalyticsEvent.alloc initWithName:RAnalyticsInstallEventName parameters:nil];
    [self assertProcessEvent:event state:self.defaultState expectEtype:RAnalyticsInstallEventName assertBlock:^(id  _Nonnull payload) {
        XCTAssertTrue([payload[@"userid"] isEqual:@"userId"]);
    }];
}

- (void)testPayloadUserIdentifierWithEmptyState
{
    RAnalyticsEvent *event = [RAnalyticsEvent.alloc initWithName:RAnalyticsInstallEventName parameters:nil];
    RAnalyticsState *state = [RAnalyticsState.alloc initWithSessionIdentifier:sessionIdentifier deviceIdentifier:@"deviceId"];
    [self assertProcessEvent:event state:state expectEtype:RAnalyticsInstallEventName assertBlock:^(id  _Nonnull payload) {
        XCTAssertNil(payload[@"userid"]);
    }];
}

- (void)testPayloadUserIdentifierWithNilState
{
    RAnalyticsEvent *event = [RAnalyticsEvent.alloc initWithName:RAnalyticsInstallEventName parameters:nil];
    [self assertProcessEvent:event state:nil expectEtype:RAnalyticsInstallEventName assertBlock:^(id  _Nonnull payload) {
        XCTAssertNil(payload[@"userid"]);
    }];
}

#pragma mark Easy Identifier

- (void)testPayloadEasyIdentifierWithDefaultState
{
    RAnalyticsEvent *event = [RAnalyticsEvent.alloc initWithName:RAnalyticsInstallEventName parameters:nil];
    [self assertProcessEvent:event state:self.defaultState expectEtype:RAnalyticsInstallEventName assertBlock:^(id  _Nonnull payload) {
        XCTAssertTrue([payload[@"easyid"] isEqual:@"easyId"]);
    }];
}

- (void)testPayloadEasyIdentifierWithEmptyState
{
    RAnalyticsEvent *event = [RAnalyticsEvent.alloc initWithName:RAnalyticsInstallEventName parameters:nil];
    RAnalyticsState *state = [RAnalyticsState.alloc initWithSessionIdentifier:sessionIdentifier deviceIdentifier:@"deviceId"];
    [self assertProcessEvent:event state:state expectEtype:RAnalyticsInstallEventName assertBlock:^(id  _Nonnull payload) {
        XCTAssertNil(payload[@"easyid"]);
    }];
}

- (void)testPayloadEasyIdentifierWithNilState
{
    RAnalyticsEvent *event = [RAnalyticsEvent.alloc initWithName:RAnalyticsInstallEventName parameters:nil];
    [self assertProcessEvent:event state:nil expectEtype:RAnalyticsInstallEventName assertBlock:^(id  _Nonnull payload) {
        XCTAssertNil(payload[@"easyid"]);
    }];
}

@end
