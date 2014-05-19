//
//  NSData+RAExtensions.h
//  Authentication
//
//  Created by Gatti, Alessandro | Alex | SDTD on 5/24/13.
//  Copyright (c) 2013 Rakuten Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 * Category extending NSData with additions needed by the Rakuten SDK.
 */
@interface NSData (RAExtensions)

/**
 * Returns a NSString with the Base64 representation of the bytes contained
 * in the object.
 *
 * @see http://tools.ietf.org/html/rfc4648
 *
 * @return A string with the Base64-encoded bytes in the object.
 */
- (NSString *)base64;

/**
 * Returns a NSData containing the SHA-1 hash of the bytes contained in the
 * object.
 *
 * @see http://www.itl.nist.gov/fipspubs/fip180-1.htm
 *
 * @return A NSData with the SHA-1 hash of the object.
 */
- (instancetype)sha1;

/**
 * Returns a NSData containing the HMAC data computed with the given key using
 * the SHA-1 algorithm.
 *
 * @see http://tools.ietf.org/html/rfc2104
 *
 * @param key The HMAC key to use.
 *
 * @return A NSData with the HMAC data computed from the object.
 */
- (instancetype)hmacSha1ForKey:(NSData *)key;

/**
 * Returns content as a hex-encoded string.
 *
 * @return Content as a hex-encoded string.
 */
- (NSString *)hexadecimal;

/**
 * Parses the given hex-encoded string and creates an NSData object with its
 * contents.
 *
 * @param string The hex-encodes string to parse.
 *
 * @return A NSData object containing the hex-encoded data, or nil if the input
 *         string was invalid.
 */
+ (instancetype)dataWithHexadecimal:(NSString *)string;

@end
