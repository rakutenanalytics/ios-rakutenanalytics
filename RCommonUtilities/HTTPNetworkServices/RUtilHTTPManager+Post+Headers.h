/*
 Copyright: Copyright (C) 2013 Rakuten, Inc.  All Rights Reserved.
 
 
 File Name:  RUtilHTTPManager+Post+Headers.h
 
 Description:   Category for RUtilHTTPManager responsible for forming the POST request and also adding the headers to the post request.
 
 Author: Mandar Kadam
 
 Created: 4/17/13
 
 Changed:
 
 Version: 1.0
 
 */

#import <Foundation/Foundation.h>
#import "RUtilHTTPManager+Post.h"

@interface RUtilHTTPManager(RUtilHTTPManager_Post_Headers)
- (void)initWithURL:(NSString *)url
         parameters:(NSDictionary *)params
             header:(NSDictionary *)headerFields
        withTimeOut:(int)timeOut;
@end
