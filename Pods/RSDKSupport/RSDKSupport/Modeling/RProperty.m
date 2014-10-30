//
//  RProperty.m
//  RSearch
//
//  Created by Zachary Radke on 10/29/13.
//  Copyright (c) 2013 Rakuten Inc. All rights reserved.
//

#import "RProperty.h"

NSString *const RPropertyAttributeTypeEncoding = @"T";
NSString *const RPropertyAttributeIVarName = @"V";
NSString *const RPropertyAttributeReadOnly = @"R";
NSString *const RPropertyAttributeCopy = @"C";
NSString *const RPropertyAttributeRetain = @"&";
NSString *const RPropertyAttributeNonAtomic = @"N";
NSString *const RPropertyAttributeCustomGetter = @"G";
NSString *const RPropertyAttributeCustomSetter = @"S";
NSString *const RPropertyAttributeDynamic = @"D";
NSString *const RPropertyAttributeWeak = @"W";
NSString *const RPropertyAttributeGarbageCollectable = @"P";
NSString *const RPropertyAttributeOldTypeEncoding = @"t";

@interface RProperty ()
{
    objc_property_t _property;
    NSString *_name;
    NSMutableDictionary *_mutableAttributes;
}
@end

@implementation RProperty

+ (instancetype)propertyWithObjCProperty:(objc_property_t)property
{
    return [[self alloc] initWithObjCProperty:property];
}

- (instancetype)initWithObjCProperty:(objc_property_t)property
{
    if ((self = [super init]))
    {
        _property = property;
        _name = [NSString stringWithUTF8String:property_getName(property)];
        
        NSArray *attributePairs = [[NSString stringWithUTF8String:property_getAttributes(property)] componentsSeparatedByString:@","];
        _mutableAttributes = [NSMutableDictionary dictionary];
        for (NSString *pair in attributePairs)
        {
            [_mutableAttributes setObject:[pair substringFromIndex:1] forKey:[pair substringToIndex:1]];
        }
    }
    
    return self;
}

- (NSString *)name
{
    return _name;
}

- (NSDictionary *)attributes
{
    return [_mutableAttributes copy];
}

- (NSString *)iVarName
{
    return [_mutableAttributes objectForKey:RPropertyAttributeIVarName];
}

- (NSString *)typeEncoding
{
    return [_mutableAttributes objectForKey:RPropertyAttributeTypeEncoding];
}

- (BOOL)isReadOnly
{
    return [self hasAttribute:RPropertyAttributeReadOnly];
}

- (BOOL)isPrimitiveType
{
    return ![[[self typeEncoding] substringToIndex:1] isEqualToString:@"@"];
}

- (Class)typeClass
{
    NSString *typeEncoding = [self typeEncoding];
    
    if (!typeEncoding || [self isPrimitiveType]) { return NULL; }
    
    NSMutableCharacterSet *validClassCharacters = [NSMutableCharacterSet alphanumericCharacterSet];
    [validClassCharacters removeCharactersInString:@"@\"<>"];
    
    NSArray *explodedType = [typeEncoding componentsSeparatedByCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"@\""]];
    
    NSString *cleanedEncoding = [explodedType componentsJoinedByString:@""];
    
    NSScanner *scanner = [NSScanner scannerWithString:cleanedEncoding];
    NSString *protocolEncoding = nil;
    [scanner scanUpToString:@"<" intoString:NULL];
    [scanner scanUpToString:@">" intoString:&protocolEncoding];
    
    if (protocolEncoding)
    {
        protocolEncoding = [protocolEncoding stringByAppendingString:@">"];
        cleanedEncoding = [cleanedEncoding stringByReplacingOccurrencesOfString:protocolEncoding withString:@""];
    }
    
    if (!cleanedEncoding || cleanedEncoding.length == 0) { return NULL; }
    
    return NSClassFromString(cleanedEncoding);
}

- (SEL)customGeter
{
    return NSSelectorFromString([_mutableAttributes objectForKey:RPropertyAttributeCustomGetter]);
}

- (SEL)customSetter
{
    return NSSelectorFromString([_mutableAttributes objectForKey:RPropertyAttributeCustomSetter]);
}

- (BOOL)hasAttribute:(NSString *)attribute
{
    return [_mutableAttributes objectForKey:attribute] != nil;
}

@end
