#import <Kiwi/Kiwi.h>
#import <WebKit/WebKit.h>
#import "../../RAnalytics/Util/Private/_RAnalyticsCookieInjector.h"

SPEC_BEGIN(CookieInjectorTests)

describe(@"injectAppToWebTrackingCookie", ^{
    __block NSString *deviceID = @"12345";

    it(@"should set expected cookie value using device identifier", ^{
        // IDFA is always zero'd on simulator
        NSHTTPCookie *cookie = [_RAnalyticsCookieInjector injectAppToWebTrackingCookieWithDomain:nil
                                                                                deviceIdentifier:deviceID];

        [[cookie.value should] equal:@"rat_uid%3D12345%3Ba_uid%3D00000000-0000-0000-0000-000000000000"];
    });

    it(@"should set cookie path to /", ^{
        NSHTTPCookie *cookie = [_RAnalyticsCookieInjector injectAppToWebTrackingCookieWithDomain:nil
                                                                                deviceIdentifier:deviceID];

        [[cookie.path should] equal:@"/"];
    });

    it(@"should set cookie name to ra_uid", ^{
        NSHTTPCookie *cookie = [_RAnalyticsCookieInjector injectAppToWebTrackingCookieWithDomain:nil
                                                                                deviceIdentifier:deviceID];

        [[cookie.name should] equal:@"ra_uid"];
    });

    it(@"should set cookie samesite to none", ^{
        NSHTTPCookie *cookie = [_RAnalyticsCookieInjector injectAppToWebTrackingCookieWithDomain:nil
                                                                                deviceIdentifier:deviceID];

        if (@available(iOS 13.0, *)) {
            [[cookie.sameSitePolicy should] beNil];
        }
    });

    it(@"should set cookie as secure", ^{
        NSHTTPCookie *cookie = [_RAnalyticsCookieInjector injectAppToWebTrackingCookieWithDomain:nil
                                                                                deviceIdentifier:deviceID];

        [[theValue(cookie.isSecure) should] beTrue];
    });

    context(@"when domain param is nil", ^{
        it(@"should set default .rakuten.co.jp domain on cookie", ^{
            NSHTTPCookie *cookie = [_RAnalyticsCookieInjector injectAppToWebTrackingCookieWithDomain:nil
                                                                                    deviceIdentifier:deviceID];

            [[cookie.domain should] equal:@".rakuten.co.jp"];
        });
    });

    context(@"when domain param is non-nil", ^{
        it(@"should set passed in domain on cookie", ^{
            NSHTTPCookie *cookie = [_RAnalyticsCookieInjector injectAppToWebTrackingCookieWithDomain:@".my-domain.co.jp"
                                                                                    deviceIdentifier:deviceID];

            [[cookie.domain should] equal:@".my-domain.co.jp"];
        });
    });

    it(@"should return nil cookie when device identifier is nil", ^{
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wnonnull"
        NSHTTPCookie *cookie = [_RAnalyticsCookieInjector injectAppToWebTrackingCookieWithDomain:nil
                                                                                deviceIdentifier:nil];
#pragma clang diagnostic pop

        [[cookie should] beNil];
    });

    it(@"should inject cookie into WKWebsiteDataStore httpCookieStore", ^{
        __block BOOL hasCookie = NO;
        __unused NSHTTPCookie *cookie = [_RAnalyticsCookieInjector injectAppToWebTrackingCookieWithDomain:nil
                                                                                         deviceIdentifier:deviceID];

        if (@available(iOS 11.0, *)) {
            WKHTTPCookieStore *store = WKWebsiteDataStore.defaultDataStore.httpCookieStore;

            // [_RAnalyticsCookieInjector injectAppToWebTrackingCookieWithDomain:deviceIdentifier:]
            // is based on [WKHTTPCookieStore setCookie:completionHandler:] that is asynchronous
            dispatch_async(dispatch_get_main_queue(), ^{
                [store getAllCookies:^(NSArray<NSHTTPCookie *> * _Nonnull cookies) {
                    [cookies enumerateObjectsUsingBlock:^(NSHTTPCookie * _Nonnull obj, __unused NSUInteger idx, BOOL * _Nonnull stop) {
                        if ([obj.name isEqualToString:@"ra_uid"]) {
                            hasCookie = YES;
                            *stop = YES;
                        }
                    }];
                }];
            });

            [[expectFutureValue(theValue(hasCookie)) shouldNotEventuallyBeforeTimingOutAfter(1.0)] beFalse];
        }
    });
});

SPEC_END

