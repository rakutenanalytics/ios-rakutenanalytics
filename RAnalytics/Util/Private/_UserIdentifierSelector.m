#import "_UserIdentifierSelector.h"
#import <RAnalytics/RAnalytics-Swift.h>

NSString* const _RATTrackingIdentifierNoLoginFound = @"NO_LOGIN_FOUND";

@implementation _UserIdentifierSelector

+ (NSString * _Nullable)selectedTrackingIdentifier
{
    NSString *selectedTrackingIdentifier = RAnalyticsManager.sharedInstance.externalCollector.userIdentifier;
    if (!selectedTrackingIdentifier)
    {
        selectedTrackingIdentifier = RAnalyticsManager.sharedInstance.externalCollector.trackingIdentifier;
    }
    if (!selectedTrackingIdentifier)
    {
        selectedTrackingIdentifier = _RATTrackingIdentifierNoLoginFound;
    }
    return selectedTrackingIdentifier;
}

@end
