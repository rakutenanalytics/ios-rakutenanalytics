@import XCTest;
#import <RAnalytics/RAnalyticsProgressNotifications.h>
#import <OHHTTPStubs/OHHTTPStubs.h>
#import <OCMock/OCMock.h>
#import <Kiwi/Kiwi.h>
#import <sqlite3.h>
#import <RAnalytics/RAnalytics-Swift.h>
#import "UnitTests-Swift.h"

@interface SenderTests : XCTestCase
@property (nonatomic) RAnalyticsSender *sender;
@property (nonatomic, copy) NSString *databaseTableName;
@property (nonatomic) RAnalyticsDatabase *database;
@property (nonatomic) NSDictionary *payload;
@property (nonatomic) NSMutableArray *mocks;
@property (nonatomic) sqlite3 *connection;
@end

@implementation SenderTests

- (void)setUp {
    [super setUp];
    _mocks = NSMutableArray.new;
    _payload = @{@"key":@"value"};

    // Create in-memory DB
    _databaseTableName = @"testTableName";
    _connection = [DatabaseTestUtils openRegularConnection];
    _database = [DatabaseTestUtils mkDatabaseWithConnection:self.connection];
    
    _sender = [[RAnalyticsSender alloc] initWithEndpoint:[NSURL URLWithString:@"https://endpoint.co.jp/"]
                                                database:_database
                                           databaseTable:_databaseTableName];
}

- (void)tearDown {
    [_mocks enumerateObjectsUsingBlock:^(id mock, __unused NSUInteger idx, __unused BOOL *stop) {
        [mock stopMocking];
    }];

    // Clear any still running timers because they can break our async batching delay tests
    [_sender.uploadTimer invalidate];
    _sender.uploadTimer = nil;

    [DatabaseTestUtils deleteTableIfExists:_databaseTableName connection:_connection];

    _sender = nil;
    _database = nil;
    _connection = nil;
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

    [_sender sendJSONObject:_payload];

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

- (void)testSetBatchingDelay
{
    [_sender setBatchingDelayBlock:^NSTimeInterval{
        return 15.0;
    }];

    BatchingDelayBlock block = [_sender batchingDelayBlock];
    NSTimeInterval delay  = block();

    XCTAssertEqual(delay, 15.0);
}

#pragma mark Test sending events to RAT

- (void)testSendEventToRAT
{
    XCTestExpectation *sent = [self expectationWithDescription:@"sent"];

    [self stubRATResponseWithStatusCode:200 completionHandler:^{
        [sent fulfill];
    }];

    [_sender sendJSONObject:_payload];
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

    [_sender sendJSONObject:_payload];

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
            NSArray<NSData *> *contents = [DatabaseTestUtils fetchTableContents:self.databaseTableName connection:self.connection];
            XCTAssertEqual(contents.count, 0);
            [wait fulfill];
        });
    }];

    [_sender sendJSONObject:_payload];
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
        NSArray<NSData *> *contents = [DatabaseTestUtils fetchTableContents:self.databaseTableName connection:self.connection];
        XCTAssertEqual(contents.count, 1);
        [wait fulfill];
    });

    [_sender sendJSONObject:_payload];
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
                                [self.sender sendJSONObject:self.payload];

                                // Wait for events to be sent
                                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(4 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{

                                    NSArray<NSData *> *contents = [DatabaseTestUtils fetchTableContents:self.databaseTableName connection:self.connection];
                                    XCTAssertEqual(uploadsToRAT, 1);
                                    XCTAssertEqual(contents.count, 0);
                                    [notified fulfill];
                                });
                            }];

    [NSNotificationCenter.defaultCenter postNotificationName:UIApplicationDidBecomeActiveNotification object:self];

    [self waitForExpectationsWithTimeout:5.0 handler:nil];
    [NSNotificationCenter.defaultCenter removeObserver:cbDidUploadToRAT];
    [NSNotificationCenter.defaultCenter removeObserver:cbDidBecomeActive];
}

@end
