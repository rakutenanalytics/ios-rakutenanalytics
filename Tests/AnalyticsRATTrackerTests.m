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
@property (nonatomic, nullable, readwrite)          UIViewController            *lastVisitedPage;
@end

@interface RATTracker ()
@property (nonatomic) int64_t  accountIdentifier;
@property (nonatomic) int64_t  applicationIdentifier;
@property (nonatomic) NSTimer *uploadTimer;
@end

@interface AnalyticsRATTrackerTests : XCTestCase
{
    RATTracker      *_tracker;
    NSCalendar      *_calendar;
    NSDictionary    *_jsonDataObject;
}
@end

@interface CurrentPage: UIViewController
@end

@implementation CurrentPage
@end

@interface LastVisitedPage: UIViewController
@end

@implementation LastVisitedPage
@end

@implementation AnalyticsRATTrackerTests

- (void)setUp
{
    [super setUp];
    _calendar = [NSCalendar.alloc initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
    _tracker = RATTracker.sharedInstance;
}

- (void)tearDown
{
    [OHHTTPStubs removeAllStubs];
}

#pragma mark - Helpers

- (RSDKAnalyticsState *)defaultState
{
    CLLocation *location = [[CLLocation alloc] initWithLatitude:-56.6462520 longitude:-36.6462520];
    CurrentPage *currentPage = [CurrentPage.alloc init];
    currentPage.view.frame = CGRectMake(0, 0, 100, 100);
    
    NSDateComponents *dateComponents = [NSDateComponents.alloc init];
    [dateComponents setDay:10];
    [dateComponents setMonth:6];
    [dateComponents setYear:2016];
    [dateComponents setHour:9];
    [dateComponents setMinute:15];
    [dateComponents setSecond:30];
    NSDate *sessionStartDate = [_calendar dateFromComponents:dateComponents];
    
    [dateComponents setDay:10];
    [dateComponents setMonth:6];
    [dateComponents setYear:2016];
    NSDate *initialLaunchDate = [_calendar dateFromComponents:dateComponents];
    
    [dateComponents setDay:12];
    [dateComponents setMonth:7];
    [dateComponents setYear:2016];
    NSDate *lastLaunchDate = [_calendar dateFromComponents:dateComponents];
    
    [dateComponents setDay:11];
    [dateComponents setMonth:7];
    [dateComponents setYear:2016];
    NSDate *lastUpdateDate = [_calendar dateFromComponents:dateComponents];
    
    RSDKAnalyticsState *state       = [RSDKAnalyticsState.alloc initWithSessionIdentifier:@"CA7A88AB-82FE-40C9-A836-B1B3455DECAB"
                                                                         deviceIdentifier:@"deviceId"];
    state.advertisingIdentifier     = @"adId";
    state.lastKnownLocation         = location;
    state.sessionStartDate          = sessionStartDate;
    state.userIdentifier            = @"userId";
    state.loginMethod               = RSDKAnalyticsOneTapLoginLoginMethod;
    state.origin                    = RSDKAnalyticsInternalOrigin;
    state.lastVersion               = @"1.0";
    state.initialLaunchDate         = initialLaunchDate;
    state.installLaunchDate         = [initialLaunchDate dateByAddingTimeInterval:-10];
    state.lastLaunchDate            = lastLaunchDate;
    state.lastUpdateDate            = lastUpdateDate;
    state.lastVersionLaunches       = 10;
    state.currentPage               = currentPage;
    state.lastVisitedPage           = LastVisitedPage.new;
    return state;
}

- (RSDKAnalyticsEvent *)defaultEvent
{
    RSDKAnalyticsEvent *event = [RSDKAnalyticsEvent.alloc initWithName:[NSString stringWithFormat:@"%@defaultEvent", _RATEventPrefix] parameters:@{@"param1":@"value1"}];
    return event;
}

- (void)stubInsertBlob:(NSData *)blob
                  into:(NSString *)table
                 limit:(unsigned int)maximumNumberOfBlobs
                  then:(dispatch_block_t)completion
{
    if (!blob) { return; }
    
    _jsonDataObject = [NSJSONSerialization JSONObjectWithData:blob options:0 error:0] ?: nil;
}

- (void)assertProcessedEvent:(RSDKAnalyticsEvent *)event
                   withState:(RSDKAnalyticsState *)state
                    hasValue:(NSString *)value
                      forKey:(NSString *)key
{
    id classMock = OCMClassMock([_RSDKAnalyticsDatabase class]);
    
    OCMStub([classMock insertBlob:[OCMArg any] into:[OCMArg any] limit:5000u then:[OCMArg any]])._andCall(self, @selector(stubInsertBlob:into:limit:then:));
    
    XCTAssertTrue([_tracker processEvent:event state:state ?: [self defaultState]]);
    XCTAssertTrue([_jsonDataObject[key] isEqualToString:value]);
    
    [classMock stopMocking];
}

- (BOOL)assertExpectedNotification:(NSDictionary *)userInfo
{
    NSError *error = userInfo[NSUnderlyingErrorKey];
    XCTAssertTrue([error.userInfo[NSLocalizedDescriptionKey] isEqualToString:@"invalid_response"]);
    return YES;
}

#pragma mark - Tests

- (void)testAnalyticsRATTrackerSharedInstanceIsNotNil
{
    XCTAssertNotNil(_tracker);
}

- (void)testAnalyticsRATTrackerSharedInstanceAreEqual
{
    XCTAssertEqualObjects(_tracker, RATTracker.sharedInstance);
}

- (void)testInitThrowsException
{
    XCTAssertThrowsSpecificNamed([RATTracker.alloc init], NSException, NSInvalidArgumentException);
}

- (void)testEventWithTypeAndParameters
{
    RSDKAnalyticsEvent *event = [_tracker eventWithEventType:@"login" parameters:@{@"acc":@555}];
    XCTAssertNotNil(event);
    XCTAssertTrue([event.name isEqualToString:@"rat.login"]);    
}

- (void)testConfigureWithApplicationId
{
    [_tracker configureWithApplicationId:555];
    XCTAssertTrue(_tracker.applicationIdentifier == 555);
}

- (void)testConfigureWithAccountId
{
    [_tracker configureWithAccountId:333];
    XCTAssertTrue(_tracker.accountIdentifier == 333);
}

- (void)testProcessValidRATEvent
{
    [self assertProcessedEvent:[self defaultEvent]
                     withState:nil
                      hasValue:@"defaultEvent"
                        forKey:@"etype"];
}

- (void)testProcessInitialLaunchEvent
{
    [self assertProcessedEvent:[RSDKAnalyticsEvent.alloc initWithName:RSDKAnalyticsInitialLaunchEventName parameters:nil]
                     withState:nil
                      hasValue:RSDKAnalyticsInitialLaunchEventName
                        forKey:@"etype"];
}

- (void)testProcessInstallEvent
{
    id mockBundle = [OCMockObject niceMockForClass:[NSBundle class]];
    NSBundle *correctMainBundle = [NSBundle bundleForClass:RATTracker.class];
    [[[[mockBundle stub] classMethod] andReturn:correctMainBundle] mainBundle];
    
    [self assertProcessedEvent:[RSDKAnalyticsEvent.alloc initWithName:RSDKAnalyticsInstallEventName parameters:nil]
                     withState:nil
                      hasValue:RSDKAnalyticsInstallEventName
                        forKey:@"etype"];
    
    XCTAssertTrue([_jsonDataObject[@"cp"][@"app_info"] containsString:@"xcode"]);
    XCTAssertTrue([_jsonDataObject[@"cp"][@"app_info"] containsString:@"iphonesimulator"]);
    
    [mockBundle stopMocking];
}

- (void)testProcessSessionStartEvent
{
    [self assertProcessedEvent:[RSDKAnalyticsEvent.alloc initWithName:RSDKAnalyticsSessionStartEventName parameters:nil]
                     withState:nil
                      hasValue:RSDKAnalyticsSessionStartEventName
                        forKey:@"etype"];
    
    NSInteger daysSinceFirstUse = [_jsonDataObject[@"cp"][@"days_since_first_use"] integerValue];
    NSInteger daysSinceLastUse = [_jsonDataObject[@"cp"][@"days_since_last_use"] integerValue];
    XCTAssertTrue(daysSinceFirstUse > 0);
    XCTAssertTrue(daysSinceLastUse > 0);
}

- (void)testProcessSessionEndEvent
{
    [self assertProcessedEvent:[RSDKAnalyticsEvent.alloc initWithName:RSDKAnalyticsSessionEndEventName parameters:nil]
                     withState:nil
                      hasValue:RSDKAnalyticsSessionEndEventName
                        forKey:@"etype"];
}

- (void)testProcessApplicationUpdateEvent
{
    [self assertProcessedEvent:[RSDKAnalyticsEvent.alloc initWithName:RSDKAnalyticsApplicationUpdateEventName parameters:nil]
                     withState:nil
                      hasValue:RSDKAnalyticsApplicationUpdateEventName
                        forKey:@"etype"];
    
    NSInteger launchesSinceUpgrade = [_jsonDataObject[@"cp"][@"launches_since_last_upgrade"] integerValue];
    NSInteger daysSinceUpgrade = [_jsonDataObject[@"cp"][@"days_since_last_upgrade"] integerValue];
    XCTAssertTrue(launchesSinceUpgrade > 0);
    XCTAssertTrue(daysSinceUpgrade > 0);
}

- (void)testProcessOneTapLoginEvent
{
    [self assertProcessedEvent:[RSDKAnalyticsEvent.alloc initWithName:RSDKAnalyticsLoginEventName parameters:nil]
                     withState:nil
                      hasValue:RSDKAnalyticsLoginEventName
                        forKey:@"etype"];
    
    XCTAssertTrue([_jsonDataObject[@"cp"][@"login_method"] isEqualToString:@"one_tap_login"]);
}

- (void)testProcessPasswordLoginEvent
{
    RSDKAnalyticsState *state = [self defaultState];
    state.loginMethod = RSDKAnalyticsPasswordInputLoginMethod;
    
    [self assertProcessedEvent:[RSDKAnalyticsEvent.alloc initWithName:RSDKAnalyticsLoginEventName parameters:nil]
                     withState:state
                      hasValue:RSDKAnalyticsLoginEventName
                        forKey:@"etype"];
    
    XCTAssertTrue([_jsonDataObject[@"cp"][@"login_method"] isEqualToString:@"password"]);
}

- (void)testProcessLocalLogoutEvent
{
    [self assertProcessedEvent:[RSDKAnalyticsEvent.alloc initWithName:RSDKAnalyticsLogoutEventName
                                                           parameters:@{RSDKAnalyticsLogoutMethodEventParameter:RSDKAnalyticsLocalLogoutMethod}]
                     withState:nil
                      hasValue:RSDKAnalyticsLogoutEventName
                        forKey:@"etype"];
    
    XCTAssertTrue([_jsonDataObject[@"cp"][@"logout_method"] isEqualToString:@"single"]);
}

- (void)testProcessGlobalLogoutEvent
{
    [self assertProcessedEvent:[RSDKAnalyticsEvent.alloc initWithName:RSDKAnalyticsLogoutEventName
                                                           parameters:@{RSDKAnalyticsLogoutMethodEventParameter:RSDKAnalyticsGlobalLogoutMethod}]
                     withState:nil
                      hasValue:RSDKAnalyticsLogoutEventName
                        forKey:@"etype"];
    
    XCTAssertTrue([_jsonDataObject[@"cp"][@"logout_method"] isEqualToString:@"all"]);
}

- (void)testProcessEmptyLogoutEvent
{
    [self assertProcessedEvent:[RSDKAnalyticsEvent.alloc initWithName:RSDKAnalyticsLogoutEventName
                                                           parameters:nil]
                     withState:nil
                      hasValue:RSDKAnalyticsLogoutEventName
                        forKey:@"etype"];
    
    XCTAssertNil(_jsonDataObject[@"cp"][@"logout_method"]);
}

- (void)testProcessInternalPageVisitEventWithParam
{
    [self assertProcessedEvent:[RSDKAnalyticsEvent.alloc initWithName:RSDKAnalyticsPageVisitEventName
                                                           parameters:@{@"page_id":@"TestPage1"}]
                     withState:nil
                      hasValue:@"pv"
                        forKey:@"etype"];
    
    XCTAssertTrue([_jsonDataObject[@"pgn"] isEqualToString:@"TestPage1"]);
    XCTAssertTrue([_jsonDataObject[@"ref"] isEqualToString:NSStringFromClass(LastVisitedPage.class)]);
    XCTAssertTrue([_jsonDataObject[@"cp"][@"ref_type"] isEqualToString:@"internal"]);
}

- (void)testProcessInternalPageVisitEventNoParam
{
    [self assertProcessedEvent:[RSDKAnalyticsEvent.alloc initWithName:RSDKAnalyticsPageVisitEventName
                                                           parameters:nil]
                     withState:nil
                      hasValue:@"pv"
                        forKey:@"etype"];
    
    XCTAssertTrue([_jsonDataObject[@"pgn"] isEqualToString:NSStringFromClass(CurrentPage.class)]);
    XCTAssertTrue([_jsonDataObject[@"ref"] isEqualToString:NSStringFromClass(LastVisitedPage.class)]);
    XCTAssertTrue([_jsonDataObject[@"cp"][@"ref_type"] isEqualToString:@"internal"]);
}

- (void)testProcessSSODialogPageVisitEvent
{
    NSString *ssoPageEvent = @"ssodialog.aSSODialogEvent";
    NSString *pageRef = [NSString stringWithFormat:@"%@.aSSODialogEvent", NSStringFromClass(CurrentPage.class)];
    
    [self assertProcessedEvent:[RSDKAnalyticsEvent.alloc initWithName:RSDKAnalyticsPageVisitEventName
                                                           parameters:@{@"page_id":ssoPageEvent}]
                     withState:nil
                      hasValue:@"pv"
                        forKey:@"etype"];
    
    XCTAssertTrue([_jsonDataObject[@"pgn"] isEqualToString:pageRef]);
    XCTAssertTrue([_jsonDataObject[@"ref"] isEqualToString:NSStringFromClass(CurrentPage.class)]);
    XCTAssertTrue([_jsonDataObject[@"cp"][@"ref_type"] isEqualToString:@"internal"]);
}

- (void)testProcessExternalPageVisitEvent
{
    RSDKAnalyticsState *state = [self defaultState];
    state.origin = RSDKAnalyticsExternalOrigin;
    
    [self assertProcessedEvent:[RSDKAnalyticsEvent.alloc initWithName:RSDKAnalyticsPageVisitEventName
                                                           parameters:@{@"page_id":@"TestPage2"}]
                     withState:state
                      hasValue:@"pv"
                        forKey:@"etype"];
    
    XCTAssertTrue([_jsonDataObject[@"pgn"] isEqualToString:@"TestPage2"]);
    XCTAssertTrue([_jsonDataObject[@"ref"] isEqualToString:NSStringFromClass(LastVisitedPage.class)]);
    XCTAssertTrue([_jsonDataObject[@"cp"][@"ref_type"] isEqualToString:@"external"]);
}

- (void)testProcessPushPageVisitEvent
{
    RSDKAnalyticsState *state = [self defaultState];
    state.origin = RSDKAnalyticsPushOrigin;
    
    [self assertProcessedEvent:[RSDKAnalyticsEvent.alloc initWithName:RSDKAnalyticsPageVisitEventName
                                                           parameters:@{@"page_id":@"TestPage3"}]
                     withState:state
                      hasValue:@"pv"
                        forKey:@"etype"];
    
    XCTAssertTrue([_jsonDataObject[@"pgn"] isEqualToString:@"TestPage3"]);
    XCTAssertTrue([_jsonDataObject[@"ref"] isEqualToString:NSStringFromClass(LastVisitedPage.class)]);
    XCTAssertTrue([_jsonDataObject[@"cp"][@"ref_type"] isEqualToString:@"push"]);
}

- (void)testProcessPushEvent
{
    NSString *trackingIdentifier = @"trackingIdentifier";
    
    [self assertProcessedEvent:[RSDKAnalyticsEvent.alloc initWithName:RSDKAnalyticsPushNotificationEventName
                                                           parameters:@{RSDKAnalyticPushNotificationTrackingIdentifierParameter : trackingIdentifier}]
                     withState:nil
                      hasValue:RSDKAnalyticsPushNotificationEventName
                        forKey:@"etype"];
    
    XCTAssertTrue([_jsonDataObject[@"cp"][@"push_notify_value"] isEqualToString:trackingIdentifier]);
}

- (void)testProcessDiscoverEvent
{
    NSString *discoverEvent = @"_rem_discover_event";
    NSString *appNameKey    = @"prApp";
    NSString *appName       = @"appName";
    NSString *storeURLKey   = @"prStoreUrl";
    NSString *storeURL      = @"storeUrl";
    
    [self assertProcessedEvent:[RSDKAnalyticsEvent.alloc initWithName:discoverEvent
                                                           parameters:@{appNameKey : appName, storeURLKey: storeURL}]
                     withState:nil
                      hasValue:discoverEvent
                        forKey:@"etype"];
    
    XCTAssertTrue([_jsonDataObject[@"cp"][appNameKey] isEqualToString:appName]);
    XCTAssertTrue([_jsonDataObject[@"cp"][storeURLKey] isEqualToString:storeURL]);
}

- (void)testProcessCardInfoEvent
{
    NSString *cardInfoEvent = @"_rem_cardinfo_event";
    
    [self assertProcessedEvent:[RSDKAnalyticsEvent.alloc initWithName:cardInfoEvent
                                                           parameters:nil]
                     withState:nil
                      hasValue:cardInfoEvent
                        forKey:@"etype"];
}

- (void)testProcessInvalidEventFails
{
    RSDKAnalyticsEvent *event = [RSDKAnalyticsEvent.alloc initWithName:@"unknown" parameters:@{@"param1":@"value1"}];
    XCTAssertFalse([_tracker processEvent:event state:[self defaultState]]);
}

- (void)testDeviceBatteryStateReportedInJSON
{
    id deviceSpy = OCMPartialMock(UIDevice.currentDevice);
    
    OCMStub([deviceSpy batteryState]).andReturn(UIDeviceBatteryStateUnplugged);
    OCMStub([deviceSpy batteryLevel]).andReturn(0.5);
    
    [self assertProcessedEvent:[self defaultEvent]
                     withState:nil
                      hasValue:@"defaultEvent"
                        forKey:@"etype"];
    
    XCTAssertTrue([_jsonDataObject[@"powerstatus"] integerValue] == 0);
    XCTAssertTrue([_jsonDataObject[@"mbat"] floatValue] == 50);
    
    [deviceSpy stopMocking];
}

- (void)testSendEventToRAT
{
    XCTestExpectation *sent = [self expectationWithDescription:@"sent"];
    
    [OHHTTPStubs stubRequestsPassingTest:^BOOL(NSURLRequest *request) {
        return [request.URL.absoluteString isEqualToString:RATTracker.endpointAddress.absoluteString];
    } withStubResponse:^OHHTTPStubsResponse * _Nonnull(NSURLRequest * _Nonnull request) {
        [sent fulfill];
        return [OHHTTPStubsResponse responseWithData:[NSData data] statusCode:200 headers:nil];
    }];
    
    [_tracker processEvent:[self defaultEvent] state:[self defaultState]];
    
    // Reduce RATTracker's upload timer from 60s to 1s
    _tracker.uploadTimer = [NSTimer scheduledTimerWithTimeInterval:1.0
                                                            target:_tracker
                                                          selector:@selector(_doBackgroundUpload)
                                                          userInfo:nil
                                                           repeats:NO];
    
    [self waitForExpectationsWithTimeout:5.0 handler:nil];
}

- (void)testSendEventToRATServerError
{
    XCTestExpectation *sent = [self expectationWithDescription:@"sent"];
    
    [OHHTTPStubs stubRequestsPassingTest:^BOOL(NSURLRequest *request) {
        return [request.URL.absoluteString isEqualToString:RATTracker.endpointAddress.absoluteString];
    } withStubResponse:^OHHTTPStubsResponse * _Nonnull(NSURLRequest * _Nonnull request) {
        [sent fulfill];
        return [OHHTTPStubsResponse responseWithData:[NSData data] statusCode:500 headers:nil];
    }];
    
    id notificationCenterSpy = OCMPartialMock(NSNotificationCenter.defaultCenter);
    
    [_tracker processEvent:[self defaultEvent] state:[self defaultState]];
    
    // Reduce RATTracker's upload timer from 60s to 0.1s
    _tracker.uploadTimer = [NSTimer scheduledTimerWithTimeInterval:0.1
                                                            target:_tracker
                                                          selector:@selector(_doBackgroundUpload)
                                                          userInfo:nil
                                                           repeats:NO];
    
    [self waitForExpectationsWithTimeout:5.0 handler:^(NSError * _Nullable error) {

        OCMVerify([notificationCenterSpy postNotificationName:RATUploadFailureNotification
                                                       object:OCMOCK_ANY
                                                     userInfo:[OCMArg checkWithSelector:@selector(assertExpectedNotification:)
                                                                               onObject:self]]);
    }];
    
    [notificationCenterSpy stopMocking];
}

@end
