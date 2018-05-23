#import <Kiwi/Kiwi.h>
#import <sqlite3.h>

#import "../../RAnalytics/Core/Private/_RAnalyticsDatabase.h"

#import "DatabaseTestUtils.h"

NSData* mkEvent(void);
NSData* mkAnotherEvent(void);

SPEC_BEGIN(RAnalyticsDatabaseFunctionalTests)

describe(@"RAnalyticsDatabase", ^{
    __block NSString* databasePath;
    __block sqlite3* connection;
    
    beforeAll(^{
        NSString *documentsDirectoryPath = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0];
        databasePath = [documentsDirectoryPath stringByAppendingPathComponent:@"RSDKAnalytics.db"];

        [[NSFileManager defaultManager] removeItemAtPath:databasePath error:nil];
    });
    
    beforeEach(^{
        connection = mkAnalyticsDBConnection();
    });
    
    afterEach(^{
        sqlite3_close(connection);

        [[NSFileManager defaultManager] removeItemAtPath:databasePath error:nil];
    });
    
    it(@"should create database", ^{
        [_RAnalyticsDatabase databaseWithConnection:connection];
        
        [[theValue([[NSFileManager defaultManager] fileExistsAtPath:databasePath]) should] beTrue];
    });
    
    it(@"should insert events to database", ^{
        _RAnalyticsDatabase* database = [_RAnalyticsDatabase databaseWithConnection:connection];
        NSArray* events = @[mkEvent(), mkAnotherEvent()];
        
        __block NSArray* eventsInDb;
        [database insertBlobs:events into:@"events_table" limit:2 then:^{
            eventsInDb = fetchTableContents(@"events_table", connection);
        }];
        
        [[expectFutureValue(eventsInDb) shouldEventually] equal:events];
    });
    
    it(@"should fetch saved events from database", ^{
        _RAnalyticsDatabase* database = [_RAnalyticsDatabase databaseWithConnection:connection];
        NSArray* events = @[mkEvent(), mkAnotherEvent()];
        insertBlobsIntoTable(events, @"events_table", connection);
        
        __block NSArray* fetchedEvents;
        __block NSArray* fetchedIds;
        [database fetchBlobs:2 from:@"events_table" then:^(NSArray<NSData *> * _Nullable blobs, NSArray<NSNumber *> * _Nullable identifiers) {
            fetchedEvents = blobs;
            fetchedIds = identifiers;
        }];
        
        [[expectFutureValue(fetchedEvents) shouldEventually] equal:@[mkEvent(), mkAnotherEvent()]];
        [[expectFutureValue(fetchedIds) shouldEventually] equal:@[@1, @2]];
    });
    
    it(@"should delete saved events according to passed IDs", ^{
        _RAnalyticsDatabase* database = [_RAnalyticsDatabase databaseWithConnection:connection];
        NSArray* events = @[mkEvent(), mkAnotherEvent()];
        insertBlobsIntoTable(events, @"events_table", connection);
        
        __block NSArray* eventsInDb;
        [database deleteBlobsWithIdentifiers:@[@1, @2] in:@"events_table" then:^{
            eventsInDb = fetchTableContents(@"events_table", connection);
        }];
        
        [[expectFutureValue(eventsInDb) shouldEventually] equal:@[]];
    });
});

SPEC_END

NSData* mkEvent(void) {
    return [@"{"
        "\"ckp\" : \"bd7ac43958a9e7fa0f097c0a0ba5c2979299e69e\","
        "\"ts1\" : 1526965941,"
        "\"ltm\" : \"2018-05-22 14:12:22\","
        "\"app_name\" : \"jp.co.rakuten.Host\","
        "\"ua\" : \"jp.co.rakuten.Host/1.0\","
        "\"etype\" : \"_rem_launch\","
        "\"aid\" : 1,"
        "\"mori\" : 1,"
        "\"mnetw\" : 1,"
        "\"dln\" : \"en\","
        "\"tzo\" : 9,"
        "\"res\" : \"414x736\","
        "\"ver\" : \"3.0.0\","
        "\"cks\" : \"D4EE83DC-815B-41D3-88D8-BE94C4B7E0E1\","
        "\"acc\" : 477,"
        "\"cka\" : \"334A064E-3B19-45FB-BED2-A887E68FF7B3\","
        "\"app_ver\" : \"1.0\","
        "\"model\" : \"x86_64\","
        "\"mos\" : \"iOS 11.2\","
        "\"online\" : true,"
        "\"cp\" : {"
            "\"days_since_last_use\" : 0,"
            "\"days_since_first_use\" : 0"
        "}"
    "}" dataUsingEncoding:NSUTF8StringEncoding];
}

NSData* mkAnotherEvent(void) {
    return [@"{"
        "\"ckp\" : \"bd7ac43958a9e7fa0f097c0a0ba5c2979299e69e\","
        "\"ts1\" : 1526966160,"
        "\"ltm\" : \"2018-05-22 14:12:22\","
        "\"app_name\" : \"jp.co.rakuten.Host\","
        "\"ua\" : \"jp.co.rakuten.Host/1.0\","
        "\"etype\" : \"_rem_credential_strategies\","
        "\"aid\" : 1,"
        "\"mori\" : 1,"
        "\"mnetw\" : 1,"
        "\"dln\" : \"en\","
        "\"tzo\" : 9,"
        "\"res\" : \"414x736\","
        "\"ver\" : \"3.0.0\","
        "\"cks\" : \"D4EE83DC-815B-41D3-88D8-BE94C4B7E0E1\","
        "\"acc\" : 477,"
        "\"cka\" : \"334A064E-3B19-45FB-BED2-A887E68FF7B3\","
        "\"app_ver\" : \"1.0\","
        "\"model\" : \"x86_64\","
        "\"mos\" : \"iOS 11.2\","
        "\"online\" : true,"
        "\"cp\" : {"
            "\"strategies\" : {"
                "\"password-manager\" : \"false\""
            "}"
        "}"
    "}" dataUsingEncoding:NSUTF8StringEncoding];
}
