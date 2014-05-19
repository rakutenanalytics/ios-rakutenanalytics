//
//  RSDKAnalyticsRecordTests.m
//  RSDKAnalytics
//
//  Created by Julien Cayzac on 5/20/14.
//  Copyright (c) 2014 Rakuten, Inc. All rights reserved.
//

@import XCTest;

#import "RSDKAnalyticsRecord.h"

@interface RSDKAnalyticsRecordTests : XCTestCase
@end

@implementation RSDKAnalyticsRecordTests

- (NSString *)veryLongString
{
    static NSString *veryLongString;
    static dispatch_once_t once;
    dispatch_once(&once, ^
    {
        // Start with 16 characters
        veryLongString = @"0123456789ABCDEF";

        // Make it 256-character long
        veryLongString = [NSString stringWithFormat:@"%1$@%1$@%1$@%1$@%1$@%1$@%1$@%1$@%1$@%1$@%1$@%1$@%1$@%1$@%1$@%1$@", veryLongString];

        // Make if 4096-character long
        veryLongString = [NSString stringWithFormat:@"%1$@%1$@%1$@%1$@%1$@%1$@%1$@%1$@%1$@%1$@%1$@%1$@%1$@%1$@%1$@%1$@", veryLongString];
    });

    return veryLongString;
}

- (void)testRecordWithZeroAccountId
{
    RSDKAnalyticsRecord *record = [RSDKAnalyticsRecord recordWithAccountId:0 serviceId:0];
    XCTAssertNotNil(record);
    XCTAssertEqual(record.accountId, 0ull);
}

- (void)testRecordDefaultValues
{
    RSDKAnalyticsRecord *record = [RSDKAnalyticsRecord recordWithAccountId:0 serviceId:0];
    XCTAssertNotNil(record);

    XCTAssertEqual(record.affiliateId, RSDKAnalyticsInvalidAffiliateId);
    XCTAssertNil(record.campaignCode);
    XCTAssertEqual(record.cartState, RSDKAnalyticsInvalidCartState);
    XCTAssertEqual(record.checkoutStage, RSDKAnalyticsInvalidCheckoutStage);
    XCTAssertEqual(record.checkpoints, RSDKAnalyticsInvalidCheckpoints);
    XCTAssertNil(record.componentId);
    XCTAssertNil(record.componentTop);
    XCTAssertEqualObjects(record.contentLocale, NSLocale.currentLocale);
    XCTAssertNil(record.currencyCode);
    XCTAssertNil(record.customParameters);
    XCTAssertNil(record.eventType);
    XCTAssertNil(record.excludeWordSearchQuery);
    XCTAssertNil(record.genre);
    XCTAssertNil(record.goalId);
    XCTAssertNil(record.itemGenre);
    XCTAssertNil(record.itemId);
    XCTAssertNil(record.itemVariation);
    XCTAssertEqual(record.navigationTime, RSDKAnalyticsInvalidNavigationTime);
    XCTAssertNil(record.numberOfItems);
    XCTAssertNil(record.orderId);
    XCTAssertEqual(record.searchMethod, RSDKAnalyticsInvalidSearchMethod);
    XCTAssertNil(record.pageName);
    XCTAssertNil(record.pageType);
    XCTAssertNil(record.itemPrice);
    XCTAssertNil(record.referrer);
    XCTAssertNil(record.requestCode);
    XCTAssertNil(record.scrollDivId);
    XCTAssertNil(record.scrollViewed);
    XCTAssertNil(record.searchQuery);
    XCTAssertNil(record.searchSelectedLocale);
    XCTAssertNil(record.shopId);
}

- (void)testRecordAffiliateIdSetter
{
    RSDKAnalyticsRecord *record = [RSDKAnalyticsRecord recordWithAccountId:0 serviceId:0];

    for (NSNumber *item in @[@(-1000), @0, @1000, @(RSDKAnalyticsInvalidAffiliateId)]) {
        int64_t value = item.longLongValue;
        record.affiliateId = value;
        XCTAssertEqual(record.affiliateId, value);
    }
}

- (void)testRecordCampaignCodeSetter
{
    RSDKAnalyticsRecord *record = [RSDKAnalyticsRecord recordWithAccountId:0 serviceId:0];

    XCTAssertNoThrow(record.campaignCode = @"123");
    XCTAssertEqualObjects(record.campaignCode, @"123");
    XCTAssertThrows(record.campaignCode = self.veryLongString);
    XCTAssertNoThrow(record.campaignCode = nil);
    XCTAssertNil(record.campaignCode);
}

