/*
 * © Rakuten, Inc.
 * authors: "Rakuten Ecosystem Mobile" <ecosystem-mobile@mail.rakuten.com>
 */
@import XCTest;
#import <RSDKAnalytics/RSDKAnalytics.h>
#import "../RSDKAnalytics/Private/_RSDKAnalyticsHelpers.h"

@interface HelperTests : XCTestCase
@end

@implementation HelperTests

- (void)testFilterPushPayloadDictionary
{
    NSDictionary *dict = @{@"A1":@{@"A2":@"a2"},
                           @"B1":@{@"B2":@{@"B3":@"b3",
                                           @"B4":@"b4",
                                           @"B5":@{@"B6":@"b6",
                                                   @"B7":@"b7"}}},
                           @"C1":@"c1"};
    
    NSMutableDictionary *filterResult = NSMutableDictionary.new;
    _RSDKAnalyticsTraverseObjectWithSearchKeys(dict, @[@"B3", @"A2", @"A3", @"B7"], filterResult);
    XCTAssertTrue([filterResult[@"A2"] isEqualToString:@"a2"]);
    XCTAssertTrue([filterResult[@"B3"] isEqualToString:@"b3"]);
    XCTAssertTrue([filterResult[@"B7"] isEqualToString:@"b7"]);
    XCTAssertNil(filterResult[@"A3"]);
}

- (void)testFilterPushPayloadArray
{
    NSArray *array = @[@{@"A1":@"a1"},
                       @{@"B1":@{@"B2":@"b2"}}];
    
    NSMutableDictionary *filterResult = NSMutableDictionary.new;
    _RSDKAnalyticsTraverseObjectWithSearchKeys(array, @[@"A1", @"B2", @"C1"], filterResult);
    XCTAssertTrue([filterResult[@"A1"] isEqualToString:@"a1"]);
    XCTAssertTrue([filterResult[@"B2"] isEqualToString:@"b2"]);
    XCTAssertNil(filterResult[@"C1"]);
}

- (void)testStringWithObject
{
    XCTAssertEqualObjects(@"string", _RSDKAnalyticsStringWithObject(@"string"));
    XCTAssertEqualObjects(nil, _RSDKAnalyticsStringWithObject([NSNull null]));
    XCTAssertEqualObjects(@"100", _RSDKAnalyticsStringWithObject(@(100)));
    XCTAssertThrowsSpecificNamed(_RSDKAnalyticsStringWithObject([NSData data]), NSException, NSInvalidArgumentException);
    XCTAssertEqualObjects(nil, _RSDKAnalyticsStringWithObject(@""));
}

@end
