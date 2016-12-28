/*
 * © Rakuten, Inc.
 * authors: "Rakuten Ecosystem Mobile" <ecosystem-mobile@mail.rakuten.com>
 */
@import XCTest;
#import <RSDKAnalytics/RSDKAnalytics.h>
#import "../RSDKAnalytics/Private/_RSDKAnalyticsHelpers.h"
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
}

- (void)testInitThrows
{
    XCTAssertThrowsSpecificNamed([RSDKAnalyticsManager.alloc init], NSException, NSInvalidArgumentException);
}

- (void)testDealloc
{
    __weak RSDKAnalyticsManager *weakMgr;
    @autoreleasepool
    {
        RSDKAnalyticsManager *manager = [RSDKAnalyticsManager.alloc initSharedInstance];
        weakMgr = manager;
    }
    XCTAssertNil(weakMgr);
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

- (void)testFilterPushPayloadDictionary
{
    NSDictionary *dict = @{@"A1":@{@"A2":@"a2"},
                           @"B1":@{@"B2":@{@"B3":@"b3",
                                           @"B4":@"b4",
                                           @"B5":@{@"B6":@"b6",
                                                   @"B7":@"b7"}}},
                           @"C1":@"c1"};

    NSMutableDictionary *filterResult = NSMutableDictionary.new;
    _RSDKAnalyticsTraverseObjectWithSearchKeys(dict, @[@"B3", @"A2", @"A3", @"B7"], filterResult);
    XCTAssertTrue([filterResult[@"A2"] isEqualToString:@"a2"]);
    XCTAssertTrue([filterResult[@"B3"] isEqualToString:@"b3"]);
    XCTAssertTrue([filterResult[@"B7"] isEqualToString:@"b7"]);
    XCTAssertNil(filterResult[@"A3"]);
}

- (void)testFilterPushPayloadArray
{
    NSArray *array = @[@{@"A1":@"a1"},
                       @{@"B1":@{@"B2":@"b2"}}];
    
    NSMutableDictionary *filterResult = NSMutableDictionary.new;
    _RSDKAnalyticsTraverseObjectWithSearchKeys(array, @[@"A1", @"B2", @"C1"], filterResult);
    XCTAssertTrue([filterResult[@"A1"] isEqualToString:@"a1"]);
    XCTAssertTrue([filterResult[@"B2"] isEqualToString:@"b2"]);
    XCTAssertNil(filterResult[@"C1"]);
}

- (void)testStringWithObject
{
    XCTAssertEqualObjects(@"string", _RSDKAnalyticsStringWithObject(@"string"));
    XCTAssertEqualObjects(nil, _RSDKAnalyticsStringWithObject([NSNull null]));
    XCTAssertEqualObjects(@"100", _RSDKAnalyticsStringWithObject(@(100)));
    XCTAssertThrowsSpecificNamed(_RSDKAnalyticsStringWithObject([NSData data]), NSException, NSInvalidArgumentException);
    XCTAssertEqualObjects(nil, _RSDKAnalyticsStringWithObject(@""));
}

- (void)testSpoolRecord
{
    id arrayOfStrings = @[@"A", @"B"];
    id arrayOfNumbers = @[@1, @2];
    id dictionary = @{@"A": arrayOfStrings, @"B": arrayOfNumbers};
    
    RSDKAnalyticsRecord *record = [RSDKAnalyticsRecord recordWithAccountId:0
                                                                 serviceId:0];
    record.affiliateId = 1;
    record.campaignCode = @"campaign_code";
    record.customParameters = dictionary;
    record.eventType = @"etype";
    
    RSDKAnalyticsItem *item1 = [RSDKAnalyticsItem itemWithIdentifier:@"A"];
    RSDKAnalyticsItem *item2 = [RSDKAnalyticsItem itemWithIdentifier:@"B"];
    item1.quantity = 1;
    item2.quantity = 2;
    item1.genre = @"A";
    item2.genre = @"B";
    item1.price = 1;
    item2.price = 2;
    item1.variation = dictionary;
    item2.variation = dictionary;
    
    [record addItem:item1];
    [record addItem:item2];
    
    id mockManager = OCMPartialMock(RSDKAnalyticsManager.sharedInstance);
    
    [RSDKAnalyticsManager spoolRecord:record];
    
    OCMVerify([mockManager process:[OCMArg checkWithBlock:^BOOL(id obj) {
        RSDKAnalyticsEvent *event = obj;
        XCTAssertNotNil(event);
        BOOL expected = ([event.name isEqualToString:@"rat.etype"]);
        XCTAssertTrue(expected, @"Unexpected event processed: %@", event.name);
        return expected;
    }]]);
    [mockManager stopMocking];
}

- (void)testEndpointAddress
{
    XCTAssertTrue([[RSDKAnalyticsManager endpointAddress].absoluteString hasSuffix:@"rat.rakuten.co.jp/"]);
}

- (void)testProcessMethodThrowsWhenDeviceIdentifierIsNil
{
    _manager.deviceIdentifier = nil;
    XCTAssertThrows([_manager process:[RSDKAnalyticsEvent.alloc initWithName:@"event" parameters:nil]]);
}

- (void)testSetShouldTrackLastKnownLocation
{
    BOOL track = _manager.shouldTrackLastKnownLocation;
    _manager.shouldTrackLastKnownLocation = !track;
    XCTAssertTrue(_manager.shouldTrackLastKnownLocation != track);
}

- (void)testLocationTrackingEnabled
{
    BOOL track = _manager.shouldTrackLastKnownLocation;
    [_manager setLocationTrackingEnabled:!track];
    XCTAssertTrue(_manager.isLocationTrackingEnabled != track);
}

- (void)testLocationManagerDelegates
{
    // These methods have no side-effects to verify so just call them
    [_manager.locationManager.delegate locationManagerDidPauseLocationUpdates:_manager.locationManager];
    [_manager.locationManager.delegate locationManagerDidResumeLocationUpdates:_manager.locationManager];
    [_manager.locationManager.delegate locationManager:_manager.locationManager didFinishDeferredUpdatesWithError:nil];
}

- (void)testStartMonitoringLocation
{
    id locationManagerMock = OCMClassMock(CLLocationManager.class);
    
    OCMStub([locationManagerMock authorizationStatus]).andReturn(kCLAuthorizationStatusAuthorizedAlways);
    
    [_manager _startStopMonitoringLocationIfNeeded];
    
    XCTAssertTrue(_manager.locationManagerIsUpdating);
    
    [locationManagerMock stopMocking];
}

- (void)testStopMonitoringLocation
{
    id locationManagerMock = OCMClassMock(CLLocationManager.class);
    
    _manager.locationManagerIsUpdating = YES;
    
    OCMStub([locationManagerMock authorizationStatus]).andReturn(kCLAuthorizationStatusDenied);
    
    [_manager _startStopMonitoringLocationIfNeeded];
    
    XCTAssertFalse(_manager.locationManagerIsUpdating);
    
    [locationManagerMock stopMocking];
}

- (void)testStopMonitoringLocationUnlessAlways
{
    _manager.locationManagerIsUpdating = YES;
    [NSNotificationCenter.defaultCenter postNotificationName:UIApplicationWillResignActiveNotification object:self];
    XCTAssertFalse(_manager.locationManagerIsUpdating);
}

#pragma clang diagnostic push

@end
