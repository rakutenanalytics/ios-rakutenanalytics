#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface _RAnalyticsCookieInjector : NSObject

/**
 *  Inject app-to-web tracking cookie
 *
 * @param domain  Domain to set on cookie, if nil default domain will be used
 * @param deviceIdentifier Device identifier string
 *
 * completionHandler:  Injected cookie or nil if cookie cannot be created or injected
 */
+ (void)injectAppToWebTrackingCookieWithDomain:(nullable NSString *)domain
                              deviceIdentifier:(NSString *)deviceIdentifier
                             completionHandler:(nullable void(^)(NSHTTPCookie * _Nullable))completionHandler;
@end

NS_ASSUME_NONNULL_END
