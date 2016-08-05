/*
 * © Rakuten, Inc.
 * authors: "Rakuten Ecosystem Mobile" <ecosystem-mobile@mail.rakuten.com>
 */
@import XCTest;
#import <RSDKAnalytics/RSDKAnalytics.h>

@interface RSDKAnalyticsRATTracker ()
@property (nonatomic) int64_t accountIdentifier;
@property (nonatomic) int64_t applicationIdentifier;
@end

@interface AnalyticsRATTrackerTests : XCTestCase
{
    RSDKAnalyticsRATTracker* _tracker;
}
@end

@implementation AnalyticsRATTrackerTests

- (void)setUp
{
    [super setUp];
    _tracker = RSDKAnalyticsRATTracker.sharedInstance;
}

- (void)testAnalyticsRATTrackerSharedInstanceIsNotNil
{
    XCTAssertNotNil(_tracker);
}

- (void)testAnalyticsRATTrackerSharedInstanceAreEqual
{
    XCTAssertEqualObjects(_tracker, RSDKAnalyticsRATTracker.sharedInstance);
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

@end
