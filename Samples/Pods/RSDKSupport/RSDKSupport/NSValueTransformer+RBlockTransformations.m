//
//  NSValueTransformer+RBlockTransformations.m
//  RSearch
//
//  Created by Zachary Radke on 11/18/13.
//  Copyright (c) 2013 Rakuten Inc. All rights reserved.
//
//  Copied shamelessly from https://github.com/mattt/TransformerKit

@import ObjectiveC.runtime;

#import "NSValueTransformer+RBlockTransformations.h"

@interface _RBlockTransformer : NSValueTransformer

@property (copy, nonatomic) id (^forwardBlock)(id value);
@property (copy, nonatomic) id (^reverseBlock)(id value);

+ (instancetype)transformerWithBlock:(id (^)(id value))block;
+ (instancetype)transformerWithForwardBlock:(id (^)(id value))forwardBlock reverseBlock:(id (^)(id value))reverseBlock;

@end


@interface _RBlockReversibleTranformer : _RBlockTransformer
@end


@implementation _RBlockTransformer

- (instancetype)initWithForwardBlock:(id (^)(id))forwardBlock reverseBlock:(id (^)(id))reverseBlock
{
    NSParameterAssert(forwardBlock);
    
    if (!(self = [super init])) { return nil; }
    
    _forwardBlock = [forwardBlock copy];
    _reverseBlock = [reverseBlock copy];
    
    return self;
}

+ (instancetype)transformerWithBlock:(id (^)(id))block
{
    return [self transformerWithForwardBlock:block reverseBlock:nil];
}

+ (instancetype)transformerWithForwardBlock:(id (^)(id))forwardBlock reverseBlock:(id (^)(id))reverseBlock
{
    Class transformerClass = (reverseBlock) ? [_RBlockReversibleTranformer class] : [_RBlockTransformer class];
    return [[transformerClass alloc] initWithForwardBlock:forwardBlock reverseBlock:reverseBlock];
}

+ (BOOL)allowsReverseTransformation
{
    return NO;
}

+ (Class)transformedValueClass
{
    return [NSObject class];
}

- (id)transformedValue:(id)value
{
    return self.forwardBlock(value);
}

@end


@implementation _RBlockReversibleTranformer

- (instancetype)initWithForwardBlock:(id (^)(id))forwardBlock reverseBlock:(id (^)(id))reverseBlock
{
    NSParameterAssert(reverseBlock);
    self = [super initWithForwardBlock:forwardBlock reverseBlock:reverseBlock];
    
    return self;
}

+ (BOOL)allowsReverseTransformation
{
    return YES;
}

- (id)reverseTransformedValue:(id)value
{
    return self.reverseBlock(value);
}

@end


@implementation NSValueTransformer (RBlockTransformations)

+ (BOOL)r_registerTransformerWithName:(NSString *)transformerName transformationBlock:(id (^)(id))transformBlock
{
    return [self r_registerTransformerWithName:transformerName transformationBlock:transformBlock reverseBlock:nil];
}

+ (BOOL)r_registerTransformerWithName:(NSString *)transformerName transformationBlock:(id (^)(id))transformBlock reverseBlock:(id (^)(id))reverseBlock
{
    NSParameterAssert(transformerName);
    NSParameterAssert(transformBlock);
    
    if ([NSValueTransformer valueTransformerForName:transformerName]) { return NO; }
    
    NSValueTransformer *transformer = [_RBlockTransformer transformerWithForwardBlock:transformBlock reverseBlock:reverseBlock];
    
    [NSValueTransformer setValueTransformer:transformer forName:transformerName];
    
    return YES;
}

+ (instancetype)r_transformerWithBlock:(id (^)(id))block
{
    return [self r_transformerWithForwardBlock:block reverseBlock:nil];
}

+ (instancetype)r_transformerWithForwardBlock:(id (^)(id))forwardBlock reverseBlock:(id (^)(id))reverseBlock
{
    return [_RBlockTransformer transformerWithForwardBlock:forwardBlock reverseBlock:reverseBlock];
}

#if RSDKSupportShorthand

+ (BOOL)registerTransformerWithName:(NSString *)transformerName transformationBlock:(id (^)(id))transformBlock
{
    return [self r_registerTransformerWithName:transformerName transformationBlock:transformBlock];
}

+ (BOOL)registerTransformerWithName:(NSString *)transformerName transformationBlock:(id (^)(id))transformBlock reverseBlock:(id (^)(id))reverseBlock
{
    return [self r_registerTransformerWithName:transformerName transformationBlock:transformBlock reverseBlock:reverseBlock];
}

+ (instancetype)transformerWithBlock:(id (^)(id))block
{
    return [self r_transformerWithBlock:block];
}

+ (instancetype)transformerWithForwardBlock:(id (^)(id))forwardBlock reverseBlock:(id (^)(id))reverseBlock
{
    return [self r_transformerWithForwardBlock:forwardBlock reverseBlock:reverseBlock];
}

#endif

@end
