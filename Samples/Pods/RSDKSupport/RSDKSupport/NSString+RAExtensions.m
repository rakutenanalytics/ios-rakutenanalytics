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
    // Switch to NSUUID when iOS 5 is deprecated
#if __IPHONE_OS_VERSION_MIN_REQUIRED < __IPHONE_6_0
    CFUUIDRef uuidRef = CFUUIDCreate(kCFAllocatorDefault);
    if (uuidRef) {
        CFStringRef uuidString = CFUUIDCreateString(kCFAllocatorDefault, uuidRef);
        CFRelease(uuidRef);
        return uuidString ? (__bridge_transfer NSString *) uuidString : nil;
    }
    
    return nil;
#else
    return [[NSUUID UUID] UUIDString];
#endif // __IPHONE_OS_VERSION_MIN_REQUIRED < __IPHONE_6_0
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
