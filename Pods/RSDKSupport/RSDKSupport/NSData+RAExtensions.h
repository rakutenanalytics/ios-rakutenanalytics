//
//  NSData+RAExtensions.h
//  Authentication
//
//  Created by Gatti, Alessandro | Alex | SDTD on 5/24/13.
//  Copyright (c) 2013 Rakuten Inc. All rights reserved.
//

@import Foundation;

/**
 * Category extending `NSData` with additions needed by the Rakuten SDK.
 *
 * @category NSData(RAExtensions) NSData+RAExtensions.h <RSDKSupport/NSData+RAExtensions.h>
 */
@interface NSData (RAExtensions)

/**
 * Return a `NSString` with the Base64 representation of the data held
 * by the receiver.
 *
 * @see [RFC4648: The Base16, Base32, and Base64 Data Encodings](http://tools.ietf.org/html/rfc4648)
 * @return A Base64 representation of the data held by the receiver.
 * @deprecated Please use `-base64EncodedStringWithOptions:` on iOS7+ or `-base64Encoding` on earlier OS versions.
 */
- (NSString *)base64 DEPRECATED_MSG_ATTRIBUTE("Please use -base64EncodedStringWithOptions: on iOS7+ or -base64Encoding on earlier OS versions");

/**
 * Return a `NSData` containing the SHA-1 hash of the data held by the
 * receiver.
 *
 * @see [FIP 180-1: Secure Hash Standard](http://cpansearch.perl.org/src/GAAS/Digest-SHA1-2.13/fip180-1.html)
 *
 * @return A `NSData` with the SHA-1 hash of the receiver.
 */
- (instancetype)sha1;

/**
 * Return a `NSData` containing the HMAC data computed with the given key using
 * the SHA-1 algorithm.
 *
 * @see [RFC 2104: HMAC, Keyed-Hashing for Message Authentication](http://tools.ietf.org/html/rfc2104)
 *
 * @param key The HMAC key to use.
 *
 * @return A `NSData` with the HMAC data computed from the receiver.
 */
- (instancetype)hmacSha1ForKey:(NSData *)key;

/**
 * Return a hexadecimal representation of the data held by the receiver.
 *
 * @return Hexadecimal representation of the data held by the receiver.
 */
- (NSString *)hexadecimal;

/**
 * Parse some hexadecimal string and create the corresponding `NSData`.
 *
 * @param string Hexadecimal representation of some data.
 *
 * @return New `NSData` instance containing the decoded data, or `nil` if the input
 *         was not valid hexadecimal.
 */
+ (instancetype)dataWithHexadecimal:(NSString *)string;

@end
