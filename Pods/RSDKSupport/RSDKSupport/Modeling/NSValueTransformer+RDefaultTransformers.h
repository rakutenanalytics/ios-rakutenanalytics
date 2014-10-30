//
//  NSValueTransformer+RDefaultTransformers.h
//  RSDKSupport
//
//  Created by Zachary Radke on 11/25/13.
//  Copyright (c) 2013 Rakuten Inc. All rights reserved.
//

@import Foundation;

/**
 * Identifier for the default URL transformer, which converts `NSString`
 * instances to `NSURL` ones and back.
 *
 * @ingroup SupportConstants
 */
FOUNDATION_EXTERN NSString *const kRDefaultURLTransformerName;

/**
 * Identifier for the default date transformer, which converts `NSString`
 * instances to `NSDate` ones and back.
 *
 * @ingroup SupportConstants
 */
FOUNDATION_EXTERN NSString *const kRDefaultDateTransformerName;

/**
 * Format of the default date transformer, set to `yyyy-MM-dd'T'HH:mm:ss'Z'`.
 *
 * @ingroup SupportConstants
 */
FOUNDATION_EXTERN NSString *const kRDefaultDateFormat;

/**
 * Adds some default transformers:
 *
 * * The **URL transformer** converts `NSString` instances to `NSURL` ones and back.
 *   It is registered under #kRDefaultURLTransformerName, and can be accessed via:
 *
 *       NSValueTransformer *transformer = [NSValueTransformer valueTransformerForName:kRDefaultURLTransformerName];
 *
 * * The **Date transformer** converts `NSString` instances to `NSDate` ones and back.
 *   It is registered under #kRDefaultDateTransformerName, and can be accessed via:
 *
 *       NSValueTransformer *transformer = [NSValueTransformer valueTransformerForName:kRDefaultDateTransformerName];
 *
 *   The default date format is defined in the constant #kRDefaultDateFormat as
 *   `yyyy-MM-dd'T'HH:mm:ss'Z'`.
 *
 * * **JSON to entity transformer:** The method #r_JSONToEntityTransformerForClass:
 *   can be used to get a transformer which will convert JSON dictionaries into new
 *   instances of the passed class. For more details, see REntityJSONSerializer.
 *
 * @category NSValueTransformer(RDefaultTransformers) NSValueTransformer+RDefaultTransformers.h <RSDKSupport/NSValueTransformer+RDefaultTransformers.h>
 */
@interface NSValueTransformer (RDefaultTransformers)

/**
 * Create a new value transformer which turns a JSON dictionary into an entity
 * and back.
 *
 * @param entityClass The class of the entity to serialize, which should
 *                    conform to the REntityJSONSerializer protocol.
 *
 * @return A new value transformer for the entity class.
 */
+ (instancetype)r_JSONToEntityTransformerForClass:(Class)entityClass;

#if RSDKSupportShorthand

/**
 * Alias for #r_JSONToEntityTransformerForClass:.
 *
 * @note This method is only available if #RSDKSupportShorthand has been defined.
 *
 * @param entityClass The class of the entity to serialize, which should.
 *                    conform to the REntityJSONSerializer protocol.
 *
 * @return A new value transformer for the entity class.
 */
+ (instancetype)JSONToEntityTransformerForClass:(Class)entityClass;

#endif

@end
