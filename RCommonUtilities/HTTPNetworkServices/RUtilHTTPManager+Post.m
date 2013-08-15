/*
 Copyright: Copyright (C) 2012 Rakuten, Inc.  All Rights Reserved.
 
 
 File Name:  RUtilHTTPManager+Post.h
 
 Description:   Category for RUtilHTTPManager responsible for forming the POST request using the key value pair or the map and will attach it to the POST body of the HTTP
 
 Author: Mandar Kadam
 
 Created: 25th-Jun-2012 
 
 Changed: 
 
 Version: 1.0
 
 */

#import "RUtilHTTPManager+Post.h"
#import "RCommon.h"
#import "RUtilLogger.h"
#import "RGenericUtility.h"

//POST body constants
NSString *const kPost =  @"POST";
NSString *const kContentTypeValue = @"application/x-www-form-urlencoded; charset=utf-8";
NSString *const kContentTypeKey = @"Content-Type";
NSString *const kContentLengthKey = @"Content-Length";

@implementation RUtilHTTPManager(RUtilHTTPManager_Post)

/*
 @function      initWithRequest: parameters: withConnectionTimeOut:
 @description   initiate request with api url, performs the functionality of forming the POST body using the dictionary or the
 key value pairs.
 @param         requestUrl
 @param         params of type NSDictionary
 @param         connectionTimeOut
 @return        void
 */
- (void)initWithRequest:(NSString*)url 
             parameters:(NSDictionary*)params 
  withConnectionTimeOut:(int)timeOut
{
    NSData* httpBody = [[RGenericUtility formKeyValuePair:params withEncoding:YES] dataUsingEncoding:NSUTF8StringEncoding];
	
    [self formURLRequestAndSendToNetwork:url andHTTPBody:httpBody withTimeOut:timeOut];
}

- (NSData *)synchronousRequestWithURL:(NSString*)url
                           parameters:(NSDictionary*)params
                withConnectionTimeOut:(int)timeOut
{
    NSData* httpBody = [[RGenericUtility formKeyValuePair:params withEncoding:YES] dataUsingEncoding:NSUTF8StringEncoding];
	
    NSURL *webservice_url = [NSURL URLWithString:url];
    
	NSMutableURLRequest* urlRequest = [NSMutableURLRequest requestWithURL:webservice_url];
    
    [urlRequest setHTTPMethod:kPost];
    [urlRequest setHTTPBody:httpBody];
	
    [urlRequest setValue:kContentTypeValue forHTTPHeaderField:kContentTypeKey];
	[urlRequest setValue:[NSString stringWithFormat:@"%d", httpBody.length] forHTTPHeaderField:kContentLengthKey];
	
    [urlRequest setTimeoutInterval:timeOut];
    return [self makeSynchronousRequestWithURL:urlRequest withConnectionTimeOut:timeOut];
}

/*
 @function      formURLRequestAndSendToNetwork: andHTTPBody: withConnectionTimeOut:
 @description   initiate request with api url, performs the functionality of forming the POST body using the binay data
 @param         urlString of type NSString
 @param         postdata of type binary format.
 @param         connectionTimeOut
 @return        void
 */
- (void)formURLRequestAndSendToNetwork:(NSString *)urlString
                           andHTTPBody:(NSData *)postData
                           withTimeOut:(int)timeOut
{
    NSURL *webservice_url = [NSURL URLWithString:urlString];
    
	NSMutableURLRequest* urlRequest = [NSMutableURLRequest requestWithURL:webservice_url];
    
    [urlRequest setHTTPMethod:kPost];
    [urlRequest setHTTPBody:postData];
	
    [urlRequest setValue:kContentTypeValue forHTTPHeaderField:kContentTypeKey];
	[urlRequest setValue:[NSString stringWithFormat:@"%d", postData.length] forHTTPHeaderField:kContentLengthKey];
	
    [urlRequest setTimeoutInterval:timeOut];
    
	[self makeRequest:urlRequest withConnectionTimeOut:timeOut];
}
/*
 @function      initWithRequest: withOutURLEncoding: withConnectionTimeOut:
 @description   initiate request with api url, performs the functionality of forming the POST body using the dictionary or the
 key value pairs.Here value is not URL encoded.
 @param         requestUrl
 @paaram        params of type NSString
 @param         connectionTimeOut
 @return        void
 */
- (void)initWithRequest:(NSString*)url 
     withOutURLEncoding:(NSDictionary*)params 
  withConnectionTimeOut:(int)timeOut
{
    NSData* httpBody = [[RGenericUtility formKeyValuePair:params withEncoding:NO] dataUsingEncoding:NSUTF8StringEncoding];
    
    [self formURLRequestAndSendToNetwork:url andHTTPBody:httpBody withTimeOut:timeOut];  
}

@end
