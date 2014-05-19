//
//  NSCoder+RAExtensions.m
//  RSDKSupport
//
//  Created by Gatti, Alessandro | Alex | SDTD on 6/2/13.
//  Copyright (c) 2013 Rakuten Inc. All rights reserved.
//

#import "NSCoder+RAExtensions.h"

#if !defined(__IPHONE_6_0) || __IPHONE_OS_VERSION_MIN_REQUIRED < __IPHONE_6_0

@implementation NSCoder (RAExtensions)

- (id)decodeObjectOfClass:(Class)class forKey:(NSString *)key
{
    
    SEL requiresSecureCoding = @selector(requiresSecureCoding);
    
    if ([self respondsToSelector:requiresSecureCoding] && [self requiresSecureCoding])
    {
        if (![class instancesRespondToSelector:requiresSecureCoding])
        {
            [NSException raise:NSInvalidArgumentException
                        format:@"Decoded class does not support secure coding"];
        }
        
        id object = [self decodeObjectForKey:key];
        if (![object isKindOfClass:class])
        {
            [NSException raise:NSInvalidArgumentException
                        format:@"Decoded object does not match required class"];
        }
        
        return object;
    }
    
    return [self decodeObjectForKey:key];
}

@end

#endif // !__IPHONE_6_0 || __IPHONE_OS_VERSION_MIN_REQUIRED < __IPHONE_6_0
