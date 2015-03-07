/*
 * © Rakuten, Inc.
 * authors: "Rakuten Mobile SDK Team | SDTD" <prj-rmsdk@mail.rakuten.com>
 */
#import <RSDKAnalytics/RSDKAnalyticsDefines.h>

@class RSDKAnalyticsRecord;

/**
 * Main class of the module.
 *
 * This class handles:
 *
 *  - Enabling or disabling **location tracking** with @ref RSDKAnalyticsManager::locationTrackingEnabled;
 *  - **Spooling** @ref RSDKAnalyticsRecord instances with @ref RSDKAnalyticsManager::spoolRecord:.
 *  - **Gathering system data** that it merges with each record it spools. See the next section.
 *
 * ## Automatically gathered system data
 * The fields below, documented in the [Rakuten Analytics Generic IDL](https://git.dev.rakuten.com/projects/RG/repos/rg/browse/ratGeneric.idl),
 * are automatically merged with the properties of each @ref RSDKAnalyticsRecord that gets spooled:
 *
 *  Field         | Long field name
 *  -------------:|:-------------------------------
 *  `ckp`         | `PERSISTENT_COOKIE`
 *  `cks`         | `SESSION_COOKIE`
 *  `dln`         | `DEVICE_LANGUAGE`
 *  `loc`         | `LOCATION`
 *  `ltm`         | `SCRIPT_START_TIME`
 *  `mbat`        | `BATTERY_USAGE`
 *  `mcn`         | `MOBILE_CARRIER_NAME`
 *  `mnetw`       | `MOBILE_NETWORK_TYPE`
 *  `model`       | `MOBILE_DEVICE_BRAND_MODEL`
 *  `mori`        | `MOBILE_ORIENTATION`
 *  `mos`         | `MOBILE_OS`
 *  `online`      | `ONLINE_STATUS`
 *  `powerstatus` | `BATTERY_CHARGING_STATUS`
 *  `res`         | `RESOLUTION`
 *  `ts1`         | `CLIENT_PROVIDED_TIMESTAMP`
 *  `tzo`         | `TIMEZONE`
 *  `ua`          | `USER_AGENT`
 *  `ver`         | `VERSION`
 *
 * @class RSDKAnalyticsManager RSDKAnalyticsManager.h <RSDKAnalytics/RSDKAnalyticsManager.h>
 */
RMSDK_EXPORT @interface RSDKAnalyticsManager : NSObject

/**
 * Retrieve the shared instance.
 *
 * @return The shared instance.
 */

+ (instancetype)sharedInstance;


/**
 * Spool a record\. It is first saved on-disk, then uploaded asynchronously
 * to the RAT server, on the background queue.
 *
 * @msc
 *   hscale="0.8";
 *
 *   app [label="app", linecolor="transparent", textcolor="transparent"],
 *   RSDKAnalyticsManager [label="Manager"],
 *   db [label="On-disk Database"],
 *   server [label="RAT Server"];
 *
 *   app => RSDKAnalyticsManager [label="spoolRecord:"];
 *   RSDKAnalyticsManager => db [label="enqueue operation"];
 *   RSDKAnalyticsManager >> app [label="OK"];
 *   db => db [label="insert record"];
 *   RSDKAnalyticsManager loop server [label="Poll database periodically"] {
 *     RSDKAnalyticsManager => db [label="fetch records"];
 *     db >> RSDKAnalyticsManager [label="records[]"];
 *     RSDKAnalyticsManager => server [label="async send"];
 *     server >> RSDKAnalyticsManager [label="200 OK"];
 *     RSDKAnalyticsManager => db [label="delete records"];
 *   };
 * @endmsc
 *
 * Developers who wish to monitor the module's network activity can do so
 * by listening to the notifications it sends, respectively @ref RSDKAnalyticsWillUploadNotification,
 * @ref RSDKAnalyticsUploadFailureNotification and @ref RSDKAnalyticsUploadSuccessNotification.
 *
 * @param record  Record to be added to the database.
 */

+ (void)spoolRecord:(RSDKAnalyticsRecord *)record;


/**
 * This is the URL this module uploads records to.
 *
 * @return URL of the server.
 */

+ (NSURL*)endpointAddress;


/**
 * Control whether the SDK should record the device's location or not.
 *
 * This property is set to `NO` by default, which means @ref RSDKAnalyticsManager will
 * not attempt to record the device's location.
 *
 * @warning If the application has not already requested access to the location
 * information, trying to set this property to `YES` has no effect. Please refer
 * to the [Location and Maps Programming Guide](https://developer.apple.com/library/ios/documentation/UserExperience/Conceptual/LocationAwarenessPG/)
 * for more information.
 */

@property (nonatomic,getter=isLocationTrackingEnabled) BOOL locationTrackingEnabled;

@end


/// @name Notifications


/**
 * The SDK sends this notification when it is about to make a request
 * to upload a group of records to RAT servers.
 *
 * `object` is a the JSON payload being uploaded, in its unserialized
 * NSArray form.
 *
 * @ingroup AnalyticsConstants
 */

RMSDK_EXPORT NSString *const RSDKAnalyticsWillUploadNotification;


/**
 * The SDK sends this notification after an upload failed.
 *
 * `object` is a the JSON payload that was being uploaded, in its unserialized
 * NSArray form.
 * `userInfo` contains a NSError instance under the key `NSUnderlyingErrorKey`. Connection
 * errors use the `NSURLErrorDomain` domain. Other errors use @ref RakutenAPIErrorDomain.
 *
 * @ingroup AnalyticsConstants
 */

RMSDK_EXPORT NSString *const RSDKAnalyticsUploadFailureNotification;


/**
 * The SDK sends this notification after an upload succeeded.
 *
 * `object` is a the JSON payload that was being uploaded, in its unserialized
 * `NSArray` form.
 *
 * @ingroup AnalyticsConstants
 */

RMSDK_EXPORT NSString *const RSDKAnalyticsUploadSuccessNotification;
