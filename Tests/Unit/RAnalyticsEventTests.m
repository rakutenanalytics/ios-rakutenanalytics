@import XCTest;
#import <RAnalytics/RAnalytics.h>
#import <OCMock/OCMock.h>
#import "../../RAnalytics/Util/Private/_RAnalyticsHelpers.h"

@interface EventTests : XCTestCase
@end

@implementation EventTests

- (void)setUp
{
    [super setUp];
}

- (RAnalyticsEvent *)defaultEvent
{
    RAnalyticsEvent *event = [RAnalyticsEvent.alloc initWithName:_RATGenericEventName parameters:@{@"param1":@"value1"}];
    return event;
}

- (void)testAnalyticsEventDefault
{
    RAnalyticsEvent *event = [self defaultEvent];
    XCTAssertNotNil(event);
    XCTAssertNotNil(event.name);
    XCTAssertNotNil(event.parameters);
    XCTAssertTrue([event.name isEqualToString:@"rat.generic"]);
    XCTAssertTrue([event.parameters[@"param1"] isEqualToString:@"value1"]);
}

- (void)testCopiesAreEqual
{
    RAnalyticsEvent *event = [self defaultEvent];
    RAnalyticsEvent *copy = [event copy];

    XCTAssertEqualObjects(event, copy);
    XCTAssertNotEqual(event, copy);
}

- (void)testEventsWithSamePropertiesAreEqual
{
    RAnalyticsEvent *event = [self defaultEvent];
    RAnalyticsEvent *other = [self defaultEvent];
    XCTAssertEqualObjects(event, other);
}

- (void)testEventsWithDifferentPropertiesAreNotEqual
{
    RAnalyticsEvent *event = [self defaultEvent];
    RAnalyticsEvent *other = [RAnalyticsEvent.alloc initWithName:_RATGenericEventName parameters:@{@"param1":@"value2"}];
    XCTAssertNotEqualObjects(event, other);
}

- (void)testEventIsNotEqualToDifferentObject
{
    RAnalyticsEvent *event = [self defaultEvent];
    XCTAssertNotEqualObjects(event, UIView.new);
}

- (void)testHashIsIdenticalWhenObjectsEqual
{
    RAnalyticsEvent *event = [self defaultEvent];
    RAnalyticsEvent *other = [self defaultEvent];
    XCTAssertEqualObjects(event, other);
    XCTAssertEqual(event.hash, other.hash);
}

- (void)testHashIsDifferentWhenObjectsNotEqual
{
    RAnalyticsEvent *event = [self defaultEvent];
    RAnalyticsEvent *other = [RAnalyticsEvent.alloc initWithName:_RATGenericEventName parameters:@{@"param1":@"value1", @"param2":@"value2"}];
    XCTAssertNotEqualObjects(event, other);
    XCTAssertNotEqual(event.hash, other.hash);
}

- (void)testCoding
{
    RAnalyticsEvent *event = [self defaultEvent];
    
    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:event];
    RAnalyticsEvent *unarchived = [NSKeyedUnarchiver unarchiveObjectWithData:data];
    
    XCTAssertEqualObjects(unarchived, event);
    XCTAssertEqualObjects(unarchived.name, event.name);
    XCTAssertEqualObjects(unarchived.parameters, event.parameters);
}

- (void)testSecureCoding
{
    RAnalyticsEvent *event = [self defaultEvent];
    
    NSMutableData *data = [NSMutableData data];
    NSKeyedArchiver *secureEncoder = [NSKeyedArchiver.alloc initForWritingWithMutableData:data];
    secureEncoder.requiresSecureCoding = YES;
    
    NSString *key = @"event";
    [secureEncoder encodeObject:event forKey:key];
    [secureEncoder finishEncoding];
    
    NSKeyedUnarchiver *secureDecoder = [[NSKeyedUnarchiver alloc] initForReadingWithData:data];
    secureDecoder.requiresSecureCoding = YES;
    RAnalyticsEvent *decodedEvent = [secureDecoder decodeObjectOfClass:[RAnalyticsEvent class] forKey:key];
    [secureDecoder finishDecoding];
    
    XCTAssertEqualObjects(event, decodedEvent);
    XCTAssertEqualObjects(event.name, decodedEvent.name);
    XCTAssertEqualObjects(event.parameters, event.parameters);
}

- (void)testTracking
{
    RAnalyticsEvent *event = [self defaultEvent];

    id mock = OCMPartialMock(RAnalyticsManager.sharedInstance);
    [event track];

    OCMVerify([mock process:[OCMArg checkWithBlock:^BOOL(id obj) {
        return [event isEqual:obj];
    }]]);
    [mock stopMocking];
}

@end
