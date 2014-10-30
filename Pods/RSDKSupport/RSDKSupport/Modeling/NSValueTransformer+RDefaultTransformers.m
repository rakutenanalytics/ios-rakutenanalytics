//
//  NSValueTransformer+RDefaultTransformers.m
//  RSDKSupport
//
//  Created by Zachary Radke on 11/25/13.
//  Copyright (c) 2013 Rakuten Inc. All rights reserved.
//

#import "NSValueTransformer+RDefaultTransformers.h"
#import "NSValueTransformer+RBlockTransformations.h"
#import "REntityJSONSerializer.h"

NSString *const kRDefaultURLTransformerName = @"kRDefaultURLTransformerName";
NSString *const kRDefaultDateTransformerName = @"kRDefaultDateTransformerName";
NSString *const kRDefaultDateFormat = @"yyyy-MM-dd'T'HH:mm:ss'Z'";

@implementation NSValueTransformer (RDefaultTransformers)

+ (void)load
{
    @autoreleasepool
    {
        [self r_registerTransformerWithName:kRDefaultURLTransformerName transformationBlock:^id(id value) {
            return (value) ? [NSURL URLWithString:value] : nil;
            
        } reverseBlock:^id(id value) {
            return (value) ? [value absoluteString] : nil;
        }];
        
        NSDateFormatter *(^dateFormatterBlock)(void) = ^NSDateFormatter *() {
            static NSDateFormatter *sharedDateFormatter;
            static dispatch_once_t onceToken;
            dispatch_once(&onceToken, ^{
                
                sharedDateFormatter = [NSDateFormatter new];
                sharedDateFormatter.locale = [NSLocale localeWithLocaleIdentifier:@"en_US_POSIX"];
                sharedDateFormatter.dateFormat = kRDefaultDateFormat;
            });
            
            return sharedDateFormatter;
        };
        
        [self r_registerTransformerWithName:kRDefaultDateTransformerName transformationBlock:^id(id value) {
            if (!value) { return nil; }
            NSDateFormatter *dateFormatter = dateFormatterBlock();
            return [dateFormatter dateFromString:value];
            
        } reverseBlock:^id(id value) {
            if (!value) { return nil; }
            NSDateFormatter *dateFormatter = dateFormatterBlock();
            return [dateFormatter stringFromDate:value];
        }];
    }
}

+ (instancetype)r_JSONToEntityTransformerForClass:(Class)entityClass
{
    NSParameterAssert(entityClass);
    NSParameterAssert([entityClass conformsToProtocol:@protocol(REntityJSONSerializer)]);
    
    return [self r_transformerWithForwardBlock:^id(id value) {
        if (!value) { return nil; }
        return [REntityJSONSerializer entityOfClass:entityClass fromJSONDictionary:value error:NULL];
        
    } reverseBlock:^id(id value) {
        if (!value) { return nil; }
        return [REntityJSONSerializer JSONDictionaryFromEntity:value error:NULL];
    }];
}

#if RSDKSupportShorthand

+ (instancetype)JSONToEntityTransformerForClass:(Class)entityClass
{
    return [self r_JSONToEntityTransformerForClass:entityClass];
}

#endif

@end
