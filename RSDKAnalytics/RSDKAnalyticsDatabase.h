#ifndef DOXYGEN
/*
 * © Rakuten, Inc.
 *
 * @authors "Rakuten Mobile SDK Team | SDTD" <prj-rmsdk@mail.rakuten.com>
 */
#import <RSDKAnalytics/RSDKAnalyticsDefines.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * Internal interface used to centralize access to the analytics database.
 *
 * All the methods below are executed on a background FIFO, so there is no
 * need to otherwise synchronize calls to them. Completion blocks are then
 * executed on the caller's operation queue.
 *
 * @class RSDKAnalyticsDatabase RSDKAnalyticsDatabase.h RSDKAnalytics/RSDKAnalyticsDatabase.h
 */
RSDKA_EXPORT @interface RSDKAnalyticsDatabase : NSObject

/**
 * Add a record to the database.
 *
 * @param record      The data to write.
 * @param completion  The block to call once the record has been added.
 */
+ (void)addRecord:(NSData *)record completion:(void (^)())completion;

/**
 * Fetch a group of records from the database.
 *
 * The completion block is passed an array of records (NSData) as well as an
 * array of unique record identifiers (each record's primary key in the
 * database). Both arrays have equal lengths, which may be 0 if the database
 * was empty.
 *
 * @param completion  The block to call once the records have been fetched.
 */
+ (void)fetchRecordGroup:(void (^)(NSArray *records, NSArray *identifiers))completion;

/**
 * Delete some records from the database.
 *
 * @param identifiers  The identifiers of the records to be deleted.
 * @param completion   The block to call once the records have been deleted.
 */
+ (void)deleteRecordsWithIdentifiers:(NSArray*)identifiers completion:(void (^)())completion;

@end

NS_ASSUME_NONNULL_END

#endif

