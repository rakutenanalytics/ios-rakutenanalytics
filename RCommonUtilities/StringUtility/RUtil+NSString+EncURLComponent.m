/*
 Copyright: Copyright (C) 2012 Rakuten, Inc.  All Rights Reserved.
 
 
 File Name:   RUtil+NSString+EncURLComponent.m
 
 Description: Performs the functionality of creating url compatible string by encode the character of string
 
 Author: Mandar Kadam
 
 Created: 27th-June-2012
 
 Changed: 
 
 Version: 1.0
 
 *
 */

#import "RUtil+NSString+EncURLComponent.h"

@implementation  NSString (RUtil_NSString_EncURLComponent)

/*
 * @functionName : encodeAsURLComponent 
 * @return : Returns encoded string with url component
 * @description : Performs the functionality of creating url compatible string.
 */
- (NSString*)encodeAsURLComponent
{
	const char* p = [self UTF8String]; //return null-terminated UTF8 representation
	NSMutableString* result = [NSMutableString string];
	
	for (;*p ;p++) {
		unsigned char c = *p;
		if (('0' <= c && c <= '9') || ('a' <= c && c <= 'z') || ('A' <= c && c <= 'Z') || (c == '-' || c == '_')) {
			[result appendFormat:@"%c", c];
		}
		else {
			[result appendFormat:@"%%%02X", c];
		}
	}
	return result;
}
@end
