//
//  RProperty.h
//  RSearch
//
//  Created by Zachary Radke on 10/29/13.
//  Copyright (c) 2013 Rakuten Inc. All rights reserved.
//

@import Foundation;
@import ObjectiveC.runtime;

/**
 * @ingroup SupportConstants
 */
FOUNDATION_EXTERN NSString *const RPropertyAttributeTypeEncoding;

/**
 * @ingroup SupportConstants
 */
FOUNDATION_EXTERN NSString *const RPropertyAttributeIVarName;

/**
 * @ingroup SupportConstants
 */
FOUNDATION_EXTERN NSString *const RPropertyAttributeReadOnly;

/**
 * @ingroup SupportConstants
 */
FOUNDATION_EXTERN NSString *const RPropertyAttributeCopy;

/**
 * @ingroup SupportConstants
 */
FOUNDATION_EXTERN NSString *const RPropertyAttributeRetain;

/**
 * @ingroup SupportConstants
 */
FOUNDATION_EXTERN NSString *const RPropertyAttributeNonAtomic;

/**
 * @ingroup SupportConstants
 */
FOUNDATION_EXTERN NSString *const RPropertyAttributeCustomGetter;

/**
 * @ingroup SupportConstants
 */
FOUNDATION_EXTERN NSString *const RPropertyAttributeCustomSetter;

/**
 * @ingroup SupportConstants
 */
FOUNDATION_EXTERN NSString *const RPropertyAttributeDynamic;

/**
 * @ingroup SupportConstants
 */
FOUNDATION_EXTERN NSString *const RPropertyAttributeWeak;

/**
 * @ingroup SupportConstants
 */
FOUNDATION_EXTERN NSString *const RPropertyAttributeGarbageCollectable;

/**
 * @ingroup SupportConstants
 */
FOUNDATION_EXTERN NSString *const RPropertyAttributeOldTypeEncoding;


/**
 * `RProperty` is an object representing a class' property. This is mostly useful for class
 * introspection.
 *
 * Instances of this class require a backing `objc_property_t`, a type defined in the
 * `<objc/runtime.h>`. In order to get properties from a class, the functions `class_getProperty()` or
 * `class_copyPropertyList()` should be used, also defined in the `<objc/runtime.h>`.
 *
 * @class RProperty RProperty.h <RSDKSupport/RProperty.h>
 */
@interface RProperty : NSObject

/// @name Creating properties

/**
 * Generate a new instance with a backing property.
 *
 * @param property The `objc_property_t` which backs this instance.
 * @return A new instance of the calling class.
 */
+ (instancetype)propertyWithObjCProperty:(objc_property_t)property;

/**
 * The designated initializer for this class with a backing property.
 *
 * @param property The `objc_property_t` which backs this instance.
 * @return A new instance of the calling class.
 */
- (instancetype)initWithObjCProperty:(objc_property_t)property;


/// @name Common attributes

/**
 * Get the name of the backing property.
 *
 * @return The name of the backing property as an `NSString`.
 */
- (NSString *)name;

/**
 * Get the iVar name of the backing property.
 *
 * @return The iVar name which backs the property as an `NSString`.
 */
- (NSString *)iVarName;

/**
 * Get the type encoding of the backing property.
 *
 * @return The type encoding of the backing property as an `NSString`.
 */
- (NSString *)typeEncoding;

/**
 * Checks if the property is read-only or not.
 *
 * @return A flag indicating if this property is read-only or not.
 */
- (BOOL)isReadOnly;

/**
 * Checks if the property has a primitive type or an object type.
 *
 * @return A flag indicating if this property's type is primitive or not.
 */
- (BOOL)isPrimitiveType;

/**
 * Attempts to parse a class from #typeEncoding.
 *
 * @note Protocols are ignored from #typeEncoding.
 * @return A class parsed from #typeEncoding, or `NULL` if the property is primitive or of type `id`.
 */
- (Class)typeClass;

/**
 * Returns a custom getter selector if it is defined.
 *
 * @return The custom getter selector if it exists, or `NULL`.
 */
- (SEL)customGeter;

/**
 * Returns a custom setter selector if it is defined.
 *
 * @return The custom setter selector if it exists, or `NULL`.
 */
- (SEL)customSetter;


/// @name Accessing attributes

/**
 * Gets the property attributes as a dictionary.
 *
 * If a key exists in these attributes, the attribute exists in the property. Some attributes will
 * also have an associated value, such as the custom getter key, while others do not.
 *
 * @see #hasAttribute: for a list of attribute keys.
 * @return A dictionary of attributes present in the backing property.
 */
- (NSDictionary *)attributes;

/**
 * Check if the passed attribute exists in the backing property. The following
 * attributes are considered valid ーother strings passed will result in `NO`
 * being returned:
 *
 *  - #RPropertyAttributeTypeEncoding
 *  - #RPropertyAttributeIVarName
 *  - #RPropertyAttributeReadOnly
 *  - #RPropertyAttributeCopy
 *  - #RPropertyAttributeRetain
 *  - #RPropertyAttributeNonAtomic
 *  - #RPropertyAttributeCustomGetter
 *  - #RPropertyAttributeCustomSetter
 *  - #RPropertyAttributeDynamic
 *  - #RPropertyAttributeWeak
 *  - #RPropertyAttributeGarbageCollectable
 *  - #RPropertyAttributeOldTypeEncoding
 *
 *  @param attribute The attribute to check for.
 *  @return `YES` if the given attribute is present, or `NO` if it is not.
 */
- (BOOL)hasAttribute:(NSString *)attribute;

@end
