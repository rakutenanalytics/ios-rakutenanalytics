@import Foundation;
#import <Availability.h>

#ifdef __cplusplus
#define RSDKDEVICEINFORMATION_EXPORT extern "C" __attribute__((visibility ("default")))
#else
#define RSDKDEVICEINFORMATION_EXPORT extern __attribute__((visibility ("default")))
#endif

#ifdef DOXYGEN
/**
 * @defgroup DeviceInformationConstants Constants
 */
#endif

/**
 *  The version of the RSDKDeviceInformation module.
 *
 *  @ingroup DeviceInformationConstants
 */
RSDKDEVICEINFORMATION_EXPORT const NSString* const RSDKDeviceInformationVersion;


/**
 * The keychain access group used to share the unique device identifier
 * across all applications.
 *
 * The value of this string is `jp.co.rakuten.ios.sdk.deviceinformation`.
 *
 * @ingroup DeviceInformationConstants
 */
RSDKDEVICEINFORMATION_EXPORT NSString *const RSDKDeviceInformationKeychainAccessGroup;


/**
 * This class provides information about the device the application is currently running on.
 * @class RSDKDeviceInformation RSDKDeviceInformation.h <RSDKDeviceInformation/RSDKDeviceInformation.h>
 */
@interface RSDKDeviceInformation : NSObject


/**
 * Return a string uniquely identifying the device the application is currently running on.
 *
 * @attention For this method to work, keychain access **MUST** be properly configured first. Please
 *            refer to @ref device-information-keychain-setup "Setting up the keychain" for
 *            the right way to do so.
 *
 * This value is initially derived from `-[UIDevice identifierForVendor]`, then
 * stored in a keychain item made accessible to other applications. This has a number of
 * benefits:
 *
 * Feature                                                       | `-[UIDevice identifierForVendor]` | `-[RSDKDeviceInformation uniqueDeviceIdentifier]`
 * ------------------------------------------------------------- | --------------------------------- | ------------------------------------------------
 * Universally unique                                            | YES                               | YES
 * Restored from device backups, but only on the original device | YES                               | YES
 * Survives OS update                                            | YES                               | YES
 * Survives application update                                   | DEPEND ¹                          | YES
 * Survives application uninstall                                | YES                               | YES
 * Survives all applications being uninstalled ²                 | NO                                | YES
 * Works without 3-component bundle ID ³                         | NO                                | YES
 *
 * 1. On <b>iOS6.1+</b> `-[UIDevice identifierForVendor]` returns the same value
 *    after an application has been updated. On <b>iOS6.0</b> however this is not the case.
 * 2. If a Rakuten application is reinstalled after all have been uninstalled,
 *    iOS resets the value to be returned by `-[UIDevice identifierForVendor]`.
 * 3. `-[UIDevice identifierForVendor]` uses the application's bundle identifier
 *    to determine whether two applications come from the same publisher, but iOS6 and iOS7
 *    do things differently and the only way to get a consistent behavior across OS versions
 *    with that method is to use a 3-component bundle ID, e.g. `com.rakuten.ichiba`.
 *
 * @warning Applications built with different application identifier prefixes/bundle seed identifiers, i.e.
 *          different provisioning profiles, will not produce the same device identifier.
 *
 * @return A string uniquely identifying the device the application is currently running on.
 *         If the keychain is not available (i.e. the device is locked) and no value has been
 *         retrieved yet, `nil` is returned and the developer should try again when the device
 *         is unlocked.
 */

+ (NSString *)uniqueDeviceIdentifier;


/**
 * Return the model identifier of the device the application is currently running on.
 *
 * This returns the internal model identifier. Here is a list of some known model identifiers,
 * copied from the [enterprise iOS](http://www.enterpriseios.com/wiki/iOS_Devices) website.
 * Note that it might be be current.
 *
 * Device name                  | Model identifier(s)
 * ---------------------------- | -------------------
 * iOS Simulator                | `i386`<br>`x86_64`
 * Apple TV 2G                  | `AppleTV2,1`
 * Apple TV 3                   | `AppleTV3,1`
 * Apple TV 3 (2013)            | `AppleTV3,2`
 * iPad 2 (WiFi)                | `iPad2,1`
 * iPad 2 (GSM)                 | `iPad2,2`
 * iPad 2 (CDMA)                | `iPad2,3`
 * iPad 2 (Mid 2012)            | `iPad2,4`
 * iPad Mini (WiFi)             | `iPad2,5`
 * iPad Mini (GSM)              | `iPad2,6`
 * iPad Mini (Global)           | `iPad2,7`
 * iPad 3 (WiFi)                | `iPad3,1`
 * iPad 3 (CDMA)                | `iPad3,2`
 * iPad 3 (GSM)                 | `iPad3,3`
 * iPad 4 (WiFi)                | `iPad3,4`
 * iPad 4 (GSM)                 | `iPad3,5`
 * iPad 4 (Global)              | `iPad3,6`
 * iPad Air (WiFi)              | `iPad4,1`
 * iPad Air (Cellular)          | `iPad4,2`
 * iPad Air (China)             | `iPad4,3`
 * iPad Mini Retina (WiFi)      | `iPad4,4`
 * iPad Mini Retina (Cellular)  | `iPad4,5`
 * iPad Mini Retina (China)     | `iPad4,6`
 * iPhone 3GS                   | `iPhone2,1`
 * iPhone 4 (GSM)               | `iPhone3,1`
 * iPhone 4 (GSM / 2012)        | `iPhone3,2`
 * iPhone 4 (CDMA)              | `iPhone3,3`
 * iPhone 4S                    | `iPhone4,1`
 * iPhone 5 (GSM)               | `iPhone5,1`
 * iPhone 5 (Global)            | `iPhone5,2`
 * iPhone 5c (GSM)              | `iPhone5,3`
 * iPhone 5c (Global)           | `iPhone5,4`
 * iPhone 5s (GSM)              | `iPhone6,1`
 * iPhone 5s (Global)           | `iPhone6,2`
 * iPod touch 4                 | `iPod4,1`
 * iPod touch 5                 | `iPod5,1`
 *
 * @return The model identifier of the device the application is currently running on.
 */

+ (NSString *)modelIdentifier;

@end
