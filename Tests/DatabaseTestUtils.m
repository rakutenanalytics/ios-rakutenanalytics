#import "DatabaseTestUtils.h"\

#import "../RAnalytics/Core/Private/_RAnalyticsDatabase.h"

sqlite3* openRegularConnection() {
    return openConnection(SQLITE_OPEN_READWRITE | SQLITE_OPEN_CREATE);
}

sqlite3* openReadonlyConnection() {
    return openConnection(SQLITE_OPEN_READONLY | SQLITE_OPEN_CREATE);
}

sqlite3* openConnection(int flags) {
    sqlite3* connection;
    
    sqlite3_open_v2("file::memory:?cache=shared", &connection, flags, NULL);
    
    return connection;
}

static _RAnalyticsDatabase* db; // Required because of ARC
_RAnalyticsDatabase* mkDatabase(sqlite3* connection) {
    db = [_RAnalyticsDatabase databaseWithConnection:connection];
    
    return db;
}

BOOL isTableExist(NSString* table, sqlite3* connection) {
    int tableCount = 0;
    NSString* query = [NSString stringWithFormat:@"SELECT count(*) FROM sqlite_master WHERE type='table' AND name='%@'", table];
    
    sqlite3_stmt* statement;
    sqlite3_prepare_v2(connection, query.UTF8String, -1, &statement, 0);
    sqlite3_step(statement);
    tableCount = sqlite3_column_int(statement, 0);
    sqlite3_reset(statement);
    sqlite3_finalize(statement);
    
    return tableCount > 0;
}

NSArray* fetchTableContents(NSString* table, sqlite3* connection) {
    NSMutableArray* result = [NSMutableArray array];
    
    NSString *query = [NSString stringWithFormat:@"select * from %@", table];
    
    sqlite3_stmt *statement;
    if (sqlite3_prepare_v2(connection, query.UTF8String, -1, &statement, 0) == SQLITE_OK) {
        int code;
        while ((code = sqlite3_step(statement)) == SQLITE_ROW) {
            const void *bytes = sqlite3_column_blob(statement, 1);
            NSUInteger length = (NSUInteger)sqlite3_column_bytes(statement, 1);
            
            [result addObject:[NSData dataWithBytes:bytes length:length]];
        }
        sqlite3_finalize(statement);
    }
    
    return result;
}

void insertBlobsIntoTable(NSArray* blobs, NSString* table, sqlite3* connection) {
    NSString *createTableQuery = [NSString stringWithFormat:@"create table if not exists %@ (id integer primary key, data blob)", table];
    sqlite3_exec(connection, createTableQuery.UTF8String, 0, 0, 0);
    
    
    NSString *insertQuery = [NSString stringWithFormat:@"insert into %@ (data) values(?)", table];
    for (NSData *blob in blobs) {
        sqlite3_stmt *statement;
        
        sqlite3_prepare_v2(connection, insertQuery.UTF8String, -1, &statement, 0);
        sqlite3_bind_blob(statement, 1, blob.bytes, (int)blob.length, 0);
        sqlite3_step(statement);
        sqlite3_clear_bindings(statement);
        sqlite3_reset(statement);
        sqlite3_finalize(statement);
    }
    
    sqlite3_exec(connection, "commit transaction", 0, 0, 0);
}

