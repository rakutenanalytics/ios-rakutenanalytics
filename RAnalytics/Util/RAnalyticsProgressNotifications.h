#import <RAnalytics/RAnalyticsDefines.h>

NS_ASSUME_NONNULL_BEGIN

/// @name Notifications

/**
 * The RAnalyticsSender instance sends this notification when it is about to make a request to upload a group of records to the servers.
 * `NSNotification.object` is the JSON payload being uploaded, in its unserialized `NSArray` form.
 *
 * @ingroup AnalyticsConstants
 */
RSDKA_EXPORT NSString *const RAnalyticsWillUploadNotification;

/**
 * The RAnalyticsSender instance sends this notification after an upload failed.
 *
 * `object` is the JSON payload that was being uploaded, in its unserialized
 * NSArray form.
 * `userInfo` contains a `NSError` instance under the key `NSUnderlyingErrorKey`, that uses the `NSURLErrorDomain` domain.
 *
 * @ingroup AnalyticsConstants
 */
RSDKA_EXPORT NSString *const RAnalyticsUploadFailureNotification;

/**
 * The RAnalyticsSender instance sends this notification after an upload succeeded.
 *
 * `object` is the JSON payload that was being uploaded, in its unserialized
 * `NSArray` form.
 *
 * @ingroup AnalyticsConstants
 */
RSDKA_EXPORT NSString *const RAnalyticsUploadSuccessNotification;

NS_ASSUME_NONNULL_END
