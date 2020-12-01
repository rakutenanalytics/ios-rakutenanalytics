#import <Kiwi/Kiwi.h>
#import <WebKit/WebKit.h>
#import "../../RAnalytics/Util/Private/_RAnalyticsCookieInjector.h"

SPEC_BEGIN(CookieInjectorTests)

describe(@"injectAppToWebTrackingCookie", ^{
    __block NSString *deviceID = @"12345";

    it(@"should set expected cookie value using device identifier", ^{
        // IDFA is always zero'd on simulator
        __block NSHTTPCookie *cookie = nil;
        
        [_RAnalyticsCookieInjector injectAppToWebTrackingCookieWithDomain:nil
                                                         deviceIdentifier:deviceID
                                                        completionHandler:^(NSHTTPCookie * _Nullable injectedCookie) {
            cookie = injectedCookie;
        }];

        [[expectFutureValue(cookie.value) shouldEventually] equal:@"rat_uid%3D12345%3Ba_uid%3D00000000-0000-0000-0000-000000000000"];
    });

    it(@"should set cookie path to /", ^{
        __block NSHTTPCookie *cookie = nil;
        
        [_RAnalyticsCookieInjector injectAppToWebTrackingCookieWithDomain:nil
                                                         deviceIdentifier:deviceID
                                                        completionHandler:^(NSHTTPCookie * _Nullable injectedCookie) {
            cookie = injectedCookie;
        }];

        [[expectFutureValue(cookie.path) shouldEventually] equal:@"/"];
    });

    it(@"should set cookie name to ra_uid", ^{
        __block NSHTTPCookie *cookie = nil;
        
        [_RAnalyticsCookieInjector injectAppToWebTrackingCookieWithDomain:nil
                                                         deviceIdentifier:deviceID
                                                        completionHandler:^(NSHTTPCookie * _Nullable injectedCookie) {
            cookie = injectedCookie;
        }];

        [[expectFutureValue(cookie.name) shouldEventually] equal:@"ra_uid"];
    });

    it(@"should set cookie samesite to none", ^{
        __block NSHTTPCookie *cookie = nil;
        
        [_RAnalyticsCookieInjector injectAppToWebTrackingCookieWithDomain:nil
                                                         deviceIdentifier:deviceID
                                                        completionHandler:^(NSHTTPCookie * _Nullable injectedCookie) {
            cookie = injectedCookie;
        }];

        if (@available(iOS 13.0, *)) {
            [[expectFutureValue(cookie.sameSitePolicy) shouldEventually] beNil];
        }
    });

    it(@"should set cookie as secure", ^{
        __block NSHTTPCookie *cookie = nil;
        
        [_RAnalyticsCookieInjector injectAppToWebTrackingCookieWithDomain:nil
                                                         deviceIdentifier:deviceID
                                                        completionHandler:^(NSHTTPCookie * _Nullable injectedCookie) {
            cookie = injectedCookie;
        }];

        [[expectFutureValue(theValue(cookie.isSecure)) shouldEventually] beTrue];
    });

    context(@"when domain param is nil", ^{
        it(@"should set default .rakuten.co.jp domain on cookie", ^{
            __block NSHTTPCookie *cookie = nil;
            
            [_RAnalyticsCookieInjector injectAppToWebTrackingCookieWithDomain:nil
                                                             deviceIdentifier:deviceID
                                                            completionHandler:^(NSHTTPCookie * _Nullable injectedCookie) {
                cookie = injectedCookie;
            }];

            [[expectFutureValue(cookie.domain) shouldEventually] equal:@".rakuten.co.jp"];
        });
    });

    context(@"when domain param is non-nil", ^{
        it(@"should set passed in domain on cookie", ^{
            __block NSHTTPCookie *cookie = nil;
            
            [_RAnalyticsCookieInjector injectAppToWebTrackingCookieWithDomain:@".my-domain.co.jp"
                                                             deviceIdentifier:deviceID
                                                            completionHandler:^(NSHTTPCookie * _Nullable injectedCookie) {
                cookie = injectedCookie;
            }];

            [[expectFutureValue(cookie.domain) shouldEventually] equal:@".my-domain.co.jp"];
        });
    });

    it(@"should return nil cookie when device identifier is nil", ^{
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wnonnull"
        __block NSHTTPCookie *cookie = nil;
        
        [_RAnalyticsCookieInjector injectAppToWebTrackingCookieWithDomain:nil
                                                         deviceIdentifier:nil
                                                        completionHandler:^(NSHTTPCookie * _Nullable injectedCookie) {
            cookie = injectedCookie;
        }];
#pragma clang diagnostic pop

        [[expectFutureValue(cookie) shouldEventually] beNil];
    });

    it(@"should inject cookie into WKWebsiteDataStore httpCookieStore", ^{
        __block BOOL hasCookie = NO;
        __unused __block NSHTTPCookie *cookie = nil;
        
        [_RAnalyticsCookieInjector injectAppToWebTrackingCookieWithDomain:nil
                                                         deviceIdentifier:deviceID
                                                        completionHandler:^(NSHTTPCookie * _Nullable injectedCookie) {
            cookie = injectedCookie;
            
            if (@available(iOS 11.0, *)) {
                WKHTTPCookieStore *store = WKWebsiteDataStore.defaultDataStore.httpCookieStore;
                
                [store getAllCookies:^(NSArray<NSHTTPCookie *> * _Nonnull cookies) {
                    [cookies enumerateObjectsUsingBlock:^(NSHTTPCookie * _Nonnull obj, __unused NSUInteger idx, BOOL * _Nonnull stop) {
                        if ([obj.name isEqualToString:@"ra_uid"]) {
                            hasCookie = YES;
                            *stop = YES;
                        }
                    }];
                }];
            }
        }];
        
        [[expectFutureValue(theValue(hasCookie)) shouldEventually] beTrue];
    });
    
    it(@"should replace the existing cookie by the new one that has the same name into WKWebsiteDataStore httpCookieStore", ^{
        __block NSHTTPCookie *existingCookie = nil;
        __block NSHTTPCookie *replacedCookie = nil;
        __block NSMutableArray * ratCookies = [NSMutableArray array];

        if (@available(iOS 11.0, *)) {
            WKHTTPCookieStore *store = WKWebsiteDataStore.defaultDataStore.httpCookieStore;
             [_RAnalyticsCookieInjector injectAppToWebTrackingCookieWithDomain:@"https://domain1.com"
                                                              deviceIdentifier:deviceID
                                                             completionHandler:^(NSHTTPCookie * _Nullable injectedCookie) {
                 existingCookie = injectedCookie;
                 [_RAnalyticsCookieInjector injectAppToWebTrackingCookieWithDomain:@"https://domain2.com"
                                                                                   deviceIdentifier:deviceID
                                                                 completionHandler:^(NSHTTPCookie * _Nullable newInjectedCookie) {
                     replacedCookie = newInjectedCookie;
                     [store getAllCookies:^(NSArray<NSHTTPCookie *> * _Nonnull cookies) {
                         [cookies enumerateObjectsUsingBlock:^(NSHTTPCookie * _Nonnull obj, __unused NSUInteger idx, __unused BOOL * _Nonnull stop) {
                             if ([obj.name isEqualToString:@"ra_uid"]) {
                                 [ratCookies addObject:obj];
                             }
                         }];
                     }];
                 }];
             }];
        }

        [[expectFutureValue(existingCookie.domain) shouldEventually] equal:@"https://domain1.com"];
        [[expectFutureValue(replacedCookie.domain) shouldEventually] equal:@"https://domain2.com"];
        [[expectFutureValue(theValue(ratCookies.count)) shouldEventually] equal:theValue(1)];
        [[expectFutureValue([((NSHTTPCookie *)[ratCookies firstObject]) name]) shouldEventually] equal:@"ra_uid"];
        [[expectFutureValue([((NSHTTPCookie *)[ratCookies firstObject]) domain]) shouldEventually] equal:@"https://domain2.com"];
    });
});

SPEC_END
