//
//  UIColor+RExtensions.h
//  RSDKSupport
//
//  Created by Zachary Radke on 1/9/14.
//  Copyright (c) 2014 Rakuten Inc. All rights reserved.
//

@import UIKit;

/**
 * `UIColor` extension.
 *
 * @category UIColor(RExtensions) UIColor+RExtensions.h <RSDKSupport/UIColor+RExtensions.h>
 */
@interface UIColor (RExtensions)

/**
 * Creates a `UIColor` object from a 32-bit RGBA value.
 *
 * For instance `0x11223344` will result in a color with `red=0.06667` (`0x11/0xff`),
 * `green=0.13333` (`0x22/0xff`), `blue=0.2` (`0x33/0xff`) and `alpha=0.26667` (`0x44/0xff`).
 *
 * @param rgbaValue The RGBA value.
 *
 * @return a `UIColor` with the corresponding red, green, blue and alpha values.
 */
+ (instancetype)r_colorWithRGBAValue:(uint32_t)rgbaValue;

/**
 *  Creates a `UIColor` object from an RGB hex string with full alpha.
 *
 *  @param hexString The hex string to parse into a `UIColor`. This must be in the format `RGB` or `RRGGBB`.
 *
 *  @return A full alpha `UIColor` parsed from the RGB hex.
 */
+ (instancetype)r_colorWithHexString:(NSString *)hexString;

/**
 *  Creates a `UIColor` object from an RGB hex string with the passed alpha.
 *
 *  @param hexString The hex string to parse into a `UIColor`. This must be in the format `RGB` or `RRGGBB`.
 *  @param alpha     The alpha component of the color
 *
 *  @return A `UIColor` parsed from the RGB hex and passed alpha.
 */
+ (instancetype)r_colorWithHexString:(NSString *)hexString alpha:(CGFloat)alpha;

#if RSDKSupportShorthand

/**
 * Alias for #r_colorWithRGBAValue:
 *
 * @note This method is only available if #RSDKSupportShorthand has been defined.
 *
 * @param rgbaValue The RGBA value.
 *
 * @return a `UIColor` with the corresponding red, green, blue and alpha values.
 */
+ (instancetype)colorWithRGBAValue:(uint32_t)rgbaValue;

/**
 * Alias for #r_colorWithHexString:
 *
 * @note This method is only available if #RSDKSupportShorthand has been defined.
 *
 * @param hexString The hex string to parse into a `UIColor`. This must be in the format `RGB` or `RRGGBB`.
 *
 * @return A `UIColor` parsed from the given string.
 */
+ (instancetype)colorWithHexString:(NSString *)hexString;

/**
 * Alias for #r_colorWithHexString:alpha:
 *
 * @note This method is only available if #RSDKSupportShorthand has been defined.
 *
 * @param hexString The hex string to parse into a `UIColor`. This must be in the format `RGB` or `RRGGBB`.
 * @param alpha     The alpha component of the color.
 *
 * @return A `UIColor` parsed from the given string with the given alpha.
 */
+ (instancetype)colorWithHexString:(NSString *)hexString alpha:(CGFloat)alpha;

#endif

@end
