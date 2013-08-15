/*
 Copyright: Copyright (C) 2012 Rakuten, Inc.  All Rights Reserved.
 
 
 File Name:  RADBHelper.m
 
 Description: This class is used to store the buffered data synchronously. All the CRUD operation on
 the RakutenAnalytics table is performed in this class.
 There will be a single table which will contain tracking information of the application when user is in offline 
 mode or buffered mode   
 
 Author: Mandar Kadam
 
 Created: 3rd-May-2012 
 
 Changed: 
 
 Version: 1.0
 
 *
 */

#import "RADBHelper.h"
#import "RACommons.h"
#import "RAJsonHelperUtil.h"

//All sql queries for data operation on table
NSString *const kInsertQuery = @"INSERT INTO RAKUTEN_ANALYTICS_TABLE (timeStamp, trackInfoData) VALUES (\"%@\", \"%@\")";

NSString *const kDeleteTableQuery = @"DELETE FROM RAKUTEN_ANALYTICS_TABLE";

NSString *const kDeleteTableWithTimeStampQuery = @"DELETE FROM RAKUTEN_ANALYTICS_TABLE WHERE timeStamp = %@";

@interface RADBHelper()

// Checks db present if not creates new DB with a table inside it.
-(void)checkAndLoadTable;

@end

@implementation RADBHelper
/*!
 @function		sharedInstance
 @discussion	This is singleton implementation of Database helper
 @param			none 
 @result		LocationController
 */
+ (RADBHelper *)sharedInstance {
    static dispatch_once_t pred;
    static RADBHelper *shared = nil;
    dispatch_once(&pred, ^{
        shared = [[RADBHelper alloc] init];
    });
    return shared;
}

- (id)init
{
    if( (self = [super init]) )
    {
        // Get the documents directory
        dirPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *docsDir = nil;
        docsDir = [dirPaths objectAtIndex:0];
        databasePath = [docsDir stringByAppendingPathComponent: @"Reports.db"];
        
        stringUtility = [[RStringUtility alloc] init];
    }
    return self;
}
/*!
 @function		checkAndLoadTable
 @discussion	Checks db present if not creates new DB with a table inside it. 
 @param			none 
 @result		nil
 */
- (void)checkAndLoadTable
{
    // Build the path to the database file
    NSFileManager *filemgr = [NSFileManager defaultManager];
    
    if ([filemgr fileExistsAtPath: databasePath ] == NO)
    {
		const char *dbpath = [databasePath UTF8String];
        
        if(sqlite3_open(dbpath, &rakutenDB) == SQLITE_OK)
        {
            char *errMsg = nil;
            const char *sql_stmt = "CREATE TABLE IF NOT EXISTS RAKUTEN_ANALYTICS_TABLE (trackInfoData BLOB, timeStamp VARCHAR)";
            
            if (sqlite3_exec(rakutenDB, sql_stmt, NULL, NULL, &errMsg) != SQLITE_OK)
            {
                RULog(@"Table Created");
            }
            sqlite3_close(rakutenDB);
        }
    }
}
/*!
 @function		insertRecordWithValues
 @discussion	Inserts record in table containing the automated parameters and custom parameters. 
 @param			ts: timstamp
 @param         jsonString: track information data of type NSString
 @result		nil
 */
- (void)insertRecordWithValues:(__unsafe_unretained NSString *)ts
                 andJSONString:(__unsafe_unretained NSString *)jsonString
{
    [self checkAndLoadTable];
    
    sqlite3_stmt    *statement;
    const char *dbpath = [databasePath UTF8String];
    
    NSData *customData = [jsonString dataUsingEncoding:NSUTF8StringEncoding];
    
    if (sqlite3_open(dbpath, &rakutenDB) == SQLITE_OK)
    {
        const char *insert_stmt = "insert into RAKUTEN_ANALYTICS_TABLE (timeStamp, trackInfoData) Values(?, ?)";
        sqlite3_prepare_v2(rakutenDB, insert_stmt, -1, &statement, NULL);
        
        if(customData != nil)
            sqlite3_bind_blob(statement, 2, [customData bytes], [customData length], NULL);
        else
            sqlite3_bind_blob(statement, 2, nil, -1, NULL);
        
        sqlite3_bind_text(statement, 1, [[stringUtility conversion:ts] UTF8String], -1, NULL);
        
        int code = sqlite3_step(statement);
               
        RULog(@"sqlite3_step(statement) %d code: %d", SQLITE_DONE, code);
        if (code == SQLITE_DONE)
        {
            RULog(@"Record inserted successfully");
        }
        else
        {
            RULog(@"Record inserted unsuccessfully");
        }
        sqlite3_finalize(statement);
        sqlite3_close(rakutenDB);
    }
}

