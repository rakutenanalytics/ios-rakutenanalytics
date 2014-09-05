//
//  NSObject+RAccessibility.h
//  RSDKSupport
//
//  Created by Zachary Radke on 1/9/14.
//  Copyright (c) 2014 Rakuten Inc. All rights reserved.
//

@import Foundation;

/**
 * Extensions to `NSObject` adding accessibility utilities.
 *
 * @category NSObject(RAccessibility) NSObject+RAccessibility.h <RSDKSupport/NSObject+RAccessibility.h>
 */
@interface NSObject (RAccessibility)

/**
 * Automatically set the accessibility identifiers for `UIView`
 * properties or child `UIView` instances contained in `NSArray`
 * properties of the receiver, matching the name of the properties.
 *
 * @note This method will **NOT** set the accessbility identifier of any
 *       `UIView` property that does not have a standard getter, has a
 *       `_` prefix or is named `view`.
 */
- (void)r_setupAccessibilityIdentifiers;

#if RSDKSupportShorthand

/**
 * Alias for #r_setupAccessibilityIdentifiers
 *
 * @note This method is only available if #RSDKSupportShorthand has been defined.
 */
- (void)setupAccessibilityIdentifiers;

#endif

@end
