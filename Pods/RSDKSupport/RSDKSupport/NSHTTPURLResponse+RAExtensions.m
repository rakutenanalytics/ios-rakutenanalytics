//
//  NSHTTPURLResponse+RAExtensions.m
//  Authentication
//
//  Created by Gatti, Alessandro | Alex | SDTD on 5/9/13.
//  Copyright (c) 2013 Rakuten Inc. All rights reserved.
//

#import "NSHTTPURLResponse+RAExtensions.h"

@implementation NSHTTPURLResponse (RAExtensions)

- (NSStringEncoding)textEncoding
{
    NSString *encodingName = [self textEncodingName];
    return encodingName ? CFStringConvertEncodingToNSStringEncoding(CFStringConvertIANACharSetNameToEncoding((__bridge CFStringRef) encodingName)) : NSUTF8StringEncoding;
}

@end
