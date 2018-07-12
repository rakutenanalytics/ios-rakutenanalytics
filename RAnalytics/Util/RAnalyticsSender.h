#import <RAnalytics/RAnalyticsDefines.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * A sender saves the data to the database firstly then schedule to send the data in the database to the server.
 * The data will be removed from the database if the sender upload them to the server successfully.
 *
 * @attention By default, the sender will try to send the data immediately after the data are saved to the database. To configure the upload time interval for the sender, please use AnalyticsSender::setBatchingDelayBlock: method.
 *
 * @par Swift 3
 * This class is exposed as **AnalyticsSender**.
 *
 * @class RAnalyticsSender RAnalyticsSender.h <RAnalytics/RAnalyticsSender.h>
 */
RSDKA_EXPORT RSDKA_SWIFT_NAME(AnalyticsSender) @interface RAnalyticsSender : NSObject

/**
 *  Initialize a new sender
 *
 *  @param endpoint              `[Required]` The endpoint to use.
 *  @param databaseName          `[Required]` The name of the database to create.
 *  @param tableName             `[Required]` The name of the table in the database where the sender saves the data.
 *
 *  @return Initialized instance, or `nil` if initialization failed.
 */
- (instancetype)initWithEndpoint:(NSURL *)endpoint databaseName:(NSString *)databaseName databaseTableName:(NSString *)tableName;

/**
 * Send the data which is generated from the JSON object to the server.
 *
 * @param obj   The object from which to generate JSON data. Must not be nil.
 */
- (void)sendJSONOject:(id)obj;

/**
 * Method for configuring the batching delay.
 *
 * @param batchingDelayBlock   The block returns delivery delay in seconds. Value should be >= 0 and <= 60.
 */
- (void)setBatchingDelayBlock:(BatchingDelayBlock)batchingDelayBlock;
@end

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
 * `object` is a the JSON payload that was being uploaded, in its unserialized
 * NSArray form.
 * `userInfo` contains a `NSError` instance under the key `NSUnderlyingErrorKey`, that uses the `NSURLErrorDomain` domain.
 *
 * @ingroup AnalyticsConstants
 */
RSDKA_EXPORT NSString *const RAnalyticsUploadFailureNotification;

/**
 * The RAnalyticsSender instance sends this notification after an upload succeeded.
 *
 * `object` is a the JSON payload that was being uploaded, in its unserialized
 * `NSArray` form.
 *
 * @ingroup AnalyticsConstants
 */
RSDKA_EXPORT NSString *const RAnalyticsUploadSuccessNotification;

NS_ASSUME_NONNULL_END
