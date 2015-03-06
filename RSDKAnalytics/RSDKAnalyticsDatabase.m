/*
 * © Rakuten, Inc.
 * authors: "SDK Team | SDTD" <prj-rmsdk@mail.rakuten.com>
 */

#import "RSDKAnalyticsDatabase.h"
#import <RSDKAnalytics/RSDKAnalytics.h>
#import <sqlite3.h>

#if DEBUG
#define debugMessage NSLog
#else
#define debugMessage
#endif

////////////////////////////////////////////////////////////////////////////


/*
 * The maximum number of records in a record group sent to the server.
 */

static const NSUInteger RSDKAnalyticsRecordGroupSize = 16;


/*
 * The maximum number of records kept in the database.
 *
 * The specification says 256, but this is because of browsers
 * restrictions that do not apply to native applications. Since
 * our implementation always buffer records before uploading them,
 * it's better to increase that limit to a more reasonnable amount
 * that minimizes the chances of losing data if the application
 * calls [RSDKAnalyticsManager spoolRecord:] very frequently.
 */

static const NSUInteger RSDKAnalyticsHistorySize = 5000;


/*
 * The SQLite database name.
 */

static NSString *const RSDKAnalyticsDatabaseName = @"RSDKAnalytics.db";


/*
 * The SQLite table name.
 */

static NSString *const RSDKAnalyticsTableName = @"RAKUTEN_ANALYTICS_TABLE";



////////////////////////////////////////////////////////////////////////////

@interface RSDKAnalyticsDatabase ()
+ (NSOperationQueue *)queue;
+ (sqlite3*)database;
@end

@implementation RSDKAnalyticsDatabase

//--------------------------------------------------------------------------

+ (void)addRecord:(NSData *)record completion:(void (^)())completion
{
    NSOperationQueue * __weak callerQueue = NSOperationQueue.currentQueue;
    [self.queue addOperationWithBlock:^
    {
        sqlite3 *database = self.database;
        if (record.length && database)
        {
            static NSString *insertQuery;
            static NSString *purgeQuery;
            static dispatch_once_t once;
            dispatch_once(&once, ^
            {
                insertQuery = [NSString stringWithFormat:@"insert into %@ (data) values(?)",
                               RSDKAnalyticsTableName];

                purgeQuery = [NSString stringWithFormat:@"delete from %1$@ where id not in (select id from %1$@ order by id desc limit %2$u)",
                              RSDKAnalyticsTableName,
                              MAX(0u, (unsigned int) RSDKAnalyticsHistorySize - 1)];
            });

            sqlite3_stmt *statement;
            if (sqlite3_prepare_v2(database, insertQuery.UTF8String, -1, &statement, 0) == SQLITE_OK)
            {
                /*
                 * Try to delete old records.
                 *
                 * <New size> + 1 (this record) should be less than or equal to RSDKAnalyticsHistorySize.
                 */

                sqlite3_exec(database, purgeQuery.UTF8String, 0, 0, 0);

                if (sqlite3_bind_blob(statement, 1, record.bytes, (int)record.length, 0) == SQLITE_OK)
                {
                    /*
                     * FIXME: What can we do if this fails? It is a *very* unlikely scenario.
                     * Should we delete the database and start afresh?
                     */

                    sqlite3_step(statement);
                }
                sqlite3_finalize(statement);
            }
        }

        if (completion)
        {
            typeof(callerQueue) __strong queue = callerQueue;
            [queue addOperationWithBlock:completion];
        }
    }];
}

//--------------------------------------------------------------------------

+ (void)fetchRecordGroup:(void (^)(NSArray *records, NSArray *identifiers))completion
{
    NSOperationQueue * __weak callerQueue = NSOperationQueue.currentQueue;
    [self.queue addOperationWithBlock:^
    {
        NSMutableArray *records = [NSMutableArray arrayWithCapacity:RSDKAnalyticsRecordGroupSize];
        NSMutableArray *primaryKeys = [NSMutableArray arrayWithCapacity:RSDKAnalyticsRecordGroupSize];

        sqlite3 *database = self.database;
        if (database)
        {
            static NSString *query;
            static dispatch_once_t once;
            dispatch_once(&once, ^
            {
                query = [NSString stringWithFormat:@"select * from %@ limit %u",
                         RSDKAnalyticsTableName,
                         MAX(0u, (unsigned int) RSDKAnalyticsRecordGroupSize)];
            });

            sqlite3_stmt *statement;
            if (sqlite3_prepare_v2(database, query.UTF8String, -1, &statement, 0) == SQLITE_OK)
            {
                int code;
                while ((code = sqlite3_step(statement)) == SQLITE_ROW)
                {
                    int64_t primaryKey = sqlite3_column_int64(statement, 0);
                    const void *bytes = sqlite3_column_blob(statement, 1);
                    NSUInteger length = (NSUInteger)sqlite3_column_bytes(statement, 1);

                    [records addObject:[NSData dataWithBytes:bytes length:length]];
                    [primaryKeys addObject:@(primaryKey)];
                }
                sqlite3_finalize(statement);
            }
        }

        if (completion)
        {
            typeof(callerQueue) __strong queue = callerQueue;
            [queue addOperationWithBlock:^
            {
                completion(records, primaryKeys);
            }];
        }
    }];
}

