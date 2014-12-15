//
//  RSDKDeviceInformation.m
//  RSDKDeviceInformation
//
//  Created by Julien Cayzac on 6/3/14.
//  Copyright (c) 2014 Rakuten, Inc. All rights reserved.
//

@import UIKit.UIDevice;
@import Darwin.POSIX.sys.utsname;
#import <CommonCrypto/CommonCrypto.h>

#import "RSDKDeviceInformation.h"

#define RSDKDeviceInformationDomain @"jp.co.rakuten.ios.sdk.deviceinformation"
#define QUOTE(s) #s
#define EXPAND_AND_QUOTE(s) QUOTE(s)

/* RSDKDEVICEINFORMATION_EXPORT */ const NSString* const RSDKDeviceInformationVersion = @ EXPAND_AND_QUOTE(RMSDK_DEVICE_INFORMATION_VERSION);
/* RSDKDEVICEINFORMATION_EXPORT */ NSString *const RSDKDeviceInformationKeychainAccessGroup = RSDKDeviceInformationDomain;

static NSString *const probeKey = RSDKDeviceInformationDomain @"probe";
static NSString *const uuidKey  = RSDKDeviceInformationDomain @"uuid";

static NSString *hexadecimal(const NSData *data)
{
    const unsigned char *bytes = data.bytes;
    NSUInteger length = data.length;
    NSMutableString *output = [NSMutableString stringWithCapacity:(length << 1)];
    for (NSUInteger offset = 0; offset < length; ++offset)
    {
        [output appendFormat:@"%02x", bytes[offset]];
    }
    return output.copy;
}

static void checkMissingAccessControl(OSStatus status)
{
    // errSecNoAccessForItem is not defined for iOS, only OS X.
    // Normally it would be found in <Security/SecBase.h>.
    if (status == /* errSecNoAccessForItem */ -25243)
    {
        [NSException raise:NSObjectNotAvailableException format:
         @"\nYour application is lacking the proper keychain-access-group entitlements.\n"
         @"Please refer to the API reference documentation for RSDKDeviceInformation here:\n\t"
         @"https://rmsdk.azurewebsites.net/docs/ios/RSDKDeviceInformation#device-information-keychain-setup\n\n"];
    }
}

@implementation RSDKDeviceInformation

