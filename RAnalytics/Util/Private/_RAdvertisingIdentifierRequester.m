#import "_RAdvertisingIdentifierRequester.h"
#import <AdSupport/AdSupport.h>

#pragma clang diagnostic ignored "-Wundeclared-selector"

typedef NS_ENUM(NSUInteger, RTrackingAuthorizationStatus) {
    RTrackingAuthorizationStatusNotDetermined = 0,
    RTrackingAuthorizationStatusRestricted,
    RTrackingAuthorizationStatusDenied,
    RTrackingAuthorizationStatusAuthorized
};

@implementation _RAdvertisingIdentifierRequester

# pragma mark - IDFA Authorization Request

+ (void)requestAuthorization:(void(^)(NSString * _Nullable advertisingIdentifier))completion
{
    if (@available(iOS 14, *)) {
        Class ATTrackingManagerClass = [_RAdvertisingIdentifierRequester ATTrackingManagerClass];
        if (ATTrackingManagerClass
            && [_RAdvertisingIdentifierRequester trackingTransparencyIsNotDetermined]
            && [_RAdvertisingIdentifierRequester userTrackingUsageDescription]) {
            [ATTrackingManagerClass performSelector:@selector(requestTrackingAuthorizationWithCompletionHandler:) withObject:^{
                dispatch_async(dispatch_get_main_queue(), ^{
                   completion([_RAdvertisingIdentifierRequester advertisingIdentifier]);
                });
            }];
            return;
        }
    }
    
    completion([_RAdvertisingIdentifierRequester advertisingIdentifier]);
}

# pragma mark - Tracking Transparency

+ (BOOL)userTrackingUsageDescription
{
    return [[NSBundle mainBundle] infoDictionary][@"NSUserTrackingUsageDescription"];
}

+ (Class)ATTrackingManagerClass
{
    return NSClassFromString(@"ATTrackingManager");
}

+ (BOOL)trackingTransparencyIsNotDetermined
{
    return (NSUInteger)[[_RAdvertisingIdentifierRequester ATTrackingManagerClass] performSelector:@selector(trackingAuthorizationStatus)] == RTrackingAuthorizationStatusNotDetermined/*ATTrackingManagerAuthorizationStatusNotDetermined*/;
}

+ (BOOL)trackingTransparencyIsAuthorized
{
    return (NSUInteger)[[_RAdvertisingIdentifierRequester ATTrackingManagerClass] performSelector:@selector(trackingAuthorizationStatus)] == RTrackingAuthorizationStatusAuthorized/*ATTrackingManagerAuthorizationStatusAuthorized*/;
}

#pragma mark - Advertising Identifier

+ (NSString * _Nullable)advertisingIdentifier
{
    if (![_RAdvertisingIdentifierRequester advertisingIdentifierIsAuthorized])
    {
        return nil;
    }
    
    NSString *idfa = [_RAdvertisingIdentifierRequester advertisingIdentifierUUIDString];
    if (idfa.length && [idfa stringByReplacingOccurrencesOfString:@"[0\\-]"
                                                       withString:@""
                                                          options:NSRegularExpressionSearch
                                                            range:NSMakeRange(0, idfa.length)].length)
    {
        return idfa;
    }
    
    return nil;
}

+ (NSString *)advertisingIdentifierUUIDString
{
    return ASIdentifierManager.sharedManager.advertisingIdentifier.UUIDString;
}

+ (BOOL)advertisingIdentifierIsAuthorized
{
    if (@available(iOS 14, *))
    {
        if (![_RAdvertisingIdentifierRequester ATTrackingManagerClass])
        {
            return NO;
        }
        return [_RAdvertisingIdentifierRequester trackingTransparencyIsAuthorized];
    }
    else
    {
        return ASIdentifierManager.sharedManager.isAdvertisingTrackingEnabled;
    }
}

@end
