//
//  RSDKAnalyticsDatabase.h
//  RSDKAnalytics
//
//  Created by Julien Cayzac on 5/16/14.
//  Copyright (c) 2014 Rakuten, Inc. All rights reserved.
//

@import Foundation;

/*
 * Internal interface used to centralize access to the analytics database.
 *
 * All the methods below are executed on a background FIFO, so there is no
 * need to otherwise synchronize calls to them. Completion blocks are then
 * executed on the caller's operation queue.
 *
 * @internal
 * @since 2.0.0
 */
@interface RSDKAnalyticsDatabase : NSObject

/*
 * Add a record to the database.
 *
 * @param record      The data to write.
 * @param completion  The block to call once the record has been added.
 * @internal
 * @since 2.0.0
 */
+ (void)addRecord:(NSData *)record completion:(void (^)())completion;

/*
 * Fetch a group of records from the database.
 *
 * The completion block is passed an array of records (NSData) as well as an
 * array of unique record identifiers (each record's primary key in the
 * database). Both arrays have equal lengths, which may be 0 if the database
 * was empty.
 *
 * @param completion  The block to call once the records have been fetched.
 * @internal
 * @since 2.0.0
 */
+ (void)fetchRecordGroup:(void (^)(NSArray *records, NSArray *identifiers))completion;

/*
 * Delete some records from the database.
 *
 * @param identifiers  The identifiers of the records to be deleted.
 * @param completion   The block to call once the records have been deleted.
 * @internal
 * @since 2.0.0
 */
+ (void)deleteRecordsWithIdentifiers:(NSArray*)identifiers completion:(void (^)())completion;

@end

