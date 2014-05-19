//
//  NSValueTransformer+RBlockTransformations.h
//  RSearch
//
//  Created by Zachary Radke on 11/18/13.
//  Copyright (c) 2013 Rakuten Inc. All rights reserved.
//

#import <Foundation/Foundation.h>


/**
 * This category adds methods for creating block based NSValueTransformers, and registering them
 */
@interface NSValueTransformer (RBlockTransformations)

/// @name Creating block transformers

/**
 * Creates a one-way transformer with a block
 *
 * @param block The block to use when transforming a value into another value. This parameter is
 * required
 * @return A new instance of the caller
 */
+ (instancetype)r_transformerWithBlock:(id (^)(id))block;

/**
 * Creates a transformer with a forward and reversal block
 *
 * @param forwardBlock The block to use when transforming a value into another value. This parameter
 * is required
 * @param reverseBlock An optional block which undoes the action of the forwardBlock. If this is nil,
 * the transformer returned will be one-way and raise an exception if the `reverseTransformedValue:`
 * is invoked
 * @return A new instance of the caller
 */
+ (instancetype)r_transformerWithForwardBlock:(id (^)(id value))forwardBlock reverseBlock:(id (^)(id value))reverseBlock;


/// @name Registering transformers

/**
 * Attempts to creates and register a one-way block-based NSValueTransformer
 *
 * If successful, the transformer can be accessed using the class method `valueTransformerForName:`
 * on NSValueTransformer. If a transformer was already registered with the passed name, this method
 * will return `NO`.
 *
 * @param transformerName The name to register the new transformer with. This parameter is required
 * @param transformBlock The block to use when transforming a value into another value. This
 * parameter is required
 * @return A flag indicating if the registration was successful or not.
 * @see r_transformerWithBlock:
 */
+ (BOOL)r_registerTransformerWithName:(NSString *)transformerName transformationBlock:(id (^)(id value))transformBlock;

/**
 * Attempts to create and register a block-based NSValueTransformer
 *
 * If successful, the transformer can be accessed using the class method `valueTransformerForName:`
 * on NSValueTransformer. If a transformer was already registered with the passed name, this method
 * will return `NO`.
 *
 * @param transformerNameThe name to register the new transformer with. This parameter is required
 * @param transformBlock The block to use when transforming a block into another value. This
 * parameter is required
 * @param reverseBlock A block that undoes the transformation of the transformBlock. This parameter
 * is optional
 * @return A flag indicating if the registration was successful or not
 * @see r_transformerWithForwardBlock:reverseBlock:
 */
+ (BOOL)r_registerTransformerWithName:(NSString *)transformerName transformationBlock:(id (^)(id value))transformBlock reverseBlock:(id (^)(id value))reverseBlock;

#if RSDKSupportShorthand

/// @name Shorthand versions

/**
 * Alias for r_registerTransformerWithName:transformationBlock:
 *
 * @see r_registerTransformerWithName:transformationBlock:
 */
+ (BOOL)registerTransformerWithName:(NSString *)transformerName transformationBlock:(id (^)(id value))transformBlock;

/**
 * Alias for r_registerTransformerWithName:transformationBlock:reverseBlock:
 *
 * @see r_registerTransformerWithName:transformationBlock:reverseBlock:
 */
+ (BOOL)registerTransformerWithName:(NSString *)transformerName transformationBlock:(id (^)(id value))transformBlock reverseBlock:(id (^)(id value))reverseBlock;

/**
 * Alias for r_transformerWithBlock:
 *
 * @see r_transformerWithBlock:
 */
+ (instancetype)transformerWithBlock:(id (^)(id))block;

/**
 * Alias for r_transformerWithForwardBlock:reverseBlock:
 *
 * @see r_transformerWithForwardBlock:reverseBlock:
 */
+ (instancetype)transformerWithForwardBlock:(id (^)(id value))forwardBlock reverseBlock:(id (^)(id value))reverseBlock;

#endif

@end
