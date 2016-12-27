/*
 * © Rakuten, Inc.
 * authors: "Rakuten Ecosystem Mobile" <ecosystem-mobile@mail.rakuten.com>
 */
@import XCTest;
#import <RSDKAnalytics/RSDKAnalytics.h>
#import "../RSDKAnalytics/Private/_RSDKAnalyticsHelpers.h"
#import <OCMock/OCMock.h>

@interface RSDKAnalyticsManager ()
@property (nonatomic, nullable, copy) NSString *deviceIdentifier;
@end

@interface AnalyticsEventTests : XCTestCase
@end

@implementation AnalyticsEventTests

- (void)setUp
{
    [super setUp];
    RSDKAnalyticsManager.sharedInstance.deviceIdentifier = @"deviceIdentifier";
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

- (void)testEquality
{
    RSDKAnalyticsEvent *event = [self defaultEvent];
    RSDKAnalyticsEvent *anotherEvent = [self defaultEvent];
    XCTAssertEqual(event, event);
    XCTAssertNotEqual(event, anotherEvent);
    XCTAssertEqualObjects(event, anotherEvent);
    XCTAssertNotEqualObjects(event, UIView.new);
}

- (void)testCoding
{
    RSDKAnalyticsEvent *event = [self defaultEvent];
    
    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:event];
    RSDKAnalyticsEvent *unarchived = [NSKeyedUnarchiver unarchiveObjectWithData:data];
    
    XCTAssertEqualObjects(unarchived, event);
}

- (void)testTracking
{
    RSDKAnalyticsEvent *event = [self defaultEvent];
    [event track];
    OCMVerify([RSDKAnalyticsManager.sharedInstance process:event]);
}

@end
