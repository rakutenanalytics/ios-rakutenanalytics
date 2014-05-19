//
//  NSObject+RAccessibility.m
//  RSDKSupport
//
//  Created by Zachary Radke on 1/9/14.
//  Copyright (c) 2014 Rakuten Inc. All rights reserved.
//

#import "NSObject+RAccessibility.h"
#import <UIKit/UIKit.h>
#import <objc/runtime.h>

@implementation NSObject (RAccessibility)

- (void)r_setupAccessbilityIdentifiers
{
    unsigned int propertyCount;
    
    Class currentClass = [self class];
    do
    {
        objc_property_t *properties = class_copyPropertyList(currentClass, &propertyCount);
        for (NSUInteger i = 0; i < propertyCount; i++)
        {
            objc_property_t property = properties[i];
            
            char *typeEncoding = NULL;
            typeEncoding = property_copyAttributeValue(property, "T");
            if (typeEncoding[0] != _C_ID) // Only accept object type properties
            {
                free(typeEncoding);
                continue;
            }
            free(typeEncoding);
            
            const char* name = property_getName(property);
            NSString *propertyName = [NSString stringWithUTF8String:name];
            //If it has an underscore, it was probably a private view and probably shouldn't try to get access to that
            //If its name is view, it might mean that there's no value to accessing the view, or its the UIViewController's view.
            //At this point, you should set the accessibility labels yourself.
            if (![self respondsToSelector:NSSelectorFromString(propertyName)] || [propertyName hasPrefix:@"_"] || [propertyName isEqualToString:@"view"])
            {
                continue;
            }
            
            id propertyObject = [self valueForKey:propertyName];
            if (!propertyObject) { continue; }
            
            if ([propertyObject isKindOfClass:[UIView class]])
            {
                [propertyObject setAccessibilityIdentifier:propertyName];
            } else if ([propertyObject isKindOfClass:[NSArray class]])
            {
                [propertyObject enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
                    if ([obj isKindOfClass:[UIView class]])
                    {
                        NSString *nameString = [NSString stringWithFormat:@"%s%lu", name, (unsigned long)idx];
                        [obj setAccessibilityIdentifier:nameString];
                    }
                }];
            }
        }
        
        free(properties);
        currentClass = [currentClass superclass];
        
    } while (currentClass);
}

#if RSDKSupportShorthand

- (void)setupAccessbilityIdentifiers
{
    [self r_setupAccessibilityIdentifiers];
}

#endif

@end
