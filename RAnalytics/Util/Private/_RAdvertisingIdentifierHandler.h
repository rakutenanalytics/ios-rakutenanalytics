NS_ASSUME_NONNULL_BEGIN

@interface _RAdvertisingIdentifierHandler: NSObject

/**
 * Request the advertising identifier.
 * Returned value is not nil if tracking is authorized.
 *
 * Note: returns nil on simulator
 *
 */
+ (NSString * _Nullable)idfa;

/**
 * Wrapper to get the ADSupport framework `advertisingIdentifier` string.
 * Use the `idfa` method above unless you need direct access.
 */
+ (NSString *)advertisingIdentifierUUIDString;

@end

NS_ASSUME_NONNULL_END
