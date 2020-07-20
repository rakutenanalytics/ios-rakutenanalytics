NS_ASSUME_NONNULL_BEGIN

@interface _RAdvertisingIdentifierRequester: NSObject

// NOTE: AppTrackingTransparency framework has to be embedded in the app built with iOS SDK >= 14.0

/**
 * Request user authorization to access advertising identifier.
 * Returned advertisingIdentifier value is not nil if tracking is authorized.
 *
 */
+ (void)requestAuthorization:(void(^)(NSString * _Nullable advertisingIdentifier))completion;

@end

NS_ASSUME_NONNULL_END
