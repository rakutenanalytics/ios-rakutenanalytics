/*
 * © Rakuten, Inc.
 * authors: "Rakuten Ecosystem Mobile" <ecosystem-mobile@mail.rakuten.com>
 */
@import XCTest;
#import <OCMock/OCMock.h>
#import <OHHTTPStubs/OHHTTPStubs.h>

#import <RAnalytics/RAnalytics.h>
#import <RAnalytics/RAnalyticsState.h>

#import "../../RAnalytics/Util/Private/_RAnalyticsHelpers.h"

@interface RAnalyticsRATTracker ()
- (instancetype)initInstance;
@end

@interface AnalyticsRATRpCookieTests : XCTestCase

@end


@implementation AnalyticsRATRpCookieTests

- (void)setUp
{
    // Clear all the cookies if exist any
    for(NSHTTPCookie *cookie in [[NSHTTPCookieStorage sharedHTTPCookieStorage] cookies])
    {
        [[NSHTTPCookieStorage sharedHTTPCookieStorage] deleteCookie:cookie];
    }
}

- (void)testCookieIsSavedOnRATInstanceInitialization
{
    __weak XCTestExpectation *expectation = [self expectationWithDescription:@"sent"];
    NSString* const cookieName = @"TestCookieName";
    NSString* const cookieValue = @"TestCookieValue";
    
    [OHHTTPStubs stubRequestsPassingTest:^BOOL(NSURLRequest *request) {
        return [request.URL.absoluteString containsString:[NSString stringWithFormat:@"%@",[RAnalyticsRATTracker endpointAddress]]];
    } withStubResponse:^OHHTTPStubsResponse *(NSURLRequest *request) {
        NSString* cookie = [NSString stringWithFormat:@"%@=%@;", cookieName, cookieValue];
        NSDictionary* headers = @{@"Set-Cookie": cookie};
        return [OHHTTPStubsResponse responseWithData:[NSData new]
                                          statusCode:200
                                             headers:headers];
    }];
    RAnalyticsRATTracker __unused *trackerInstance = [[RAnalyticsRATTracker alloc] initInstance];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [[NSHTTPCookieStorage sharedHTTPCookieStorage] getCookiesForTask:[[NSURLSession sharedSession] dataTaskWithURL:_RAnalyticsEndpointAddress()] completionHandler:^(NSArray<NSHTTPCookie *> * _Nullable cookies)
         {
             XCTAssertEqualObjects(cookieName, cookies[0].name);
             XCTAssertEqualObjects(cookieValue, cookies[0].value);
             [expectation fulfill];
         }];
    });
    [self waitForExpectationsWithTimeout:4.0 handler:nil];
}

- (void)testGetRpCookieWithError
{
    __weak XCTestExpectation *expectation = [self expectationWithDescription:@"sent"];
    
    [OHHTTPStubs stubRequestsPassingTest:^BOOL(NSURLRequest *request) {
        return [request.URL.absoluteString containsString:[NSString stringWithFormat:@"%@",[RAnalyticsRATTracker endpointAddress]]];
    } withStubResponse:^OHHTTPStubsResponse *(NSURLRequest *request) {
        return [OHHTTPStubsResponse responseWithData:[NSData new]
                                          statusCode:500
                                             headers:nil];
    }];
    
    RAnalyticsRATTracker __unused *trackerInstance = [[RAnalyticsRATTracker alloc] initInstance];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [[RAnalyticsRATTracker sharedInstance] getRpCookieCompletionHandler:^(NSHTTPCookie *cookie, NSError *error) {
            
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
    
    [self setRpCookieWithName:@"Rp" Value:@"CookieValue" ExpiryDate:@"Fri, 16-Nov-16 16:59:07 GMT"];
    
    RAnalyticsRATTracker __unused *trackerInstance = [[RAnalyticsRATTracker alloc] initInstance];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [[RAnalyticsRATTracker sharedInstance] getRpCookieCompletionHandler:^(NSHTTPCookie *cookie, NSError *error) {
            
            XCTAssertNil(cookie);
            XCTAssertNotNil(error);
            [expectation fulfill];
        }];
    });
    
    [self waitForExpectationsWithTimeout:4.0 handler:nil];
}
- (void)testGetRpCookieWithValidCookie
{
    XCTestExpectation *expectation = [self expectationWithDescription:@"send"];
    
    [self setRpCookieWithName:@"Rp" Value:@"CookieValue" ExpiryDate:@"Fri, 16-Nov-20 16:59:07 GMT"];
    
    RAnalyticsRATTracker __unused *trackerInstance = [[RAnalyticsRATTracker alloc] initInstance];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [[RAnalyticsRATTracker sharedInstance] getRpCookieCompletionHandler:^(NSHTTPCookie *cookie, NSError *error) {
            
            XCTAssertNotNil(cookie);
            XCTAssertNil(error);
            XCTAssertEqualObjects(@"CookieValue", cookie.value);
            [expectation fulfill];
        }];
    });
    
    [self waitForExpectationsWithTimeout:4.0 handler:nil];
}

#pragma mark Helper function for RpCookie

- (void)setRpCookieWithName:(NSString *)cookieName Value:(NSString *)cookieValue ExpiryDate:(NSString *)expiryDate
{
    [OHHTTPStubs stubRequestsPassingTest:^BOOL(NSURLRequest *request) {
        return [request.URL.absoluteString containsString:[NSString stringWithFormat:@"%@",[RAnalyticsRATTracker endpointAddress]]];
    } withStubResponse:^OHHTTPStubsResponse *(NSURLRequest *request) {
        NSString* cookie = [NSString stringWithFormat:@"%@=%@; path=/; expires=%@; session-only=%@; domain=.rakuten.co.jp", cookieName, cookieValue, expiryDate, [NSNumber numberWithBool:NO]];
        NSDictionary* headers = @{@"Set-Cookie": cookie};
        return [OHHTTPStubsResponse responseWithData:[NSData new]
                                          statusCode:200
                                             headers:headers];
    }];
}

- (void)tearDown
{
    [OHHTTPStubs removeAllStubs];
}

@end

