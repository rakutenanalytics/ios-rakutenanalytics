#import "_RAnalyticsCookieInjector.h"
#import "_RAdvertisingIdentifierHandler.h"
#import "RLogger.h"
#import <WebKit/WebKit.h>

static NSString *const RAnalyticsCookieName = @"ra_uid";
static char *const RAnalyticsCookiesDeletingQueue = "com.analytics.cookies.deleting.queue";

@implementation _RAnalyticsCookieInjector
+ (void)injectAppToWebTrackingCookieWithDomain:(nullable NSString *)domain
                              deviceIdentifier:(NSString *)deviceIdentifier
                             completionHandler:(nullable void(^)(NSHTTPCookie * _Nullable))completionHandler
{
    if (!deviceIdentifier.length ||
        NSClassFromString(@"WKHTTPCookieStore") == nil) {
        if (completionHandler) { completionHandler(nil); }
        return;
    }
    
    NSString *rawValue = [NSString stringWithFormat:@"rat_uid=%@;a_uid=%@",
                          deviceIdentifier,
                          [_RAdvertisingIdentifierHandler advertisingIdentifierUUIDString]];
    NSString *unreserved = @"-._~/?";
    NSMutableCharacterSet *allowed = [NSMutableCharacterSet
                                      alphanumericCharacterSet];
    [allowed addCharactersInString:unreserved];
    NSString *value = [rawValue stringByAddingPercentEncodingWithAllowedCharacters:allowed];
    NSHTTPCookie *trackingCookie = [NSHTTPCookie cookieWithProperties:@{NSHTTPCookieName: RAnalyticsCookieName,
                                                                        NSHTTPCookieDomain: domain.length ? domain : @".rakuten.co.jp",
                                                                        NSHTTPCookieValue: value,
                                                                        NSHTTPCookiePath: @"/",
                                                                        NSHTTPCookieSecure: @(YES)
    }];

    // Inject cookie
    if (@available(iOS 11.0, *)) {
        [WKWebsiteDataStore.defaultDataStore.httpCookieStore getAllCookies:^(NSArray<NSHTTPCookie *> * _Nonnull cookies) {
            [_RAnalyticsCookieInjector deleteCookies:cookies forName:RAnalyticsCookieName completionHandler:^{
                [_RAnalyticsCookieInjector storeCookie:trackingCookie completionHandler:^{
                    if (completionHandler) { completionHandler(trackingCookie); }
                }];
            }];
        }];
    }
}

// Check if a cookie with the same name already exists.
// If a cookie with the same name is found, delete it.
+ (void)deleteCookies:(NSArray *)cookies
              forName:(NSString *)cookieName
    completionHandler:(nullable void(^)(void))completionHandler API_AVAILABLE(ios(11.0))
{
    NSMutableArray *cookiesToDelete = nil;

    if (cookies.count > 0) {
        cookiesToDelete = [NSMutableArray array];
        [cookies enumerateObjectsUsingBlock:^(NSHTTPCookie * _Nonnull aCookie, __unused NSUInteger idx, BOOL * _Nonnull stop) {
            if ([aCookie.name isEqualToString:cookieName]) {
                [cookiesToDelete addObject:aCookie];
            }
        }];
    }

    if (cookiesToDelete && cookiesToDelete.count > 0) {
        dispatch_group_t group = dispatch_group_create();
        dispatch_queue_t queue = dispatch_queue_create(RAnalyticsCookiesDeletingQueue,  DISPATCH_QUEUE_PRIORITY_DEFAULT);
        
        [cookiesToDelete enumerateObjectsUsingBlock:^(NSHTTPCookie * _Nonnull aCookie, NSUInteger idx, BOOL * _Nonnull stop) {
            dispatch_group_enter(group);
            // deleteCookie is an asynchronous method
            [WKWebsiteDataStore.defaultDataStore.httpCookieStore deleteCookie:aCookie completionHandler:^{
                [RLogger verbose:@"Delete cookie %@ on webview", aCookie];
                dispatch_group_leave(group);
            }];
        }];
        dispatch_group_notify(group, queue, ^{
            dispatch_async(dispatch_get_main_queue(), ^{
                completionHandler();
            });
        });

    } else {
        completionHandler();
    }
}

+ (void)storeCookie:(NSHTTPCookie *)cookieToStore completionHandler:(nullable void(^)(void))completionHandler API_AVAILABLE(ios(11.0))
{
    [WKWebsiteDataStore.defaultDataStore.httpCookieStore setCookie:cookieToStore completionHandler:^{
        [RLogger verbose:@"Set cookie %@ on webview", cookieToStore];
        completionHandler();
    }];
}

@end
