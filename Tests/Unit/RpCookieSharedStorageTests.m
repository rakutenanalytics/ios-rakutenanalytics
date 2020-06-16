#import <Kiwi/Kiwi.h>
#import <OHHTTPStubs/OHHTTPStubs.h>
#import <RAnalytics/RAnalytics.h>

SPEC_BEGIN(RpCookieSharedStorageTests)

describe(@"getRpCookieFromCookieStorage", ^{

    __block RAnalyticsRpCookieFetcher *cookieFetcher = nil;

    beforeEach(^{
        NSHTTPCookieStorage *storage = NSHTTPCookieStorage.sharedHTTPCookieStorage;
        [storage removeCookiesSinceDate:NSDate.distantPast];
        cookieFetcher = [RAnalyticsRpCookieFetcher.alloc initWithCookieStorage:storage];

        [OHHTTPStubs stubRequestsPassingTest:^BOOL(NSURLRequest *request) {
            return [request.URL.absoluteString containsString:[NSString stringWithFormat:@"%@",[RAnalyticsRATTracker endpointAddress]]];
        } withStubResponse:^OHHTTPStubsResponse *(__unused NSURLRequest *request) {
            NSString* cookie = [NSString stringWithFormat:@"%@=%@; path=/; expires=%@; session-only=%@; domain=.rakuten.co.jp", @"Rp", @"cookieValue", @"Fri, 16-Nov-50 16:59:07 GMT", [NSNumber numberWithBool:NO]];
            NSDictionary* headers = @{@"Set-Cookie": cookie};
            return [OHHTTPStubsResponse responseWithData:[NSData new]
                                              statusCode:200
                                                 headers:headers];
        }];
    });

    afterEach(^{
        [OHHTTPStubs removeAllStubs];
    });
    context(@"when user sets 'disable shared cookie storage' key to true in app info.plist", ^{
        it(@"should return nil cookie", ^{
            [[NSBundle mainBundle] stub:@selector(objectForInfoDictionaryKey:) andReturn:@(YES) withArguments:@"RATDisableSharedCookieStorage"];

            XCTestExpectation *wait = [self expectationWithDescription:@"wait"];

            [cookieFetcher getRpCookieCompletionHandler:^(NSHTTPCookie * _Nullable __unused cookie, NSError * _Nullable __unused error) {
                [[[cookieFetcher getRpCookieFromCookieStorage] should] beNil];
                [wait fulfill];
            }];

            [self waitForExpectationsWithTimeout:2.0 handler:nil];
        });
    });
    context(@"when user sets 'disable shared cookie storage' key to false in app info.plist", ^{
        it(@"should return Rp cookie", ^{
            [[NSBundle mainBundle] stub:@selector(objectForInfoDictionaryKey:) andReturn:@(NO) withArguments:@"RATDisableSharedCookieStorage"];

            [cookieFetcher getRpCookieCompletionHandler:^(NSHTTPCookie * _Nullable __unused cookie, NSError * _Nullable __unused error) {}];

            [[expectFutureValue([[cookieFetcher getRpCookieFromCookieStorage] name]) shouldEventually] equal:@"Rp"];
        });
    });
    context(@"when user did not set 'disable shared cookie storage' key in app info.plist", ^{
        it(@"should return Rp cookie", ^{
            [[NSBundle mainBundle] stub:@selector(objectForInfoDictionaryKey:) andReturn:nil withArguments:@"RATDisableSharedCookieStorage"];

            [cookieFetcher getRpCookieCompletionHandler:^(NSHTTPCookie * _Nullable __unused cookie, NSError * _Nullable __unused error) {}];

            [[expectFutureValue([[cookieFetcher getRpCookieFromCookieStorage] name]) shouldEventually] equal:@"Rp"];
        });
    });
});

SPEC_END
