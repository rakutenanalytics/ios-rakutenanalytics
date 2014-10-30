//
//  RBaseEntity.h
//  RSearch
//
//  Created by Zachary Radke on 10/28/13.
//  Copyright (c) 2013 Rakuten Inc. All rights reserved.
//

@import Foundation;

#import <RSDKSupport/REntityJSONSerializer.h>

/**
 * The domain for RBaseEntity errors.
 *
 * @ingroup SupportConstants
 */
FOUNDATION_EXPORT NSString *const kRBaseEntityErrorDomain;

/**
 * An error raised when an unexpected exception was caught.
 *
 * @ingroup SupportConstants
 */
FOUNDATION_EXPORT NSInteger const RBaseEntityExceptionError;

/**
 * A protocol for uniquely identifying entities, regardless of changes made to
 * their internal contents.
 *
 * This is especially useful for resolving duplicates of models returned from
 * an external API and merging their differences.
 *
 * @protocol RUniqueEntity RBaseEntity.h <RSDKSupport/RBaseEntity.h>
 */
@protocol RUniqueEntity <NSObject>
@required

/**
 * Return a unique identifier for this entity.
 *
 * The unique id should not change based on the internal contents of a model.
 * Instead it should be set to a static string which can be used to identify it
 * over time. For example, a server might return an entity with a server id,
 * which could be returned from this method.
 *
 * @return A string uniquely identifying the entity.
 */
- (NSString *)uniqueID;
@end

@class RProperty;

/**
 * An abstract class representing a base entity which can be subclassed to
 * easily interface with external APIs.
 *
 * # Equality and hashing
 *
 * This class provides immediate equality checks and hash support to its
 * subclasses using an comparison of property values and a XOR hash of its
 * properties' values.
 *
 * # Copying
 *
 * This class provides immediate copy functionality for properties to its
 * subclasses, assuming the properties are visible to the class internally.
 *
 * @note This class should be subclassed before being used. Specifically, the
 *       protocol methods @ref RUniqueEntity-p::uniqueID and
 *       @ref REntityJSONSerializer-p::JSONKeyPathsForPropertyKeys should be overriden.
 *       By default, the former will return a string with the instance's pointer
 *       and the latter simply map property keys to JSON key paths directly.
 *
 * @class RBaseEntity RBaseEntity.h <RSDKSupport/RBaseEntity.h>
 */
@interface RBaseEntity : NSObject <RUniqueEntity, REntityJSONSerializer, NSCopying>

/// @name Converting to and from dictionary representations

/**
 * Initializer which immediately invokes #populateWithAttributes:.
 *
 * @param attributes The attributes matching settable property keys to populate the new instance with.
 * @return A new, populated instance of the receiver.
 */
- (instancetype)initWithAttributes:(NSDictionary *)attributes;

/**
 * Attemtps to populate the instance with a dictionary of property keys and associated values.
 *
 * @note `NSNull` values will be converted into `nil`.
 * @warning If attempting to set one of the property keys and values raises an exception in debug
 * mode, this will throw the exception.
 * @param attributes The attributes matching settable property keys and matching values.
 */
- (void)populateWithAttributes:(NSDictionary *)attributes;

/**
 * Converts the entity into an `NSDictionary`.
 *
 * @note `nil` property values will be converted into `NSNull`.
 * @return An `NSDictionary` representing this entity.
 * @see #propertyKeys
 */
- (NSDictionary *)dictionaryValue;


/// @name Class introspection

/**
 * A set of available (settable) property keys.
 *
 * @note A settable property is defined as one that is either not read-only, or provides a public
 * facing iVar.
 * @return A set of `NSString` objects for settable properties.
 */
+ (NSSet *)propertyKeys;

/**
 * Enumerates through all properties of a class using the passed block.
 *
 * This method will enumerate through all properties of a class, and execute the passed block with
 * each. To stop the enumeration, the `BOOL` flag passed can be set to `YES`. This method includes
 * properties inherited up to this class.
 *
 * @note This method will do nothing if passed a `nil` block.
 * @param block A block for interacting with each property, with a boolean flag to stop the
 * enumeration.
 */
+ (void)enumeratePropertiesWithBlock:(void (^)(RProperty *property, BOOL *stop))block;

@end
