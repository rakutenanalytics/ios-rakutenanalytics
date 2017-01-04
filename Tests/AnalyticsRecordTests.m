/*
 * © Rakuten, Inc.
 * authors: "Rakuten Ecosystem Mobile" <ecosystem-mobile@mail.rakuten.com>
 */
@import XCTest;
#import <RSDKAnalytics/RSDKAnalytics.h>
#import <AdSupport/ASIdentifierManager.h>

@interface RSDKAnalyticsRecord ()
@property (nonatomic) int64_t  serviceId;
@end

@interface AnalyticsRecordTests : XCTestCase
@end

@implementation AnalyticsRecordTests

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
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

- (RSDKAnalyticsRecord *)defaultRecord
{
    id arrayOfStrings = @[@"A", @"B"];
    id arrayOfNumbers = @[@1, @2];
    id dictionary = @{@"A": arrayOfStrings, @"B": arrayOfNumbers};
    
    RSDKAnalyticsRecord *record = [RSDKAnalyticsRecord recordWithAccountId:0
                                                                 serviceId:0];
    record.affiliateId = 1;
    record.campaignCode = @"campaign_code";
    record.customParameters = dictionary;
    record.eventType = @"etype";
    record.selectedTags = @[@"tag1", @"tag2"];
    record.componentId = @[@"comp1", @"comp2"];
    record.componentTop = @[@1, @2];
    record.scrollDivId = @[@"scroll", @"div", @"id"];
    record.scrollViewed = @[@"scroll", @"viewed"];
    record.customParameters = @{@"param1":@"1", @"param2":@"2"};

    RSDKAnalyticsItem *item1 = [RSDKAnalyticsItem itemWithIdentifier:@"A"];
    RSDKAnalyticsItem *item2 = [RSDKAnalyticsItem itemWithIdentifier:@"B"];
    item1.quantity = 1;
    item2.quantity = 2;
    item1.genre = @"A";
    item2.genre = @"B";
    item1.price = 1;
    item2.price = 2;
    item1.variation = dictionary;
    item2.variation = dictionary;
    
    [record addItem:item1];
    [record addItem:item2];
    
    return record;
}

- (void)testInitThrows
{
    XCTAssertThrowsSpecificNamed([RSDKAnalyticsRecord.alloc init], NSException, NSInvalidArgumentException);
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
    XCTAssertNil(record.userId);
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

    __block BOOL hasItems = NO;
    [record enumerateItemsWithBlock:^(RSDKAnalyticsItem __unused *item, NSUInteger __unused index, BOOL __unused *stop) {
        hasItems = YES;
    }];
    XCTAssertFalse(hasItems);

    XCTAssertEqual(record.navigationTime, RSDKAnalyticsInvalidNavigationTime);
    XCTAssertNil(record.orderId);
    XCTAssertEqual(record.searchMethod, RSDKAnalyticsInvalidSearchMethod);
    XCTAssertNil(record.pageName);
    XCTAssertNil(record.pageType);
    XCTAssertNil(record.referrer);
    XCTAssertNil(record.requestCode);
    XCTAssertNil(record.scrollDivId);
    XCTAssertNil(record.scrollViewed);
    XCTAssertNil(record.searchQuery);
    XCTAssertNil(record.searchSelectedLocale);
    XCTAssertNil(record.shopId);
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
                               @"shopid": @"N"
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

    RSDKAnalyticsItem *item1 = [RSDKAnalyticsItem itemWithIdentifier:@"A"];
    RSDKAnalyticsItem *item2 = [RSDKAnalyticsItem itemWithIdentifier:@"B"];
    item1.quantity = 1;
    item2.quantity = 2;
    item1.genre = @"A";
    item2.genre = @"B";
    item1.price = 1;
    item2.price = 2;
    item1.variation = dictionary;
    item2.variation = dictionary;

    [record addItem:item1];
    [record addItem:item2];

    record.navigationTime = (NSTimeInterval)[expected[@"mnavtime"] longLongValue] / 1000.0;
    record.orderId = expected[@"order_id"];
    record.searchMethod = RSDKAnalyticsSearchMethodAnd;
    record.pageName = expected[@"pgn"];
    record.pageType = expected[@"pgt"];
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

- (void)testCodingDecoding
{
    RSDKAnalyticsRecord *record = [self defaultRecord];

    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:record];
    RSDKAnalyticsRecord *unarchived = [NSKeyedUnarchiver unarchiveObjectWithData:data];

    XCTAssertEqualObjects(unarchived.propertiesDictionary, record.propertiesDictionary);
}

- (void)testCopying
{
    RSDKAnalyticsRecord *record = [self defaultRecord];
    RSDKAnalyticsRecord *copy = record.copy;
    
    XCTAssertEqualObjects(record, copy);
    XCTAssertNotEqual(record, copy);
    
    copy.serviceId = 3;
    
    XCTAssertNotEqualObjects(record, copy);
}

- (void)testCopiesAreEqual
{
    RSDKAnalyticsRecord *record = [self defaultRecord];
    RSDKAnalyticsRecord *copy = record.copy;
    
    XCTAssertEqualObjects(record, copy);
    XCTAssertNotEqual(record, copy);
}

- (void)testRecordsWithSamePropertiesAreEqual
{
    RSDKAnalyticsRecord *record = [self defaultRecord];
    RSDKAnalyticsRecord *other = [self defaultRecord];
    XCTAssertEqualObjects(record, other);
}

- (void)testRecordsWithDifferentPropertiesAreNotEqual
{
    RSDKAnalyticsRecord *record = [self defaultRecord];
    RSDKAnalyticsRecord *other = [self defaultRecord];
    other.serviceId = 10;
    XCTAssertNotEqualObjects(record, other);
}

- (void)testRecordIsNotEqualToDifferentObject
{
    RSDKAnalyticsRecord *record = [self defaultRecord];
    XCTAssertNotEqualObjects(record, UIView.new);
}

- (void)testHashIsIdenticalWhenObjectsEqual
{
    RSDKAnalyticsRecord *record = [self defaultRecord];
    RSDKAnalyticsRecord *other = [self defaultRecord];
    XCTAssertEqualObjects(record, other);
    XCTAssertEqual(record.hash, other.hash);
}

- (void)testHashIsDifferentWhenObjectsNotEqual
{
    RSDKAnalyticsRecord *record = [self defaultRecord];
    RSDKAnalyticsRecord *other = [RSDKAnalyticsRecord recordWithAccountId:1 serviceId:1];
    XCTAssertNotEqualObjects(record, other);
    XCTAssertNotEqual(record.hash, other.hash);
}

#pragma clang diagnostic pop

@end

