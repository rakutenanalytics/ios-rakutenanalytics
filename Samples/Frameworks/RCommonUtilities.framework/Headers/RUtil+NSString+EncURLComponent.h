/*
 Copyright: Copyright (C) 2012 Rakuten, Inc.  All Rights Reserved.
 
 
 File Name:  RUtil+NSString+EncURLComponent.h
 
 Description: Performs the functionality of creating url compatible string by encode the character of string.
 
 Author: Mandar Kadam
 
 Created: 27th-June-2012
 
 Changed: 
 
 Version: 1.0
 
 *
 */

#import <Foundation/Foundation.h>

@interface  NSString (RUtil_NSString_EncURLComponent)

//Performs the functionality of creating url compatible string by encode the character of string
- (NSString*)encodeAsURLComponent;
@end