- (void)testRecordCheckoutStageSetter
{
    RSDKAnalyticsRecord *record = [RSDKAnalyticsRecord recordWithAccountId:0 serviceId:0];

    XCTAssertThrows(record.checkoutStage = 9999);
    XCTAssertEqual(record.checkoutStage, RSDKAnalyticsInvalidCheckoutStage);

    for (NSNumber *item in @[@(RSDKAnalyticsCheckoutStage1Login),
                             @(RSDKAnalyticsCheckoutStage2ShippingDetails),
                             @(RSDKAnalyticsCheckoutStage3OrderSummary),
                             @(RSDKAnalyticsCheckoutStage4Payment),
                             @(RSDKAnalyticsCheckoutStage5Verification),
                             @(RSDKAnalyticsInvalidCheckoutStage)]) {
        RSDKAnalyticsCheckoutStage value = item.intValue;
        XCTAssertNoThrow(record.checkoutStage = value);
        XCTAssertEqual(record.checkoutStage, value);
    }
}

- (void)testRecordCheckpointsSetter
{
    RSDKAnalyticsRecord *record = [RSDKAnalyticsRecord recordWithAccountId:0 serviceId:0];

    for (NSNumber *item in @[@0, @(-1000), @1000]) {
        int64_t value = item.longLongValue;
        record.checkpoints = value;
        XCTAssertEqual(record.checkpoints, value);
    }
}

- (void)testRecordComponentIdSetter
{
    RSDKAnalyticsRecord *record = [RSDKAnalyticsRecord recordWithAccountId:0 serviceId:0];

    id obj = @[@"string", @1, @YES];
    XCTAssertThrows(record.componentId = obj);
    XCTAssertNil(record.componentId);

    obj = @[@"string"];
    XCTAssertNoThrow(record.componentId = obj);
    XCTAssertEqual(record.componentId, obj);
}

- (void)testRecordComponentTopSetter
{
    RSDKAnalyticsRecord *record = [RSDKAnalyticsRecord recordWithAccountId:0 serviceId:0];

    id obj = @[@"string", @1, @YES];
    XCTAssertThrows(record.componentTop = obj);
    XCTAssertNil(record.componentTop);

    obj = @[@1, @2.2];
    XCTAssertNoThrow(record.componentTop = obj);
    XCTAssertEqual(record.componentTop, obj);
}

- (void)testRecordCurrencyCodeSetter
{
    RSDKAnalyticsRecord *record = [RSDKAnalyticsRecord recordWithAccountId:0 serviceId:0];
    XCTAssertThrows(record.currencyCode = self.veryLongString);
    XCTAssertNoThrow(record.currencyCode = @"USD");
    ;
    XCTAssertEqualObjects(record.currencyCode, @"USD");
    XCTAssertNoThrow(record.currencyCode = nil);
    XCTAssertNil(record.currencyCode);
    XCTAssertThrows(record.currencyCode = @"US Dollar");
    XCTAssertThrows(record.currencyCode = @"EU");
    XCTAssertThrows(record.currencyCode = @"X");
    XCTAssertThrows(record.currencyCode = @"");
}

- (void)testRecordCustomParametersSetter
{
    RSDKAnalyticsRecord *record = [RSDKAnalyticsRecord recordWithAccountId:0 serviceId:0];

    record.customParameters = @{};
    XCTAssertNil(record.customParameters);

    id obj = @{@"foo": @"bar"};
    record.customParameters = obj;
    XCTAssertEqualObjects(record.customParameters, obj);
}

- (void)testRecordEventTypeSetter
{
    RSDKAnalyticsRecord *record = [RSDKAnalyticsRecord recordWithAccountId:0 serviceId:0];

    record.eventType = @"foo";
    XCTAssertEqualObjects(record.eventType, @"foo");
}

- (void)testExcludeWordSearchQuerySetter
{
    RSDKAnalyticsRecord *record = [RSDKAnalyticsRecord recordWithAccountId:0 serviceId:0];
    XCTAssertThrows(record.excludeWordSearchQuery = self.veryLongString);
    XCTAssertNoThrow(record.excludeWordSearchQuery = @"foo");
    ;
    XCTAssertEqualObjects(record.excludeWordSearchQuery, @"foo");
    XCTAssertNoThrow(record.excludeWordSearchQuery = nil);
    XCTAssertNil(record.excludeWordSearchQuery);
}

- (void)testGenreSetter
{
    RSDKAnalyticsRecord *record = [RSDKAnalyticsRecord recordWithAccountId:0 serviceId:0];
    XCTAssertThrows(record.genre = self.veryLongString);
    XCTAssertNoThrow(record.genre = nil);
    XCTAssertNil(record.genre);
    XCTAssertNoThrow(record.genre = @"foo");
    XCTAssertEqualObjects(record.genre, @"foo");
}

