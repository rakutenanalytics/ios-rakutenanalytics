//
//  NSValueTransformer+RBlockTransformations.h
//  RSearch
//
//  Created by Zachary Radke on 11/18/13.
//  Copyright (c) 2013 Rakuten Inc. All rights reserved.
//

@import Foundation;


/**
 * Add methods for creating block-based `NSValueTransformers` and registering them.
 *
 * @category NSValueTransformer(RBlockTransformations) NSValueTransformer+RBlockTransformations.h <RSDKSupport/NSValueTransformer+RBlockTransformations.h>
 */
@interface NSValueTransformer (RBlockTransformations)

/// @name Creating block transformers

/**
 * Create a one-way transformer with a block.
 *
 * @param block The block to use when transforming a value into another value.
 * @return A new instance of the receiver.
 */
+ (instancetype)r_transformerWithBlock:(id (^)(id value))block;

/**
 * Create a transformer with forward and reverse transformation blocks.
 *
 * @param forwardBlock Block to be used when transforming a value into another value.
 * @param reverseBlock Optional block that undoes the action of `forwardBlock`.
 *                     If `nil`, transformations are one-way and raise an exception
 *                     if `-reverseTransformedValue:` is invoked.
 * @return A new instance of the receiver.
 */
+ (instancetype)r_transformerWithForwardBlock:(id (^)(id value))forwardBlock
                                 reverseBlock:(id (^)(id value))reverseBlock;


/// @name Registering transformers

/**
 * Attempt to create and register a one-way block-based `NSValueTransformer`.
 *
 * If successful, the transformer can be accessed using `+ [NSValueTransformer valueTransformerForName:]`.
 * If a transformer was already registered with the passed name, this method will return `NO`.
 *
 * @param transformerName The name to register the new transformer with.
 * @param transformBlock The block to be used for transforming a value into another value.
 * @return `YES` on success, `NO` on failure.
 * @see #r_transformerWithBlock:
 */
+ (BOOL)r_registerTransformerWithName:(NSString *)transformerName
                  transformationBlock:(id (^)(id value))transformBlock;

/**
 * Attempts to create and register a block-based `NSValueTransformer`.
 *
 * If successful, the transformer can be accessed using `+[NSValueTransformer valueTransformerForName:]`.
 * If a transformer was already registered with the passed name, this method will return `NO`.
 *
 * @param transformerName The name to register the new transformer with.
 * @param transformBlock The block to be used for transforming a value into another value.
 * @param reverseBlock Optional block that undoes the action of `forwardBlock`.
 *                     If `nil`, transformations are one-way and raise an exception
 *                     if `-reverseTransformedValue:` is invoked.
 * @return `YES` on success, `NO` on failure.
 * @see #r_transformerWithForwardBlock:reverseBlock:
 */
+ (BOOL)r_registerTransformerWithName:(NSString *)transformerName
                  transformationBlock:(id (^)(id value))transformBlock
                         reverseBlock:(id (^)(id value))reverseBlock;

#if RSDKSupportShorthand

/// @name Shorthand versions

/**
 * Alias for #r_registerTransformerWithName:transformationBlock:
 *
 * @note This method is only available if #RSDKSupportShorthand has been defined.
 *
 * @param transformerName The name to register the new transformer with.
 * @param transformBlock The block to be used for transforming a value into another value.
 * @return `YES` on success, `NO` on failure.
 */
+ (BOOL)registerTransformerWithName:(NSString *)transformerName
                transformationBlock:(id (^)(id value))transformBlock;

/**
 * Alias for #r_registerTransformerWithName:transformationBlock:reverseBlock:
 *
 * @note This method is only available if #RSDKSupportShorthand has been defined.
 *
 * @param transformerName The name to register the new transformer with.
 * @param transformBlock The block to be used for transforming a value into another value.
 * @param reverseBlock Optional block that undoes the action of `forwardBlock`.
 *                     If `nil`, transformations are one-way and raise an exception
 *                     if `-reverseTransformedValue:` is invoked.
 * @return `YES` on success, `NO` on failure.
 */
+ (BOOL)registerTransformerWithName:(NSString *)transformerName
                transformationBlock:(id (^)(id value))transformBlock
                       reverseBlock:(id (^)(id value))reverseBlock;

/**
 * Alias for #r_transformerWithBlock:
 *
 * @note This method is only available if #RSDKSupportShorthand has been defined.
 *
 * @param block The block to use when transforming a value into another value.
 * @return A new instance of the receiver.
 */
+ (instancetype)transformerWithBlock:(id (^)(id value))block;

/**
 * Alias for #r_transformerWithForwardBlock:reverseBlock:
 *
 * @note This method is only available if #RSDKSupportShorthand has been defined.
 *
 * @param forwardBlock Block to be used when transforming a value into another value.
 * @param reverseBlock Optional block that undoes the action of `forwardBlock`.
 *                     If `nil`, transformations are one-way and raise an exception
 *                     if `-reverseTransformedValue:` is invoked.
 * @return A new instance of the receiver.
 */
+ (instancetype)transformerWithForwardBlock:(id (^)(id value))forwardBlock
                               reverseBlock:(id (^)(id value))reverseBlock;

#endif

@end
