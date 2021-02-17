#import "_RAnalyticsCoreHelpers.h"
#import "_RAnalyticsHelpers.h"
#import "SwiftHeader.h"

NSDictionary *_RAnalyticsSharedPayload(RAnalyticsState * state)
{
    return [CoreHelpers sharedPayloadFor:state];
}

NSDictionary *_RAnalyticsApplicationInfoAndSDKComponents(void)
{
    return CoreHelpers.applicationInfo;
}
