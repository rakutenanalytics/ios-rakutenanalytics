/*
 * © Rakuten, Inc.
 * authors: "Rakuten Ecosystem Mobile" <ecosystem-mobile@mail.rakuten.com>
 */
#import "_RSDKAnalyticsDatabase.h"
#import <RSDKAnalytics/RSDKAnalytics.h>
#import <sqlite3.h>
#import "_RSDKAnalyticsHelpers.h"


////////////////////////////////////////////////////////////////////////////

static NSString *const RSDKAnalyticsDatabaseName = @"RSDKAnalytics.db";

/*
 * Our global background queue (singleton, created in [_RSDKAnalyticsDatabase load].
 */
static NSOperationQueue *_queue = nil;

/*
 * Prepare a table for access.
 *
 * @param table  The name of the table we want to access.
 * @return The SQLite handler.
 */
static sqlite3 *prepareTable(NSString *table)
{
    assert(NSOperationQueue.currentQueue == _queue);

    static sqlite3 *result = 0;
    if (!result)
    {
        NSString *documentsDirectoryPath = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0];
        NSString *databasePath = [documentsDirectoryPath stringByAppendingPathComponent:RSDKAnalyticsDatabaseName];

        if (sqlite3_open(databasePath.UTF8String, &result) == SQLITE_OK)
        {
            atexit_b(^{
                sqlite3_close(result);
            });
        }
        else
        {
            RSDKAnalyticsDebugLog(@"Failed to open database: %@", databasePath);
            sqlite3_close(result);
            result = 0;
            return 0;
        }
    }

    static NSMutableSet *tables = nil;
    if (![tables containsObject:table])
    {
        if (!tables)
        {
            tables = NSMutableSet.new;
        }

        NSString *query = [NSString stringWithFormat:@"create table if not exists %@ (id integer primary key, data blob)", table];
        if (sqlite3_exec(result, query.UTF8String, 0, 0, 0) != SQLITE_OK)
        {
            RSDKAnalyticsDebugLog(@"Failed to create table: %s", sqlite3_errmsg(result));
            return 0;
        }
        [tables addObject:table];
    }

    return result;
}


////////////////////////////////////////////////////////////////////////////

@implementation _RSDKAnalyticsDatabase
+ (void)load
{
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        _queue = NSOperationQueue.new;
        _queue.name = @"com.rakuten.esd.sdk.analytics.database";
        _queue.maxConcurrentOperationCount = 1;
        atexit_b(^{
            _queue = nil;
        });
    });
}

//--------------------------------------------------------------------------
+ (void)insertBlob:(NSData *)blob
              into:(NSString *)table
             limit:(unsigned int)maximumNumberOfBlobs
              then:(dispatch_block_t)completion
{
    [self insertBlobs:@[blob.copy] into:table limit:maximumNumberOfBlobs then:completion];
}

//--------------------------------------------------------------------------

+ (void)insertBlobs:(NSArray RSDKA_GENERIC(NSData *) *)blobs
               into:(NSString *)table
              limit:(unsigned int)maximumNumberOfBlobs
               then:(dispatch_block_t)completion
{
    // Make params immutable, otherwise they could be modified before getting accessed later on the queue
    blobs = [NSArray.alloc initWithArray:blobs copyItems:YES];
    table = table.copy;

    NSOperationQueue * __weak callerQueue = NSOperationQueue.currentQueue;
    [_queue addOperationWithBlock:^{
        sqlite3 *db = prepareTable(table);
        if (db && sqlite3_exec(db, "begin exclusive transaction", 0, 0, 0) == SQLITE_OK)
        {
            NSString *query = [NSString stringWithFormat:@"insert into %@ (data) values(?)", table];
            for (NSData *blob in blobs)
            {
                sqlite3_stmt *statement;
                if (sqlite3_prepare_v2(db, query.UTF8String, -1, &statement, 0) == SQLITE_OK)
                {
                    if (sqlite3_bind_blob(statement, 1, blob.bytes, (int)blob.length, 0) == SQLITE_OK)
                    {
                        sqlite3_step(statement);
                        sqlite3_clear_bindings(statement);
                    }
                    sqlite3_reset(statement);
                    sqlite3_finalize(statement);
                }
            }

            if (maximumNumberOfBlobs)
            {
                query = [NSString stringWithFormat:@"delete from %1$@ where id not in (select id from %1$@ order by id desc limit %2$u)", table, maximumNumberOfBlobs];
                sqlite3_exec(db, query.UTF8String, 0, 0, 0);
            }

            sqlite3_exec(db, "commit transaction", 0, 0, 0);
        }

        if (completion) {
            typeof(callerQueue) __strong queue = callerQueue;
            [queue addOperationWithBlock:completion];
        }
    }];
}

