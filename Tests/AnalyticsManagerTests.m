/*
 * © Rakuten, Inc.
 * authors: "Rakuten Ecosystem Mobile" <ecosystem-mobile@mail.rakuten.com>
 */
@import XCTest;
#import <RSDKAnalytics/RSDKAnalytics.h>
#import "../RSDKAnalytics/Private/_RSDKAnalyticsHelpers.h"

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

@interface AnalyticsManagerTests : XCTestCase
{
    RSDKAnalyticsManager *_manager;
}

@end

@implementation AnalyticsManagerTests

- (void)setUp {
    [super setUp];
    _manager = RSDKAnalyticsManager.sharedInstance;
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

- (void)testFilterPushPayload
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

@end
