/*
 * © Rakuten, Inc.
 * authors: "Rakuten Ecosystem Mobile" <ecosystem-mobile@mail.rakuten.com>
 */
#import <RSDKAnalytics/RSDKAnalyticsDefines.h>

NS_ASSUME_NONNULL_BEGIN

/*
 * Internal interface used to centralize access to the analytics database.
 *
 * All the methods below are executed on a background FIFO, so there is no
 * need to otherwise synchronize calls to them. Completion blocks are then
 * executed on the caller's operation queue.
 *
 */
RSDKA_EXPORT @interface _RSDKAnalyticsDatabase : NSObject

/*
 * Insert a new, single blob into a table.
 *
 * @param blob                  Blob to insert.
 * @param table                 Name of the destination table.
 * @param maximumNumberOfBlobs  Maximum number of blobs to keep in the table.
 * @param completion            Block to call upon completion.
 */
+ (void)insertBlob:(NSData *)blob
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
+ (void)insertBlobs:(NSArray RSDKA_GENERIC(NSData *) *)blobs
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
+ (void)fetchBlobs:(unsigned int)maximumNumberOfBlobs
              from:(NSString *)table
              then:(void (^)(NSArray RSDKA_GENERIC(NSData *) *__nullable blobs, NSArray RSDKA_GENERIC(NSNumber *) *__nullable identifiers))completion;

//REM-21402 - [Special Analytics build for Ichiba] Send events immediately
/*
 * Try to fetch a number of blobs from a table, from the most ancient to the most recent.
 *
 * @param maximumNumberOfBlobs  Maximum number of blobs we want to read.
 * @param table                 Name of the table.
 * @param sendingIdentifiers    A set of identifiers which are being sent.
 * @param completion            Block to call upon completion.
 */
+ (void)fetchBlobs:(unsigned int)maximumNumberOfBlobs
              from:(NSString *)table sendingIdentifiers:(NSArray RSDKA_GENERIC(NSNumber *) *)sendingIdentifiers
              then:(void (^)(NSArray RSDKA_GENERIC(NSData *) *__nullable blobs, NSArray RSDKA_GENERIC(NSNumber *) *__nullable identifiers))completion;

/*
 * Delete blobs with the given identifier from a table.
 *
 * @param identifiers  Blob identifiers.
 * @param table        Name of the table.
 * @param completion   Block to call upon completion.
 */
+ (void)deleteBlobsWithIdentifiers:(NSArray RSDKA_GENERIC(NSNumber *) *)identifiers
                                in:(NSString *)table
                              then:(dispatch_block_t)completion;
@end

NS_ASSUME_NONNULL_END
