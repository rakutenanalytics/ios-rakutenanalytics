/*
 * © Rakuten, Inc.
 * authors: "Rakuten Ecosystem Mobile" <ecosystem-mobile@mail.rakuten.com>
 */
@import XCTest;
#import <RSDKAnalytics/RSDKAnalytics.h>
#import "../RSDKAnalytics/Private/_RSDKAnalyticsHelpers.h"

@interface AnalyticsEventTests : XCTestCase

@end

@implementation AnalyticsEventTests

- (void)setUp
{
    [super setUp];
}

- (RSDKAnalyticsEvent *)defaultEvent
{
    RSDKAnalyticsEvent *event = [RSDKAnalyticsEvent.alloc initWithName:_RATGenericEventName parameters:@{@"param1":@"value1"}];
    return event;
}

- (void)testAnalyticsEventDefault
{
    RSDKAnalyticsEvent *event = [self defaultEvent];
    XCTAssertNotNil(event);
    XCTAssertNotNil(event.name);
    XCTAssertNotNil(event.parameters);
    XCTAssertTrue([event.name isEqualToString:@"rat.generic"]);
    XCTAssertTrue([event.parameters[@"param1"] isEqualToString:@"value1"]);
}

- (void)testCopy
{
    RSDKAnalyticsEvent *event = [self defaultEvent];
    RSDKAnalyticsEvent *copy = [event copy];

    XCTAssertEqualObjects(event, copy);
    XCTAssertNotEqual(event, copy);
}

@end
