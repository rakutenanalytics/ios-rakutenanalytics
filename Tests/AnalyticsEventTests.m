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

- (void)testCopiesAreEqual
{
    RSDKAnalyticsEvent *event = [self defaultEvent];
    RSDKAnalyticsEvent *copy = [event copy];

    XCTAssertEqualObjects(event, copy);
    XCTAssertNotEqual(event, copy);
}

- (void)testEventsWithSamePropertiesAreEqual
{
    RSDKAnalyticsEvent *event = [self defaultEvent];
    RSDKAnalyticsEvent *other = [self defaultEvent];
    XCTAssertEqualObjects(event, other);
}

- (void)testEventsWithDifferentPropertiesAreNotEqual
{
    RSDKAnalyticsEvent *event = [self defaultEvent];
    RSDKAnalyticsEvent *other = [RSDKAnalyticsEvent.alloc initWithName:_RATGenericEventName parameters:@{@"param1":@"value2"}];
    XCTAssertNotEqualObjects(event, other);
}

- (void)testEventIsNotEqualToDifferentObject
{
    RSDKAnalyticsEvent *event = [self defaultEvent];
    XCTAssertNotEqualObjects(event, UIView.new);
}

- (void)testHashIsIdenticalWhenObjectsEqual
{
    RSDKAnalyticsEvent *event = [self defaultEvent];
    RSDKAnalyticsEvent *other = [self defaultEvent];
    XCTAssertEqualObjects(event, other);
    XCTAssertEqual(event.hash, other.hash);
}

- (void)testHashIsDifferentWhenObjectsNotEqual
{
    RSDKAnalyticsEvent *event = [self defaultEvent];
    RSDKAnalyticsEvent *other = [RSDKAnalyticsEvent.alloc initWithName:_RATGenericEventName parameters:@{@"param1":@"value1", @"param2":@"value2"}];
    XCTAssertNotEqualObjects(event, other);
    XCTAssertNotEqual(event.hash, other.hash);
}

- (void)testCoding
{
    RSDKAnalyticsEvent *event = [self defaultEvent];
    
    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:event];
    RSDKAnalyticsEvent *unarchived = [NSKeyedUnarchiver unarchiveObjectWithData:data];
    
    XCTAssertEqualObjects(unarchived, event);
    XCTAssertEqualObjects(unarchived.name, event.name);
    XCTAssertEqualObjects(unarchived.parameters, event.parameters);
}

- (void)testSecureCoding
{
    RSDKAnalyticsEvent *event = [self defaultEvent];
    
    NSMutableData *data = [NSMutableData data];
    NSKeyedArchiver *secureEncoder = [NSKeyedArchiver.alloc initForWritingWithMutableData:data];
    secureEncoder.requiresSecureCoding = YES;
    
    NSString *key = @"event";
    [secureEncoder encodeObject:event forKey:key];
    [secureEncoder finishEncoding];
    
    NSKeyedUnarchiver *secureDecoder = [[NSKeyedUnarchiver alloc] initForReadingWithData:data];
    secureDecoder.requiresSecureCoding = YES;
    RSDKAnalyticsEvent *decodedEvent = [secureDecoder decodeObjectOfClass:[RSDKAnalyticsEvent class] forKey:key];
    [secureDecoder finishDecoding];
    
    XCTAssertEqualObjects(event, decodedEvent);
    XCTAssertEqualObjects(event.name, decodedEvent.name);
    XCTAssertEqualObjects(event.parameters, event.parameters);
}

- (void)testTracking
{
    RSDKAnalyticsEvent *event = [self defaultEvent];

    id mock = OCMPartialMock(RSDKAnalyticsManager.sharedInstance);
    [event track];

    OCMVerify([mock process:[OCMArg checkWithBlock:^BOOL(id obj) {
        return [event isEqual:obj];
    }]]);
    [mock stopMocking];
}

@end
