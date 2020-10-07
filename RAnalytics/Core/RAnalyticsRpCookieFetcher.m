#import "RAnalyticsRpCookieFetcher.h"
#import <RAnalytics/_RAnalyticsHelpers.h>
#import <RLogger/RLogger.h>

static const NSTimeInterval  RATRpCookieRequestInitialRetryInterval = 10u; //10s as initial timeout request
static const NSUInteger      RATRpCookieRequestBackOffMultiplier    = 2u; // Setting multiplier as 2
static const NSUInteger      RATRpCookieRequestMaximumTimeOut       = 600u; // 10 mins as the time out

@interface RAnalyticsRpCookieFetcher()
/*
 * session is used to retrieve the cookie details on initialize
 */
@property (nonatomic) NSTimeInterval   RATRpCookieRequestRetryInterval;
@property (nonatomic) dispatch_queue_t rpCookieQueue;
@property (nonatomic) NSUInteger       rpCookieRequestRetryCount;
@property (strong, nonatomic) NSHTTPCookieStorage *cookieStorage;
@end

@implementation RAnalyticsRpCookieFetcher

- (instancetype)initWithCookieStorage:(NSHTTPCookieStorage *)cookieStorage
{
    self = [super init];
    if (self) {
        _RATRpCookieRequestRetryInterval = RATRpCookieRequestInitialRetryInterval;
        _rpCookieRequestRetryCount = 0;
        _rpCookieQueue = dispatch_queue_create("com.rakuten.tech.analytics.rpcookie", DISPATCH_QUEUE_SERIAL);
        _cookieStorage = cookieStorage;
    }
    return self;
}

- (void)getRpCookieCompletionHandler:(void (^)(NSHTTPCookie * _Nullable cookie, NSError * _Nullable error))completionHandler
{
    __block NSHTTPCookie *rpCookie = nil;
    NSDictionary *userInfo = @{NSLocalizedDescriptionKey: @"Cannot get RATRp cookie from RAT Server/CookieStorage",
                               NSLocalizedFailureReasonErrorKey: @"Invalid/NoCookie details available"};
    NSError *error = [NSError errorWithDomain:NSURLErrorDomain
                                         code:NSURLErrorUnknown
                                     userInfo:userInfo];
    
    rpCookie = [self getRpCookieFromCookieStorage];
    
    if(rpCookie == nil)
    {
        [self getRpCookieFromRATCompletionHandler:^(NSHTTPCookie *cookie) {
            rpCookie = cookie;
            completionHandler(rpCookie, rpCookie ? nil : error);
        }];
    }
    else
    {
        completionHandler(rpCookie, nil);
    }
}

- (NSHTTPCookie * _Nullable)getRpCookieFromCookieStorage
{
    NSArray *cookies = [_cookieStorage cookiesForURL:_RAnalyticsEndpointAddress()];
    NSHTTPCookie *rpCookie = nil;
    
    for(NSHTTPCookie *cookie in cookies)
    {
        if([cookie.name isEqualToString:@"Rp"] && [cookie.expiresDate timeIntervalSinceNow] > 0)
        {
            rpCookie = cookie;
            break;
        }
    }
    return rpCookie;
}

- (NSHTTPCookie * _Nullable)getRpCookieFromHttpResponse:(NSHTTPURLResponse *)httpResponse
{
    NSHTTPCookie *rpCookie = nil;
    NSArray<NSHTTPCookie *> *cookies = [NSHTTPCookie cookiesWithResponseHeaderFields:httpResponse.allHeaderFields
                                                                              forURL:_RAnalyticsEndpointAddress()];

    for (NSHTTPCookie *cookie in cookies) {
        if ([cookie.name isEqualToString:@"Rp"]) {
            rpCookie = cookie;
            break;
        }
    }
    return rpCookie;
}

- (void)getRpCookieFromRATCompletionHandler:(void (^)(NSHTTPCookie * _Nullable cookie))completionHandler
{
    __weak typeof (self) weakSelf = self;

    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:_RAnalyticsEndpointAddress()];
    request.HTTPShouldHandleCookies = _RAnalyticsUseDefaultSharedCookieStorage();

    [[[NSURLSession sharedSession] dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error)
    {
        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
        if (error || httpResponse.statusCode != 200)
        {
            // If failed retry fetch
            weakSelf.rpCookieRequestRetryCount++;

            weakSelf.RATRpCookieRequestRetryInterval = MIN(RATRpCookieRequestMaximumTimeOut, pow(RATRpCookieRequestBackOffMultiplier, weakSelf.rpCookieRequestRetryCount) * RATRpCookieRequestInitialRetryInterval);

            // Retry till the RATRpCookieRequestMaximumTimeOut
            if (weakSelf.RATRpCookieRequestRetryInterval < RATRpCookieRequestMaximumTimeOut)
            {
                dispatch_time_t delay = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(weakSelf.RATRpCookieRequestRetryInterval * NSEC_PER_SEC));
                dispatch_after(delay, weakSelf.rpCookieQueue, ^(void){
                    [weakSelf fetchRATRpCookie];
                });
            }
        }

        weakSelf.rpCookieRequestRetryCount = 0;
        NSHTTPCookie *cookie = request.HTTPShouldHandleCookies ? [weakSelf getRpCookieFromCookieStorage] : [weakSelf getRpCookieFromHttpResponse:httpResponse];
        completionHandler(cookie);
    }] resume];
}

- (void)fetchRATRpCookie
{
    [self getRpCookieCompletionHandler:^(NSHTTPCookie * _Nullable cookie, NSError * _Nullable error)
     {
         if (error)
         {
             [_RLogger error:@"%@", error];
         }
     }];
}

@end
