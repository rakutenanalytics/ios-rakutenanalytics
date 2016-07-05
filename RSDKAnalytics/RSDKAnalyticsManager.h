/*
 * © Rakuten, Inc.
 * authors: "Rakuten Ecosystem Mobile" <ecosystem-mobile@mail.rakuten.com>
 */
#import <RSDKAnalytics/RSDKAnalyticsDefines.h>

NS_ASSUME_NONNULL_BEGIN

@class RSDKAnalyticsRecord;

/**
 * Main class of the module.
 *
 * This class handles:
 *
 *  - Enabling or disabling **location tracking** with #shouldTrackLastKnownLocation;
 *  - Enabling or disabling **[advertising identifier (IDFA)](https://developer.apple.com/reference/adsupport/asidentifiermanager) tracking** with #shouldTrackAdvertisingIdentifier.
 *  - **Spooling** @ref RSDKAnalyticsRecord instances with @ref RSDKAnalyticsManager::spoolRecord:.
 *  - **Gathering system data** that it merges with each record it spools. See the next section.
 *
 * ## Automatically gathered system data
 * The fields below, documented in the [Rakuten Analytics Generic IDL](https://git.rakuten-it.com/projects/RG/repos/rg/browse/ratGeneric.idl),
 * are automatically merged with the properties of each @ref RSDKAnalyticsRecord that gets spooled:
 *
 *  Field         | Long field name
 *  -------------:|:-------------------------------
 *  `app_name`    | `APPLICATION_NAME`
 *  `app_ver`     | `APPLICATION_VERSION`
 *  `ckp`         | `PERSISTENT_COOKIE`
 *  `cka`         | |
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
RSDKA_EXPORT @interface RSDKAnalyticsManager : NSObject

/**
 * Retrieve the shared instance.
 *
 * @note **Swift 3+:** This method is now called `shared()`.
 *
 * @return The shared instance.
 */

+ (instancetype)sharedInstance RSDKA_SWIFT3_NAME(shared());

/**
 * Spool a record\. It is first saved on-disk, then uploaded asynchronously
 * to the RAT server, on the background queue.
 *
 * Developers who wish to monitor the module's network activity can do so
 * by listening to the notifications it sends, respectively @ref RSDKAnalyticsWillUploadNotification,
 * @ref RSDKAnalyticsUploadFailureNotification and @ref RSDKAnalyticsUploadSuccessNotification.
 *
 * @param record  `[Required]` Record to be added to the database.
 * @exception NSObjectInaccessibleException The application's entitlements do not include the
 *            access group required to access the device identifier. See @ref device-information-keychain-setup "RSDKDeviceInformation: Setting up the keychain"
 *            for more information.
 * @exception NSInternalInconsistencyException The application is misconfigured and the first
 *            access group does not match the application's bundle identifier. See @ref device-information-keychain-setup "RSDKDeviceInformation: Setting up the keychain"
 *            for more information.
 */

+ (void)spoolRecord:(RSDKAnalyticsRecord *)record;


/**
 * This is the URL this module uploads records to.
 *
 * @return URL of the server.
 */

+ (NSURL*)endpointAddress;


/**
 * Control whether the SDK should track the device's location or not.
 *
 * This property is set to `NO` by default, which means @ref RSDKAnalyticsManager will
 * not use the device's location.
 *
 * @warning If the application has not already requested access to the location
 * information, trying to set this property to `YES` has no effect. Please refer
 * to the [Location and Maps Programming Guide](https://developer.apple.com/library/ios/documentation/UserExperience/Conceptual/LocationAwarenessPG/)
 * for more information.
 */
@property (nonatomic) BOOL shouldTrackLastKnownLocation;

/**
 * Control whether the SDK should track the [advertising identifier (IDFA)](https://developer.apple.com/reference/adsupport/asidentifiermanager) or not.
 *
 * This property is set to `YES` by default, which means @ref RSDKAnalyticsManager will
 * use the advertising identifier.
 */
@property (nonatomic) BOOL shouldTrackAdvertisingIdentifier;

/**
 * @deprecated Use #shouldTrackLastKnownLocation instead.
 */
@property (nonatomic, getter=isLocationTrackingEnabled) BOOL locationTrackingEnabled DEPRECATED_MSG_ATTRIBUTE("Use shouldTrackLastKnownLocation instead");

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

RSDKA_EXPORT NSString *const RSDKAnalyticsWillUploadNotification;


/**
 * The SDK sends this notification after an upload failed.
 *
 * `object` is a the JSON payload that was being uploaded, in its unserialized
 * NSArray form.
 * `userInfo` contains a `NSError` instance under the key `NSUnderlyingErrorKey`, that uses the `NSURLErrorDomain` domain.
 *
 * @ingroup AnalyticsConstants
 */

RSDKA_EXPORT NSString *const RSDKAnalyticsUploadFailureNotification;


/**
 * The SDK sends this notification after an upload succeeded.
 *
 * `object` is a the JSON payload that was being uploaded, in its unserialized
 * `NSArray` form.
 *
 * @ingroup AnalyticsConstants
 */

RSDKA_EXPORT NSString *const RSDKAnalyticsUploadSuccessNotification;

NS_ASSUME_NONNULL_END