//--------------------------------------------------------------------------

+ (void)deleteRecordsWithIdentifiers:(NSArray*)identifiers completion:(void (^)())completion
{
    NSOperationQueue * __weak callerQueue = NSOperationQueue.currentQueue;
    [self.queue addOperationWithBlock:^
    {
        sqlite3 *database = self.database;
        if (identifiers.count && database)
        {
            if (sqlite3_exec(database, "begin exclusive transaction", 0, 0, 0) != SQLITE_OK)
            {
                debugMessage(@"Failed to begin transaction: %s", sqlite3_errmsg(database));
            }
            else
            {
                static NSString *query;
                static dispatch_once_t once;
                dispatch_once(&once, ^
                {
                    query = [NSString stringWithFormat:@"delete from %@ where id=?", RSDKAnalyticsTableName];
                });

                sqlite3_stmt *statement;
                if (sqlite3_prepare_v2(database, query.UTF8String, -1, &statement, 0) == SQLITE_OK)
                {
                    for (NSNumber *identifier in identifiers)
                    {
                        sqlite3_bind_int64(statement, 1, identifier.longLongValue);

                        sqlite3_step(statement);
                        if (sqlite3_reset(statement) != SQLITE_OK)
                        {
                            break;
                        }
                    }
                    sqlite3_finalize(statement);
                }

                if(sqlite3_exec(database, "commit transaction", 0, 0, 0) != SQLITE_OK)
                {
                    /*
                     * FIXME: What can we do? It is a *very* unlikely scenario.
                     * Should we delete the database and start afresh?
                     */
                    debugMessage(@"Analytics: Failed to commit transaction: %s", sqlite3_errmsg(database));
                }
            }
        }

        if (completion)
        {
            typeof(callerQueue) __strong queue = callerQueue;
            [queue addOperationWithBlock:completion];
        }
    }];
}

//--------------------------------------------------------------------------

+ (NSOperationQueue *)queue
{
    static NSOperationQueue *queue;
    static dispatch_once_t once;
    dispatch_once(&once, ^
    {
        queue = NSOperationQueue.new;
        queue.name = @"jp.co.rakuten.ios.sdk.analytics.database";

        /*
         * Make the queue a FIFO so we don't need to worry about
         * concurrency issues.
         */

        queue.maxConcurrentOperationCount = 1;
    });
    return queue;
}

//--------------------------------------------------------------------------

+ (sqlite3*)database
{
    static sqlite3 *database = 0;
    static dispatch_once_t once;
    dispatch_once(&once, ^
    {
        NSString *documentsDirectoryPath = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0];
        NSString *databasePath = [documentsDirectoryPath stringByAppendingPathComponent:RSDKAnalyticsDatabaseName];


        /*
         * Open the database
         */

        if(sqlite3_open(databasePath.UTF8String, &database) != SQLITE_OK)
        {
            database = 0;
            [NSException raise:NSInternalInconsistencyException format:@"Failed to open database: %@", databasePath];
            return;
        }


        /*
         * Create our table if it does exist yet.
         */

        NSString *query = [NSString stringWithFormat:@"create table if not exists %@ (id integer primary key, data blob)", RSDKAnalyticsTableName];
        if (sqlite3_exec(database, query.UTF8String, 0, 0, 0) != SQLITE_OK)
        {
            sqlite3_close(database);
            database = 0;

            [NSException raise:NSInternalInconsistencyException format:@"Failed to create table: %s", sqlite3_errmsg(database)];
            return;
        }


        /*
         * Close database upon end of thread.
         */

        atexit_b(^
        {
            sqlite3_close(database);
            database = 0;
        });
    });

    return database;
}

@end

