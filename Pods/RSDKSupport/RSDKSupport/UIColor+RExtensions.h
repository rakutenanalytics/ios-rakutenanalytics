//
//  UIColor+RExtensions.h
//  RSDKSupport
//
//  Created by Zachary Radke on 1/9/14.
//  Copyright (c) 2014 Rakuten Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

/**
 *  UIColor extensions for the RSDKSupport module
 */
@interface UIColor (RExtensions)

/**
 *  Creates a UIColor object from an RGB hex string with full alpha.
 *
 *  @param hexString The hex string to parse into a UIColor. This must be in the format "RGB" or "RRGGBB".
 *
 *  @return A full alpha UIColor parsed from the RGB hex.
 */
+ (instancetype)r_colorWithHexString:(NSString *)hexString;

/**
 *  Creates a UIColor object from an RGB hex string with the passed alpha.
 *
 *  @param hexString The hex string to parse into a UIColor. This must be in the format "RGB" or "RRGGBB".
 *  @param alpha     The alpha component of the color
 *
 *  @return A UIColor parsed from the RGB hex and passed alpha.
 */
+ (instancetype)r_colorWithHexString:(NSString *)hexString alpha:(CGFloat)alpha;

#if RSDKSupportShorthand

/**
 *  Alias for r_colorWithHexString:
 */
+ (instancetype)colorWithHexString:(NSString *)hexString;

/**
 *  Alias for r_colorWithHexString:alpha:
 */
+ (instancetype)colorWithHexString:(NSString *)hexString alpha:(CGFloat)alpha;

#endif

@end
