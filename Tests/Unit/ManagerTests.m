@import XCTest;
#import <RAnalytics/RAnalytics.h>
#import <RDeviceIdentifier/RDeviceIdentifier.h>
#import <OCMock/OCMock.h>

@interface TestTracker : NSObject<RAnalyticsTracker>
@end

@implementation TestTracker
- (instancetype)init
{
    if (self = [super init])
    {

    }
    return self;
}

- (BOOL)processEvent:(RAnalyticsEvent *)event state:(RAnalyticsState *)state
{
    return YES;
}
@end

@interface RAnalyticsState ()
@property (nonatomic, nullable, readwrite) UIViewController *currentPage;
@end

@interface RAnalyticsManager ()
@property (nonatomic, nullable, copy) NSString *deviceIdentifier;
@property (nonatomic) BOOL locationManagerIsUpdating;
@property (nonatomic, strong) CLLocationManager *locationManager;

- (instancetype)initSharedInstance;
- (void)_startStopMonitoringLocationIfNeeded;
@end

@interface ManagerTests : XCTestCase
{
    RAnalyticsManager *_manager;
}

@end

@implementation ManagerTests

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"

- (void)setUp
{
    [super setUp];
    _manager = RAnalyticsManager.sharedInstance;
    _manager.deviceIdentifier = @"deviceIdentifier";
    _manager.shouldTrackLastKnownLocation = NO;
}

- (void)testInitThrows
{
    XCTAssertThrowsSpecificNamed([RAnalyticsManager.alloc init], NSException, NSInvalidArgumentException);
}

- (void)testAnalyticsManagerSharedInstanceIsNotNil
{
    XCTAssertNotNil(_manager);
}

- (void)testAnalyticsManagerSharedInstanceAreEqual
{
    XCTAssertEqualObjects(RAnalyticsManager.sharedInstance, RAnalyticsManager.sharedInstance);
}

- (void)testAnalyticsManagerAddExistingTypeTracker
{
    XCTAssertNoThrow([_manager addTracker:RAnalyticsRATTracker.sharedInstance]);
}

- (void)testAnalyticsManagerAddNewTypeTracker
{
    XCTAssertNoThrow([_manager addTracker:TestTracker.new]);
}

- (void)testProcessEvent
{
    RAnalyticsEvent *event = [RAnalyticsEvent.alloc initWithName:@"foo" parameters:nil];

    id mock = OCMPartialMock(RAnalyticsRATTracker.sharedInstance);
    [RAnalyticsManager.sharedInstance process:event];

    OCMVerify([mock processEvent:[OCMArg checkWithBlock:^BOOL(id obj) {
        return [obj isEqual:event];
    }] state:OCMOCK_ANY]);

    [mock stopMocking];
}

- (void)testUsingStagingEndpointAddress
{
    RAnalyticsManager.sharedInstance.shouldUseStagingEnvironment = YES;
    XCTAssertTrue([[RAnalyticsRATTracker endpointAddress].absoluteString isEqualToString:@"https://stg.rat.rakuten.co.jp/"]);
}

- (void)testUsingProductionEndpointAddress
{
    RAnalyticsManager.sharedInstance.shouldUseStagingEnvironment = NO;
    XCTAssertTrue([[RAnalyticsRATTracker endpointAddress].absoluteString isEqualToString:@"https://rat.rakuten.co.jp/"]);
}

- (void)testStartMonitoringLocation
{
    id locationManagerMock = OCMClassMock(CLLocationManager.class);

    OCMStub([locationManagerMock authorizationStatus]).andReturn(kCLAuthorizationStatusAuthorizedAlways);

    _manager.shouldTrackLastKnownLocation = YES;

    XCTAssertTrue(_manager.locationManagerIsUpdating);

    [locationManagerMock stopMocking];
}

- (void)testStopMonitoringLocation
{
    id locationManagerMock = OCMClassMock(CLLocationManager.class);

    OCMStub([locationManagerMock authorizationStatus]).andReturn(kCLAuthorizationStatusAuthorizedAlways);

    _manager.shouldTrackLastKnownLocation = NO;

    XCTAssertFalse(_manager.locationManagerIsUpdating);

    [locationManagerMock stopMocking];
}

- (void)testStopMonitoringLocationOnResignActive
{
    _manager.locationManagerIsUpdating = YES;
    [NSNotificationCenter.defaultCenter postNotificationName:UIApplicationWillResignActiveNotification object:self];
    XCTAssertFalse(_manager.locationManagerIsUpdating);
}

- (void)testPageViewIsTrackedWhenShouldTrackPageViewIsTrue
{
    // Assert that page view event is processed by RAT Tracker when the AnalyticsManager's shouldTrackPageView property is true

    RAnalyticsState *state = [RAnalyticsState.alloc initWithSessionIdentifier:@"CA7A88AB-82FE-40C9-A836-B1B3455DECAB"
                                                             deviceIdentifier:@"deviceId"];
    UIViewController *currentPage = UIViewController.new;
    state.currentPage = currentPage;
    id event = [RAnalyticsEvent.alloc initWithName:RAnalyticsPageVisitEventName parameters:@{@"page_id": @"TestPage"}];

    id mock = OCMPartialMock(RAnalyticsManager.sharedInstance);
    OCMStub([mock shouldTrackPageView]).andReturn(YES);
    XCTAssertTrue([RAnalyticsRATTracker.sharedInstance processEvent:event state:state]);
    [mock stopMocking];
}

- (void)testPageViewIsNotTrackedWhenShouldTrackPageViewIsFalse
{
    // Assert that page view event is not processed by RAT Tracker when the AnalyticsManager's shouldTrackPageView property is false

    RAnalyticsState *state = [RAnalyticsState.alloc initWithSessionIdentifier:@"CA7A88AB-82FE-40C9-A836-B1B3455DECAB"
                                                             deviceIdentifier:@"deviceId"];
    UIViewController *currentPage = UIViewController.new;
    state.currentPage = currentPage;
    id event = [RAnalyticsEvent.alloc initWithName:RAnalyticsPageVisitEventName parameters:@{@"page_id": @"TestPage"}];

    id mock = OCMPartialMock(RAnalyticsManager.sharedInstance);
    OCMStub([mock shouldTrackPageView]).andReturn(NO);
    XCTAssertFalse([RAnalyticsRATTracker.sharedInstance processEvent:event state:state]);
    [mock stopMocking];
}

#pragma clang diagnostic pop

@end
