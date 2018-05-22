@import XCTest;
#import <OCMock/OCMock.h>
#import <OHHTTPStubs/OHHTTPStubs.h>

#import "../../RAnalytics/Core/Private/_SDKTracker.h"
#import "../../RAnalytics/Core/Private/_RAnalyticsDatabase.h"
#import "../../RAnalytics/Util/Private/_RAnalyticsHelpers.h"

#import "TrackerTests.h"

#pragma mark - Module Internals

@interface RAnalyticsManager ()
@property(nonatomic, strong) NSMutableSet RSDKA_GENERIC(id<RAnalyticsTracker>) *trackers;
@end

@interface _SDKTracker ()
@property (nonatomic) RAnalyticsSender      *sender;
- (instancetype)initInstance;
@end

@interface SDKTrackerTests : TrackerTests
@end

@implementation SDKTrackerTests

- (void)setUp {
    [super setUp];
}

- (void)tearDown {
    // Clear any still running timers because they can break our async batching delay tests
    for (id<RAnalyticsTracker> t in RAnalyticsManager.sharedInstance.trackers)
    {
        if ([t isKindOfClass:_SDKTracker.class])
        {
            _SDKTracker *tracker = (_SDKTracker *)t;
            [self invalidateTimerOfSender:tracker.sender];
        }
    }
    [super tearDown];
}

#pragma mark TrackerTestConfiguration protocol
- (id<RAnalyticsTracker>)testedTracker
{
    return [_SDKTracker.alloc initInstance];
}

#pragma mark Test initialisation and configuration

- (void)testAnalyticsSDKTrackerSharedInstanceIsNotNil
{
    XCTAssertNotNil(_SDKTracker.sharedInstance);
}

- (void)testAnalyticsSDKTrackerSharedInstanceAreEqual
{
    XCTAssertEqualObjects(_SDKTracker.sharedInstance, _SDKTracker.sharedInstance);
}

- (void)testInitThrowsException
{
    XCTAssertThrowsSpecificNamed([_SDKTracker new], NSException, NSInvalidArgumentException);
}

#pragma mark Test processing events

- (void)testDoNotProcessTheEventWhichIsNotInstallEvent
{
    XCTAssertNotNil(self.defaultEvent);
    XCTAssert(![_SDKTracker.sharedInstance processEvent:self.defaultEvent state:self.defaultState]);
    id payload = self.database.latestAddedJSON;
    XCTAssertNil(payload);
}

- (void)testProcessInstallEvent
{
    [self stubRATResponseWithStatusCode:200 completionHandler:nil];
    id event = [RAnalyticsEvent.alloc initWithName:RAnalyticsInstallEventName parameters:nil];
    id payload = [self assertProcessEvent:event state:self.defaultState expectType:@"_rem_internal_install"];
    NSNumber *acc = payload[@"acc"];
    XCTAssert([acc isEqualToNumber:@477]);
    NSNumber *aid = payload[@"aid"];
    XCTAssert([aid isEqualToNumber:@1]);
    id appInfo = [payload valueForKeyPath:@"cp.app_info"];
    XCTAssert([appInfo containsString:@"xcode"]);
    XCTAssert([appInfo containsString:@"iphonesimulator"]);
}
@end

