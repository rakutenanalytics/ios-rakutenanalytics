#import "_NSString+Encryption.h"
#import <CommonCrypto/CommonDigest.h>

@implementation NSString (Encryption)

-(NSString*) rat_encrypt
{
    NSData *data = [self dataUsingEncoding:NSUTF8StringEncoding];
    NSMutableData *digest = [NSMutableData dataWithLength:CC_SHA256_DIGEST_LENGTH];
    CC_SHA256(data.bytes, (CC_LONG) data.length, digest.mutableBytes);

    NSMutableString *hexDigest = [NSMutableString stringWithCapacity:digest.length * 2];
    const unsigned char *bytes = digest.bytes;

    for (NSUInteger byteIndex = 0; byteIndex < digest.length; ++byteIndex)
    {
       [hexDigest appendFormat:@"%02x", (unsigned int) bytes[byteIndex]];
    }
    return hexDigest;
}

@end
