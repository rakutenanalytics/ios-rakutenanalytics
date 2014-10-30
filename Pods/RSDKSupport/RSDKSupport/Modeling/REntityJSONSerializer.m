//
//  REntityJSONSerializer.m
//  RSDKSupport
//
//  Created by Zachary Radke on 11/25/13.
//  Copyright (c) 2013 Rakuten Inc. All rights reserved.
//

#import "REntityJSONSerializer.h"
#import "RSDKError.h"

NSString *const REntityJSONSerializationErrorDomain = @"jp.co.rakuten.sdk.entityJSONSerializer.errors";


@implementation REntityJSONSerializer

#pragma mark - Initializers

+ (instancetype)serializerWithEntityClass:(Class)entityClass
{
    REntityJSONSerializer *serializer = [[self alloc] init];
    serializer.entityClass = entityClass;
    
    return serializer;
}


#pragma mark - Serializing JSON to entities

- (id)entityFromJSONDictionary:(NSDictionary *)JSONDictionary error:(NSError *__autoreleasing *)error
{
    return [self.class entityOfClass:self.entityClass fromJSONDictionary:JSONDictionary error:error];
}

+ (id)entityOfClass:(Class)entityClass fromJSONDictionary:(NSDictionary *)JSONDictionary error:(NSError *__autoreleasing *)error
{
    if (!entityClass || ![entityClass conformsToProtocol:@protocol(REntityJSONSerializer)])
    {
        if (error != NULL)
        {
            *error = [self _errorForMissingParameter:@"entityClass" recoverySuggestion:@"Pass a valid entity class that conforms to the REntityJSONSerializer protocol."];
        }
        return nil;
    }
    
    if (!JSONDictionary) { return nil; }
    
    __block id entity = [[entityClass alloc] init];
    
    if (JSONDictionary.count == 0) { return entity; }
    
    NSDictionary *JSONKeyPathsForPropertyKeys = [self _JSONKeyPathsForPropertyKeysOfClass:entityClass];
    
    BOOL populateSuccess = [self _populateEntity:entity withJSONDictionary:[JSONDictionary mutableCopy] JSONMapping:JSONKeyPathsForPropertyKeys reverse:NO error:error];
    
    if (!populateSuccess) { return nil; }
    
    return entity;
}


#pragma mark - Serializing entities to JSON

- (NSDictionary *)JSONDictionaryFromEntity:(id)entity error:(NSError *__autoreleasing *)error
{
    return [self.class JSONDictionaryFromEntity:entity error:error];
}

+ (NSDictionary *)JSONDictionaryFromEntity:(id<REntityJSONSerializer>)entity error:(NSError *__autoreleasing *)error
{
    if (!entity)
    {
        if (error != NULL)
        {
            *error = [self _errorForMissingParameter:@"entity" recoverySuggestion:@"Pass an enity to serialize."];
        }
        return nil;
    }
    
    NSMutableDictionary *JSONDictionary = [NSMutableDictionary dictionary];
    
    NSDictionary *JSONKeyPathsForPropertyKeys = [self _JSONKeyPathsForPropertyKeysOfClass:[entity class]];
    
    BOOL populateSuccess = [self _populateEntity:entity withJSONDictionary:JSONDictionary JSONMapping:JSONKeyPathsForPropertyKeys reverse:YES error:error];
    
    if (!populateSuccess) { return nil; }
    
    return [JSONDictionary copy];
}

+ (void)_fillJSONDictionary:(NSMutableDictionary *)JSONDictionary withValue:(id)value forKeyPath:(NSString *)JSONKeyPath
{
    if (!value) { return; } // If the value is nil, we assume that it should not appear in the JSON at all
    
    NSArray *splitJSONKeyPath = [JSONKeyPath componentsSeparatedByString:@"."];
    
    NSMutableDictionary *currentJSONDictionary = JSONDictionary;
    for (NSString *JSONPathComponent in splitJSONKeyPath)
    {
        if ([currentJSONDictionary valueForKey:JSONPathComponent] == nil)
        {
            currentJSONDictionary[JSONPathComponent] = [NSMutableDictionary dictionary];
        }
        
        currentJSONDictionary = currentJSONDictionary[JSONPathComponent];
    }
    
    [JSONDictionary setValue:value forKeyPath:JSONKeyPath];
}


#pragma mark - Common utilities

+ (NSDictionary *)_JSONKeyPathsForPropertyKeysOfClass:(Class)entityClass
{
    if (![entityClass conformsToProtocol:@protocol(REntityJSONSerializer) ]) { return nil; }
    
    return [entityClass JSONKeyPathsForPropertyKeys];
}

