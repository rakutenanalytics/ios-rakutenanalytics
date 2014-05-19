//
//  NSData+RAExtensions.m
//  Authentication
//
//  Created by Gatti, Alessandro | Alex | SDTD on 5/13/13.
//  Copyright (c) 2013 Rakuten Inc. All rights reserved.
//

#import "NSString+RAExtensions.h"

@implementation NSString (RAExtensions)

+ (instancetype)stringWithUUID
{
    if ([NSUUID class])
    {
        // iOS 6+
        return [[NSUUID UUID] UUIDString];
    } else
    {
        // iOS 5.x
        CFUUIDRef uuidRef = CFUUIDCreate(kCFAllocatorDefault);
        if (uuidRef)
        {
            CFStringRef uuidString = CFUUIDCreateString(kCFAllocatorDefault, uuidRef);
            CFRelease(uuidRef);
            return uuidString ? (__bridge_transfer NSString *) uuidString : nil;
        }

        return nil;
    }
}

- (instancetype)trim
{
    return [self stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
}



- (BOOL)isEmpty
{
    return (self.length == 0) || ([self trim].length == 0);
}

@end