/*!
 @function		deleteRecordWithTimeStamp
 @discussion    Check if timestamp is nilt or not, if nil directly flush all records from table and
 if timestamp is not nil flust specific record which matches the timestamp value 
 @param			timestamp of type string 
 @result		nil
 */
- (void)deleteRecordWithTimeStamp:(NSString *)timeStamp
{
    NSString *sqlStatement = nil;
    const char *dbpath = nil;
    if( timeStamp == nil )
    {
        sqlStatement = [NSString stringWithFormat:kDeleteTableQuery];
    }
    else
    {
        sqlStatement = [NSString stringWithFormat:kDeleteTableWithTimeStampQuery, [stringUtility conversion:timeStamp]];
    }
    dbpath = [databasePath UTF8String];
    rakutenDB = nil;
    
	// Open the database from the users filessytem
	if(sqlite3_open(dbpath, &rakutenDB) == SQLITE_OK) 
    {
        const char *sql = [sqlStatement cStringUsingEncoding:NSUTF8StringEncoding];
        sqlite3_stmt *statement = nil;
        
        if(sqlite3_prepare_v2(rakutenDB, sql, -1, &statement, nil) != SQLITE_OK) {
            return;
        }
        
        //Without this line, table is not modified
        int code = sqlite3_step(statement);
        
        if (code == SQLITE_DONE) {
            RULog(@"\nRecord successfully deleted");
            //Do nothing here...
        }
        sqlite3_finalize(statement);
        sqlite3_close(rakutenDB);
    }
    
}

/*!
 @function		fetchRecordsFromTable
 @discussion	Fetch records in a format specified and pass it for compression
 @param			none 
 @result		NSString : retuns string with base64 encoding
 */
- (NSString *)fetchRecordsFromTable
{
    sqlite3 *database = nil;
    
    int recordsCount = 0;
    NSString *parameterString = @"";
    
    // Open the database from the users filessytem
    if(sqlite3_open([databasePath UTF8String], &database) == SQLITE_OK)
    {
        // Setup the SQL Statement and compile it for faster access
        const char *sqlStatement = "select * from RAKUTEN_ANALYTICS_TABLE";
        sqlite3_stmt *compiledStatement;
        
        if(sqlite3_prepare_v2(database, sqlStatement, -1, &compiledStatement, NULL) == SQLITE_OK)
        {
            // Loop through the results and add them to the feeds array
            while(sqlite3_step(compiledStatement) == SQLITE_ROW)
            {
                // Read the data from the result row
                recordsCount = recordsCount + 1;
                
                #ifdef DEBUG
                    NSString *string = [NSString stringWithUTF8String:(char *)sqlite3_column_text(compiledStatement, 1)];
                    RULog(@"data is: %@", string);
                #else
                    [NSString stringWithUTF8String:(char *)sqlite3_column_text(compiledStatement, 1)];
                #endif
                
                int dataLength = sqlite3_column_bytes(compiledStatement, 0);
                RULog(@"data lenght: %d", dataLength);
                NSData *data = [[NSData alloc] initWithBytes:sqlite3_column_blob(compiledStatement, 0) length:dataLength];

                 NSString* jsonString = (NSString *)[NSString stringWithUTF8String:[data bytes]];
                RULog(@"Actual data string :%@", jsonString);
                
                parameterString = [parameterString stringByAppendingFormat:@",\"%@\":%@", [NSNumber numberWithInt:recordsCount], jsonString];
            }
        }
        // Release the compiled statement from memory
        sqlite3_finalize(compiledStatement);
    }
    sqlite3_close(database);
    
    if( recordsCount == 0 )
    {
        return nil;
    }
    
    NSString *compressedPackageString = @"";
    compressedPackageString = [compressedPackageString stringByAppendingFormat:@"{\"totalRecords\":\"%d\"%@}",recordsCount, parameterString];
    
    RULog(@"\n\nparameterString :::::::::::::::::: %@\n\n", compressedPackageString);
    // Steps invovled in compression package i.e Encoding
    /*
     1. Converting string to binary data with NSUTF8Encodiing
     2. Compress binary data using gzip
     3. Convert compressed binary data to CompressedBase64EncodedString
     */
    // 1. String converted to Binary(NSData) with UTF8encoded string
    //RULog(@"Compressed string:%@", compressedPackageString);
    NSData *compressedData=[compressedPackageString dataUsingEncoding:NSUTF8StringEncoding];
    
    // 2. Compress binary data using gzip
    compressedData = [compressedData gzipDeflate];
    
    // 3. Convert compressed binary data to CompressedBase64EncodedString
    NSString *base64String = [compressedData stringEncodedWithBase64];
    
    return base64String;
}

-(void)dealloc
{
    dirPaths = nil;
    databasePath = nil;
    stringUtility = nil;
}
@end
