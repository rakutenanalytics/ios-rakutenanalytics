/*

 Reference from Rakuten iPhone Ichiba application code base
 Version: 1.6
 
//
//  UIColor-HexEncoding.h
//  Rakuten
//
//  Created by gaku.obata on 11/11/04.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
 
 Actual reference: https://github.com/thisandagain/color/blob/master/EDColor/UIColor%2BHex.m
*/ 
 
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface UIColor(RUtil_UIColor_HexEncoding)
+ (UIColor *)colorWithRGBHex:(UInt32)hex;
+ (UIColor *)colorWithHexString:(NSString *)stringToConvert;
@end
