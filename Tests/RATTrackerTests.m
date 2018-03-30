@import XCTest;
#import <OCMock/OCMock.h>
#import <OHHTTPStubs/OHHTTPStubs.h>
#import "../RAnalytics/Util/Private/_RAnalyticsHelpers.h"
#import "../RAnalytics/Util/Private/_RAnalyticsDatabase.h"
#import "TrackerTests.h"

#pragma mark - Module Internals

@interface RAnalyticsState ()
@property (nonatomic, readwrite)                    RAnalyticsLoginMethod     loginMethod;
@property (nonatomic, readwrite)                    RAnalyticsOrigin          origin;
@end

@interface RATTracker ()
@property (nonatomic) int64_t                   accountIdentifier;
@property (nonatomic) int64_t                   applicationIdentifier;
@property (nonatomic, copy, nullable) NSString *lastVisitedPageIdentifier;
@property (nonatomic, copy, nullable) NSNumber *carriedOverOrigin;
@property (nonatomic) RAnalyticsSender      *sender;
- (instancetype)initInstance;
@end

@interface RAnalyticsSender ()
@property (nonatomic) NSTimeInterval            uploadTimerInterval;
@property (nonatomic) NSTimer                  *uploadTimer;
@end

@interface RAnalyticsManager ()
@property(nonatomic, strong) NSMutableSet RSDKA_GENERIC(id<RAnalyticsTracker>) *trackers;
@end

#pragma mark - Unit Tests

@interface RATTrackerTests : TrackerTests
@end

@implementation RATTrackerTests

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
        if ([t isKindOfClass:RATTracker.class])
        {
            RATTracker *rT = (RATTracker *)t;
            [self invalidateTimerOfSender:rT.sender];
        }
    }
    [super tearDown];
}

#pragma mark TrackerTestConfiguration protocol
- (id<RAnalyticsTracker>)testedTracker
{
    return [RATTracker.alloc initInstance];
}

#pragma mark Test initialisation and configuration

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
    RAnalyticsEvent *event = [RATTracker.sharedInstance eventWithEventType:@"login" parameters:params];
    XCTAssertNotNil(event);
    XCTAssertEqualObjects(event.name,       @"rat.login");
    XCTAssertEqualObjects(event.parameters, params);
}

- (void)testThatPlistAccountIdKeyIsUsedWhenSet
{
    // setUp() already mocks mainBundle so need to remove
    [self.mocks enumerateObjectsUsingBlock:^(id mock, NSUInteger idx, BOOL *stop) {
        [mock stopMocking];
    }];
    
    NSInteger expected = 10;
    id mockBundle = OCMPartialMock(NSBundle.mainBundle);
    OCMStub([mockBundle objectForInfoDictionaryKey:@"RATAccountIdentifier"]).andReturn([NSNumber numberWithLongLong:expected]);
    
    // need a freshly allocated instance so that the plist is read
    RATTracker *tracker = [RATTracker.alloc initInstance];
    
    XCTAssertEqual(tracker.accountIdentifier, expected);
}

- (void)testThatDefaultAccountIdIsUsedWhenPlistKeyIsNotSet
{
    XCTAssertEqual(RATTracker.sharedInstance.accountIdentifier, 477);
}

- (void)testThatPlistApplicationIdKeyIsUsedWhenSet
{
    // setUp() already mocks mainBundle so need to remove
    [self.mocks enumerateObjectsUsingBlock:^(id mock, NSUInteger idx, BOOL *stop) {
        [mock stopMocking];
    }];
    
    NSInteger expected = 10;
    id mockBundle = OCMPartialMock(NSBundle.mainBundle);
    OCMStub([mockBundle objectForInfoDictionaryKey:@"RATAppIdentifier"]).andReturn([NSNumber numberWithLongLong:expected]);
    
    // need a freshly allocated instance so that the plist is read
    RATTracker *tracker = [RATTracker.alloc initInstance];
    
    XCTAssertEqual(tracker.applicationIdentifier, expected);
}

- (void)testThatDefaultApplicationIdIsUsedWhenPlistKeyIsNotSet
{
    XCTAssertEqual(RATTracker.sharedInstance.applicationIdentifier, 1);
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
    XCTAssertFalse([RATTracker.sharedInstance processEvent:event state:[self defaultState]]);
}

- (void)testProcessInvalidEventFails
{
    RAnalyticsEvent *event = [RAnalyticsEvent.alloc initWithName:@"unknown" parameters:nil];
    XCTAssertFalse([RATTracker.sharedInstance processEvent:event state:[self defaultState]]);
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

#pragma mark Test batch delay handling and setting delivery strategy

- (void)testRATTrackerWithBatchingDelay
{
    XCTestExpectation *wait = [self expectationWithDescription:@"wait"];

    [self stubRATResponseWithStatusCode:200 completionHandler:nil];

    [RATTracker.sharedInstance setBatchingDelay:15.0];

    [RATTracker.sharedInstance processEvent:self.defaultEvent state:self.defaultState];

    // Wait for Sender to check delivery strategy batching delay
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{

        [wait fulfill];
        NSTimeInterval expectedDelay = 15.0;
        XCTAssertEqual(RATTracker.sharedInstance.sender.uploadTimerInterval, expectedDelay);
    });

    [self waitForExpectationsWithTimeout:3.0 handler:nil];
}

- (void)testRATTrackerWithBatchingDelayBlock
{
    XCTestExpectation *wait = [self expectationWithDescription:@"wait"];

    [self stubRATResponseWithStatusCode:200 completionHandler:nil];

    [RATTracker.sharedInstance setBatchingDelayWithBlock:^NSTimeInterval{
        return 10.0;
    }];

    [RATTracker.sharedInstance processEvent:self.defaultEvent state:self.defaultState];

    // Wait for Sender to check delivery strategy batching delay
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{

        [wait fulfill];
        NSTimeInterval expectedDelay = 10.0;
        XCTAssertEqual(RATTracker.sharedInstance.sender.uploadTimerInterval, expectedDelay);
    });

    [self waitForExpectationsWithTimeout:3.0 handler:nil];
}
@end
