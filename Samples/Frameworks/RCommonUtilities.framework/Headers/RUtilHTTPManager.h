/*
 Copyright: Copyright (C) 2012 Rakuten, Inc.  All Rights Reserved.
 
 
 File Name:  RUtilHTTPManager.h
 
 Description: This component is designed in order to communicate with the server from the application over http. 
 This component encapsulates all the http related functionalities like making a URL connection, setting up http
 methods, http headers, http body etc. This component will be used by application components whenever there is need to
 connect to web services and send data or analytics information to server. 
 This component is designed in an asynchronous fashion so that application components will not get blocked by a
 network call.     
 
 Author: Mandar Kadam
 
 Created: 5th-Jun-2012  
 
 Changed: 
 
 Version: 1.0
 
 *
 */
#import <Foundation/Foundation.h>

typedef void(^RUtilHTTPRequestCompletionBlock)(NSData *data);
typedef void(^RUtilHTTPRequestFailureBlock)(NSError *error);

@protocol RUtilHTTPManagerDelegate <NSObject>

- (void)handleReceivedData:(NSData*)data;
- (void)handleError:(NSError*)error;

@end

@interface RUtilHTTPManager : NSObject
{
@private
    NSURLConnection                     *_urlConnection;
    NSMutableData                       *_mutableData;
    NSURLRequest                        *_urlRequest;
    NSUInteger                          _statusCode;
    NSTimer                             *requestTimer;
    RUtilHTTPRequestCompletionBlock     completionBlock;
    RUtilHTTPRequestFailureBlock        failureBlock;
    
}
@property (nonatomic, unsafe_unretained) id <RUtilHTTPManagerDelegate>   delegate;
@property (nonatomic, strong, readonly) NSURLConnection *urlConnection;
@property (nonatomic, strong, readonly) NSMutableData   *mutableData;
@property (nonatomic, strong) NSURLRequest      *urlRequest;
@property (readonly) NSUInteger                 statusCode;

/**
 initiate the server request if network is available else return with an error.
 @param requestUrl The request to use in the connection.
 @param connectionTimeOut The timeout value in seconds.
 */
-(void)makeRequest:(NSURLRequest*)requestUrl withConnectionTimeOut:(int)connectionTimeOut;

/**
 Initialize a request with support for completion and failure blocks.
 The completion/failure blocks will only be called if the handleReceivedData: and handleError: delegate methods aren't implemented.
 @param request The request to use in the connection. 
 @param timeout The timeout value in seconds.
 @param completionBlock The block to call if the request is completed.
 @param failureBlock The block to call if the request failed.
 */
- (void)makeRequest:(NSURLRequest *)request
            timeout:(int)connectionTimeout
    completionBlock:(RUtilHTTPRequestCompletionBlock)aCompletionBlock
       failureBlock:(RUtilHTTPRequestFailureBlock)aFailureBlock;

/** Initialize a request and make synchronous call
 @param request The request to use in the connection.
 @param connectionTimeOut of type int
 @param binary data of type NSData.
 */
- (NSData *)makeSynchronousRequestWithURL:(NSURLRequest*)requestUrl
                   withConnectionTimeOut:(int)connectionTimeOut;

@end
