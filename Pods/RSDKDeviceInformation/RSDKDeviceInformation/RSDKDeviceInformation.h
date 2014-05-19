//
//  RSDKDeviceInformation.h
//  RSDKDeviceInformation
//
//  Created by Julien Cayzac on 6/3/14.
//  Copyright (c) 2014 Rakuten, Inc. All rights reserved.
//


@import Foundation;


/**
 * The keychain access group used to share the unique device identifier
 * across all applications.
 *
 * The value of this string is `jp.co.rakuten.ios.sdk.deviceinformation`.
 */

FOUNDATION_EXTERN NSString *const RSDKDeviceInformationKeychainAccessGroup;



/**
 * This class provides information about the device the application is currently running on.
 */

@interface RSDKDeviceInformation : NSObject


/**
 * Return a string uniquely identifying the device the application is currently running on.
 *
 * This value is initially derived from `-[UIDevice identifierForVendor]`, then
 * stored in a keychain item made accessible to other applications. This has a number of
 * benefits.
 *
 * <table>
 *   <thead>
 *     <tr>
 *       <th>Feature</th>
 *       <th>UIDevice identifierForVendor</th>
 *       <th>RSDKDeviceInformation uniqueDeviceIdentifier</th>
 *     </tr>
 *   </thead>
 *   <tbody>
 *     <tr>
 *       <td>Universally unique</td>
 *       <td>YES</td>
 *       <td>YES</td>
 *     </tr>
 *     <tr>
 *       <td>Restored from device backups, but only on the original device</td>
 *       <td>YES</td>
 *       <td>YES</td>
 *     </tr>
 *     <tr>
 *       <td>Survives OS update</td>
 *       <td>YES</td>
 *       <td>YES</td>
 *     </tr>
 *     <tr>
 *       <td>Survives application update</td>
 *       <td>DEPEND<sup>[1]</sup></td>
 *       <td>YES</td>
 *     </tr>
 *     <tr>
 *       <td>Survives application uninstall</td>
 *       <td>YES</td>
 *       <td>YES</td>
 *     </tr>
 *     <tr>
 *       <td>Survives all applications being uninstalled<sup>[2]</sup></td>
 *       <td>NO</td>
 *       <td>YES</td>
 *     </tr>
 *     <tr>
 *       <td>Works without 3-component bundle ID<sup>[3]</sup></td>
 *       <td>NO</td>
 *       <td>YES</td>
 *     </tr>
 *   </tbody>
 * </table>
 *
 * - <sup>[1]</sup> On **iOS6.1+** `-[UIDevice identifierForVendor]` returns the same value
 *   after an application has been updated. On **iOS6.0** however this is not the case.
 * - <sup>[2]</sup> If a Rakuten application is reinstalled after all have been uninstalled,
 *   iOS resets the value to be returned by `-[UIDevice identifierForVendor]`.
 * - <sup>[3]</sup> `-[UIDevice identifierForVendor]` uses the application's bundle identifier
 *   to determine whether two applications come from the same publisher, but iOS6 and iOS7
 *   do things differently and the only way to get a consistent behavior across OS versions
 *   with that method is to use a 3-component bundle ID, e.g. `com.rakuten.ichiba`.
 *
 *
 * Developers must add the `jp.co.rakuten.ios.sdk.deviceinformation` keychain access group
 * to their application's **Keychain Sharing** capabilities, as shown below.
 * Failure to do so will result in undefined behavior.
 *
 * ->![](../docs/StaticDocs/KeychainSharingSettings.png)<-
 *
 * <div class='warning'>**warning:** `jp.co.rakuten.ios.sdk.deviceinformation` should **never** be the
 * first entry of this list. The first entry should always be your application's bundle identifier.</div>
 *
 * <div class='warning'>**warning:** Applications built with different application identifier prefixes/bundle seed identifiers, i.e.
 * different provisioning profiles, will not produce the same device identifier.</div>
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
 *
 * <table>
 *   <tr><th>Device name                  </th><th>Model identifier(s) </th></tr>
 *   <tr><td>iOS Simulator                </td><td>i386<br>x86_64      </td></tr>
 *   <tr><td>Apple TV 2G                  </td><td>AppleTV2,1       </td></tr>
 *   <tr><td>Apple TV 3                   </td><td>AppleTV3,1       </td></tr>
 *   <tr><td>Apple TV 3 (2013)            </td><td>AppleTV3,2       </td></tr>
 *   <tr><td>iPad 2 (WiFi)                </td><td>iPad2,1          </td></tr>
 *   <tr><td>iPad 2 (GSM)                 </td><td>iPad2,2          </td></tr>
 *   <tr><td>iPad 2 (CDMA)                </td><td>iPad2,3          </td></tr>
 *   <tr><td>iPad 2 (Mid 2012)            </td><td>iPad2,4          </td></tr>
 *   <tr><td>iPad Mini (WiFi)             </td><td>iPad2,5          </td></tr>
 *   <tr><td>iPad Mini (GSM)              </td><td>iPad2,6          </td></tr>
 *   <tr><td>iPad Mini (Global)           </td><td>iPad2,7          </td></tr>
 *   <tr><td>iPad 3 (WiFi)                </td><td>iPad3,1          </td></tr>
 *   <tr><td>iPad 3 (CDMA)                </td><td>iPad3,2          </td></tr>
 *   <tr><td>iPad 3 (GSM)                 </td><td>iPad3,3          </td></tr>
 *   <tr><td>iPad 4 (WiFi)                </td><td>iPad3,4          </td></tr>
 *   <tr><td>iPad 4 (GSM)                 </td><td>iPad3,5          </td></tr>
 *   <tr><td>iPad 4 (Global)              </td><td>iPad3,6          </td></tr>
 *   <tr><td>iPad Air (WiFi)              </td><td>iPad4,1          </td></tr>
 *   <tr><td>iPad Air (Cellular)          </td><td>iPad4,2          </td></tr>
 *   <tr><td>iPad Air (China)             </td><td>iPad4,3          </td></tr>
 *   <tr><td>iPad Mini Retina (WiFi)      </td><td>iPad4,4          </td></tr>
 *   <tr><td>iPad Mini Retina (Cellular)  </td><td>iPad4,5          </td></tr>
 *   <tr><td>iPad Mini Retina (China)     </td><td>iPad4,6          </td></tr>
 *   <tr><td>iPhone 3GS                   </td><td>iPhone2,1        </td></tr>
 *   <tr><td>iPhone 4 (GSM)               </td><td>iPhone3,1        </td></tr>
 *   <tr><td>iPhone 4 (GSM / 2012)        </td><td>iPhone3,2        </td></tr>
 *   <tr><td>iPhone 4 (CDMA)              </td><td>iPhone3,3        </td></tr>
 *   <tr><td>iPhone 4S                    </td><td>iPhone4,1        </td></tr>
 *   <tr><td>iPhone 5 (GSM)               </td><td>iPhone5,1        </td></tr>
 *   <tr><td>iPhone 5 (Global)            </td><td>iPhone5,2        </td></tr>
 *   <tr><td>iPhone 5c (GSM)              </td><td>iPhone5,3        </td></tr>
 *   <tr><td>iPhone 5c (Global)           </td><td>iPhone5,4        </td></tr>
 *   <tr><td>iPhone 5s (GSM)              </td><td>iPhone6,1        </td></tr>
 *   <tr><td>iPhone 5s (Global)           </td><td>iPhone6,2        </td></tr>
 *   <tr><td>iPod touch 4                 </td><td>iPod4,1          </td></tr>
 *   <tr><td>iPod touch 5                 </td><td>iPod5,1          </td></tr>
 * </table>
 *
 * @return The model identifier of the device the application is currently running on.
 */

+ (NSString *)modelIdentifier;

@end
