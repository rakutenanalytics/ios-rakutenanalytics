/*
 * © Rakuten, Inc.
 * authors: "Rakuten Ecosystem Mobile" <ecosystem-mobile@mail.rakuten.com>
 */
@import XCTest;
#import <RSDKAnalytics/RSDKAnalytics.h>
#import "../RSDKAnalytics/Private/_RSDKAnalyticsHelpers.h"

@interface RSDKAnalyticsManager ()
@property (nonatomic, nullable, copy) NSString *deviceIdentifier;
@end

@interface AnalyticsItemTests : XCTestCase
@end

@implementation AnalyticsItemTests

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"

- (RSDKAnalyticsItem *)defaultItem
{
    RSDKAnalyticsItem *item = [RSDKAnalyticsItem itemWithIdentifier:@"identifier"];
    item.quantity = 5;
    item.price = 10.5;
    item.genre = @"genre";
    item.variation = @{@"foo":@"bar"};
    item.tags = @[@"tag1", @"tag2"];
    return item;
}

- (void)testItemWithIdentifierFactory
{
    NSString *identifier = @"identifier";
    RSDKAnalyticsItem *item = [RSDKAnalyticsItem itemWithIdentifier:identifier];
    XCTAssertTrue([item.identifier isEqualToString:identifier]);
    XCTAssertTrue(item.quantity == 0);
    XCTAssertTrue(item.price == 0.0);
    XCTAssertNil(item.genre);
    XCTAssertNil(item.variation);
    XCTAssertNil(item.tags);
}

- (void)testItemsWithSamePropertiesAreEqual
{
    RSDKAnalyticsItem *item = [self defaultItem];
    RSDKAnalyticsItem *other = [self defaultItem];
    XCTAssertEqualObjects(item, other);
}

- (void)testItemsWithDifferentPropertiesAreNotEqual
{
    RSDKAnalyticsItem *item = [self defaultItem];
    RSDKAnalyticsItem *other = [self defaultItem];
    other.identifier = @"other";
    XCTAssertNotEqualObjects(item, other);
}

- (void)testItemIsNotEqualToDifferentObject
{
    RSDKAnalyticsItem *item = [self defaultItem];
    XCTAssertNotEqualObjects(item, UIView.new);
}

- (void)testHashIsIdenticalWhenObjectsEqual
{
    RSDKAnalyticsItem *item = [self defaultItem];
    RSDKAnalyticsItem *other = [self defaultItem];
    XCTAssertEqualObjects(item, other);
    XCTAssertEqual(item.hash, other.hash);
}

- (void)testHashIsDifferentWhenObjectsNotEqual
{
    RSDKAnalyticsItem *item = [self defaultItem];
    RSDKAnalyticsItem *other = [self defaultItem];
    other.identifier = @"other";
    XCTAssertNotEqualObjects(item, other);
    XCTAssertNotEqual(item.hash, other.hash);
}

- (void)testCopiesAreEqual
{
    RSDKAnalyticsItem *item = [self defaultItem];
    RSDKAnalyticsItem *copy = item.copy;
    
    XCTAssertEqualObjects(item, copy);
    XCTAssertNotEqual(item, copy);
}

- (void)testCoding
{
    RSDKAnalyticsItem *item = [self defaultItem];
    
    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:item];
    RSDKAnalyticsEvent *unarchived = [NSKeyedUnarchiver unarchiveObjectWithData:data];
    
    XCTAssertEqualObjects(unarchived, item);
}

- (void)testSecureCoding
{
    RSDKAnalyticsItem *item = [self defaultItem];
    
    NSMutableData *data = [NSMutableData data];
    NSKeyedArchiver *secureEncoder = [NSKeyedArchiver.alloc initForWritingWithMutableData:data];
    secureEncoder.requiresSecureCoding = YES;
    
    NSString *key = @"item";
    [secureEncoder encodeObject:item forKey:key];
    [secureEncoder finishEncoding];
    
    NSKeyedUnarchiver *secureDecoder = [[NSKeyedUnarchiver alloc] initForReadingWithData:data];
    secureDecoder.requiresSecureCoding = YES;
    RSDKAnalyticsItem *decodedItem = [secureDecoder decodeObjectOfClass:[RSDKAnalyticsItem class] forKey:key];
    [secureDecoder finishDecoding];
    
    XCTAssertEqualObjects(item, decodedItem);
}

- (void)testDescription
{
    RSDKAnalyticsItem *item = [self defaultItem];
    item.quantity = 100;
    XCTAssertTrue([item.description containsString:@"quantity = 100"]);
}

#pragma clang diagnostic pop

@end
