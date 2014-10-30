//
//  RSDKDeviceInformation.m
//  RSDKDeviceInformation
//
//  Created by Julien Cayzac on 6/3/14.
//  Copyright (c) 2014 Rakuten, Inc. All rights reserved.
//

@import UIKit.UIDevice;
@import Darwin.POSIX.sys.utsname;

#import "RSDKDeviceInformation.h"
#import <RSDKSupport/RSDKAssert.h>
#import <RSDKSupport/NSData+RAExtensions.h>
#import <RSDKSupport/RLoggingHelper.h>

#define RSDKDeviceInformationDomain @"jp.co.rakuten.ios.sdk.deviceinformation"

/* FOUNDATION_EXTERN */ NSString *const RSDKDeviceInformationKeychainAccessGroup = RSDKDeviceInformationDomain;

static NSString *const probeKey = RSDKDeviceInformationDomain @"probe";
static NSString *const uuidKey  = RSDKDeviceInformationDomain @"uuid";


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
            CFDictionaryRef query = (__bridge CFDictionaryRef) @{(__bridge id)kSecAttrService: probeKey,
                                                                 (__bridge id)kSecAttrAccount: probeKey,
                                                                 (__bridge id)kSecClass: (__bridge id)kSecClassGenericPassword,
                                                                 (__bridge id)kSecAttrAccessible: (__bridge id)kSecAttrAccessibleAlways,
                                                                 (__bridge id)kSecReturnAttributes: @YES};

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

            RSDKASSERTIFNOT(![RSDKDeviceInformationKeychainAccessGroup isEqualToString:[defaultAccessGroup substringFromIndex:firstDot.location + 1]],
                            @"\"%@\" is your default access group. Make sure your application's bundle identifier is the first entry of `keychain-access-groups` in your entitlements!", RSDKDeviceInformationDomain);


            /*
             * Try to clean things up
             */
            SecItemDelete((__bridge CFDictionaryRef) @{(__bridge id)kSecAttrService: probeKey,
                                                       (__bridge id)kSecAttrAccount: probeKey,
                                                       (__bridge id)kSecClass: (__bridge id)kSecClassGenericPassword});
        }
#endif // TARGET_IPHONE_SIMULATOR

        /*
         * Try to find the device identifier in the keychain.
         * Here we always have a bundle seed id.
         */

        static CFDictionaryRef searchQuery = NULL;
        if (!searchQuery)
        {
            searchQuery = (__bridge CFDictionaryRef) @{(__bridge id)kSecAttrAccount: uuidKey,
                                                       (__bridge id)kSecAttrService: uuidKey,
                                                       (__bridge id)kSecClass: (__bridge id)kSecClassGenericPassword,
#if !TARGET_IPHONE_SIMULATOR
                                                       (__bridge id)kSecAttrAccessGroup: accessGroup,
#endif // TARGET_IPHONE_SIMULATOR
                                                       (__bridge id)kSecMatchLimit: (__bridge id)kSecMatchLimitOne,
                                                       (__bridge id)kSecReturnData: (__bridge id)kCFBooleanTrue,
                                                       };
        };

        status = SecItemCopyMatching(searchQuery, &result);

        if (status == errSecSuccess)
        {
            /*
             * Device id found!
             */

            value = [CFBridgingRelease(result) hexadecimal];

            RDebugLog(@"Unique device identifier: %@", value);
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

            deviceIdData = [idForVendor dataUsingEncoding:NSUTF8StringEncoding].sha1;
        }

        static CFDictionaryRef saveQuery = NULL;
        if (!saveQuery)
        {
            saveQuery = (__bridge CFDictionaryRef) @{(__bridge id)kSecAttrAccount: uuidKey,
                                                     (__bridge id)kSecAttrService: uuidKey,
                                                     (__bridge id)kSecClass: (__bridge id)kSecClassGenericPassword,
#if !TARGET_IPHONE_SIMULATOR
                                                     (__bridge id)kSecAttrAccessGroup: accessGroup,
#endif // TARGET_IPHONE_SIMULATOR
                                                     (__bridge id)kSecAttrAccessible: (__bridge id)kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly,
                                                     (__bridge id)kSecValueData: deviceIdData,
                                                     };
        };

        status = SecItemAdd(saveQuery, NULL);
        if (status != errSecSuccess)
        {
            return nil;
        }

        value = deviceIdData.hexadecimal;

        RDebugLog(@"Unique device identifier: %@", value);
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

        RDebugLog(@"Model identifier: %@", value);
    });

    return value;
}

@end

