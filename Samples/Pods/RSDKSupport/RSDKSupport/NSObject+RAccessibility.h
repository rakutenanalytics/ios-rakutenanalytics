//
//  NSObject+RAccessibility.h
//  RSDKSupport
//
//  Created by Zachary Radke on 1/9/14.
//  Copyright (c) 2014 Rakuten Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 *  Extensions to NSobject adding accessibility utilities
 */
@interface NSObject (RAccessibility)

/**
 *  Automatically sets the accessbilityIdentifier of UIView properties or UIViews contained in NSArray properties in this instance to the name of the property.
 *
 *  @note This method will *NOT* set the accessbility identifier of any UIView property that does not have a standard getter, begins with a "_" prefix, or is named "view".
 */
- (void)r_setupAccessbilityIdentifiers;

#if RSDKSupportShorthand

/**
 *  Alias for r_setupAccessibilityIdentifiers
 */
- (void)setupAccessibilityIdentifiers;

#endif

@end
