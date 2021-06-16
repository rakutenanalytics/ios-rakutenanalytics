#import "RAnalyticsDeviceIdentifier.h"
#import <RDeviceIdentifier/RDeviceIdentifier.h>

@implementation RAnalyticsDeviceIdentifier

NSString * _Nullable RAnalyticsUniqueDeviceIdentifier(void) {
    @try {
        return RDeviceIdentifier.uniqueDeviceIdentifier;
    }
    @catch (NSException *__unused exception) {
        return nil;
    }
}

@end
