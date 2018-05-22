#import <Kiwi/Kiwi.h>
#import <sqlite3.h>

#import "../../RAnalytics/Core/Private/_RAnalyticsDatabase.h"

#import "DatabaseTestUtils.h"

SPEC_BEGIN(RAnalyticsDatabaseUnitTests)

describe(@"RAnalyticsDatabase", ^{
    __block sqlite3* connection;
    __block sqlite3* readonlyConnection;
    
    beforeEach(^{
        connection = openRegularConnection();
        readonlyConnection = openReadonlyConnection();
    });
    
    afterEach(^{
        sqlite3_close(connection);
        sqlite3_close(readonlyConnection);
        
        connection = nil;
        readonlyConnection = nil;
    });
    
    describe(@"insertBlob:into:limit:then:", ^{
        it(@"should trigger multiple blobs insertation with a passed parameters", ^{
            _RAnalyticsDatabase* db = mkDatabase(connection);
            NSData* blob = [@"foo" dataUsingEncoding:NSUTF8StringEncoding];
            
            [[db should] receive:@selector(insertBlobs:into:limit:then:) withArguments:@[blob], @"test_table", theValue(1), nil];
            
            [db insertBlob:blob into:@"test_table" limit:1 then:nil];
        });
    });
    
    describe(@"insertBlobs:into:limit:then:", ^{
        it(@"should create table to insert if it does not exist yet", ^{
            _RAnalyticsDatabase* db = mkDatabase(connection);

            __block BOOL exists = NO;
            [db insertBlobs:@[] into:@"some_table" limit:1 then:^{
                exists = isTableExist(@"some_table", connection);
            }];

            [[expectFutureValue(theValue(exists)) shouldEventually] equal:theValue(YES)];
        });
        
        it(@"should insert blobs into provided table", ^{
            _RAnalyticsDatabase* db = mkDatabase(connection);
            NSData* blob = [@"foo" dataUsingEncoding:NSUTF8StringEncoding];
            NSData* anotherBlob = [@"bar" dataUsingEncoding:NSUTF8StringEncoding];
            
            __block NSArray* insertedBlobs;
            [db insertBlobs:@[blob, anotherBlob] into:@"some_table" limit:0 then:^{
                insertedBlobs = fetchTableContents(@"some_table", connection);
            }];
            
            [[expectFutureValue(insertedBlobs) shouldEventually] equal:@[blob, anotherBlob]];
        });
        
        it(@"should insert only blobs which were added to the array on the moment blobs insertation was requested", ^{
            _RAnalyticsDatabase* db = mkDatabase(connection);
            NSData* blob = [@"foo" dataUsingEncoding:NSUTF8StringEncoding];
            NSData* anotherBlob = [@"bar" dataUsingEncoding:NSUTF8StringEncoding];
            NSMutableArray* blobs = [NSMutableArray arrayWithObject:blob];
            
            __block NSArray* insertedBlobs;
            [db insertBlobs:blobs into:@"some_table" limit:0 then:^{
                insertedBlobs = fetchTableContents(@"some_table", connection);
            }];
            [blobs addObject:anotherBlob];
            
            [[expectFutureValue(insertedBlobs) shouldEventually] equal:@[blob]];
        });
        
        it(@"should insert blobs to table name as it was on the moment function called", ^{
            _RAnalyticsDatabase* db = mkDatabase(connection);
            NSArray* blobs = @[[@"foo" dataUsingEncoding:NSUTF8StringEncoding]];
            NSMutableString* table = [NSMutableString stringWithString:@"some_table"];
            
            __block NSArray* insertedBlobs;
            [db insertBlobs:blobs into:table limit:0 then:^{
                insertedBlobs = fetchTableContents(@"some_table", connection);
            }];
            [table appendString:@"_foobar"];
            
            [[expectFutureValue(insertedBlobs) shouldEventually] equal:blobs];
        });
        
        it(@"should limit amount of records in updated table as limit passed in param", ^{
            _RAnalyticsDatabase* db = mkDatabase(connection);
            NSArray* previousContent = @[
                [@"fizz" dataUsingEncoding:NSUTF8StringEncoding],
                [@"bazz" dataUsingEncoding:NSUTF8StringEncoding]
            ];
            insertBlobsIntoTable(previousContent, @"some_table", connection);
            
            __block NSArray* tableContents;
            [db insertBlobs:@[] into:@"some_table" limit:1 then:^{
                tableContents = fetchTableContents(@"some_table", connection);
            }];
            
            [[expectFutureValue(theValue(tableContents.count)) shouldEventually] equal:theValue(1)];
        });
        
        it(@"should limit both just-inserted and old entries leaving the newest ones", ^{
            _RAnalyticsDatabase* db = mkDatabase(connection);
            NSArray* previousContent = @[
                 [@"fizz" dataUsingEncoding:NSUTF8StringEncoding],
                 [@"bazz" dataUsingEncoding:NSUTF8StringEncoding]
            ];
            NSArray* newContent = @[
                [@"foo" dataUsingEncoding:NSUTF8StringEncoding],
                [@"bar" dataUsingEncoding:NSUTF8StringEncoding]
            ];
            insertBlobsIntoTable(previousContent, @"some_table", connection);
            
            __block NSArray* tableContents;
            [db insertBlobs:newContent into:@"some_table" limit:1 then:^{
                tableContents = fetchTableContents(@"some_table", connection);
            }];
            
            [[expectFutureValue(tableContents) shouldEventually] equal:@[[@"bar" dataUsingEncoding:NSUTF8StringEncoding]]];
        });
        
        it(@"should not remove previous or new records from DB if limit is 0", ^{
            _RAnalyticsDatabase* db = mkDatabase(connection);
            NSArray* previousContent = @[
                [@"fizz" dataUsingEncoding:NSUTF8StringEncoding],
                [@"bazz" dataUsingEncoding:NSUTF8StringEncoding]
            ];
            NSArray* newContent = @[
                [@"foo" dataUsingEncoding:NSUTF8StringEncoding],
                [@"bar" dataUsingEncoding:NSUTF8StringEncoding]
            ];
            insertBlobsIntoTable(previousContent, @"some_table", connection);
            
            __block NSArray* tableContents;
            [db insertBlobs:newContent into:@"some_table" limit:0 then:^{
                tableContents = fetchTableContents(@"some_table", connection);
            }];
            
            
            [[expectFutureValue(tableContents) shouldEventually] equal:@[
                [@"fizz" dataUsingEncoding:NSUTF8StringEncoding],
                [@"bazz" dataUsingEncoding:NSUTF8StringEncoding],
                [@"foo" dataUsingEncoding:NSUTF8StringEncoding],
                [@"bar" dataUsingEncoding:NSUTF8StringEncoding]
            ]];
        });
        
        describe(@"erroring connection", ^{
            it(@"should not create passed table if some error occured",  ^{
                _RAnalyticsDatabase* db = mkDatabase(readonlyConnection);
                
                __block BOOL someTableExists = YES;
                [db insertBlobs:@[[@"foo" dataUsingEncoding:NSUTF8StringEncoding]] into:@"some_table" limit:0 then:^{
                    someTableExists = isTableExist(@"some_table", connection);
                }];
                
                [[expectFutureValue(theValue(someTableExists)) shouldEventually] equal:theValue(NO)];
            });
            
            it(@"should not insert records in DB if some error occured",  ^{
                _RAnalyticsDatabase* db = mkDatabase(readonlyConnection);
                
                __block NSArray* tableContents;
                [db insertBlobs:@[[@"foo" dataUsingEncoding:NSUTF8StringEncoding]] into:@"some_table" limit:0 then:^{
                    tableContents = fetchTableContents(@"some_table", readonlyConnection);
                }];
                
                [[expectFutureValue(tableContents) shouldEventually] equal:@[]];
            });
            
            it(@"should not remove old records from DB if some error occured",  ^{
                _RAnalyticsDatabase* db = mkDatabase(readonlyConnection);
                insertBlobsIntoTable(@[[@"foo" dataUsingEncoding:NSUTF8StringEncoding]], @"some_table", connection);
                
                __block NSArray* tableContents;
                [db insertBlobs:@[[@"bar" dataUsingEncoding:NSUTF8StringEncoding]] into:@"some_table" limit:0 then:^{
                    tableContents = fetchTableContents(@"some_table", connection);
                }];
                
                [[expectFutureValue(tableContents) shouldEventually] equal:@[[@"foo" dataUsingEncoding:NSUTF8StringEncoding]]];
            });
        });
    });
    
    describe(@"fetchBlobs:from:then:", ^{
        it(@"should create passed table if table did not exist before", ^{
            _RAnalyticsDatabase* database = mkDatabase(connection);
            
            __block BOOL someTableExists;
            [database fetchBlobs:100500 from:@"some_table" then:^(NSArray<NSData *> * _Nullable blobs, NSArray<NSNumber *> * _Nullable identifiers) {
                someTableExists = isTableExist(@"some_table", connection);
            }];
            
            [[expectFutureValue(theValue(someTableExists)) shouldEventually] equal:theValue(YES)];
        });
        
        it(@"should fetch blobs from passed table", ^{
            _RAnalyticsDatabase* database = mkDatabase(connection);
            NSArray* blobs = @[[@"foo" dataUsingEncoding:NSUTF8StringEncoding]];
            insertBlobsIntoTable(blobs, @"some_table", connection);
            
            __block NSArray* fetchedBlobs;
            [database fetchBlobs:100500 from:@"some_table" then:^(NSArray<NSData *> * _Nullable blobsFromDb, NSArray<NSNumber *> * _Nullable identifiers) {
                fetchedBlobs = blobsFromDb;
            }];
            
            [[expectFutureValue(fetchedBlobs) shouldEventually] equal:blobs];
        });
        
        it(@"should fetch ids corresponding to blobs from passed table", ^{
            _RAnalyticsDatabase* database = mkDatabase(connection);
            NSArray* blobs = @[[@"foo" dataUsingEncoding:NSUTF8StringEncoding]];
            insertBlobsIntoTable(blobs, @"some_table", connection);
            
            __block NSArray* fetchedIds;
            [database fetchBlobs:100500 from:@"some_table" then:^(NSArray<NSData *> * _Nullable blobs, NSArray<NSNumber *> * _Nullable identifiers) {
                fetchedIds = identifiers;
            }];
            
            [[expectFutureValue(fetchedIds) shouldEventually] equal:@[@1]];
        });
        
        it(@"should fetch blobs from table name as it was on the moment function called", ^{
            _RAnalyticsDatabase* db = mkDatabase(connection);
            NSMutableString* table = [NSMutableString stringWithString:@"some_table"];
            insertBlobsIntoTable(@[[@"foo" dataUsingEncoding:NSUTF8StringEncoding]], @"some_table", connection);
            
            __block NSArray* fetchedBlobs;
            [db fetchBlobs:100500 from:table then:^(NSArray<NSData *> * _Nullable blobsFromDb, NSArray<NSNumber *> * _Nullable identifiers) {
                fetchedBlobs = blobsFromDb;
            }];
            [table appendString:@"_foobar"];
            
            [[expectFutureValue(fetchedBlobs) shouldEventually] equal:@[[@"foo" dataUsingEncoding:NSUTF8StringEncoding]]];
        });
        
        it(@"should fetch blob ids from table name as it was on the moment function called", ^{
            _RAnalyticsDatabase* db = mkDatabase(connection);
            NSMutableString* table = [NSMutableString stringWithString:@"some_table"];
            insertBlobsIntoTable(@[[@"foo" dataUsingEncoding:NSUTF8StringEncoding]], @"some_table", connection);
            
            __block NSArray* fetchedIds;
            [db fetchBlobs:100500 from:table then:^(NSArray<NSData *> * _Nullable blobsFromDb, NSArray<NSNumber *> * _Nullable identifiers) {
                fetchedIds = identifiers;
            }];
            [table appendString:@"_foobar"];
            
            [[expectFutureValue(fetchedIds) shouldEventually] equal:@[@1]];
        });
        
        it(@"should not fetch blobs if amount to fetch is 0", ^{
            _RAnalyticsDatabase* database = mkDatabase(connection);
            NSArray* blobs = @[[@"foo" dataUsingEncoding:NSUTF8StringEncoding]];
            insertBlobsIntoTable(blobs, @"some_table", connection);
            
            __block NSArray* fetchedBlobs = @[];
            [database fetchBlobs:0 from:@"some_table" then:^(NSArray<NSData *> * _Nullable blobsFromDb, NSArray<NSNumber *> * _Nullable identifiers) {
                fetchedBlobs = blobsFromDb;
            }];
            
            [[expectFutureValue(fetchedBlobs) shouldEventually] beNil];
        });
        
        it(@"should not fetch identifiers if amount to fetch is 0", ^{
            _RAnalyticsDatabase* database = mkDatabase(connection);
            NSArray* blobs = @[[@"foo" dataUsingEncoding:NSUTF8StringEncoding]];
            insertBlobsIntoTable(blobs, @"some_table", connection);
            
            __block NSArray* fetchedIds = @[];
            [database fetchBlobs:0 from:@"some_table" then:^(NSArray<NSData *> * _Nullable blobsFromDb, NSArray<NSNumber *> * _Nullable identifiers) {
                fetchedIds = identifiers;
            }];
            
            [[expectFutureValue(fetchedIds) shouldEventually] beNil];
        });
        
        it(@"should limit the amount of fetched blobs to amount param fetching the oldest ones first", ^{
            _RAnalyticsDatabase* database = mkDatabase(connection);
            NSArray* blobs = @[
                [@"foo" dataUsingEncoding:NSUTF8StringEncoding],
                [@"bar" dataUsingEncoding:NSUTF8StringEncoding],
                [@"baz" dataUsingEncoding:NSUTF8StringEncoding]
            ];
            insertBlobsIntoTable(blobs, @"some_table", connection);
            
            __block NSArray* fetchedBlobs = @[];
            [database fetchBlobs:2 from:@"some_table" then:^(NSArray<NSData *> * _Nullable blobsFromDb, NSArray<NSNumber *> * _Nullable identifiers) {
                fetchedBlobs = blobsFromDb;
            }];
            
            [[expectFutureValue(fetchedBlobs) shouldEventually] equal:@[
                [@"foo" dataUsingEncoding:NSUTF8StringEncoding],
                [@"bar" dataUsingEncoding:NSUTF8StringEncoding]
            ]];
        });
        
        it(@"should limit the amount of fetched ids to amount param fetching the oldest ones first", ^{
            _RAnalyticsDatabase* database = mkDatabase(connection);
            NSArray* blobs = @[
                [@"foo" dataUsingEncoding:NSUTF8StringEncoding],
                [@"bar" dataUsingEncoding:NSUTF8StringEncoding],
                [@"baz" dataUsingEncoding:NSUTF8StringEncoding]
            ];
            insertBlobsIntoTable(blobs, @"some_table", connection);
            
            __block NSArray* fetchedIds = @[];
            [database fetchBlobs:2 from:@"some_table" then:^(NSArray<NSData *> * _Nullable blobsFromDb, NSArray<NSNumber *> * _Nullable identifiers) {
                fetchedIds = identifiers;
            }];
            
            [[expectFutureValue(fetchedIds) shouldEventually] equal:@[
                @1,
                @2
            ]];
        });
        
        describe(@"erroring connection", ^{
            it(@"should not create passed table if some error occured",  ^{
                _RAnalyticsDatabase* db = mkDatabase(readonlyConnection);
                
                __block BOOL someTableExists = YES;
                [db fetchBlobs:123 from:@"some_table" then:^(NSArray<NSData *> * _Nullable blobsFromDB, NSArray<NSNumber *> * _Nullable identifiers) {
                    someTableExists = isTableExist(@"some_table", connection);
                }];
                
                [[expectFutureValue(theValue(someTableExists)) shouldEventually] equal:theValue(NO)];
            });
            
            it(@"should not fetch blobs from DB if some error occured",  ^{
                _RAnalyticsDatabase* db = mkDatabase(readonlyConnection);
                NSArray* blobs = @[[@"foo" dataUsingEncoding:NSUTF8StringEncoding]];
                insertBlobsIntoTable(blobs, @"some_table", connection);
                
                __block NSArray* fetchedBlobs = @[];
                [db fetchBlobs:123 from:@"some_table" then:^(NSArray<NSData *> * _Nullable blobsFromDB, NSArray<NSNumber *> * _Nullable identifiers) {
                    fetchedBlobs = blobsFromDB;
                }];
                
                [[expectFutureValue(fetchedBlobs) shouldEventually] beNil];
            });
        });
    });
    
    describe(@"deleteBlobsWithIdentifiers:in:then:", ^{
        it(@"should create passed table if table did not exist before", ^{
            _RAnalyticsDatabase* database = mkDatabase(connection);
            
            __block BOOL someTableExists;
            [database deleteBlobsWithIdentifiers:@[] in:@"some_table" then:^{
                someTableExists = isTableExist(@"some_table", connection);
            }];
            
            [[expectFutureValue(theValue(someTableExists)) shouldEventually] equal:theValue(YES)];
        });
        
        it(@"should delete items for passed IDs", ^{
            _RAnalyticsDatabase* database = mkDatabase(connection);
            NSArray* blobs = @[
                [@"foo" dataUsingEncoding:NSUTF8StringEncoding],
                [@"bar" dataUsingEncoding:NSUTF8StringEncoding]
            ];
            insertBlobsIntoTable(blobs, @"some_table", connection);
            
            __block NSArray* itemsInDb;
            [database deleteBlobsWithIdentifiers:@[@1, @2] in:@"some_table" then:^{
                itemsInDb = fetchTableContents(@"some_table", connection);
            }];
            
            [[expectFutureValue(itemsInDb) shouldEventually] equal:@[]];
        });
        
        it(@"should delete items for ids as it were passed to the function", ^{
            _RAnalyticsDatabase* database = mkDatabase(connection);
            NSArray* blobs = @[
                [@"foo" dataUsingEncoding:NSUTF8StringEncoding],
                [@"bar" dataUsingEncoding:NSUTF8StringEncoding]
            ];
            NSMutableArray* ids = [NSMutableArray arrayWithObject:@1];
            insertBlobsIntoTable(blobs, @"some_table", connection);
            
            __block NSArray* itemsInDb;
            [database deleteBlobsWithIdentifiers:ids in:@"some_table" then:^{
                itemsInDb = fetchTableContents(@"some_table", connection);
            }];
            [ids addObject:@2];
            
            [[expectFutureValue(itemsInDb) shouldEventually] equal:@[[@"bar" dataUsingEncoding:NSUTF8StringEncoding]]];
        });
        
        it(@"should delete items from table name as it was passed to function", ^{
            _RAnalyticsDatabase* database = mkDatabase(connection);
            NSMutableString* tableName = [NSMutableString stringWithString:@"some_table"];
            NSArray* blobs = @[[@"foo" dataUsingEncoding:NSUTF8StringEncoding]];
            insertBlobsIntoTable(blobs, @"some_table", connection);
            
            __block NSArray* itemsInDb;
            [database deleteBlobsWithIdentifiers:@[@1] in:tableName then:^{
                itemsInDb = fetchTableContents(@"some_table", connection);
            }];
            [tableName appendString:@"_foobar"];
            
            [[expectFutureValue(itemsInDb) shouldEventually] equal:@[]];
        });
        
        it(@"should not delete items which IDs were not passed for deletion", ^{
            _RAnalyticsDatabase* database = mkDatabase(connection);
            NSArray* blobs = @[
                [@"foo" dataUsingEncoding:NSUTF8StringEncoding],
                [@"bar" dataUsingEncoding:NSUTF8StringEncoding]
            ];
            insertBlobsIntoTable(blobs, @"some_table", connection);
            
            __block NSArray* itemsInDb;
            [database deleteBlobsWithIdentifiers:@[@1] in:@"some_table" then:^{
                itemsInDb = fetchTableContents(@"some_table", connection);
            }];
            
            [[expectFutureValue(itemsInDb) shouldEventually] equal:@[[@"bar" dataUsingEncoding:NSUTF8StringEncoding]]];
        });
        
        describe(@"erroring connection", ^{
            it(@"should not create passed table if some error occured",  ^{
                _RAnalyticsDatabase* db = mkDatabase(readonlyConnection);
                
                __block BOOL someTableExists = YES;
                [db deleteBlobsWithIdentifiers:@[] in:@"some_table" then:^{
                    someTableExists = isTableExist(@"some_table", connection);
                }];
                
                [[expectFutureValue(theValue(someTableExists)) shouldEventually] equal:theValue(NO)];
            });
            
            it(@"should not delete blobs from DB if some error occured",  ^{
                _RAnalyticsDatabase* db = mkDatabase(readonlyConnection);
                NSArray* blobs = @[[@"foo" dataUsingEncoding:NSUTF8StringEncoding]];
                insertBlobsIntoTable(blobs, @"some_table", connection);
                
                __block NSArray* tableContents;
                [db deleteBlobsWithIdentifiers:@[@1] in:@"some_table" then:^{
                    tableContents = fetchTableContents(@"some_table", connection);
                }];
                
                [[expectFutureValue(tableContents) shouldEventually] equal:@[[@"foo" dataUsingEncoding:NSUTF8StringEncoding]]];
            });
        });
    });
});

SPEC_END
