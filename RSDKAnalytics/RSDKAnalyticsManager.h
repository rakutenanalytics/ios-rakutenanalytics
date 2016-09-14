/*
 * © Rakuten, Inc.
 * authors: "Rakuten Ecosystem Mobile" <ecosystem-mobile@mail.rakuten.com>
 */
#import <RSDKAnalytics/RSDKAnalyticsDefines.h>

NS_ASSUME_NONNULL_BEGIN

@class RSDKAnalyticsRecord;
@class RSDKAnalyticsEvent;
@protocol RSDKAnalyticsTracker;

/**
 * Main class of the module.
 *
 *
 * @par Swift 3
 * This class is exposed as **AnalyticsManager**.
 *
 * @class RSDKAnalyticsManager RSDKAnalyticsManager.h <RSDKAnalytics/RSDKAnalyticsManager.h>
 * @ingroup AnalyticsCore
 */
RSDKA_EXPORT RSDKA_SWIFT3_NAME(AnalyticsManager) @interface RSDKAnalyticsManager : NSObject

/**
 * Retrieve the shared instance.
 *
 * @par Swift 3
 * This method is exposed as **AnalyticsManager.shared()**.
 *
 * @return The shared instance.
 */
+ (instancetype)sharedInstance RSDKA_SWIFT3_NAME(shared());

/**
 * Process an event. The manager passes the event to each registered trackers, in turn.
 *
 * @param event  An event will be sent to RAT server.
 */
- (void)process:(RSDKAnalyticsEvent *)event;

/**
 * Add a tracker to tracker list.
 *
 * @par Swift 3
 * This method is exposed as **.add()**.
 *
 * @param tracker  Any object that comforms to the @ref RSDKAnalyticsTracker protocol.
 */
- (void)addTracker:(id<RSDKAnalyticsTracker>)tracker;

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
 *
 * @deprecated Use use RSDKAnalyticsEvent and -[RSDKAnalyticsManager process:] instead.
 */
+ (void)spoolRecord:(RSDKAnalyticsRecord *)record DEPRECATED_MSG_ATTRIBUTE("Please use RSDKAnalyticsEvent and -[RSDKAnalyticsManager process:] instead.");


/**
 * This is the URL this module uploads records to.
 *
 * @return URL of the server.
 *
 * @deprecated Use RATTracker.endpointAddress instead.
 */
+ (NSURL *)endpointAddress DEPRECATED_MSG_ATTRIBUTE("Please use RATTracker.endpointAddress from now on.");

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
 * Control whether to use the staging environment or not. Defaults to `NO`.
 */
@property (nonatomic) BOOL shouldUseStagingEnvironment;

/**
 * @deprecated Use #shouldTrackLastKnownLocation instead.
 */
@property (nonatomic, getter=isLocationTrackingEnabled) BOOL locationTrackingEnabled DEPRECATED_MSG_ATTRIBUTE("Use shouldTrackLastKnownLocation instead");

@end

NS_ASSUME_NONNULL_END
