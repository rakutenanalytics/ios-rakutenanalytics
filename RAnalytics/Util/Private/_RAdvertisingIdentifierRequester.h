NS_ASSUME_NONNULL_BEGIN

@interface _RAdvertisingIdentifierRequester: NSObject

/**
 * Request the advertising identifier.
 * Returned advertisingIdentifier value is not nil if tracking is authorized.
 *
 */
+ (void)requestAdvertisingIdentifier:(void(^)(NSString * _Nullable advertisingIdentifier))completion;

@end

NS_ASSUME_NONNULL_END
