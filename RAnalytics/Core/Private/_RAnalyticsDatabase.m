#import "_RAnalyticsDatabase.h"
#import "_RAnalyticsHelpers.h"
#import <RLogger/RLogger.h>

NSString* const RAnalyticsDBErrorDomain = @"RAnalyticsDBErrorDomain";
NSInteger RAnalyticsDBTableCreationFailureErrorCode = 1;
NSInteger RAnalyticsDBAppWillTerminateErrorCode = 2;

@interface _RAnalyticsDatabase(Private)

-(NSError*)prepareTable:(NSString*)table;

@end

@implementation _RAnalyticsDatabase {
    sqlite3* _connection;
    NSMutableSet* _tables;
    
    NSOperationQueue* _queue;
    BOOL _appWillTerminate;
}

+(_RAnalyticsDatabase*)databaseWithConnection:(sqlite3*)connection {
    return [[[self class] alloc] initWithConnection:connection];
}

-(instancetype)initWithConnection:(sqlite3*)connection {
    if (self = [super init]) {
        _connection = connection;
        
        _queue = [NSOperationQueue new];
        _queue.name = @"com.rakuten.esd.sdk.analytics.database";
        _queue.maxConcurrentOperationCount = 1;

        _tables = [NSMutableSet set];
        
        _appWillTerminate = NO;

        [NSNotificationCenter.defaultCenter addObserver:self
                                               selector:@selector(willTerminate)
                                                   name:UIApplicationWillTerminateNotification
                                                 object:nil];
    }
    return self;
}

-(void)insertBlob:(NSData *)blob
             into:(NSString *)table
            limit:(unsigned int)maximumNumberOfBlobs
             then:(dispatch_block_t)completion
{
    [self insertBlobs:@[blob.copy] into:table limit:maximumNumberOfBlobs then:completion];
}

-(void)insertBlobs:(NSArray<NSData *> *)blobs
              into:(NSString *)table
             limit:(unsigned int)maximumNumberOfBlobs
              then:(dispatch_block_t)completion
{
    // Make params immutable, otherwise they could be modified before getting accessed later on the queue
    blobs = [NSArray.alloc initWithArray:blobs copyItems:YES];
    table = table.copy;
    
    NSOperationQueue * __weak callerQueue = NSOperationQueue.currentQueue;
    _RAnalyticsDatabase* __weak welf = self;
    
    [_queue addOperationWithBlock:^{
        _RAnalyticsDatabase* __strong sself = welf;
        if (!sself) {
            return;
        }
        
        NSError* error = [sself prepareTable:table];
        if (!error && sqlite3_exec(sself->_connection, "begin exclusive transaction", 0, 0, 0) == SQLITE_OK)
        {
            NSString *query = [NSString stringWithFormat:@"insert into %@ (data) values(?)", table];
            for (NSData *blob in blobs)
            {
                sqlite3_stmt *statement;
                if (sqlite3_prepare_v2(sself->_connection, query.UTF8String, -1, &statement, 0) == SQLITE_OK)
                {
                    if (sqlite3_bind_blob(statement, 1, blob.bytes, (int)blob.length, 0) == SQLITE_OK)
                    {
                        sqlite3_step(statement);
                        sqlite3_clear_bindings(statement);
                    }
                    sqlite3_reset(statement);
                    sqlite3_finalize(statement);
                }
                else
                {
                    [RLogger error:@"insertBlobs prepare failed with error %s code %d", sqlite3_errmsg(sself->_connection), sqlite3_errcode(sself->_connection)];
                }
            }
            
            if (maximumNumberOfBlobs)
            {
                query = [NSString stringWithFormat:@"delete from %1$@ where id not in (select id from %1$@ order by id desc limit %2$u)", table, maximumNumberOfBlobs];
                sqlite3_exec(sself->_connection, query.UTF8String, 0, 0, 0);
            }
            
            sqlite3_exec(sself->_connection, "commit transaction", 0, 0, 0);
        }
        
        if (completion) {
            typeof(callerQueue) __strong queue = callerQueue;
            [queue addOperationWithBlock:completion];
        }
    }];
}

