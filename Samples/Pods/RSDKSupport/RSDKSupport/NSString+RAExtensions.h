//
//  NSData+RAExtensions.h
//  Authentication
//
//  Created by Gatti, Alessandro | Alex | SDTD on 5/13/13.
//  Copyright (c) 2013 Rakuten Inc. All rights reserved.
//

@import Foundation;

/**
 * Category extending `NSString` with additions needed by the Rakuten SDK.
 *
 * @category NSString(RAExtensions) NSString+RAExtensions.h <RSDKSupport/NSString+RAExtensions.h>
 */
@interface NSString (RAExtensions)

/**
 * Create a new `NSString` instance containing an **UUID4**.
 *
 * @see [RFC 4122: A Universally Unique IDentifier URN Namespace](http://tools.ietf.org/html/rfc4122)
 *
 * @return A `NSString` with an **UUID4** in string form.
 */
+ (instancetype)stringWithUUID;

/**
 * Return a copy of the receiver with heading and trailing white space removed.
 *
 * Heading and trailing character part of the [Unicode General Category Z*](http://www.unicode.org/versions/Unicode6.2.0/ch04.pdf#G124142) are
 * removed, as well as code points in the range **U000A…U000D** and **U0085**.
 *
 * @return Copy of the receiver with heading and trailing white space removed.
 */
- (instancetype)trim;

/**
 * Check if the current string is either empty or comprised exclusively
 * by whitespace.
 *
 * @return `YES` if the string, once trimmed, is empty, or `NO` otherwise.
 */
- (BOOL)isEmpty;

@end
