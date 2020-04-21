#import <sqlite3.h>
#import <RAnalytics/RAnalyticsDefines.h>

NS_ASSUME_NONNULL_BEGIN

/*
 * Internal interface used to centralize access to the analytics database.
 *
 * All the methods below are executed on a background FIFO, so there is no
 * need to otherwise synchronize calls to them. Completion blocks are then
 * executed on the caller's operation queue.
 *
 */
RSDKA_EXPORT @interface _RAnalyticsDatabase : NSObject

/*
 * Creates DB manager instance with SQLite connection
 *
 * @param connection SQLite DB connection
 */
+(_RAnalyticsDatabase*)databaseWithConnection:(sqlite3*)connection;

/*
 * Insert a new, single blob into a table.
 *
 * @param blob                  Blob to insert.
 * @param table                 Name of the destination table.
 * @param maximumNumberOfBlobs  Maximum number of blobs to keep in the table.
 * @param completion            Block to call upon completion.
 */
- (void)insertBlob:(NSData *)blob
              into:(NSString *)table
             limit:(unsigned int)maximumNumberOfBlobs
              then:(dispatch_block_t)completion;

/*
 * Insert multiple new blobs into a table, in a single transaction.
 *
 * @param blobs                 Blobs to insert.
 * @param table                 Name of the destination table.
 * @param maximumNumberOfBlobs  Maximum number of blobs to keep in the table.
 * @param completion            Block to call upon completion.
 */
- (void)insertBlobs:(NSArray<NSData *> *)blobs
               into:(NSString *)table
              limit:(unsigned int)maximumNumberOfBlobs
               then:(dispatch_block_t)completion;

/*
 * Try to fetch a number of blobs from a table, from the most ancient to the most recent.
 *
 * @param maximumNumberOfBlobs  Maximum number of blobs we want to read.
 * @param table                 Name of the table.
 * @param completion            Block to call upon completion.
 */
- (void)fetchBlobs:(unsigned int)maximumNumberOfBlobs
              from:(NSString *)table
              then:(void (^)(NSArray<NSData *> *__nullable blobs, NSArray<NSNumber *> *__nullable identifiers))completion;

/*
 * Delete blobs with the given identifier from a table.
 *
 * @param identifiers  Blob identifiers.
 * @param table        Name of the table.
 * @param completion   Block to call upon completion.
 */
- (void)deleteBlobsWithIdentifiers:(NSArray<NSNumber *> *)identifiers
                                in:(NSString *)table
                              then:(dispatch_block_t)completion;

@end

/*
 * Creates connection to the actual DB used by SDK.
 * DB created in user documents folder.
 *
 * @param databaseName  Name of database to create
 *
 * @return sqlite connection
 */
sqlite3* mkAnalyticsDBConnectionWithName(NSString *databaseName);

NS_ASSUME_NONNULL_END
