@import XCTest;
#import <RAnalytics/RAnalyticsSender.h>
#import <OHHTTPStubs/OHHTTPStubs.h>
#import <OCMock/OCMock.h>
#import <Kiwi/Kiwi.h>
#import "MockedDatabase.h"

#import "../../RAnalytics/Core/Private/_RAnalyticsDatabase.h"

@interface RAnalyticsSender()
@property (copy, nonatomic) NSString       *databaseTableName;
@property (nonatomic) _RAnalyticsDatabase  *database;
@property (nonatomic) NSTimeInterval        uploadTimerInterval;
@property (nonatomic) NSTimer              *uploadTimer;
@end

@interface SenderTests : XCTestCase
@property (nonatomic) RAnalyticsSender  *sender;
@property (nonatomic) MockedDatabase       *database;
@property (nonatomic) NSDictionary         *payload;
@property (nonatomic) NSMutableArray       *mocks;
@end

@implementation SenderTests

- (void)setUp {
    [super setUp];
    _mocks = NSMutableArray.new;
    _payload = @{@"key":@"value"};

    // Mock the database
    _database = MockedDatabase.new;
    
    id dbMock = OCMClassMock(_RAnalyticsDatabase.class);
    [self addMock:dbMock];
    
    OCMStub([dbMock databaseWithConnection:[OCMArg anyPointer]]).andReturn(_database);
    
    _sender = [[RAnalyticsSender alloc] initWithEndpoint:[NSURL URLWithString:@"https://endpoint.co.jp/"] databaseName:@"dbName.db" databaseTableName:@"testTableName"];
}

- (void)tearDown {
    [_mocks enumerateObjectsUsingBlock:^(id mock, __unused NSUInteger idx, __unused BOOL *stop) {
        [mock stopMocking];
    }];

    // Clear any still running timers because they can break our async batching delay tests

    [_sender.uploadTimer invalidate];
    _sender.uploadTimer = nil;

    _sender = nil;
    _database = nil;
    _payload = nil;
    _mocks = nil;
    [super tearDown];
}

#pragma mark Helpers

- (void)addMock:(id)mock
{
    [_mocks addObject:mock];
}

- (void)verifyWithBatchingDelay:(NSTimeInterval)batchingDelay
{
    XCTestExpectation *wait = [self expectationWithDescription:@"wait"];

    [_sender sendJSONOject:_payload];

    // Wait for Sender to check delivery strategy batching delay
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [wait fulfill];
        XCTAssertEqual(self.sender.uploadTimerInterval, batchingDelay);
    });

    [self waitForExpectationsWithTimeout:5.0 handler:nil];
}

- (void)stubRATResponseWithStatusCode:(int)status completionHandler:(void (^)(void))completion
{
    [OHHTTPStubs stubRequestsPassingTest:^BOOL(NSURLRequest *request) {
        return [request.URL.absoluteString isEqualToString:@"https://endpoint.co.jp/"];
    } withStubResponse:^OHHTTPStubsResponse * _Nonnull(__unused NSURLRequest * _Nonnull request) {
        dispatch_async(dispatch_get_main_queue(), ^{

            if (completion) completion();
        });

        return [[OHHTTPStubsResponse responseWithData:[NSData data] statusCode:status headers:nil] responseTime:2.0];
    }];
}

#pragma mark test initialisation and configuration

- (void)testInitWithEndPointAndDatabaseTableName
{
    XCTAssertNotNil(_sender);
    XCTAssertEqualObjects(_sender.endpointURL.absoluteString, @"https://endpoint.co.jp/");
    XCTAssertEqualObjects(_sender.databaseTableName, @"testTableName");
}

- (void)testSenderWithDefaultBatchingDelay
{
    [self stubRATResponseWithStatusCode:200 completionHandler:nil];
    [self verifyWithBatchingDelay:0.0];
}

- (void)testSenderWithCustomBatchingDelay
{
    [self stubRATResponseWithStatusCode:200 completionHandler:nil];
    [_sender setBatchingDelayBlock:^NSTimeInterval{
        return 15.0;
    }];
    [self verifyWithBatchingDelay:15.0];
}

#pragma mark Test sending events to RAT

- (void)testSendEventToRAT
{
    XCTestExpectation *sent = [self expectationWithDescription:@"sent"];

    [self stubRATResponseWithStatusCode:200 completionHandler:^{
        [sent fulfill];
    }];

    [_sender sendJSONOject:_payload];
    [self waitForExpectationsWithTimeout:5.0 handler:nil];
}

- (void)testSendEventToRATServerError
{
    XCTestExpectation *sent = [self expectationWithDescription:@"sent"];

    [self stubRATResponseWithStatusCode:500 completionHandler:^{
        [sent fulfill];
    }];

    XCTestExpectation *notified = [self expectationWithDescription:@"notified"];
    NSOperationQueue *queue = [NSOperationQueue new];
    id cb = [NSNotificationCenter.defaultCenter addObserverForName:RAnalyticsUploadFailureNotification
                                                            object:nil
                                                             queue:queue
                                                        usingBlock:^(NSNotification *note)
             {
                 NSError *error = note.userInfo[NSUnderlyingErrorKey];
                 XCTAssertEqualObjects(error.localizedDescription, @"invalid_response");
                 [notified fulfill];
             }];

    [_sender sendJSONOject:_payload];
    [self waitForExpectationsWithTimeout:5.0 handler:nil];
    [NSNotificationCenter.defaultCenter removeObserver:cb];
}

#pragma mark Test batch delay handling.

