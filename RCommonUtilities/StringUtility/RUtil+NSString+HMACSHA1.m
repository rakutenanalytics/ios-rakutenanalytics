/*
 
 Reference from Rakuten iPhone Ichiba application code base
 Version: 1.6
 //
 //  NSString+SHA1.h
 //  Rakuten
 //
 //  Created by おとくですね on 10/12/02.
 //  Copyright 2010 __MyCompanyName__. All rights reserved.
 
*/
#import "RUtil+NSString+HMACSHA1.h"
#import "CommonCrypto/CommonDigest.h"
#import "CommonCrypto/CommonHMAC.h"
#import "RUtil+NSData+Base64EncDec.h"

@implementation NSString(RUtil_NSString_HMACSHA1)

/*
 * @functionName : HMACSHA1Encrption: 
 * @return       : Returns hmacsha1 string forme dusing the secret key
 * @param1       : secretKey of type NSString
 * @description  : Created category method for NSString inorder to provide encrypted string using the HMACSHA1 algorithm
 */
- (NSString *) HMACSHA1Encrption:(NSString *)secretKey
{
    unsigned char cHMAC[CC_SHA1_DIGEST_LENGTH];
	
	NSData *secretData = [secretKey dataUsingEncoding:NSASCIIStringEncoding];
    NSData *clearTextData = [self dataUsingEncoding:NSASCIIStringEncoding];
	CCHmac(kCCHmacAlgSHA1, [secretData bytes], [secretData length], [clearTextData bytes], [clearTextData length], cHMAC);
	
	NSData *hmac = [[NSData alloc] initWithBytes:cHMAC
										  length:sizeof(cHMAC)];
	NSString *retHmac = [hmac stringEncodedWithBase64];
	return retHmac;
}
@end
