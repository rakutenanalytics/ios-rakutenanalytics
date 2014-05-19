//
//  NSData+RAExtensions.m
//  Authentication
//
//  Created by Gatti, Alessandro | Alex | SDTD on 5/24/13.
//  Copyright (c) 2013 Rakuten Inc. All rights reserved.
//

#import "RSDKAssert.h"

#import "NSData+RAExtensions.h"

// For SHA-1 and HMAC
#import <CommonCrypto/CommonCrypto.h>

@implementation NSData (RAExtensions)

- (NSString *)base64
{
    NSMutableString *result = [NSMutableString new];
    NSUInteger offset = 0;
    NSInteger state = 0;
    NSInteger index = 0;
    const unsigned char *data = [self bytes];
    
    static const char kBase64Table[] = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";
    
    while (offset < [self length])
    {
        switch (state)
        {
            case 0:
                index = (data[offset] >> 2) & 0x3F;
                break;
                
            case 1:
                index = (data[offset++] & 0x03) << 4;
                if (offset < [self length])
                {
                    index |= (data[offset] >> 4) & 0x0F;
                }
                break;
                
            case 2:
                index = (data[offset++] & 0x0F) << 2;
                if (offset < [self length])
                {
                    index |= (data[offset] >> 6) & 0x03;
                }
                break;
                
            case 3:
                index = data[offset++] & 0x3F;
                break;
                
            default:
                break;
        }
        
        state = (state + 1) % 4;
        [result appendFormat:@"%c", kBase64Table[index]];
    }
    
    switch (state)
    {
        case 1:
        case 2:
            [result appendString:@"=="];
            break;
            
        case 3:
            [result appendString:@"="];
            break;
            
        default:
            break;
    }
    
    return result;
}

- (instancetype)sha1
{
    unsigned char hash[CC_SHA1_DIGEST_LENGTH];
    if (!CC_SHA1(self.bytes, (unsigned int)self.length, hash)) { return nil; }
    
    return [[self class] dataWithBytes:hash length:CC_SHA1_DIGEST_LENGTH];
}

- (instancetype)hmacSha1ForKey:(NSData *)key
{
    unsigned char mac[CC_SHA1_DIGEST_LENGTH];
    CCHmac(kCCHmacAlgSHA1, key.bytes, key.length, self.bytes, self.length, mac);
    
    return [[self class] dataWithBytes:mac length:CC_SHA1_DIGEST_LENGTH];
}

static NSString *const kRHexTable = @"0123456789abcdef";

- (NSString *)hexadecimal
{

    
    NSMutableString *output = [NSMutableString stringWithCapacity:self.length * 2];

    for (NSUInteger offset = 0; offset < self.length; offset++)
    {
        const NSUInteger index = ((const unsigned char *)self.bytes)[offset];
        [output appendFormat:@"%C%C", [kRHexTable characterAtIndex:(index >> 4)], [kRHexTable characterAtIndex:(index & 0x0F)]];
    }

    return output;
}

+ (instancetype)dataWithHexadecimal:(NSString *)string
{
    if (!string || (string.length == 0) || ((string.length % 2) != 0))
    {
        return nil;
    }

    NSMutableData *output = [NSMutableData new];
    [output setLength:(string.length / 2)];
    NSUInteger targetOffset = 0;
    NSUInteger offset = 0;

    NSString *lowercase = [string lowercaseString];

    while (offset < string.length)
    {
        NSRange range = [kRHexTable rangeOfString:[lowercase substringWithRange:NSMakeRange(offset++, 1)]];
        if (range.location == NSNotFound)
        {
            return nil;
        }

        RSDKASSERTIFNOT(range.location <= 0x0F, @"Range out of bounds");

        unsigned char byte = (unsigned char)(range.location << 4);

        range = [kRHexTable rangeOfString:[lowercase substringWithRange:NSMakeRange(offset++, 1)]];
        if (range.location == NSNotFound)
        {
            return nil;
        }

        RSDKASSERTIFNOT(range.location <= 0x0F, @"Range out of bounds");

        byte += (unsigned char)(range.location);

        ((unsigned char *)output.mutableBytes)[targetOffset++] = byte;
    }
    
    return [self dataWithData:output];
}

@end
