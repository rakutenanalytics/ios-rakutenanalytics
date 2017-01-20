/*
 * © Rakuten, Inc.
 * authors: "Rakuten Ecosystem Mobile" <ecosystem-mobile@mail.rakuten.com>
 */
@import XCTest;
#import <RSDKAnalytics/RSDKAnalytics.h>
#import <RSDKDeviceInformation/RSDKDeviceInformation.h>
#import <OCMock/OCMock.h>

@interface TestTracker : NSObject<RSDKAnalyticsTracker>
@end

@implementation TestTracker
- (instancetype)init
{
    if (self = [super init])
    {

    }
    return self;
}

- (BOOL)processEvent:(RSDKAnalyticsEvent *)event state:(RSDKAnalyticsState *)state
{
    return YES;
}
@end

@interface RSDKAnalyticsManager ()
@property (nonatomic, nullable, copy) NSString *deviceIdentifier;
@property (nonatomic) BOOL locationManagerIsUpdating;
@property (nonatomic, strong) CLLocationManager *locationManager;

- (instancetype)initSharedInstance;
- (void)_startStopMonitoringLocationIfNeeded;
@end

@interface AnalyticsManagerTests : XCTestCase
{
    RSDKAnalyticsManager *_manager;
}

@end

@implementation AnalyticsManagerTests

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"

- (void)setUp
{
    [super setUp];
    _manager = RSDKAnalyticsManager.sharedInstance;
    _manager.deviceIdentifier = @"deviceIdentifier";
    _manager.shouldTrackLastKnownLocation = NO;
}

- (void)testInitThrows
{
    XCTAssertThrowsSpecificNamed([RSDKAnalyticsManager.alloc init], NSException, NSInvalidArgumentException);
}

- (void)testAnalyticsManagerSharedInstanceIsNotNil
{
    XCTAssertNotNil(_manager);
}

- (void)testAnalyticsManagerSharedInstanceAreEqual
{
    XCTAssertEqualObjects(RSDKAnalyticsManager.sharedInstance, RSDKAnalyticsManager.sharedInstance);
}

- (void)testAnalyticsManagerAddExistingTypeTracker
{
    XCTAssertNoThrow([_manager addTracker:RATTracker.sharedInstance]);
}

- (void)testAnalyticsManagerAddNewTypeTracker
{
    XCTAssertNoThrow([_manager addTracker:TestTracker.new]);
}

- (void)testProcessEvent
{
    RSDKAnalyticsEvent *event = [RSDKAnalyticsEvent.alloc initWithName:@"foo" parameters:nil];

    id mock = OCMPartialMock(RATTracker.sharedInstance);
    [RSDKAnalyticsManager.sharedInstance process:event];

    OCMVerify([mock processEvent:[OCMArg checkWithBlock:^BOOL(id obj) {
        return [obj isEqual:event];
    }] state:OCMOCK_ANY]);

    [mock stopMocking];
}

- (void)testSpoolRecord
{
    RSDKAnalyticsRecord *record = [RSDKAnalyticsRecord recordWithAccountId:0
                                                                 serviceId:0];
    
    // The RSDKAnalyticsEvent created as a result of spooling the record will
    // be named "rat.<eventType>"
    record.eventType = @"etype";
    
    id mock = OCMPartialMock(RSDKAnalyticsManager.sharedInstance);
    [RSDKAnalyticsManager spoolRecord:record];

    OCMVerify([mock process:[OCMArg checkWithBlock:^BOOL(id obj) {
        RSDKAnalyticsEvent *event = obj;
        return [event.name isEqualToString:@"rat.etype"];
    }]]);

    [mock stopMocking];
}

- (void)testEndpointAddress
{
    RSDKAnalyticsManager.sharedInstance.shouldUseStagingEnvironment = YES;
    XCTAssertTrue([[RSDKAnalyticsManager endpointAddress].absoluteString isEqualToString:@"https://stg.rat.rakuten.co.jp/"]);
}

- (void)testProcessMethodThrowsWhenDeviceIdentifierIsNil
{
    _manager.deviceIdentifier = nil;
    
    id deviceInformationMock = OCMClassMock(RSDKDeviceInformation.class);
    OCMStub([deviceInformationMock uniqueDeviceIdentifier]).andReturn(nil);
    
    XCTAssertThrows([_manager process:[RSDKAnalyticsEvent.alloc initWithName:@"event" parameters:nil]]);
    
    [deviceInformationMock stopMocking];
}

- (void)testStartMonitoringLocation
{
    id locationManagerMock = OCMClassMock(CLLocationManager.class);
    
    OCMStub([locationManagerMock authorizationStatus]).andReturn(kCLAuthorizationStatusAuthorizedAlways);
    
    [_manager setLocationTrackingEnabled:YES];
    
    XCTAssertTrue(_manager.locationManagerIsUpdating);
    
    [locationManagerMock stopMocking];
}

- (void)testStopMonitoringLocation
{
    id locationManagerMock = OCMClassMock(CLLocationManager.class);
    
    OCMStub([locationManagerMock authorizationStatus]).andReturn(kCLAuthorizationStatusAuthorizedAlways);
    
    _manager.shouldTrackLastKnownLocation = YES;
    
    [locationManagerMock stopMocking];
    
    _manager.shouldTrackLastKnownLocation = NO;
    
    XCTAssertFalse(_manager.locationManagerIsUpdating);
}

- (void)testStopMonitoringLocationOnResignActive
{
    _manager.locationManagerIsUpdating = YES;
    [NSNotificationCenter.defaultCenter postNotificationName:UIApplicationWillResignActiveNotification object:self];
    XCTAssertFalse(_manager.locationManagerIsUpdating);
}

#pragma clang diagnostic pop

@end
