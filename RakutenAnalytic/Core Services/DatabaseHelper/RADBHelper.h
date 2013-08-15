/*
 Copyright: Copyright (C) 2012 Rakuten, Inc.  All Rights Reserved.
 
 
 File Name:  RADBHelper.h
 
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

#import <Foundation/Foundation.h>
#import "sqlite3.h"
#import "RCommonUtilities/RStringUtility.h"
#import "RCommonUtilities/RDeviceInformation.h"
#import "RATrackingLib.h"
#import "RCommonUtilities/RGeoLocationManager.h"

@interface RADBHelper : NSObject
{
    @private
    NSArray                     *dirPaths;
    sqlite3                     *rakutenDB;
    NSString                    *databasePath;
    RStringUtility              *stringUtility;
}
+ (RADBHelper *)sharedInstance;

// Inserts record in table containing the automated parameters and custom parametrs.
- (void)insertRecordWithValues:(__unsafe_unretained NSString *)ts
                 andJSONString:(__unsafe_unretained NSString *)jsonString;

//Check if timestamp is nilt or not, if nil directly flush all records from table and
//if timestamp is not nil flust specific record which matches the timestamp value 
-(void)deleteRecordWithTimeStamp:(__unsafe_unretained NSString *)timestamp;

//Fetch records in a format specified and pass it for compression
-(NSString *)fetchRecordsFromTable;
@end
