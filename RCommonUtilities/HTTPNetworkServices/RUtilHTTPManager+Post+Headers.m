/*
 Copyright: Copyright (C) 2013 Rakuten, Inc.  All Rights Reserved.
 
 
 File Name:  RUtilHTTPManager+Post+Headers.h
 
 Description:   Category for RUtilHTTPManager responsible for forming the POST request and also adding the headers to the post request.
 
 Author: Mandar Kadam
 
 Created: 4/17/13
 
 Changed:
 
 Version: 1.0
 
 */
#import "RUtilHTTPManager+Post+Headers.h"
#import "RGenericUtility.h"

//POST body constants
NSString *const kHeadersPost =  @"POST";
NSString *const kHeadersContentTypeValue = @"application/x-www-form-urlencoded; charset=utf-8";
NSString *const kHeadersContentTypeKey = @"Content-Type";
NSString *const kHeadersContentLengthKey = @"Content-Length";

@implementation RUtilHTTPManager(RUtilHTTPManager_Post_Headers)

- (void)initWithURL:(NSString *)url
         parameters:(NSDictionary *)params
             header:(NSDictionary *)headerFields
        withTimeOut:(int)timeOut
{
    
    NSData* httpBody = [[RGenericUtility formKeyValuePair:params withEncoding:YES] dataUsingEncoding:NSUTF8StringEncoding];
	
    NSURL *webservice_url = [NSURL URLWithString:url];
    
	NSMutableURLRequest* urlRequest = [NSMutableURLRequest requestWithURL:webservice_url];
    
    [urlRequest setHTTPMethod:kHeadersPost];
    [urlRequest setHTTPBody:httpBody];
	
    [urlRequest setValue:kHeadersContentTypeValue forHTTPHeaderField:kHeadersContentTypeKey];
	[urlRequest setValue:[NSString stringWithFormat:@"%d", httpBody.length] forHTTPHeaderField:kHeadersContentLengthKey];
    
    for (NSString *key in headerFields) {
        [urlRequest setValue:[headerFields valueForKey:key] forHTTPHeaderField:key];
    }
	
    [urlRequest setTimeoutInterval:timeOut];
    
	[self makeRequest:urlRequest withConnectionTimeOut:timeOut];
}

@end
