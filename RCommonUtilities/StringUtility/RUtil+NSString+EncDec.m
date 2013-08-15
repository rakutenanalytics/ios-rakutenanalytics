//
//  NSString+URLEncoding.m
//
//  Created by Jon Crosby on 10/19/07.
//  Copyright 2007 Kaboomerang LLC. All rights reserved.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.

#import "RUtil+NSString+EncDec.h"

@implementation NSString (RUtil_NSString_EncDec)

/*
 * @functionName : urlEncodedString 
 * @return : Returns encoded string
 * @description : Created category method for NSString inorder to provide UTF8 encoding to the string.
 */
-(NSString *)urlEncodedString
{
	NSString *result = (__bridge_transfer NSString *)CFURLCreateStringByAddingPercentEscapes(
                                                               NULL,
                                                               (__bridge CFStringRef)self,
                                                               NULL,
                                                               CFSTR("!*'();:@&=+$,/?%#[]"), //The characters you want to replace go here
                                                               kCFStringEncodingUTF8 );
    return result;
}

/*
 * @functionName : urlDecodedString 
 * @return : Returns decoded string
 * @description : Created category method for NSString inorder to provide UTF8 decoding to the string.
 */
-(NSString*)urlDecodedString
{
    NSString *result = (__bridge_transfer NSString *)CFURLCreateStringByReplacingPercentEscapesUsingEncoding(
                                                                        NULL,
                                                                        (__bridge CFStringRef)self,      
                                                                        CFSTR(""),
                                                                        kCFStringEncodingUTF8);
    
    return result;           
}
@end