+ (BOOL)_populateEntity:(id)entity withJSONDictionary:(NSMutableDictionary *)JSONDictionary JSONMapping:(NSDictionary *)JSONKeyPathsForPropertyKeys reverse:(BOOL)reverse error:(NSError *__autoreleasing *)error
{
    if (!JSONKeyPathsForPropertyKeys)
    {
        if (error != NULL)
        {
            *error = [self _errorForMissingParameter:@"JSONKeyPathsForPropertyKeys" recoverySuggestion:@"Make sure your entity's class provides property key to JSON mapping."];
        }
        return NO;
    }
    
    __block BOOL populateSuccess = YES;
    
    [JSONKeyPathsForPropertyKeys enumerateKeysAndObjectsUsingBlock:^(id properyKey, id JSONKeyPath, BOOL *stop) {
        if (JSONKeyPath == [NSNull null]) { return; }
        
        populateSuccess = [self _tryExecutingBlock:^{
            id value = (reverse) ? [entity valueForKey:properyKey] : [JSONDictionary valueForKeyPath:JSONKeyPath];
            NSValueTransformer *valueTransformer = [self _valueTransformerForPropertyKey:properyKey inClass:[entity class]];
            
            value = [self _processValue:value withTransformer:valueTransformer reverseTransformation:reverse];
            
            if (!reverse)
            {
                [entity setValue:value forKey:properyKey];
            } else
            {
                [self _fillJSONDictionary:JSONDictionary withValue:value forKeyPath:JSONKeyPath];
            }
        } error:error];
        
        if (!populateSuccess) { *stop = YES; }
    }];
    
    return populateSuccess;
}

+ (id)_processValue:(__unsafe_unretained id)value withTransformer:(NSValueTransformer *)valueTransformer reverseTransformation:(BOOL)isReverseTransformation
{
    id processedValue = value;
    if (processedValue == [NSNull null]) { processedValue = nil; }
    
    if (!valueTransformer) { return processedValue; }
    
    if (isReverseTransformation)
    {
        if ([valueTransformer.class allowsReverseTransformation])
        {
            processedValue = [valueTransformer reverseTransformedValue:processedValue];
        }
    } else
    {
        processedValue = [valueTransformer transformedValue:processedValue];
    }
    
    return processedValue;
}

+ (NSValueTransformer *)_valueTransformerForPropertyKey:(NSString *)propertyKey inClass:(Class)entityClass
{
    SEL transformerSelector = NSSelectorFromString([propertyKey stringByAppendingString:@"JSONTransformer"]);
    
    if ([entityClass respondsToSelector:transformerSelector])
    {
        NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:[entityClass methodSignatureForSelector:transformerSelector]];
        invocation.target = entityClass;
        invocation.selector = transformerSelector;
        [invocation invoke];
        
        __unsafe_unretained id transformer;
        [invocation getReturnValue:&transformer];
        
        return transformer;
    }
    
    if ([entityClass respondsToSelector:@selector(JSONTransformerForPropertyKey:)])
    {
        return [entityClass JSONTransformerForPropertyKey:propertyKey];
    }
    
    return nil;
}

+ (BOOL)_tryExecutingBlock:(void (^)(void))block error:(NSError * __autoreleasing *)error
{
    if (!block) { return YES; }
    
    @try
    {
        block();
    }
    @catch (NSException *exception)
    {
#if DEBUG
        @throw exception;
#endif
        if (error != NULL)
        {
            NSDictionary *userInfo = @{NSLocalizedDescriptionKey: exception.description,
                                       NSLocalizedFailureReasonErrorKey: exception.reason};
            *error = [NSError errorWithDomain:REntityJSONSerializationErrorDomain code:REntityJSONSerializationExceptionError userInfo:userInfo];
        }
        
        return NO;
    }
    
    return YES;
}

+ (NSError *)_errorForMissingParameter:(NSString *)parameterName recoverySuggestion:(NSString *)recoverySuggestion
{
    RSDKMutableError *error = [RSDKMutableError errorWithDomain:REntityJSONSerializationErrorDomain code:REntityJSONSerializationMissingParameterError userInfo:nil];
    
    error.localizedDescription = @"Missing parameter error.";
    error.localizedFailureReason = [NSString stringWithFormat:@"Missing required parameter: %@", parameterName];
    error.localizedRecoverySuggestion = recoverySuggestion;
    
    return [error copy];
}

@end
