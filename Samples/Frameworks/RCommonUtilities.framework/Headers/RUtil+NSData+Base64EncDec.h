/*

Reference from Rakuten iPhone Ichiba application code base 
Version: 1.6
 
//  Base64EncDec.m
//
//  Created by Takeshi Yamane on 06/07/03.
//  Copyright 2006 Takeshi Yamane. All rights reserved.
//

Reference from: https://github.com/daichi1128/DCAtomPub/blob/master/Base64EncDec.m
*/

#import <Foundation/Foundation.h>

@interface NSData (RUtil_NSData_Base64EncDec)

//base64 decodes string, NSData creates an object
+ (NSData *)dataWithBase64CString:(const char *)pcBase64 length:(long)lLength;

//base64 decodes string, NSData creates an object
+ (NSData *)dataWithBase64String:(NSString *)pstrBase64;

// To generate the encoded string with Base64
- (NSString *)stringEncodedWithBase64;
//
//Base64 Seek the index of the character conversion table from
+ (int)indexOfBase64Char:(char)cBase64Char;

@end
