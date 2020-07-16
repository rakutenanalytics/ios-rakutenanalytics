#import "_RAdvertisingIdentifierRequester.h"

#pragma clang diagnostic ignored "-Wundeclared-selector"

@implementation _RAdvertisingIdentifierRequester

+ (void)requestAuthorization:(void(^)(bool success))completion
{
    if (@available(iOS 14, *)) {
        Class ATTrackingManagerClass = NSClassFromString(@"ATTrackingManager");
        
        if ((int)[ATTrackingManagerClass performSelector:@selector(trackingAuthorizationStatus)] != 0/*ATTrackingManagerAuthorizationStatusNotDetermined*/)
        {
            completion([_RAdvertisingIdentifierRequester advertisingIdentifierIsAuthorized]);
            return;
        }
        
        [ATTrackingManagerClass performSelector:@selector(requestTrackingAuthorizationWithCompletionHandler:) withObject:^{
            dispatch_async(dispatch_get_main_queue(), ^{
               completion([_RAdvertisingIdentifierRequester advertisingIdentifierIsAuthorized]);
            });
        }];
        
    } else {
        completion([_RAdvertisingIdentifierRequester advertisingIdentifierIsAuthorized]);
    }
}

+ (BOOL)advertisingIdentifierIsAuthorized
{
    if (@available(iOS 14, *))
    {
        Class ATTrackingManagerClass = NSClassFromString(@"ATTrackingManager");
        return (int)[ATTrackingManagerClass performSelector:@selector(trackingAuthorizationStatus)] == 3/*ATTrackingManagerAuthorizationStatusAuthorized*/;
    }
    else
    {
        return ASIdentifierManager.sharedManager.isAdvertisingTrackingEnabled;
    }
}

@end
