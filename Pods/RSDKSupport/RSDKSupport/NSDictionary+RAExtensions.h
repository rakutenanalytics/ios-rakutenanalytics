//
//  NSDictionary+RAExtensions.h
//  Authentication
//
//  Created by Gatti, Alessandro | Alex | SDTD on 5/17/13.
//  Copyright (c) 2013 Rakuten Inc. All rights reserved.
//

@import Foundation;

/**
 * Dictionary information container.
 *
 * @class RDictionaryStructure NSDictionary+RAExtensions.h <RSDKSupport/NSDictionary+RAExtensions.h>
 */
@interface RDictionaryStructure : NSObject

/**
 * A dictionary of keys with their expected type.
 */
@property (nonatomic, copy) NSDictionary *structure;

/**
 * A list of required keys.
 */
@property (nonatomic, copy) NSArray *requiredFields;

/**
 * Initialises a @ref RDictionaryStructure with the given (key,type) pairs
 * in a dictionary and the given required fields list.
 *
 * @see @ref NSDictionary(RAExtensions)
 *
 * @param structure A dictionary containing string keys and their
 *        respective types.  Must not be `nil`, and types must be either
 *        `NSString`, `NSNumber`, `NSArray`, `NSDictionary` or `NSNull`.
 * @param requiredFields A list containing string keys that must
 *        be present in a dictionary to be considered valid.  Can be
 *        `nil` if that part of the validation process is optional.
 *
 * @return An initialised @ref RDictionaryStructure or `nil` if parameters
 *         were invalid.
 */
- (instancetype)initWithStructure:(NSDictionary *)structure
                andRequiredFields:(NSArray *)requiredFields;

@end

/**
 * Category extending `NSDictionary` with additions needed by the Rakuten SDK.
 *
 * @category NSDictionary(RAExtensions) NSDictionary+RAExtensions.h <RSDKSupport/NSDictionary+RAExtensions.h>
 */
@interface NSDictionary (RAExtensions)

/**
 * Check if the dictionary contains the given key.
 *
 * @param key The key to check for.
 *
 * @return `YES` if present, `NO` otherwise.
 */
- (BOOL)hasKey:(id)key;

/**
 * Check if the dictionary contains a `NSString` under the given key.
 *
 * @param key The key to check for.
 *
 * @return `YES` if present and mapping to a `NSString` instance, `NO` otherwise.
 */
- (BOOL)hasStringForKey:(id)key;

/**
 * Check if the dictionary contains a `NSDictionary` under the given key.
 *
 * @param key The key to check for.
 *
 * @return `YES` if present and mapping to a `NSDictionary` instance, `NO` otherwise.
 */
- (BOOL)hasDictionaryForKey:(id)key;

/**
 * Check if the dictionary contains a `NSNumber` under the given key.
 *
 * @param key The key to check for.
 *
 * @return `YES` if present and mapping to a `NSNumber` instance, `NO` otherwise.
 */
- (BOOL)hasBooleanForKey:(id)key;

/**
 * Check if the dictionary contains a `NSArray` under the given key.
 *
 * @param key The key to check for.
 *
 * @return `YES` if present and mapping to a `NSArray` instance, `NO` otherwise.
 */
- (BOOL)hasArrayForKey:(id)key;

/**
 * Check if the dictionary matches the structure defined by the given
 * RDictionaryStructure instance.
 *
 * @param structure The dictionary structure to check against.
 *
 * @return `YES` if matches, `NO` otherwise.
 */
- (BOOL)matchesStructure:(RDictionaryStructure *)structure;

@end
