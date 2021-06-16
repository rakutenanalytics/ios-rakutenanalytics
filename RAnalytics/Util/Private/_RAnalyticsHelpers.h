#import <RAnalytics/RAnalyticsDefines.h>
#import <UIKit/UIApplication.h>

RSDKA_EXPORT NSString *const _RATEventPrefix;
RSDKA_EXPORT NSString *const _RATETypeParameter;
RSDKA_EXPORT NSString *const _RATGenericEventName;

RSDKA_EXPORT NSURL *_RAnalyticsEndpointAddress(void);
RSDKA_EXPORT BOOL _RAnalyticsUseDefaultSharedCookieStorage(void);
RSDKA_EXPORT BOOL _RAnalyticsIsAppleClass(Class cls);
RSDKA_EXPORT UIApplication *_RAnalyticsSharedApplication(void);
