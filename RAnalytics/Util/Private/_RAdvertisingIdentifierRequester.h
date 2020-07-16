#import <AdSupport/AdSupport.h>

NS_ASSUME_NONNULL_BEGIN

@interface _RAdvertisingIdentifierRequester: NSObject

// NOTE: AppTrackingTransparency framework has to be embedded in the app built with iOS SDK >= 14.0

/**
 * Request user authorization to access app-related data for tracking the user or the device if iOS SDK version >= 14.0.
 * Otherwise returned success value is true.
 *
 */
+ (void)requestAuthorization:(void(^)(bool success))completion;

@end

NS_ASSUME_NONNULL_END
