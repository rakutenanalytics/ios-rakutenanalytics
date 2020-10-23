
#import "RAnalyticsPushTrackingUtility.h"
#import "_NSString+Encryption.h"

NSString *const RPushAppGroupIdentifierPlistKey = @"RPushAppGroupIdentifier";
NSString *const RPushOpenCountSentUserDefaultKey = @"com.analytics.push.sentOpenCount";

@implementation RAnalyticsPushTrackingUtility

+ (nullable NSString*)trackingIdentifierFromPayload:(NSDictionary*)payload
{
    NSDictionary *aps = payload[@"aps"];
    NSString *rid = payload[@"rid"];
    NSString *nid = payload[@"notification_id"];
    
    // This ordering is important
    if ([self _isSilentPushNotification:aps])
    {
        return nil;
    }
    else if ([rid isKindOfClass:NSString.class] &&
               rid.length > 0)
    {
        return [NSString stringWithFormat:@"rid:%@", rid];
    }
    else if ([nid isKindOfClass:NSString.class] &&
             nid.length > 0)
    {
        return [NSString stringWithFormat:@"nid:%@", nid];
    }
    else if ([aps isKindOfClass:NSDictionary.class] &&
             aps[@"alert"])
    {
        NSString* _Nullable encryptedMessage = [self _getQualifyingEncryptedMessage:aps];
        if(encryptedMessage)
        {
            return [NSString stringWithFormat:@"msg:%@", encryptedMessage];
        }
    }
    
    return nil;
}

+ (BOOL)analyticsEventHasBeenSentWith:(nullable NSString*)trackingIdentifier
{
    NSString* appGroupId = (NSString *)[[NSBundle mainBundle] objectForInfoDictionaryKey:RPushAppGroupIdentifierPlistKey];
    if (!trackingIdentifier || !appGroupId)
    {
        return false;
    }
    
    NSUserDefaults* userDefaults = [NSUserDefaults.new initWithSuiteName:appGroupId];
    if (!userDefaults)
    {
        return false;
    }
    
    NSDictionary* domain = [userDefaults dictionaryForKey:RPushOpenCountSentUserDefaultKey];
    
    if (!domain ||
        ![domain[trackingIdentifier] isKindOfClass:NSNumber.class])
    {
        return false;
    }
    return [domain[trackingIdentifier] boolValue];
}

#pragma mark - Private Methods

+ (BOOL)_isSilentPushNotification:(NSDictionary*)apsPayload
{
    NSNumber *contentAvailable = apsPayload[@"content-available"];
     
    // a push notification is a silent push notification if content available is true and
    // the alert part is not in the payload
    if ([contentAvailable isKindOfClass:NSNumber.class] &&
        !apsPayload[@"alert"])
    {
        return contentAvailable.boolValue;
    }
    return NO;
}

+ (nullable NSString*)_getQualifyingEncryptedMessage:(NSDictionary*)aps
{
    /*
     * Otherwise, fallback to .aps.alert if that's a string, or, if that's
     * a dictionary, for either .aps.alert.body or .aps.alert.title
     */
    NSString *msg = aps[@"alert"];
    if ([msg isKindOfClass:NSDictionary.class])
    {
        NSDictionary *content = (NSDictionary*)msg;
        msg = content[@"body"] ?: content[@"title"];
    }
    
    if (msg.length == 0) { return nil; }
    
    msg = [msg rat_encrypt];
    
    return msg;
}

@end
