#import <RAnalytics/RAnalytics.h>
#import "_RAnalyticsHelpers.h"
#import "_RAnalyticsCoreHelpers.h"
#import "RAnalyticsSender.h"
#import "_SDKTracker.h"

NSString* const _SDKTableName = @"RAKUTEN_ANALYTICS_SDK_TABLE";
NSString* const _SDKDatabaseName = @"RAnalyticsSDKTracker.db";

@interface _SDKTracker ()
@property (nonatomic) RAnalyticsSender *sender;
@end

@implementation _SDKTracker

+ (instancetype)sharedInstance
{
    static _SDKTracker *instance = nil;
    static dispatch_once_t sdkTrackerOnceToken;
    dispatch_once(&sdkTrackerOnceToken, ^{
        instance = [[_SDKTracker alloc] initInstance];
    });
    return instance;
}

- (instancetype)init
{
    [self doesNotRecognizeSelector:_cmd];
    __builtin_unreachable();
}

- (instancetype)initInstance
{
    if (self = [super init])
    {
        // create a sender.
        _sender = [[RAnalyticsSender alloc] initWithEndpoint:_RAnalyticsEndpointAddress()
                                                databaseName:_SDKDatabaseName
                                           databaseTableName:_SDKTableName];
        [_sender setBatchingDelayBlock:^NSTimeInterval{
            return 60.0;
        }]; // default is 1 minute.
    }
    return self;
}

- (BOOL)processEvent:(nonnull RAnalyticsEvent *)event state:(nonnull RAnalyticsState *)state
{
    NSString *eventName = event.name;
    // SDKTracker will only react to rem_install event.
    if (![eventName isEqualToString:RAnalyticsInstallEventName]) return NO;

    NSMutableDictionary *payload = NSMutableDictionary.new;
    NSMutableDictionary *extra   = NSMutableDictionary.new;

    payload[@"acc"] = @(477);
    payload[@"aid"] = @(1);

    NSString *etype = [@"_rem_internal" stringByAppendingString:[eventName substringFromIndex:@"_rem".length]];
    payload[@"etype"] = etype;

    NSDictionary *appAndSDKDict = _RAnalyticsApplicationInfoAndSDKComponents();
    NSDictionary *appInfo = appAndSDKDict[_RAnalyticsAppInfoKey];
    NSDictionary *sdkInfo = appAndSDKDict[_RAnalyticsSDKInfoKey];

    if (sdkInfo.count)
    {
        extra[@"sdk_info"] = [NSString.alloc initWithData:[NSJSONSerialization dataWithJSONObject:sdkInfo options:0 error:0] encoding:NSUTF8StringEncoding];
    }

    if (appInfo.count)
    {
        extra[@"app_info"] = [NSString.alloc initWithData:[NSJSONSerialization dataWithJSONObject:appInfo options:0 error:0] encoding:NSUTF8StringEncoding];
    }

    // If the event already had a 'cp' field, those values take precedence
    if (payload[@"cp"])
    {
        [extra addEntriesFromDictionary:payload[@"cp"]];
    }

    payload[@"cp"] = extra;
    [payload addEntriesFromDictionary:_RAnalyticsSharedPayload(state)];

    [_sender sendJSONOject:payload];
    return YES;
}
@end