+ (NSString *)uniqueDeviceIdentifier
{
    /*
     * Because the keychain might not be available when this is called,
     * we can't use dispatch_once() here.
     */
    @synchronized(self)
    {
        /*
         * If we already have a value, return it.
         */

        static NSString *value = nil;

        if (value)
        {
            return value;
        }

        CFTypeRef result;
        OSStatus status;

#if !TARGET_IPHONE_SIMULATOR
        /*
         * First, try to grab the application identifier prefix (=bundle seed it)
         * and build the access group from it.
         */

        static NSString *accessGroup = nil;
        if (!accessGroup)
        {
            NSDictionary *strongQuery = @{(__bridge id)kSecAttrService: probeKey,
                                          (__bridge id)kSecAttrAccount: probeKey,
                                          (__bridge id)kSecClass: (__bridge id)kSecClassGenericPassword,
                                          (__bridge id)kSecAttrAccessible: (__bridge id)kSecAttrAccessibleAlways,
                                          (__bridge id)kSecReturnAttributes: @YES};
            CFDictionaryRef query = (__bridge CFDictionaryRef)strongQuery;

            status = SecItemCopyMatching(query, &result);

            if (status == errSecItemNotFound)
            {
                status = SecItemAdd(query, &result);
            }

            if (status != errSecSuccess)
            {
                /*
                 * Keychain is not available
                 */

                return nil;
            }

            NSString *defaultAccessGroup = [CFBridgingRelease(result) objectForKey:(__bridge id)kSecAttrAccessGroup];
            NSRange firstDot = [defaultAccessGroup rangeOfString:@"."];
            accessGroup = [[defaultAccessGroup substringToIndex:firstDot.location] stringByAppendingFormat:@".%@", RSDKDeviceInformationKeychainAccessGroup];

            /*
             * While we're at it, why not check developers didn't do the unthinkable?
             */
            if ([RSDKDeviceInformationKeychainAccessGroup isEqualToString:[defaultAccessGroup substringFromIndex:firstDot.location + 1]])
            {
                [NSException raise:NSGenericException format:@"\"%@\" is your default access group. Make sure your application's bundle identifier is the first entry of `keychain-access-groups` in your entitlements!", RSDKDeviceInformationDomain];
            }


            /*
             * Try to clean things up
             */
            strongQuery = @{(__bridge id)kSecAttrService: probeKey,
                            (__bridge id)kSecAttrAccount: probeKey,
                            (__bridge id)kSecClass: (__bridge id)kSecClassGenericPassword};
            SecItemDelete((__bridge CFDictionaryRef)strongQuery);
        }
#endif // TARGET_IPHONE_SIMULATOR

        /*
         * Try to find the device identifier in the keychain.
         * Here we always have a bundle seed id.
         */

        static CFDictionaryRef searchQuery = NULL;
        if (!searchQuery)
        {
            searchQuery = (CFDictionaryRef)CFBridgingRetain( @{(__bridge id)kSecAttrAccount: uuidKey,
                                                               (__bridge id)kSecAttrService: uuidKey,
                                                               (__bridge id)kSecClass: (__bridge id)kSecClassGenericPassword,
#if !TARGET_IPHONE_SIMULATOR
                                                               (__bridge id)kSecAttrAccessGroup: accessGroup,
#endif // TARGET_IPHONE_SIMULATOR
                                                               (__bridge id)kSecMatchLimit: (__bridge id)kSecMatchLimitOne,
                                                               (__bridge id)kSecReturnData: (__bridge id)kCFBooleanTrue
                                                               });
        };

        status = SecItemCopyMatching(searchQuery, &result);
        checkMissingAccessControl(status);

        if (status == errSecSuccess)
        {
            /*
             * Device id found!
             */
            value = hexadecimal(CFBridgingRelease(result));
            return value;
        }

        if (status != errSecItemNotFound)
        {
            /*
             * Keychain problem
             */

            return nil;
        }

        /*
         * Get identifierForVendor and write it to the keychain.
         * If it succeeds, then assign the result to 'value'.
         */

        static NSData *deviceIdData = nil;
        if (!deviceIdData)
        {
            static NSCharacterSet *zeroesAndHyphens;
            static dispatch_once_t once;
            dispatch_once(&once, ^
            {
                zeroesAndHyphens = [NSCharacterSet characterSetWithCharactersInString:@"0-"];
            });

            NSString *idForVendor = UIDevice.currentDevice.identifierForVendor.UUIDString;
            if (![idForVendor stringByTrimmingCharactersInSet:zeroesAndHyphens].length)
            {
                /*
                 * Filter out nil, empty, or zeroed strings (e.g. "00000000-0000-0000-0000-000000000000"):
                 * Some iOS6 devices return a zero id. See http://openradar.appspot.com/12377282
                 *
                 * We don't have many options here, beside generating an id.
                 */

                idForVendor = [NSUUID.UUID UUIDString];
            }

            NSData *data = [idForVendor dataUsingEncoding:NSUTF8StringEncoding];
            unsigned char hash[CC_SHA1_DIGEST_LENGTH];
            CC_SHA1(data.bytes, (unsigned int)data.length, hash);

            deviceIdData = [NSData dataWithBytes:hash length:CC_SHA1_DIGEST_LENGTH];
        }

        static CFDictionaryRef saveQuery = NULL;
        if (!saveQuery)
        {
            saveQuery = (CFDictionaryRef)CFBridgingRetain( @{(__bridge id)kSecAttrAccount: uuidKey,
                                                             (__bridge id)kSecAttrService: uuidKey,
                                                             (__bridge id)kSecClass: (__bridge id)kSecClassGenericPassword,
#if !TARGET_IPHONE_SIMULATOR
                                                             (__bridge id)kSecAttrAccessGroup: accessGroup,
#endif // TARGET_IPHONE_SIMULATOR
                                                             (__bridge id)kSecAttrAccessible: (__bridge id)kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly,
                                                             (__bridge id)kSecValueData: deviceIdData,
                                                             });
        };

        status = SecItemAdd(saveQuery, NULL);
        checkMissingAccessControl(status);
        if (status != errSecSuccess)
        {
            return nil;
        }

        value = hexadecimal(deviceIdData);
        return value;
    }
}

+ (NSString *)modelIdentifier
{
    static NSString *value;
    static dispatch_once_t once;
    dispatch_once(&once, ^
    {
        struct utsname systemInfo;
        uname(&systemInfo);
        value = [NSString.alloc initWithUTF8String:systemInfo.machine];
    });

    return value;
}

@end

