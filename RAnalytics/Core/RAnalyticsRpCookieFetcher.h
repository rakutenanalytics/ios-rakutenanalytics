#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface RAnalyticsRpCookieFetcher : NSObject

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
 * @return a cached valid RP cookie.
 *
 */
- (NSHTTPCookie * _Nullable)getRpCookieFromCookieStorage;

@end

NS_ASSUME_NONNULL_END
