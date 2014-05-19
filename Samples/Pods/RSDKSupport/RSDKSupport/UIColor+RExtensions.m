//
//  UIColor+RExtensions.m
//  RSDKSupport
//
//  Created by Zachary Radke on 1/9/14.
//  Copyright (c) 2014 Rakuten Inc. All rights reserved.
//

#import "UIColor+RExtensions.h"

@implementation UIColor (RExtensions)

+ (instancetype)r_colorWithHexString:(NSString *)hexString
{
    return [self r_colorWithHexString:hexString alpha:1.0];
}

+ (instancetype)r_colorWithHexString:(NSString *)hexString alpha:(CGFloat)alpha
{
    if (!([hexString length] == 3 || [hexString length] == 6)) { return nil; }
    
    NSInteger hexLength = [hexString length] / 3;
    CGFloat red, green, blue;
    
    red = [self _r_colorComponentFromHexString:hexString start:0 length:hexLength];
    green = [self _r_colorComponentFromHexString:hexString start:(1 * hexLength) length:hexLength];
    blue = [self _r_colorComponentFromHexString:hexString start:(2 * hexLength) length:hexLength];
    
    return [self colorWithRed:red green:green blue:blue alpha:alpha];
}

+ (CGFloat)_r_colorComponentFromHexString:(NSString *)hexString start:(NSInteger)start length:(NSInteger)length
{
    NSString *substring = [hexString substringWithRange:NSMakeRange(start, length)];
    NSString *fullHex = length == 2 ? substring : [NSString stringWithFormat: @"%@%@", substring, substring];
    unsigned hexComponent;
    [[NSScanner scannerWithString:fullHex] scanHexInt: &hexComponent];
    return hexComponent / 255.0;
}

#if RDKSupportShorthand

+ (instancetype)colorWithHexString:(NSString *)hexString
{
    return [self r_colorWithHexString:hexString];
}

+ (instancetype)colorWithHexString:(NSString *)hexString alpha:(CGFloat)alpha
{
    return [self r_colorWithHexString:hexString alpha:alpha];
}

#endif

@end
