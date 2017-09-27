/*
 * © Rakuten, Inc.
 * authors: "Rakuten Ecosystem Mobile" <ecosystem-mobile@mail.rakuten.com>
 */
#import <RAnalyticsBroadcast/RAnalyticsBroadcast.h>

@implementation RABEventBroadcaster

+ (void)sendEventName:(NSString *)name dataObject:(NSDictionary<NSString *, id> * __nullable)object
{
    NSParameterAssert(name);
    
    NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
    parameters[@"eventName"] = name;
    
    if ([object isKindOfClass:NSDictionary.class]) parameters[@"eventData"] = object.copy;

    [NSNotificationCenter.defaultCenter postNotificationName:@"com.rakuten.esd.sdk.events.custom" object:parameters];
}

@end
