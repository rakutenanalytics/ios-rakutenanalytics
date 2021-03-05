#import <Foundation/Foundation.h>
#import <RAnalytics/RAnalyticsEndpointSettable.h>

NS_ASSUME_NONNULL_BEGIN

@interface RAnalyticsRpCookieFetcher : NSObject <RAnalyticsEndpointSettable>

/**
 * Create a new RP Cookie Fetcher object.
 *
 * @param cookieStorage  Where the cookie will be set.
 *
 * @return A newly-initialized RP Cookie Fetcher.
 */
- (instancetype)initWithCookieStorage:(NSHTTPCookieStorage *)cookieStorage;

- (instancetype)init NS_UNAVAILABLE;

/**
 * Will pass valid Rp cookie to completionHandler as soon as it is available.
 *
 * If a valid cookie is cached it will be returned immediately. Otherwise a new cookie will be retrieved
 * from RAT, which might take time or be delayed depending on network connectivity.
 *
 * @param completionHandler  Returns valid cookie or nil cookie and an error in case of failure
 */
- (void)getRpCookieCompletionHandler:(void (^)(NSHTTPCookie * _Nullable cookie, NSError * _Nullable error))completionHandler;

/**
 *
 * @return A cached valid RP cookie.
 *
 */
- (NSHTTPCookie * _Nullable)getRpCookieFromCookieStorage;

@end

NS_ASSUME_NONNULL_END
