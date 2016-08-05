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
    NSError *error = nil;
    BOOL b = [_manager addTracker:RSDKAnalyticsRATTracker.sharedInstance error:&error];
    XCTAssertTrue(!b);
    XCTAssertNotNil(error);
    XCTAssertTrue([error.domain isEqualToString:RSDKAnalyticsErrorDomain]);
}

- (void)testAnalyticsManagerAddNewTypeTracker
{
    NSError *error = nil;
    TestTracker *tracker = [TestTracker.alloc init];
    BOOL b = [_manager addTracker:tracker error:&error];
    XCTAssertTrue(b);
    XCTAssertNil(error);
}

@end
