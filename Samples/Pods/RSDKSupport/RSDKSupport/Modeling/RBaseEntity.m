//
//  RBaseEntity.m
//  RSearch
//
//  Created by Zachary Radke on 10/28/13.
//  Copyright (c) 2013 Rakuten Inc. All rights reserved.
//
//  Copied shamelessly from https://github.com/github/Mantle/tree/master/Mantle

@import ObjectiveC.runtime;

#import "RBaseEntity.h"
#import "RProperty.h"

NSString *const kRBaseEntityErrorDomain = @"jp.co.rakuten.sdk.baseEntity.errors";
NSInteger const RBaseEntityExceptionError = -1989;

static void *kRBaseEntityPropertyKey = &kRBaseEntityPropertyKey;

@implementation RBaseEntity

- (instancetype)initWithAttributes:(NSDictionary *)attributes
{
    if ((self = [super init]))
    {
        [self populateWithAttributes:attributes];
    }
    
    return self;
}

- (void)populateWithAttributes:(NSDictionary *)attributes
{
    for (NSString *key in attributes)
    {
        id value = attributes[key];
        
        if (value == [NSNull null]) { value = nil; }
        
        [self trySettingValue:value forPropertyKey:key error:NULL];
    }
}

- (BOOL)trySettingValue:(id)value forPropertyKey:(NSString *)key error:(NSError * __autoreleasing *)error
{
    @try
    {
        [self setValue:value forKey:key];
        return YES;
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
            *error = [NSError errorWithDomain:kRBaseEntityErrorDomain code:RBaseEntityExceptionError userInfo:userInfo];
        }
        
        return NO;
    }
}

- (NSDictionary *)dictionaryValue
{
    return [self dictionaryWithValuesForKeys:self.class.propertyKeys.allObjects];
}

+ (void)enumeratePropertiesWithBlock:(void (^)(RProperty *property, BOOL *shouldStop))block
{
    if (!block) { return; }
    
    Class currentClass = self;
    BOOL shouldStop = NO;
    
    while (!shouldStop && currentClass != [RBaseEntity class])
    {
        unsigned int propertyCount = 0;
        objc_property_t *properties = class_copyPropertyList(currentClass, &propertyCount);
        
        currentClass = [currentClass superclass];
        
        if (properties == NULL)
        {
            free(properties);
            continue;
        }
        
        for (NSUInteger i = 0; i < propertyCount; i++)
        {
            RProperty *property = [RProperty propertyWithObjCProperty:properties[i]];
            block(property, &shouldStop);
            
            if (shouldStop) { break; }
        }
        
        free(properties);
    }
}

+ (NSSet *)propertyKeys
{
    NSSet *storedProperties = objc_getAssociatedObject(self, kRBaseEntityPropertyKey);
    if (storedProperties) { return storedProperties; }
    
    NSMutableSet *mutableProperties = [NSMutableSet set];
    [self enumeratePropertiesWithBlock:^(RProperty *property, BOOL *stop) {
        
        if ([property isReadOnly] && [property iVarName].length == 0) { return; }
        
        [mutableProperties addObject:property.name];
        
    }];
    
    objc_setAssociatedObject(self, kRBaseEntityPropertyKey, mutableProperties, OBJC_ASSOCIATION_COPY);
    
    return [mutableProperties copy];
}


#pragma mark - RUniqueIdentity

- (NSString *)uniqueID
{
    // Subclasses should override this
    return [NSString stringWithFormat:@"%p", self];
}


#pragma mark - REntityJSONSerializer

+ (NSDictionary *)JSONKeyPathsForPropertyKeys
{
    NSMutableDictionary *JSONKeyPathsForPropertyKeys = [NSMutableDictionary dictionary];
    
    for (NSString *propertyKey in [self propertyKeys])
    {
        JSONKeyPathsForPropertyKeys[propertyKey] = propertyKey;
    }
    
    return [JSONKeyPathsForPropertyKeys copy];
}


#pragma mark - NSCopying protocol

- (instancetype)copyWithZone:(NSZone *)zone
{
    return [[self.class allocWithZone:zone] initWithAttributes:self.dictionaryValue];
}


#pragma mark - NSObject protocol

- (NSString *)description
{
    return [NSString stringWithFormat:@"<%@: %p> %@", NSStringFromClass(self.class), self, self.dictionaryValue];
}

- (NSUInteger)hash
{
    NSUInteger hash = 0;
    
    for (NSString *key in self.class.propertyKeys)
    {
        hash ^= [[self valueForKey:key] hash];
    }
    
    return hash;
}

- (BOOL)isEqual:(id)object
{
    if (self == object) { return YES; }
    
    if (![object isMemberOfClass:self.class]) { return NO; }
    
    id selfValue, otherValue;
    for (NSString *key in self.class.propertyKeys)
    {
        selfValue = [self valueForKey:key];
        otherValue = [object valueForKey:key];
        
        BOOL equalValues = (selfValue == nil && otherValue == nil) || [selfValue isEqual:otherValue];
        if (!equalValues) { return NO; }
    }
    
    return YES;
}

@end