//--------------------------------------------------------------------------

+ (void)fetchBlobs:(unsigned int)maximumNumberOfBlobs
              from:(NSString *)table
              then:(void (^)(NSArray RSDKA_GENERIC(NSData *) *__nullable blobs, NSArray RSDKA_GENERIC(NSNumber *) *__nullable identifiers))completion
{
    // Make params immutable, otherwise they could be modified before getting accessed later on the queue
    table = table.copy;

    NSOperationQueue * __weak callerQueue = NSOperationQueue.currentQueue;
    [_queue addOperationWithBlock:^{
        sqlite3 *db = prepareTable(table);

        NSMutableArray *blobs       = nil;
        NSMutableArray *identifiers = nil;

        if (db && maximumNumberOfBlobs > 0)
        {
            blobs       = [NSMutableArray arrayWithCapacity:maximumNumberOfBlobs];
            identifiers = [NSMutableArray arrayWithCapacity:maximumNumberOfBlobs];

            NSString *query = [NSString stringWithFormat:@"select * from %@ limit %u", table, maximumNumberOfBlobs];

            sqlite3_stmt *statement;
            if (sqlite3_prepare_v2(db, query.UTF8String, -1, &statement, 0) == SQLITE_OK)
            {
                int code;
                while ((code = sqlite3_step(statement)) == SQLITE_ROW)
                {
                    int64_t primaryKey = sqlite3_column_int64(statement, 0);
                    const void *bytes = sqlite3_column_blob(statement, 1);
                    NSUInteger length = (NSUInteger)sqlite3_column_bytes(statement, 1);

                    [blobs       addObject:[NSData dataWithBytes:bytes length:length]];
                    [identifiers addObject:@(primaryKey)];
                }
                sqlite3_finalize(statement);
            }
        }

        if (completion)
        {
            typeof(callerQueue) __strong queue = callerQueue;
            [queue addOperationWithBlock:^
            {
                completion(blobs.count ? blobs : nil, identifiers.count ? identifiers : nil);
            }];
        }
    }];
}

//--------------------------------------------------------------------------

+ (void)deleteBlobsWithIdentifiers:(NSArray RSDKA_GENERIC(NSNumber *) *)identifiers
                                in:(NSString *)table
                              then:(dispatch_block_t)completion
{
    // Make params immutable, otherwise they could be modified before getting accessed later on the queue
    identifiers = [NSArray.alloc initWithArray:identifiers copyItems:YES];
    table = table.copy;

    NSOperationQueue * __weak callerQueue = NSOperationQueue.currentQueue;
    [_queue addOperationWithBlock:^{
        sqlite3 *db = prepareTable(table);

        if (db && sqlite3_exec(db, "begin exclusive transaction", 0, 0, 0) == SQLITE_OK)
        {
            NSString *query = [NSString stringWithFormat:@"delete from %@ where id=?", table];
            for (NSNumber *identifier in identifiers)
            {
                sqlite3_stmt *statement;
                if (sqlite3_prepare_v2(db, query.UTF8String, -1, &statement, 0) == SQLITE_OK)
                {
                    sqlite3_bind_int64(statement, 1, identifier.longLongValue);
                    sqlite3_step(statement);
                    sqlite3_clear_bindings(statement);
                    sqlite3_reset(statement);
                    sqlite3_finalize(statement);
                }
            }

            sqlite3_exec(db, "commit transaction", 0, 0, 0);
        }

        if (completion)
        {
            typeof(callerQueue) __strong queue = callerQueue;
            [queue addOperationWithBlock:completion];
        }
    }];
}

//--------------------------------------------------------------------------

@end

