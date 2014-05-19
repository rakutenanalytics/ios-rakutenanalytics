//
//  NSCoder+RAExtensions.h
//  RSDKSupport
//
//  Created by Gatti, Alessandro | Alex | SDTD on 6/2/13.
//  Copyright (c) 2013 Rakuten Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

#if !defined(__IPHONE_6_0) || __IPHONE_OS_VERSION_MIN_REQUIRED < __IPHONE_6_0

/**
 * Replacement for NSSecureCoding in case the SDK in use does not contain
 * said protocol.
 */
@protocol RASecureCoding <NSCoding>
@required

/**
 * Returns a flag indicating whether secure coding is supported.
 *
 * @return YES if secure coding is supported, NO otherwise.
 */
+ (BOOL)supportsSecureCoding;

@end

/**
 * Category extending NSCoder with additions needed by the Rakuten SDK.
 */
@interface NSCoder (RAExtensions)

/**
 * Replacement for NSCoder's decodeObjectForClass in case the device is using
 * a version of iOS prior to 6.0.
 *
 * Please check the appropriate NSSecureCoding documentation before attempting
 * to use this method.
 *
 * @param class The class the decoded object should be a kind of.
 * @param key The key associated to the object to decode.
 *
 * @return The decoded object, or an exception will be thrown in case of
 *         class type mismatches.
 */
- (id)decodeObjectOfClass:(Class)class forKey:(NSString *)key;

@end

#endif // !__IPHONE_6_0 || __IPHONE_OS_VERSION_MIN_REQUIRED < __IPHONE_6_0
