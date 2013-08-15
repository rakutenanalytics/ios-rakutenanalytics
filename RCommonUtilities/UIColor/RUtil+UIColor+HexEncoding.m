/*
 
 Reference from Rakuten iPhone Ichiba application code base
 Version: 1.6

 //  UIColor-HexEncoding.h
 //  Rakuten
 //
 //  Created by gaku.obata on 11/11/04.
 //  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
 
 Actual reference: https://github.com/thisandagain/color/blob/master/EDColor/UIColor%2BHex.m
 */

#import "RUtil+UIColor+HexEncoding.h"

@implementation UIColor(RUtil_UIColor_HexEncoding)

+ (UIColor *)colorWithRGBHex:(UInt32)hex {
	int r = (hex >> 16) & 0xFF;
	int g = (hex >> 8) & 0xFF;
	int b = (hex) & 0xFF;
	
	return [UIColor colorWithRed:r / 255.0f
						   green:g / 255.0f
							blue:b / 255.0f
						   alpha:1.0f];
}

// Returns a UIColor by scanning the string for a hex number and passing that to +[UIColor colorWithRGBHex:]
// Skips any leading whitespace and ignores any trailing characters
+ (UIColor *)colorWithHexString:(NSString *)stringToConvert {
	NSScanner *scanner = [NSScanner scannerWithString:stringToConvert];
	unsigned hexNum;
	if (![scanner scanHexInt:&hexNum]) return nil;
	return [UIColor colorWithRGBHex:hexNum];
}
@end