-(void)fetchBlobs:(unsigned int)maximumNumberOfBlobs
             from:(NSString *)table
             then:(void (^)(NSArray<NSData *> *__nullable blobs, NSArray<NSNumber *> *__nullable identifiers))completion
{
    // Make params immutable, otherwise they could be modified before getting accessed later on the queue
    table = table.copy;
    
    NSOperationQueue * __weak callerQueue = NSOperationQueue.currentQueue;
    _RAnalyticsDatabase* __weak welf = self;
    
    [_queue addOperationWithBlock:^{
        _RAnalyticsDatabase* __strong sself = welf;
        if (!sself) {
            return;
        }
        
        NSMutableArray *blobs       = nil;
        NSMutableArray *identifiers = nil;
        
        NSError* error = [sself prepareTable:table];
        
        if (!error && maximumNumberOfBlobs > 0) {
            blobs       = [NSMutableArray arrayWithCapacity:maximumNumberOfBlobs];
            identifiers = [NSMutableArray arrayWithCapacity:maximumNumberOfBlobs];
            
            NSString *query = [NSString stringWithFormat:@"select * from %@ limit %u", table, maximumNumberOfBlobs];
            
            sqlite3_stmt *statement;
            if (sqlite3_prepare_v2(sself->_connection, query.UTF8String, -1, &statement, 0) == SQLITE_OK) {
                int code;
                while ((code = sqlite3_step(statement)) == SQLITE_ROW) {
                    int64_t primaryKey = sqlite3_column_int64(statement, 0);
                    const void *bytes = sqlite3_column_blob(statement, 1);
                    NSUInteger length = (NSUInteger)sqlite3_column_bytes(statement, 1);
                    
                    [blobs       addObject:[NSData dataWithBytes:bytes length:length]];
                    [identifiers addObject:@(primaryKey)];
                }
                sqlite3_finalize(statement);
            }
            else
            {
                [RLogger error:@"fetchBlobs prepare failed with error %s code %d", sqlite3_errmsg(sself->_connection), sqlite3_errcode(sself->_connection)];
            }
        }
        
        if (completion) {
            typeof(callerQueue) __strong queue = callerQueue;
            [queue addOperationWithBlock:^
             {
                 completion(blobs.count ? blobs : nil, identifiers.count ? identifiers : nil);
             }];
        }
    }];
}

-(void)deleteBlobsWithIdentifiers:(NSArray<NSNumber *> *)identifiers
                               in:(NSString *)table
                             then:(dispatch_block_t)completion
{
    if (_appWillTerminate)
    {
        return;
    }
    
    // Make params immutable, otherwise they could be modified before getting accessed later on the queue
    identifiers = [NSArray.alloc initWithArray:identifiers copyItems:YES];
    table = table.copy;
    
    NSOperationQueue * __weak callerQueue = NSOperationQueue.currentQueue;
    _RAnalyticsDatabase* __weak welf = self;
    [_queue addOperationWithBlock:^{
        _RAnalyticsDatabase* __strong sself = welf;
        if (!sself) {
            return;
        }
        
        NSError* error = [sself prepareTable:table];
        
        if (!error && sqlite3_exec(sself->_connection, "begin exclusive transaction", 0, 0, 0) == SQLITE_OK)
        {
            NSString *query = [NSString stringWithFormat:@"delete from %@ where id=?", table];
            for (NSNumber *identifier in identifiers)
            {
                sqlite3_stmt *statement;
                if (sqlite3_prepare_v2(sself->_connection, query.UTF8String, -1, &statement, 0) == SQLITE_OK)
                {
                    sqlite3_bind_int64(statement, 1, identifier.longLongValue);
                    sqlite3_step(statement);
                    sqlite3_clear_bindings(statement);
                    sqlite3_reset(statement);
                    sqlite3_finalize(statement);
                }
                else
                {
                    [RLogger error:@"deleteBlobs prepare failed with error %s code %d", sqlite3_errmsg(sself->_connection), sqlite3_errcode(sself->_connection)];
                }
            }
            
            sqlite3_exec(sself->_connection, "commit transaction", 0, 0, 0);
        }
        
        if (completion)
        {
            typeof(callerQueue) __strong queue = callerQueue;
            [queue addOperationWithBlock:completion];
        }
    }];
}

- (void)willTerminate
{
    _appWillTerminate = YES;
}

@end

@implementation _RAnalyticsDatabase(Private)

-(NSError*)prepareTable:(NSString*)table {
    if (_appWillTerminate)
    {
        return [NSError errorWithDomain:RAnalyticsDBErrorDomain
                                   code:RAnalyticsDBAppWillTerminateErrorCode
                               userInfo:@{NSLocalizedDescriptionKey: @"DB operation has been cancelled because the app will terminate"}];
    }
    
    assert(NSOperationQueue.currentQueue == _queue);
    
    if (![_tables containsObject:table]) {
        NSString *query = [NSString stringWithFormat:@"create table if not exists %@ (id integer primary key, data blob)", table];
        
        if (sqlite3_exec(_connection, query.UTF8String, 0, 0, 0) != SQLITE_OK) {
            NSString* message = [NSString stringWithFormat:@"Failed to create table: %s code %d", sqlite3_errmsg(_connection), sqlite3_errcode(_connection)];
            
            [RLogger error:message];
            
            return [NSError errorWithDomain:RAnalyticsDBErrorDomain
                                       code:RAnalyticsDBTableCreationFailureErrorCode
                                   userInfo:@{NSLocalizedDescriptionKey: message}];
        }
        [_tables addObject:table];
    }
    
    return nil;
}

@end

sqlite3* mkAnalyticsDBConnectionWithName(NSString *databaseName) {
    NSString *documentsDirectoryPath = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0];
    NSString *databasePath = [documentsDirectoryPath stringByAppendingPathComponent:databaseName];
    
    sqlite3* connection = 0;
    
    if (sqlite3_open(databasePath.UTF8String, &connection) == SQLITE_OK) {
        atexit_b(^{
            sqlite3_close(connection);
        });
    } else {
        [RLogger error:@"Failed to open database: %@", databasePath];
        sqlite3_close(connection);
        connection = 0;
    }
    
    return connection;
}
