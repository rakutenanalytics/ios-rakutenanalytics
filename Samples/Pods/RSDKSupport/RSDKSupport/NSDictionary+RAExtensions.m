//
//  NSDictionary+RAExtensions.m
//  Authentication
//
//  Created by Gatti, Alessandro | Alex | SDTD on 5/17/13.
//  Copyright (c) 2013 Rakuten Inc. All rights reserved.
//

#import "NSDictionary+RAExtensions.h"
#import "NSString+RAExtensions.h"

@implementation RDictionaryStructure

- (instancetype)initWithStructure:(NSDictionary *)structure
                andRequiredFields:(NSArray *)requiredFields
{
    
    if (!structure || !(self = [super init])) { return nil; }
    
    NSMutableDictionary *items = [NSMutableDictionary new];
    
    for (id key in structure)
    {
        if (![key isKindOfClass:[NSString class]] || [key isEmpty])
        {
            return nil;
        }
        
        id value = structure[key];
        if (!((value == [NSString class]) ||
              (value == [NSArray class]) ||
              (value == [NSDictionary class]) ||
              (value == [NSNumber class]) ||
              (value == [NSNull class])))
        {
            return nil;
        }
        
        NSString *trimmedKey = [key trim];
        
        if ([items hasKey:trimmedKey])
        {
            return nil;
        }
        
        items[trimmedKey] = value;
    }
    
    NSMutableArray *required = [NSMutableArray new];
    
    for (id field in requiredFields)
    {
        if ([field isKindOfClass:[NSString class]])
        {
            NSString *requiredItem = [field trim];
            if ((requiredItem.length == 0) || [required containsObject:requiredItem])
            {
                continue;
            }
            [required addObject:requiredItem];
        } else
        {
            return nil;
        }
    }
    
    _structure = items;
    _requiredFields = required;
    
    return self;
}

@end

@implementation NSDictionary (RAExtensions)

- (BOOL)hasKey:(id)key
{
    return key && self[key] != nil;
}

- (BOOL)hasStringForKey:(id)key
{
    return [self hasKey:key] && [self[key] isKindOfClass:[NSString class]];
}

- (BOOL)hasDictionaryForKey:(id)key
{
    return [self hasKey:key] && [self[key] isKindOfClass:[NSDictionary class]];
}

- (BOOL)hasBooleanForKey:(id)key
{
    if ([self hasKey:key] && [self[key] isKindOfClass:[NSNumber class]]) {
        CFNumberType numberType = CFNumberGetType((__bridge CFNumberRef)[self valueForKey:key]);
        return numberType == kCFNumberCharType;
    }
    
    return NO;
}

- (BOOL)hasArrayForKey:(id)key
{
    return [self hasKey:key] && [self[key] isKindOfClass:[NSArray class]];
}

- (BOOL)matchesStructure:(RDictionaryStructure *)structure
{
    if (!structure) { return NO; }
    
    for (id key in self)
    {
        if ([key isKindOfClass:[NSString class]] && [structure.structure hasKey:key])
        {
            if (![self[key] isKindOfClass:structure.structure[key]])
            {
                return NO;
            }
        }
    }

    for (NSString *key in structure.requiredFields)
    {
        if (![self hasKey:key])
        {
            return NO;
        }
    }

    return YES;
}

@end
