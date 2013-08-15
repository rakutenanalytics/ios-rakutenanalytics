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

#import <Foundation/Foundation.h>

@interface NSString(RUtil_NSString_HMACSHA1)

//Generating a HMACSHA1 encrypted string
- (NSString *) HMACSHA1Encrption:(NSString *)secretKey;
@end