- (void)testThatWithAZeroSecondsBatchingDelayTheTrackerSendsEventToRAT
{
    XCTestExpectation *wait = [self expectationWithDescription:@"wait"];

    [_sender setBatchingDelayBlock:^NSTimeInterval{
        return 0.0;
    }];
    [self stubRATResponseWithStatusCode:200 completionHandler:^{

        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{

            // Event should have been sent and DB record deleted
            XCTAssertEqual(self.database.keys.count, 0);
            XCTAssertEqual(self.database.rows.count, 0);

            [wait fulfill];
        });
    }];

    [_sender sendJSONOject:_payload];
    [self waitForExpectationsWithTimeout:4.0 handler:nil];
}

- (void)testThatWithAGreaterThanZeroSecondsBatchingDelayTheTrackerWaitsBeforeSendingEventToRAT
{
    XCTestExpectation *wait = [self expectationWithDescription:@"wait"];

    [_sender setBatchingDelayBlock:^NSTimeInterval{
        return 30.0;
    }];
    [self stubRATResponseWithStatusCode:200 completionHandler:nil];

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{

        // Event's DB record should still be in DB
        XCTAssertEqual(self.database.keys.count, 1);
        XCTAssertEqual(self.database.rows.count, 1);

        [wait fulfill];
    });

    [_sender sendJSONOject:_payload];
    [self waitForExpectationsWithTimeout:4.0 handler:nil];
}

- (void)testThatWithAZeroSecondsBatchDelayWeDoNotSendDuplicateEventsWhenAppBecomesActive
{
    [self stubRATResponseWithStatusCode:200 completionHandler:nil];

    NSOperationQueue *queue = [NSOperationQueue new];
    __block NSUInteger uploadsToRAT = 0;

    id cbDidUploadToRAT = [NSNotificationCenter.defaultCenter addObserverForName:RAnalyticsUploadSuccessNotification
                                                                          object:nil
                                                                           queue:queue
                                                                      usingBlock:^(NSNotification * _Nonnull note)
                           {
        if ([((NSArray *)note.object).firstObject isEqual:self.payload]) uploadsToRAT++;
                           }];

    XCTestExpectation *notified = [self expectationWithDescription:@"notified"];

    id cbDidBecomeActive = [NSNotificationCenter.defaultCenter addObserverForName:UIApplicationDidBecomeActiveNotification
                                                                           object:nil
                                                                            queue:queue
                                                                       usingBlock:^(__unused NSNotification *note)
                            {
                            [self.sender setBatchingDelayBlock:^NSTimeInterval{
                                    return 0.0;
                                }];
                                [self.sender sendJSONOject:self.payload];

                                // Wait for events to be sent
                                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(4 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{

                                    XCTAssertEqual(uploadsToRAT, 1);
                                    XCTAssertEqual(self.database.keys.count, 0);
                                    XCTAssertEqual(self.database.rows.count, 0);

                                    [notified fulfill];
                                });
                            }];

    [NSNotificationCenter.defaultCenter postNotificationName:UIApplicationDidBecomeActiveNotification object:self];

    [self waitForExpectationsWithTimeout:5.0 handler:nil];
    [NSNotificationCenter.defaultCenter removeObserver:cbDidUploadToRAT];
    [NSNotificationCenter.defaultCenter removeObserver:cbDidBecomeActive];
}

@end

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wnonnull"

SPEC_BEGIN(SenderDatabaseTests)
describe(@"initWithEndpoint:databaseName:databaseTableName:", ^{
    NSURL *endpointURL = [NSURL URLWithString:@"https://www.example.com"];
    
    it(@"should create a database connection when a database name is passed as param", ^{
        RAnalyticsSender *sender = [RAnalyticsSender.alloc initWithEndpoint:endpointURL
                                                               databaseName:@"databaseName"
                                                          databaseTableName:@"tableName"];
        
        [[sender.database should] beNonNil];
    });
    context(@"failed initialization", ^{
        it(@"should fail intialization when nil endpoint is passed as param", ^{
            RAnalyticsSender *sender = [RAnalyticsSender.alloc initWithEndpoint:nil
                                                                   databaseName:@"databaseName"
                                                              databaseTableName:@"tableName"];
            
            [[sender.database should] beNil];
        });
        
        it(@"should fail intialization when zero-length endpoint is passed as param", ^{
            RAnalyticsSender *sender = [RAnalyticsSender.alloc initWithEndpoint:[NSURL URLWithString:@""]
                                                                   databaseName:@"databaseName"
                                                              databaseTableName:@"tableName"];
            
            [[sender.database should] beNil];
        });
        
        it(@"should fail intialization when nil db name is passed as param", ^{
            RAnalyticsSender *sender = [RAnalyticsSender.alloc initWithEndpoint:endpointURL
                                                                   databaseName:nil
                                                              databaseTableName:nil];
            
            [[sender.database should] beNil];
        });
        
        it(@"should fail intialization when zero-length db name is passed as param", ^{
            RAnalyticsSender *sender = [RAnalyticsSender.alloc initWithEndpoint:endpointURL
                                                                   databaseName:@""
                                                              databaseTableName:@"tableName"];
            
            [[sender.database should] beNil];
        });
        
        it(@"should fail intialization when nil table name is passed as param", ^{
            RAnalyticsSender *sender = [RAnalyticsSender.alloc initWithEndpoint:endpointURL
                                                                   databaseName:@"databaseName"
                                                              databaseTableName:nil];
            
            [[sender.database should] beNil];
        });
        
        it(@"should fail intialization when zero-length table name is passed as param", ^{
            RAnalyticsSender *sender = [RAnalyticsSender.alloc initWithEndpoint:endpointURL
                                                                   databaseName:@"databaseName"
                                                              databaseTableName:@""];
            
            [[sender.database should] beNil];
        });
    });
});
SPEC_END

#pragma clang diagnostic pop
