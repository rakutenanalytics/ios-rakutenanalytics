/*
 Copyright: Copyright (C) 2012 Rakuten, Inc.  All Rights Reserved.
 
 
 File Name:  RUtilHTTPManager+Post.h
 
 Description:   Category for RUtilHTTPManager responsible for forming the POST request using the key value pair or the map and will attach it to the POST body of the HTTP
 
 Author: Mandar Kadam
 
 Created: 25th-Jun-2012 
 
 Changed: 
 
 Version: 1.0
 
 */

#import <Foundation/Foundation.h>
#import "RUtilHTTPManager.h"

@interface RUtilHTTPManager(RUtilHTTPManager_Post)

//Forms url POST request consisting of key value pairs which comprise to form POST body. 
- (void)initWithRequest:(NSString*)url 
             parameters:(NSDictionary*)params 
  withConnectionTimeOut:(int)timeOut;

////Forms url POST request consisting of plain string which comprise to form POST body.Here url encoding is not done
- (void)initWithRequest:(NSString*)url 
     withOutURLEncoding:(NSDictionary*)params 
  withConnectionTimeOut:(int)timeOut;

//Performed the functionalty of sending data over network by making a call to make connection.
- (void)formURLRequestAndSendToNetwork:(NSString *)urlString 
                           andHTTPBody:(NSData *)postData
                           withTimeOut:(int)timeOut;

//Performs the synchronous call of sending data over network by making a call to connection.
- (NSData *)synchronousRequestWithURL:(NSString*)url
                           parameters:(NSDictionary*)params
                withConnectionTimeOut:(int)timeOut;

@end