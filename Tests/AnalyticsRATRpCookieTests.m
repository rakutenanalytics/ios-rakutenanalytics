/*
 * © Rakuten, Inc.
 * authors: "Rakuten Ecosystem Mobile" <ecosystem-mobile@mail.rakuten.com>
 */
@import XCTest;
#import <RSDKAnalytics/RSDKAnalytics.h>
#import <RSDKAnalytics/RSDKAnalyticsState.h>
#import "../RSDKAnalytics/Private/_RSDKAnalyticsHelpers.h"
#import "../RSDKAnalytics/Private/_RSDKAnalyticsDatabase.h"
#import <OCMock/OCMock.h>
#import <OHHTTPStubs/OHHTTPStubs.h>

#import <XCTest/XCTest.h>

@interface RATTracker ()
- (instancetype)initInstance;
@end

@interface AnalyticsRATRpCookieTests : XCTestCase

@end


@implementation AnalyticsRATRpCookieTests

- (void)testCookieIsSavedOnRATInstance
{
    __weak XCTestExpectation *expectation = [self expectationWithDescription:@"sent"];
    // Clear all the cookies if exist any
    for(NSHTTPCookie *cookie in [[NSHTTPCookieStorage sharedHTTPCookieStorage] cookies])
    {
        [[NSHTTPCookieStorage sharedHTTPCookieStorage] deleteCookie:cookie];
    }
    
    NSString* const cookieName = @"TestCookieName";
    NSString* const cookieValue = @"TestCookieValue";
    
    [OHHTTPStubs stubRequestsPassingTest:^BOOL(NSURLRequest *request) {
        return YES;
    } withStubResponse:^OHHTTPStubsResponse *(NSURLRequest *request) {
        NSString* cookie = [NSString stringWithFormat:@"%@=%@;", cookieName, cookieValue];
        NSDictionary* headers = @{@"Set-Cookie": cookie};
        return [OHHTTPStubsResponse responseWithData:[NSData new]
                                          statusCode:200
                                             headers:headers];
    }];
    RATTracker __unused *trackerInstance = [[RATTracker alloc] initInstance];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [[NSHTTPCookieStorage sharedHTTPCookieStorage] getCookiesForTask:[[NSURLSession sharedSession] dataTaskWithURL:_RSDKAnalyticsEndpointAddress()] completionHandler:^(NSArray<NSHTTPCookie *> * _Nullable cookies)
         {
             XCTAssertEqualObjects(cookieName, cookies[0].name);
             XCTAssertEqualObjects(cookieValue, cookies[0].value);
             [OHHTTPStubs removeAllStubs];
             [expectation fulfill];
         }];
    });
    [self waitForExpectationsWithTimeout:4.0 handler:nil];
}

- (void)testGetRpCookieWithError
{
    __weak XCTestExpectation *expectation = [self expectationWithDescription:@"sent"];
    
    for(NSHTTPCookie *cookie in [[NSHTTPCookieStorage sharedHTTPCookieStorage] cookies])
    {
        [[NSHTTPCookieStorage sharedHTTPCookieStorage] deleteCookie:cookie];
    }
    
    [OHHTTPStubs stubRequestsPassingTest:^BOOL(NSURLRequest *request) {
        return YES;
    } withStubResponse:^OHHTTPStubsResponse *(NSURLRequest *request) {
        return [OHHTTPStubsResponse responseWithData:[NSData new]
                                          statusCode:500
                                             headers:nil];
    }];
    
    RATTracker __unused *trackerInstance = [[RATTracker alloc] initInstance];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [[RATTracker sharedInstance] getRpCookieCompletionHandler:^(NSHTTPCookie *cookie, NSError *error) {
            
            XCTAssertNil(cookie);
            XCTAssertNotNil(error);
            [OHHTTPStubs removeAllStubs];
            [expectation fulfill];
        }];
    });
    [self waitForExpectationsWithTimeout:4.0 handler:nil];
}

- (void)testGetRpCookieWithExpiredCookie
{
    XCTestExpectation *expectation = [self expectationWithDescription:@"send"];
    
    [self setRpCookieWithName:@"Rp" Value:@"CookieValue" ExpiryDate:@"Fri, 16-Nov-16 16:59:07 GMT"];
    
    RATTracker __unused *trackerInstance = [[RATTracker alloc] initInstance];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [[RATTracker sharedInstance] getRpCookieCompletionHandler:^(NSHTTPCookie *cookie, NSError *error) {
            
            XCTAssertNil(cookie);
            XCTAssertNotNil(error);
            [OHHTTPStubs removeAllStubs];
            [expectation fulfill];
        }];
    });
    
    [self waitForExpectationsWithTimeout:4.0 handler:nil];
}
- (void)testGetRpCookieWithValidExpiredCookie
{
    XCTestExpectation *expectation = [self expectationWithDescription:@"send"];
    
    [self setRpCookieWithName:@"Rp" Value:@"CookieValue" ExpiryDate:@"Fri, 16-Nov-20 16:59:07 GMT"];
    
    RATTracker __unused *trackerInstance = [[RATTracker alloc] initInstance];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [[RATTracker sharedInstance] getRpCookieCompletionHandler:^(NSHTTPCookie *cookie, NSError *error) {
            
            XCTAssertNotNil(cookie);
            XCTAssertNil(error);
            XCTAssertEqualObjects(@"CookieValue", cookie.value);
            [OHHTTPStubs removeAllStubs];
            [expectation fulfill];
        }];
    });
    
    [self waitForExpectationsWithTimeout:4.0 handler:nil];
}

#pragma mark Helper function for RpCookie

- (void)setRpCookieWithName:(NSString *)cookieName Value:(NSString *)cookieValue ExpiryDate:(NSString *)expiryDate
{
    // Clear all the cookies if exist any
    for(NSHTTPCookie *cookie in [[NSHTTPCookieStorage sharedHTTPCookieStorage] cookies])
    {
        [[NSHTTPCookieStorage sharedHTTPCookieStorage] deleteCookie:cookie];
    }
    [OHHTTPStubs stubRequestsPassingTest:^BOOL(NSURLRequest *request) {
        return YES;
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
