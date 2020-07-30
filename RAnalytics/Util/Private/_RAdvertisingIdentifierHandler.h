NS_ASSUME_NONNULL_BEGIN

@interface _RAdvertisingIdentifierHandler: NSObject

/**
 * Request the advertising identifier.
 * Returned value is not nil if tracking is authorized.
 *
 */
+ (NSString * _Nullable)idfa;

@end

NS_ASSUME_NONNULL_END
