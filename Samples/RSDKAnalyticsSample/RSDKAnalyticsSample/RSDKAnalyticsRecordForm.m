#import "RSDKAnalyticsRecordForm.h"
#import <RAnalytics/RAnalytics.h>

@implementation RSDKAnalyticsRecordForm

- (instancetype)init
{
    if ((self = [super init]))
    {
        self.trackIDFA = YES;
        self.trackLocation = YES;
        self.useStaging = YES;

        NSNumber *plistObj = [NSBundle.mainBundle objectForInfoDictionaryKey:@"RATAccountIdentifier"];
        int64_t acc = plistObj.longLongValue; // int64_t is typedef'd long long
        self.accountId = acc;

        plistObj = [NSBundle.mainBundle objectForInfoDictionaryKey:@"RATAppIdentifier"];
        int64_t aid = plistObj.longLongValue;
        self.serviceId = aid;
    }
    return self;
}

#pragma mark - Fields

- (id)trackIDFAField
{
    return @{FXFormFieldAction: @"trackIDFAChanged:"};
}

- (id)trackLocationField
{
    return @{FXFormFieldAction: @"trackLocationChanged:"};
}

- (id)useStagingField
{
    return @{FXFormFieldAction: @"useStagingChanged:"};
}

- (id)accountIdField
{
    return @{FXFormFieldAction: @"accountIdFieldChanged:"};
}

- (id)serviceIdField
{
    return @{FXFormFieldAction: @"serviceIdFieldChanged:"};
}

@end
