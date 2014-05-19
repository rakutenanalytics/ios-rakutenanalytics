//
//  NSData+RAExtensions.h
//  Authentication
//
//  Created by Gatti, Alessandro | Alex | SDTD on 5/13/13.
//  Copyright (c) 2013 Rakuten Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 * Category extending NSString with additions needed by the Rakuten SDK.
 */
@interface NSString (RAExtensions)

/**
 * Creates a NSString object containing an UUID4 in string form.
 *
 * @see http://tools.ietf.org/html/rfc4122
 *
 * @return A NSString with an UUID4 in string form.
 */
+ (instancetype)stringWithUUID;

/**
 * Returns a copy of the current string with trailing spaces removed.
 *
 * @return A copy of the string with the trailing spaces removed.
 */
- (instancetype)trim;

/**
 * Checks if the current string is either empty or comprised exclusively
 * by whitespace.
 *
 * @return YES if the string is either empty or just made up of whitespace,
 *         NO otherwise.
 */
- (BOOL)isEmpty;

@end
