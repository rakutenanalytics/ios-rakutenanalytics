#import "_UserIdentifierSelector.h"
#import "_RAnalyticsExternalCollector.h"

@implementation _UserIdentifierSelector

+ (NSString * _Nullable)selectedTrackingIdentifier
{
    NSString *selectedTrackingIdentifier = _RAnalyticsExternalCollector.sharedInstance.userIdentifier;
    if (!selectedTrackingIdentifier) {
        selectedTrackingIdentifier = _RAnalyticsExternalCollector.sharedInstance.trackingIdentifier;
    }
    return selectedTrackingIdentifier;
}

@end
