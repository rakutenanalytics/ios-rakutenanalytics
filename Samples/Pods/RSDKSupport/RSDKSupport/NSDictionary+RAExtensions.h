//
//  NSDictionary+RAExtensions.h
//  Authentication
//
//  Created by Gatti, Alessandro | Alex | SDTD on 5/17/13.
//  Copyright (c) 2013 Rakuten Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 * Dictionary information container.
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
 * Initialises a RDictionaryStructure with the given key,type pairs
 * in a dictionary and the given required fields list.
 *
 * @see [NSDictionary(RAExtensions) matchesStructure:]
 *
 * @param structure A dictionary containing string keys and their
 *        respective types.  Must not be nil, and types must be either
 *        NSString, NSNumber, NSArray, NSDictionary, or NSNull.
 * @param requiredFields A list containing string keys that must
 *        be present in a dictionary to be considered valid.  Can be
 *        nil if that part of the validation process is optional.
 *
 * @return An initialised RDictionaryStructure or nil if parameters
 *         were invalid.
 */
- (instancetype)initWithStructure:(NSDictionary *)structure
                andRequiredFields:(NSArray *)requiredFields;

@end

/**
 * Category extending NSDictionary with additions needed by the Rakuten SDK.
 */
@interface NSDictionary (RAExtensions)

/**
 * Checks if the dictionary contains the given key.
 *
 * @param key The key to check for.
 *
 * @return YES if present, NO otherwise.
 */
- (BOOL)hasKey:(id)key;

/**
 * Checks if the dictionary contains a NSString under the given key.
 *
 * @param key The key to check for.
 *
 * @return YES if present containing a NSString, NO otherwise.
 */
- (BOOL)hasStringForKey:(id)key;

/**
 * Checks if the dictionary contains a NSDictionary under the given key.
 *
 * @param key The key to check for.
 *
 * @return YES if present containing a NSDictionary, NO otherwise.
 */
- (BOOL)hasDictionaryForKey:(id)key;

/**
 * Checks if the dictionary contains a NSNumber under the given key.
 *
 * @param key The key to check for.
 *
 * @return YES if present containing a NSNumber, NO otherwise.
 */
- (BOOL)hasBooleanForKey:(id)key;

/**
 * Checks if the dictionary contains a NSArray under the given key.
 *
 * @param key The key to check for.
 *
 * @return YES if present containing a NSArray, NO otherwise.
 */
- (BOOL)hasArrayForKey:(id)key;

/**
 * Checks if the dictionary matches the structure defined by the given
 * dictionary structure object.
 *
 * @param structure The dictionary structure to check against.
 *
 * @return YES if matches, NO otherwise.
 */
- (BOOL)matchesStructure:(RDictionaryStructure *)structure;

@end
