#import "_RAdvertisingIdentifierHandler.h"
#import <AdSupport/AdSupport.h>

#pragma clang diagnostic ignored "-Wundeclared-selector"

// ATTrackingManagerAuthorizationStatus Mapping
typedef NS_ENUM(NSUInteger, RTrackingAuthorizationStatus) {
    RTrackingAuthorizationStatusNotDetermined = 0,
    RTrackingAuthorizationStatusRestricted,
    RTrackingAuthorizationStatusDenied,
    RTrackingAuthorizationStatusAuthorized
};

@implementation _RAdvertisingIdentifierHandler

# pragma mark - IDFA

+ (NSString * _Nullable)idfa
{
    return [_RAdvertisingIdentifierHandler advertisingIdentifier];
}

# pragma mark - Tracking Transparency

+ (Class)ATTrackingManagerClass
{
    return NSClassFromString(@"ATTrackingManager");
}

+ (BOOL)trackingTransparencyIsAuthorized
{
    return (NSUInteger)[[_RAdvertisingIdentifierHandler ATTrackingManagerClass] performSelector:@selector(trackingAuthorizationStatus)] == RTrackingAuthorizationStatusAuthorized/*ATTrackingManagerAuthorizationStatusAuthorized*/;
}

#pragma mark - Advertising Identifier

+ (NSString * _Nullable)advertisingIdentifier
{
    if (![_RAdvertisingIdentifierHandler advertisingIdentifierIsAuthorized])
    {
        return nil;
    }
    
    NSString *idfa = [_RAdvertisingIdentifierHandler advertisingIdentifierUUIDString];
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
        if (![_RAdvertisingIdentifierHandler ATTrackingManagerClass])
        {
            return NO;
        }
        return [_RAdvertisingIdentifierHandler trackingTransparencyIsAuthorized];
    }
    else
    {
        return ASIdentifierManager.sharedManager.isAdvertisingTrackingEnabled;
    }
}

@end
