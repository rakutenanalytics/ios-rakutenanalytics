/*
 * © Rakuten, Inc.
 * authors: "Rakuten Ecosystem Mobile" <ecosystem-mobile@mail.rakuten.com>
 */
@import XCTest;
#import <RSDKAnalytics/RSDKAnalytics.h>

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

@end
