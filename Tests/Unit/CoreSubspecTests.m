@import XCTest;
#import <RAnalytics/RAnalytics.h>
#import "../../RAnalytics/Core/Private/_SDKTracker.h"

@interface RAnalyticsManager()<CLLocationManagerDelegate>
@property(nonatomic, strong) NSMutableSet<RAnalyticsTracker> *trackers;
- (instancetype)initSharedInstance;
@end

@interface CoreSubspecTests : XCTestCase
@end

@implementation CoreSubspecTests

- (void)testRATTrackerIsNotAvailable
{
    XCTAssertNil(NSClassFromString(@"RAnalyticsRATTracker"));
}

- (void)testSDKTrackerIsAvailable
{
    XCTAssertNotNil(NSClassFromString(@"_SDKTracker"));
}

- (void)testSDKTrackerIsAddedToManager
{
    RAnalyticsManager *manager = [RAnalyticsManager.alloc initSharedInstance];
    XCTAssert([manager.trackers containsObject:_SDKTracker.sharedInstance]);
}

- (void)testRATTrackerIsNotAddedToManager
{
    RAnalyticsManager *manager = [RAnalyticsManager.alloc initSharedInstance];
    XCTAssert([manager.trackers containsObject:_SDKTracker.sharedInstance]);
    XCTAssert(manager.trackers.count==1);
}

@end

