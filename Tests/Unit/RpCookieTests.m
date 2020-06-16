@import XCTest;
#import <OCMock/OCMock.h>
#import <OHHTTPStubs/OHHTTPStubs.h>

#import <RAnalytics/RAnalytics.h>
#import <RAnalytics/RAnalyticsState.h>

#import "../../RAnalytics/Util/Private/_RAnalyticsHelpers.h"

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated"

@interface RAnalyticsRATTracker ()
- (instancetype)initInstance;
@end

@interface RpCookieTests : XCTestCase
@end

@implementation RpCookieTests

- (void)setUp
{
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
}

- (void)testCookieIsSavedOnRATInstanceInitialization
{
    __weak XCTestExpectation *expectation = [self expectationWithDescription:@"sent"];
    NSString* const cookieName = @"TestCookieName";
    NSString* const cookieValue = @"TestCookieValue";
    
   [self setRpCookieWithName:cookieName value:cookieValue expiryDate:@"Fri, 16-Nov-50 16:59:07 GMT"];

    RAnalyticsRATTracker __unused *trackerInstance = [[RAnalyticsRATTracker alloc] initInstance];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        NSArray<NSHTTPCookie *> *cookies = [NSHTTPCookieStorage.sharedHTTPCookieStorage cookiesForURL:_RAnalyticsEndpointAddress()];

        XCTAssertEqualObjects(cookieName, cookies[0].name);
        XCTAssertEqualObjects(cookieValue, cookies[0].value);
        [expectation fulfill];
    });
    [self waitForExpectationsWithTimeout:2.0 handler:nil];
}

- (void)testGetRpCookieWithError
{
    __weak XCTestExpectation *expectation = [self expectationWithDescription:@"sent"];
    
    [OHHTTPStubs stubRequestsPassingTest:^BOOL(NSURLRequest *request) {
        return [request.URL.absoluteString containsString:[NSString stringWithFormat:@"%@",[RAnalyticsRATTracker endpointAddress]]];
    } withStubResponse:^OHHTTPStubsResponse *(__unused NSURLRequest *request) {
        return [OHHTTPStubsResponse responseWithData:[NSData new]
                                          statusCode:500
                                             headers:nil];
    }];
    
    RAnalyticsRATTracker __unused *trackerInstance = [[RAnalyticsRATTracker alloc] initInstance];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [[RAnalyticsRATTracker sharedInstance] getRpCookieCompletionHandler:^(NSHTTPCookie * _Nullable cookie, NSError * _Nullable error) {
            
            XCTAssertNil(cookie);
            XCTAssertNotNil(error);
            [expectation fulfill];
        }];
    });
    [self waitForExpectationsWithTimeout:4.0 handler:nil];
}

- (void)testGetRpCookieWithExpiredCookie
{
    XCTestExpectation *expectation = [self expectationWithDescription:@"send"];
    
    [self setRpCookieWithName:@"Rp" value:@"CookieValue" expiryDate:@"Fri, 16-Nov-16 16:59:07 GMT"];
    
    RAnalyticsRATTracker __unused *trackerInstance = [[RAnalyticsRATTracker alloc] initInstance];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [[RAnalyticsRATTracker sharedInstance] getRpCookieCompletionHandler:^(NSHTTPCookie * _Nullable cookie, NSError * _Nullable error) {
            
            XCTAssertNil(cookie);
            XCTAssertNotNil(error);
            [expectation fulfill];
        }];
    });
    
    [self waitForExpectationsWithTimeout:2.0 handler:nil];
}

- (void)testGetRpCookieWithValidCookie
{
    XCTestExpectation *expectation = [self expectationWithDescription:@"send"];
    
    [self setRpCookieWithName:@"Rp" value:@"CookieValue" expiryDate:@"Fri, 16-Nov-50 16:59:07 GMT"];
    
    RAnalyticsRATTracker __unused *trackerInstance = [[RAnalyticsRATTracker alloc] initInstance];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [[RAnalyticsRATTracker sharedInstance] getRpCookieCompletionHandler:^(NSHTTPCookie * _Nullable cookie, NSError * _Nullable error) {
            
            XCTAssertNotNil(cookie);
            XCTAssertNil(error);
            XCTAssertEqualObjects(@"CookieValue", cookie.value);
            [expectation fulfill];
        }];
    });
    
    [self waitForExpectationsWithTimeout:2.0 handler:nil];
}

#pragma mark Helper function for RpCookie

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