- (void)testGoalIdSetter
{
    RSDKAnalyticsRecord *record = [RSDKAnalyticsRecord recordWithAccountId:0 serviceId:0];
    XCTAssertThrows(record.goalId = self.veryLongString);
    XCTAssertNoThrow(record.goalId = nil);
    XCTAssertNil(record.goalId);
    XCTAssertNoThrow(record.goalId = @"foo");
    XCTAssertEqualObjects(record.goalId, @"foo");
}

- (void)testItemGenreSetter
{
    RSDKAnalyticsRecord *record = [RSDKAnalyticsRecord recordWithAccountId:0 serviceId:0];

    id obj = @[@"string", @1];
    XCTAssertThrows(record.itemGenre = obj);

    obj = [NSMutableArray arrayWithCapacity:200];
    for (int i = 0; i < 200;) {
        [obj addObject:[NSString stringWithFormat:@"genre %d", ++i]];
    }
    XCTAssertThrows(record.itemGenre = obj);
    obj = [obj subarrayWithRange:NSMakeRange(0, 100)];
    XCTAssertNoThrow(record.itemGenre = obj);
    XCTAssertEqual(record.itemGenre.count, 100u);
    XCTAssertEqualObjects(record.itemGenre, obj);
}

- (void)testItemIdSetter
{
    RSDKAnalyticsRecord *record = [RSDKAnalyticsRecord recordWithAccountId:0 serviceId:0];

    id obj = @[@"string", @1];
    XCTAssertThrows(record.itemId = obj);

    obj = [NSMutableArray arrayWithCapacity:200];
    for (int i = 0; i < 200;) {
        [obj addObject:[NSString stringWithFormat:@"id %d", ++i]];
    }
    XCTAssertThrows(record.itemId = obj);
    obj = [obj subarrayWithRange:NSMakeRange(0, 100)];
    XCTAssertNoThrow(record.itemId = obj);
    XCTAssertEqual(record.itemId.count, 100u);
    XCTAssertEqualObjects(record.itemId, obj);
}

- (void)testItemVariationSetter
{
    RSDKAnalyticsRecord *record = [RSDKAnalyticsRecord recordWithAccountId:0 serviceId:0];

    NSArray *prototype = @[@[@"array"], @{@"dictionary": @1}];
    NSUInteger prototypeCount = prototype.count;

    id obj = [NSMutableArray arrayWithCapacity:200];
    for (NSUInteger i = 0; i < 200; ++i) {
        [obj addObject:prototype[i % prototypeCount]];
    }
    XCTAssertThrows(record.itemVariation = obj);
    obj = [obj subarrayWithRange:NSMakeRange(0, 100)];
    XCTAssertNoThrow(record.itemVariation = obj);
    XCTAssertEqual(record.itemVariation.count, 100u);
    XCTAssertEqualObjects(record.itemVariation, obj);
}

- (void)testNumberOfItemsSetter
{
    RSDKAnalyticsRecord *record = [RSDKAnalyticsRecord recordWithAccountId:0 serviceId:0];

    id obj = @[@1, @2, @"string"];
    XCTAssertThrows(record.numberOfItems = obj, @"should contain NSNumber objects only");

    obj = @[@1, @2, @(-1)];
    XCTAssertThrows(record.numberOfItems = obj, @"all numbers should be positive");

    obj = @[@1, @2, @1.1];
    XCTAssertThrows(record.numberOfItems = obj, @"all numbers should be integers");

    obj = @[@1, @2, @3];
    XCTAssertNoThrow(record.numberOfItems = obj);

    obj = [NSMutableArray arrayWithCapacity:200];
    for (int i = 0; i < 200;) {
        [obj addObject:@(++i)];
    }
    XCTAssertThrows(record.numberOfItems = obj);
    obj = [obj subarrayWithRange:NSMakeRange(0, 100)];
    XCTAssertNoThrow(record.numberOfItems = obj);
    XCTAssertEqual(record.numberOfItems.count, 100u);
    XCTAssertEqualObjects(record.numberOfItems, obj);
}

- (void)testPageNameSetter
{
    RSDKAnalyticsRecord *record = [RSDKAnalyticsRecord recordWithAccountId:0 serviceId:0];
    XCTAssertThrows(record.pageName = self.veryLongString);
    XCTAssertNoThrow(record.pageName = nil);
    XCTAssertNil(record.pageName);
    XCTAssertNoThrow(record.pageName = @"foo");
    XCTAssertEqualObjects(record.pageName, @"foo");
}

