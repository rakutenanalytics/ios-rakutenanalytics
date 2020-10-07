#import "_RAnalyticsCookieInjector.h"
#import "_RAdvertisingIdentifierHandler.h"
#import "RLogger.h"
#import <WebKit/WebKit.h>

@implementation _RAnalyticsCookieInjector
+ (nullable NSHTTPCookie *)injectAppToWebTrackingCookieWithDomain:(nullable NSString *)domain
                                                 deviceIdentifier:(NSString *)deviceIdentifier
{
    if (!deviceIdentifier.length ||
        NSClassFromString(@"WKHTTPCookieStore") == nil) {
        return nil;
    }
    
    NSString *rawValue = [NSString stringWithFormat:@"rat_uid=%@;a_uid=%@",
                          deviceIdentifier,
                          [_RAdvertisingIdentifierHandler advertisingIdentifierUUIDString]];
    NSString *unreserved = @"-._~/?";
    NSMutableCharacterSet *allowed = [NSMutableCharacterSet
                                      alphanumericCharacterSet];
    [allowed addCharactersInString:unreserved];
    NSString *value = [rawValue stringByAddingPercentEncodingWithAllowedCharacters:allowed];
    NSHTTPCookie *trackingCookie = [NSHTTPCookie cookieWithProperties:@{NSHTTPCookieName: @"ra_uid",
                                                                        NSHTTPCookieDomain: domain.length ? domain : @".rakuten.co.jp",
                                                                        NSHTTPCookieValue: value,
                                                                        NSHTTPCookiePath: @"/",
                                                                        NSHTTPCookieSecure: @(YES)
    }];

    // Inject cookie
    if (@available(iOS 11.0, *)) {
        [WKWebsiteDataStore.defaultDataStore.httpCookieStore setCookie:trackingCookie completionHandler:^{
            [RLogger verbose:@"Set cookie %@ on webview", trackingCookie];
        }];
    }
    return trackingCookie;
}
@end
