@import XCTest;
#import <RAnalytics/RAnalytics.h>
#import "../RAnalytics/Util/Private/_RAnalyticsDatabase.h"

@interface DatabaseTests : XCTestCase
@end

@implementation DatabaseTests
- (void)testBasicInsertFetchDelete
{
    uint64_t millisecondsSince1970 = ceil([NSDate.date timeIntervalSince1970] * 1000.0);
    NSString *table = [NSString stringWithFormat:@"testInsertAndFetch%@", @(millisecondsSince1970)];

    // Generate a big blob
    NSUInteger blobLength = 10240;
    NSMutableData *bigBlob = [NSMutableData dataWithLength:blobLength];
    unsigned char *blobAddress = bigBlob.mutableBytes;
    unsigned char *bytePointer = blobAddress + blobLength;
    while (--bytePointer >= blobAddress)
    {
        *bytePointer = (unsigned long long)bytePointer % 256;
    }

    // Insert 10 blobs, with a table limit of 3 rows
    for (int i = 0; i < 10; ++i)
    {
        XCTestExpectation *e = [self expectationWithDescription:[NSString stringWithFormat:@"Insert expectation #%i", i]];

        // Mark the blob's first byte so we can identify it later on
        ((unsigned char *) bigBlob.mutableBytes)[0] = i;
        [_RAnalyticsDatabase insertBlob:bigBlob into:table limit:3 then:^{
            [e fulfill];
        }];
    }
    [self waitForExpectationsWithTimeout:10 handler:nil];

    XCTestExpectation *fetch = [self expectationWithDescription:@"Fetch expectation"];
    NSArray *__block fetchedIdentifiers = nil;
    [_RAnalyticsDatabase fetchBlobs:10 from:table then:^(NSArray<NSData *>* blobs, NSArray<NSNumber *>* identifiers) {
        XCTAssertNotNil(blobs);
        XCTAssertNotNil(identifiers);

        /*
         * There should be only 3 blobs in the table, with their first byte set to 7, 8 and 9, respectively.
         */
        XCTAssertEqual(blobs.count, 3);
        static const unsigned char expected[3] = {7, 8, 9};

        int i = 0;
        for (NSData *data in blobs)
        {
            XCTAssertEqual(data.length, 10240);

            const unsigned char *ptr = data.bytes;
            XCTAssertEqual(*ptr, expected[i++]);
        }

        XCTAssertEqual(identifiers.count, blobs.count);

        fetchedIdentifiers = identifiers;
        [fetch fulfill];
    }];
    [self waitForExpectationsWithTimeout:10 handler:nil];

    XCTestExpectation *purge = [self expectationWithDescription:@"Purge expectation"];
    [_RAnalyticsDatabase deleteBlobsWithIdentifiers:fetchedIdentifiers in:table then:^{
        [purge fulfill];
    }];
    [self waitForExpectationsWithTimeout:10 handler:nil];

    fetch = [self expectationWithDescription:@"Second Fetch expectation"];
    [_RAnalyticsDatabase fetchBlobs:10 from:table then:^(NSArray<NSData *>* blobs, NSArray<NSNumber *>* identifiers) {
        XCTAssertNil(blobs);
        XCTAssertNil(identifiers);
        [fetch fulfill];
    }];
    [self waitForExpectationsWithTimeout:10 handler:nil];
}

- (void)testInsertionInMultipleTables
{
    uint64_t millisecondsSince1970 = ceil([NSDate.date timeIntervalSince1970] * 1000.0);
    for (int i = 0; i < 100; ++i)
    {
        NSString *table = [NSString stringWithFormat:@"testInsertionInMultipleTables%@_%i", @(millisecondsSince1970), i];
        XCTestExpectation *e = [self expectationWithDescription:[NSString stringWithFormat:@"Insert expectation #%i", i]];
        [_RAnalyticsDatabase insertBlobs:@[[@"The"   dataUsingEncoding:NSUTF8StringEncoding],
                                           [@"quick" dataUsingEncoding:NSUTF8StringEncoding],
                                           [@"brown" dataUsingEncoding:NSUTF8StringEncoding],
                                           [@"fox"   dataUsingEncoding:NSUTF8StringEncoding],
                                           [@"jumps" dataUsingEncoding:NSUTF8StringEncoding],
                                           [@"over"  dataUsingEncoding:NSUTF8StringEncoding],
                                           [@"the"   dataUsingEncoding:NSUTF8StringEncoding],
                                           [@"lazy"  dataUsingEncoding:NSUTF8StringEncoding],
                                           [@"dog"   dataUsingEncoding:NSUTF8StringEncoding]] into:table limit:3 then:^{
            [e fulfill];
        }];
    }
    [self waitForExpectationsWithTimeout:10 handler:nil];
}

@end
