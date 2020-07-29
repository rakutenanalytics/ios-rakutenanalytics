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

+ (void)requestAdvertisingIdentifier:(void(^)(NSString * _Nullable advertisingIdentifier))completion
{
    completion([_RAdvertisingIdentifierRequester advertisingIdentifier]);
}

# pragma mark - Tracking Transparency

+ (Class)ATTrackingManagerClass
{
    return NSClassFromString(@"ATTrackingManager");
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
