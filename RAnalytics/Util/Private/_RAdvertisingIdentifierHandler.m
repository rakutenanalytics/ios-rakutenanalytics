#import "_RAdvertisingIdentifierHandler.h"
#import <AdSupport/AdSupport.h>

#pragma clang diagnostic ignored "-Wundeclared-selector"

@implementation _RAdvertisingIdentifierHandler

# pragma mark - IDFA

+ (NSString * _Nullable)idfa
{
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

@end