- (void)testPageTypeSetter
{
    RSDKAnalyticsRecord *record = [RSDKAnalyticsRecord recordWithAccountId:0 serviceId:0];
    XCTAssertThrows(record.pageType = self.veryLongString);
    XCTAssertNoThrow(record.pageType = nil);
    XCTAssertNil(record.pageType);
    XCTAssertNoThrow(record.pageType = @"foo");
    XCTAssertEqualObjects(record.pageType, @"foo");
}

- (void)testItemPriceSetter
{
    RSDKAnalyticsRecord *record = [RSDKAnalyticsRecord recordWithAccountId:0 serviceId:0];

    id obj = @[@1, @2, @"string"];
    XCTAssertThrows(record.itemPrice = obj, @"should contain NSNumber objects only");

    obj = @[@1.5, @2000, @3.3];
    XCTAssertNoThrow(record.itemPrice = obj);

    obj = [NSMutableArray arrayWithCapacity:200];
    for (int i = 0; i < 200;) {
        [obj addObject:@(++i)];
    }
    XCTAssertThrows(record.itemPrice = obj);
    obj = [obj subarrayWithRange:NSMakeRange(0, 100)];
    XCTAssertNoThrow(record.itemPrice = obj);
    XCTAssertEqual(record.itemPrice.count, 100u);
    XCTAssertEqualObjects(record.itemPrice, obj);
}

- (void)testReferrerSetter
{
    RSDKAnalyticsRecord *record = [RSDKAnalyticsRecord recordWithAccountId:0 serviceId:0];
    XCTAssertThrows(record.referrer = self.veryLongString);
    XCTAssertNoThrow(record.referrer = nil);
    XCTAssertNil(record.referrer);
    XCTAssertNoThrow(record.referrer = @"foo");
    XCTAssertEqualObjects(record.referrer, @"foo");
}

- (void)testRequestCodeSetter
{
    RSDKAnalyticsRecord *record = [RSDKAnalyticsRecord recordWithAccountId:0 serviceId:0];
    XCTAssertThrows(record.requestCode = self.veryLongString);
    XCTAssertNoThrow(record.requestCode = nil);
    XCTAssertNil(record.requestCode);
    XCTAssertNoThrow(record.requestCode = @"foo");
    XCTAssertEqualObjects(record.requestCode, @"foo");
}

- (void)testScrollDivIdSetter
{
    RSDKAnalyticsRecord *record = [RSDKAnalyticsRecord recordWithAccountId:0 serviceId:0];

    id obj = @[@1, @2, @"string"];
    XCTAssertThrows(record.scrollDivId = obj, @"should contain NSString objects only");

    obj = @[@"A", @"B", @"C"];
    XCTAssertNoThrow(record.scrollDivId = obj);

    obj = @[];
    XCTAssertNoThrow(record.scrollDivId = obj);
    XCTAssertNil(record.scrollDivId);

    obj = [NSMutableArray arrayWithCapacity:200];
    for (int i = 0; i < 200;) {
        [obj addObject:[NSString stringWithFormat:@"id %d", ++i]];
    }
    XCTAssertThrows(record.scrollDivId = obj);
    obj = [obj subarrayWithRange:NSMakeRange(0, 100)];
    XCTAssertNoThrow(record.scrollDivId = obj);
    XCTAssertEqual(record.scrollDivId.count, 100u);
    XCTAssertEqualObjects(record.scrollDivId, obj);
}

- (void)testScrollViewedSetter
{
    RSDKAnalyticsRecord *record = [RSDKAnalyticsRecord recordWithAccountId:0 serviceId:0];

    id obj = @[@1, @2, @"string"];
    XCTAssertThrows(record.scrollViewed = obj, @"should contain NSString objects only");

    obj = @[@"A", @"B", @"C"];
    XCTAssertNoThrow(record.scrollViewed = obj);

    obj = @[];
    XCTAssertNoThrow(record.scrollViewed = obj);
    XCTAssertNil(record.scrollViewed);

    obj = [NSMutableArray arrayWithCapacity:200];
    for (int i = 0; i < 200;) {
        [obj addObject:[NSString stringWithFormat:@"id %d", ++i]];
    }
    XCTAssertThrows(record.scrollViewed = obj);
    obj = [obj subarrayWithRange:NSMakeRange(0, 100)];
    XCTAssertNoThrow(record.scrollViewed = obj);
    XCTAssertEqual(record.scrollViewed.count, 100u);
    XCTAssertEqualObjects(record.scrollViewed, obj);
}

