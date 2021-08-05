@import XCTest;
#import <OCMock/OCMock.h>
#import <OHHTTPStubs/OHHTTPStubs.h>
#import <RAnalytics/RAnalytics.h>
#import <sqlite3.h>
#import "UnitTests-Swift.h"
@import CoreTelephony;

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wundeclared-selector"
#pragma clang diagnostic ignored "-Warc-repeated-use-of-weak"
#pragma clang diagnostic ignored "-Wnonnull"
#pragma clang diagnostic ignored "-Wdeprecated-declarations"

@interface RpCookieTests : XCTestCase
@end

@implementation RpCookieTests

- (void)setUp
{
    [super setUp];

    // Used to clear any ongoing cookie fetch task
    [[NSURLSession sharedSession] getTasksWithCompletionHandler:^(NSArray<NSURLSessionDataTask *> * _Nonnull dataTasks,
                                                                  __unused NSArray<NSURLSessionUploadTask *> * _Nonnull uploadTasks,
                                                                  __unused NSArray<NSURLSessionDownloadTask *> * _Nonnull downloadTasks) {
        [dataTasks makeObjectsPerformSelector:@selector(cancel)];
    }];

    // Clear cookie jar
    NSHTTPCookieStorage *storage = NSHTTPCookieStorage.sharedHTTPCookieStorage;
    for(NSHTTPCookie *cookie in storage.cookies)
    {
        [[NSHTTPCookieStorage sharedHTTPCookieStorage] deleteCookie:cookie];
    }
}

- (void)tearDown
{
    [OHHTTPStubs removeAllStubs];
    [super tearDown];
}

- (RAnalyticsRATTracker *)createTracker {
    return [RAnalyticsRATTracker create];
}

- (void)testCookieIsSavedOnRATInstanceInitialization
{
    XCTestExpectation *expectation = [self expectationWithDescription:@"expectation"];
    
    [self setRpCookieWithName:@"TestCookieName" value:@"TestCookieValue" expiryDate:@"Fri, 16-Nov-50 16:59:07 GMT"];

    [self createTracker];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        NSHTTPCookie *cookie = [self rpCookieFromStorage];
        XCTAssertEqualObjects(@"TestCookieName", cookie.name);
        XCTAssertEqualObjects(@"TestCookieValue", cookie.value);
        [expectation fulfill];
    });
    [self waitForExpectationsWithTimeout:2.0 handler:nil];
}

- (void)testRpCookieIsNilWhenServerErrorOccurs
{
    XCTestExpectation *expectation = [self expectationWithDescription:@"expectation"];
    
    [OHHTTPStubs stubRequestsPassingTest:^BOOL(NSURLRequest *request) {
        return [request.URL.absoluteString containsString:[NSString stringWithFormat:@"%@",[RAnalyticsRATTracker endpointAddress]]];
    } withStubResponse:^OHHTTPStubsResponse *(__unused NSURLRequest *request) {
        return [OHHTTPStubsResponse responseWithData:[NSData new]
                                          statusCode:500
                                             headers:nil];
    }];
    
    [self createTracker];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        XCTAssertNil([self rpCookieFromStorage]);
        [expectation fulfill];
    });
    [self waitForExpectationsWithTimeout:2.0 handler:nil];
}

- (void)testRpCookieIsNilWhenFetchedCookieIsExpired
{
    XCTestExpectation *expectation = [self expectationWithDescription:@"expectation"];
    
    [self setRpCookieWithName:@"Rp" value:@"CookieValue" expiryDate:@"Fri, 16-Nov-16 16:59:07 GMT"];
    
    [self createTracker];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        XCTAssertNil([self rpCookieFromStorage]);
        [expectation fulfill];
    });
    
    [self waitForExpectationsWithTimeout:2.0 handler:nil];
}

- (void)testRpCookieIsNonNilWhenFetchedCookieIsValid
{
    XCTestExpectation *expectation = [self expectationWithDescription:@"expectation"];
    
    [self setRpCookieWithName:@"Rp" value:@"CookieValue" expiryDate:@"Fri, 16-Nov-50 16:59:07 GMT"];

    [self createTracker];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        XCTAssertEqualObjects(@"CookieValue", [self rpCookieFromStorage].value);
        [expectation fulfill];
    });
    
    [self waitForExpectationsWithTimeout:2.0 handler:nil];
}

#pragma mark Helper function for RpCookie

- (NSHTTPCookie *)rpCookieFromStorage
{
    NSArray<NSHTTPCookie *> *cookies = [NSHTTPCookieStorage.sharedHTTPCookieStorage cookiesForURL:[BundleHelper endpointAddress]];
    return cookies.firstObject;
}

- (void)setRpCookieWithName:(NSString *)cookieName value:(NSString *)cookieValue expiryDate:(NSString *)expiryDate
{
    [OHHTTPStubs stubRequestsPassingTest:^BOOL(NSURLRequest *request) {
        return [request.URL.absoluteString containsString:[NSString stringWithFormat:@"%@",[RAnalyticsRATTracker endpointAddress]]];
    } withStubResponse:^OHHTTPStubsResponse *(__unused NSURLRequest *request) {
        NSString* cookie = [NSString stringWithFormat:@"%@=%@; path=/; expires=%@; session-only=%@; domain=.rakuten.co.jp", cookieName, cookieValue, expiryDate, [NSNumber numberWithBool:NO]];
        NSDictionary* headers = @{@"Set-Cookie": cookie};
        return [OHHTTPStubsResponse responseWithData:[NSData new]
                                          statusCode:200
                                             headers:headers];
    }];
}

@end

#pragma clang diagnostic pop
