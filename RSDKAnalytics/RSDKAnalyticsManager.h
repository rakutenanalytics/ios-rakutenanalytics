//
//  RSDKAnalyticsManager.h
//  RSDKAnalytics
//
//  Created by Julien Cayzac on 5/19/14.
//  Copyright (c) 2014 Rakuten, Inc. All rights reserved.
//

@import Foundation;

@class RSDKAnalyticsRecord;


/**
 * This class handles:
 *
 *  - Enabling or disabling **location tracking** with [RSDKAnalyticsManager locationTrackingEnabled];
 *  - **Spooling** RSDKAnalyticsRecord instances with [RSDKAnalyticsManager spoolRecord:].
 *  - **Gathering system data** that it merges with each record it spools. See the next section.
 *
 * ## Automatically gathered system data
 * The fields below, documented in the [Rakuten Analytics Generic IDL](https://git.dev.rakuten.com/projects/RG/repos/rg/browse/ratGeneric.idl),
 * are automatically merged with the properties of each RSDKAnalyticsRecord that gets spooled:
 *
 *  - **ckp** (`PERSISTENT_COOKIE`)
 *  - **cks** (`SESSION_COOKIE`)
 *  - **dln** (`DEVICE_LANGUAGE`)
 *  - **loc** (`LOCATION`)
 *  - **ltm** (`SCRIPT_START_TIME`)
 *  - **mbat** (`BATTERY_USAGE`)
 *  - **mcn** (`MOBILE_CARRIER_NAME`)
 *  - **mnetw** (`MOBILE_NETWORK_TYPE`)
 *  - **model** (`MOBILE_DEVICE_BRAND_MODEL`)
 *  - **mori** (`MOBILE_ORIENTATION`)
 *  - **mos** (`MOBILE_OS`)
 *  - **online** (`ONLINE_STATUS`)
 *  - **powerstatus** (`BATTERY_CHARGING_STATUS`)
 *  - **res** (`RESOLUTION`)
 *  - **ts1** (`CLIENT_PROVIDED_TIMESTAMP`)
 *  - **tzo** (`TIMEZONE`)
 *  - **ua** (`USER_AGENT`)
 *  - **ver** (`VERSION`)
 *
 * @since 2.0.0
 */

@interface RSDKAnalyticsManager : NSObject


/**
 * Retrieve the shared instance.
 *
 * @return The shared instance.
 *
 * @since 2.0.0
 */

+ (instancetype)sharedInstance;


/**
 * Spool a record. It is first saved on-disk, then uploaded asynchronously
 * to the RAT server, on the background queue.
 *
 * Developers who wish to monitor the module's network activity can do so
 * by listening to the notifications it sends, respectively RSDKAnalyticsWillUploadNotification,
 * RSDKAnalyticsUploadFailureNotification and RSDKAnalyticsUploadSuccessNotification.
 *
 * @param record  Record to be added to the database.
 *
 * @since 2.0.0
 */

+ (void)spoolRecord:(RSDKAnalyticsRecord *)record;


/**
 * This is the URL this module uploads records to.
 *
 * @return URL of the server.
 *
 * @since 2.0.0
 */

+ (NSURL*)endpointAddress;


/**
 * Control whether the SDK should record the device's location or not.
 *
 * This property is set to `NO` by default, which means RSDKAnalyticsManager will
 * not attempt to record the device's location.
 *
 * @warning If the application has not already requested access to the location
 * information, trying to set this property to `YES` has no effect. Please refer
 * to the [Location and Maps Programming Guide](https://developer.apple.com/library/ios/documentation/UserExperience/Conceptual/LocationAwarenessPG/)
 * for more information.
 *
 * @since 2.0.0
 */

@property (nonatomic,getter=isLocationTrackingEnabled) BOOL locationTrackingEnabled;

@end



/**
 * @name Notifications
 */


/**
 * The SDK sends this notification when it is about to make a request
 * to upload a group of records to RAT servers.
 *
 * `object` is a the JSON payload being uploaded, in its unserialized
 * NSArray form.
 *
 * @since 2.0.0
 */

FOUNDATION_EXTERN NSString *const RSDKAnalyticsWillUploadNotification;


/**
 * The SDK sends this notification after an upload failed.
 *
 * `object` is a the JSON payload that was being uploaded, in its unserialized
 * NSArray form.
 * `userInfo` contains a NSError instance under the key `NSUnderlyingErrorKey`. Connection
 * errors use the `NSURLErrorDomain` domain. Other errors use RSDKAnalyticsErrorDomain.
 *
 * @since 2.0.0
 */

FOUNDATION_EXTERN NSString *const RSDKAnalyticsUploadFailureNotification;


/**
 * The SDK sends this notification after an upload succeeded.
 *
 * `object` is a the JSON payload that was being uploaded, in its unserialized
 * NSArray form.
 *
 * @since 2.0.0
 */

FOUNDATION_EXTERN NSString *const RSDKAnalyticsUploadSuccessNotification;



/**
 * @name Errors
 */


/**
 * Error domain.
 *
 * @since 2.0.0
 */

FOUNDATION_EXTERN NSString *const RSDKAnalyticsErrorDomain;


/**
 * Error codes
 *
 * @since 2.0.0
 */

typedef NS_ENUM(NSInteger, RSDKAnalyticsError)
{
    /**
     * Server sent a status that wasn't 200.
     */
    RSDKAnalyticsErrorWrongResponseStatus
};

