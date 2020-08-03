#import "_UserIdentifierSelector.h"
#import "_RAnalyticsExternalCollector.h"

NSString* const _RATTrackingIdentifierNoLoginFound = @"NO_LOGIN_FOUND";

@implementation _UserIdentifierSelector

+ (NSString * _Nullable)selectedTrackingIdentifier
{
    NSString *selectedTrackingIdentifier = _RAnalyticsExternalCollector.sharedInstance.userIdentifier;
    if (!selectedTrackingIdentifier)
    {
        selectedTrackingIdentifier = _RAnalyticsExternalCollector.sharedInstance.trackingIdentifier;
    }
    if (!selectedTrackingIdentifier)
    {
        selectedTrackingIdentifier = _RATTrackingIdentifierNoLoginFound;
    }
    return selectedTrackingIdentifier;
}

@end