- (void)testSearchQuerySetter
{
    RSDKAnalyticsRecord *record = [RSDKAnalyticsRecord recordWithAccountId:0 serviceId:0];
    XCTAssertThrows(record.searchQuery = self.veryLongString);
    XCTAssertNoThrow(record.searchQuery = nil);
    XCTAssertNil(record.searchQuery);
    XCTAssertNoThrow(record.searchQuery = @"foo");
    XCTAssertEqualObjects(record.searchQuery, @"foo");
}

- (void)testPropertiesDictionary
{
    id arrayOfStrings = @[@"A", @"B"];
    id arrayOfNumbers = @[@1, @2];
    id dictionary = @{@"A": arrayOfStrings, @"B": arrayOfNumbers};

    NSDictionary *expected = @{
                               @"acc": @1,
                               @"afid": @2,
                               @"cc": @"A",
                               @"cart": @3,
                               @"chkout": @50,
                               @"chkpt": @4,
                               @"compid": arrayOfStrings,
                               @"comptop": arrayOfNumbers,
                               @"cntln": @"fr_CA",
                               @"cycode": @"JPY",
                               @"cp": dictionary,
                               @"etype": @"C",
                               @"esq": @"D",
                               @"genre": @"E",
                               @"gol": @"F",
                               @"igenre": arrayOfStrings,
                               @"itemid": arrayOfStrings,
                               @"variation": @[dictionary, dictionary],
                               @"mnavtime": @5,
                               @"ni": arrayOfNumbers,
                               @"order_id": @"G",
                               @"oa": @"a",
                               @"pgn": @"H",
                               @"pgt": @"I",
                               @"price": arrayOfNumbers,
                               @"ref": @"J",
                               @"reqc": @"K",
                               @"scroll": arrayOfStrings,
                               @"sresv": arrayOfStrings,
                               @"sq": @"L",
                               @"lang": @"fr_CA",
                               @"aid": @6,
                               @"shopid": @"N",
                               };


    RSDKAnalyticsRecord *record = [RSDKAnalyticsRecord recordWithAccountId:[expected[@"acc"] unsignedLongLongValue]
                                                                 serviceId:[expected[@"aid"] longLongValue]];
    record.affiliateId = [expected[@"afid"] longLongValue];
    record.campaignCode = expected[@"cc"];
    record.cartState = [expected[@"cart"] unsignedLongLongValue];
    record.checkoutStage = [expected[@"chkout"] intValue];
    record.checkpoints = [expected[@"chkpt"] longLongValue];
    record.componentId = expected[@"compid"];
    record.componentTop = expected[@"comptop"];
    record.contentLocale = [NSLocale localeWithLocaleIdentifier:expected[@"cntln"]];
    record.currencyCode = expected[@"cycode"];
    record.customParameters = expected[@"cp"];
    record.eventType = expected[@"etype"];
    record.excludeWordSearchQuery = expected[@"esq"];
    record.genre = expected[@"genre"];
    record.goalId = expected[@"gol"];
    record.itemGenre = expected[@"igenre"];
    record.itemId = expected[@"itemid"];
    record.itemVariation = expected[@"variation"];
    record.navigationTime = (NSTimeInterval)[expected[@"mnavtime"] longLongValue] / 1000.0;
    record.numberOfItems = expected[@"ni"];
    record.orderId = expected[@"order_id"];
    record.searchMethod = RSDKAnalyticsSearchMethodAnd;
    record.pageName = expected[@"pgn"];
    record.pageType = expected[@"pgt"];
    record.itemPrice = expected[@"price"];
    record.referrer = expected[@"ref"];
    record.requestCode = expected[@"reqc"];
    record.scrollDivId = expected[@"scroll"];
    record.scrollViewed = expected[@"sresv"];
    record.searchQuery = expected[@"sq"];
    record.searchSelectedLocale = [NSLocale localeWithLocaleIdentifier:expected[@"lang"]];
    record.shopId = expected[@"shopid"];

    NSDictionary *propertiesDictionary = record.propertiesDictionary;
    NSSet *gotSet = [NSSet setWithArray:propertiesDictionary.allKeys];
    NSSet *expectedSet = [NSSet setWithArray:expected.allKeys];

    NSMutableSet *missingFields = [NSMutableSet setWithSet:expectedSet];
    [missingFields minusSet:gotSet];
    XCTAssert(missingFields.count == 0, @"Missing fields: %@", missingFields);

    NSMutableSet *extraneousFields = [NSMutableSet setWithSet:gotSet];
    [extraneousFields minusSet:expectedSet];
    XCTAssert(extraneousFields.count == 0, @"Extraneous fields: %@", extraneousFields);

    XCTAssertEqualObjects(propertiesDictionary, expected);
}

@end

