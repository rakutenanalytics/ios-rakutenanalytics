#import <RAnalytics/RAnalyticsDefines.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * Interface for any class to declare an endpoint URL property.
 *
 * @protocol RAnalyticsEndpointSettable RAnalyticsEndpointSettable.h <RAnalytics/RAnalyticsEndpointSettable.h>
 */
RSDKA_EXPORT NS_SWIFT_NAME(EndpointSettable) @protocol RAnalyticsEndpointSettable <NSObject>

/**
 * Property for setting the endpoint URL at runtime.
 */
@property (nonatomic, copy) NSURL * _Nullable endpointURL;

@end

NS_ASSUME_NONNULL_END
