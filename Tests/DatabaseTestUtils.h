#ifndef DATABASE_TEST_UTILS_H
#define DATABASE_TEST_UTILS_H

#import <Foundation/Foundation.h>
#import <sqlite3.h>

@class RAnalyticsDatabase;

sqlite3* openRegularConnection(void);
sqlite3* openReadonlyConnection(void);
sqlite3* openConnection(int flags);

RAnalyticsDatabase* mkDatabase(sqlite3* connection);

BOOL isTableExist(NSString* table, sqlite3* connection);
NSArray* fetchTableContents(NSString* table, sqlite3* connection);
void insertBlobsIntoTable(NSArray* blobs, NSString* table, sqlite3* connection);

#endif
