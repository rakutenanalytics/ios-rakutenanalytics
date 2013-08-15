/*
 Copyright: Copyright (C) 2012 Rakuten, Inc.  All Rights Reserved.
 
 
 File Name:  RUtilHTTPManager.m
 
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

#import "RUtilHTTPManager.h"
#import "FXReachability.h"
#import "RUtilLogger.h"
#import "RCommon.h"

NSString *const kRakutenServiceTimeOutURL = @"";

@interface RUtilHTTPManager ()
@property (strong, nonatomic) NSArray *trustedHosts;
@end

@implementation RUtilHTTPManager
@synthesize urlConnection = _urlConnection, mutableData = _mutableData;
@synthesize delegate = _delegate, urlRequest =_urlRequest;
@synthesize statusCode = _statusCode;
@synthesize trustedHosts;

- (id)init {
    self = [super init];
    if(self) {
        trustedHosts = [NSArray arrayWithObjects:@"app.rakuten.co.jp", @"member.id.rakuten.co.jp", @"image.rakuten.co.jp", @"rat.rd.rakuten.co.jp", @"24x7.app.rakuten.co.jp", nil];
    }
    return self;
} 

/*!
 @function      makeRequest:
 @discussion    initiate the server request if network is available else return with an error.
 @param         requestUrl
 @param         connectionTimeOut
 @return        void
 */
-(void)makeRequest:(NSURLRequest*)requestUrl withConnectionTimeOut:(int)connectionTimeOut
{
    @try {
        
        if([FXReachability isReachable]){
            self.urlRequest = requestUrl;
            
            NSURL *url =[NSURL URLWithString:[NSString	stringWithFormat:@"%@",kRakutenServiceTimeOutURL]];
            if ([[requestUrl URL] isEqual:url])
            {
                requestTimer = [NSTimer scheduledTimerWithTimeInterval:connectionTimeOut target:self selector:@selector(connectionTimeOut) userInfo:nil repeats:NO];
            }
            _urlConnection = [[NSURLConnection alloc] initWithRequest:self.urlRequest delegate:self];
        }
        else 
        {
            NSError *error = nil;//set No network connectivity in object.		
            NSDictionary *userInfo = [[NSDictionary alloc] initWithObjectsAndKeys:kNoNetwork,kError, nil];
            error = [NSError errorWithDomain:@"Rakuten" code:kNoNetworkErr userInfo:userInfo];
           
            if([self.delegate respondsToSelector:@selector(handleError:)])
            {
                [self.delegate handleError:error]; //No Network connection
            } else if(failureBlock){
                failureBlock(error);
            }
        }        
	}
	@catch (NSException * exception) {
        RULog(@"%@",exception.description);
	}
}

/** Initialize a request and make synchronous call
 @param request The request to use in the connection.
 @param connectionTimeOut of type int
 @param binary data of type NSData.
 */
- (NSData *)makeSynchronousRequestWithURL:(NSURLRequest*)requestUrl withConnectionTimeOut:(int)connectionTimeOut
{
    NSData *responseData = nil;
    if([FXReachability isReachable]){
        NSHTTPURLResponse *urlResponse = nil;
        NSError *error = nil;
        responseData = [NSURLConnection sendSynchronousRequest:requestUrl returningResponse:&urlResponse error:&error];
        RULog(@"Response: %@, ode: %d", responseData, [urlResponse statusCode]);
        _statusCode = [urlResponse statusCode];
    }
    return responseData;
}

- (void)makeRequest:(NSURLRequest *)request
            timeout:(int)connectionTimeout
    completionBlock:(RUtilHTTPRequestCompletionBlock)aCompletionBlock
       failureBlock:(RUtilHTTPRequestFailureBlock)aFailureBlock {
    completionBlock = aCompletionBlock;
    failureBlock = aFailureBlock;
    [self makeRequest:request withConnectionTimeOut:connectionTimeout];
}

#pragma mark NSURLConnection delegate methods
/*!
 @function		connection:didReceiveResponse:
 @discussion	connection:didReceiveResponse: is called when
 enough data has been read to construct an NSURLResponse object. 
 @param			connection	-	NSURLConnection object
 @param			response
 @result		void
 */
- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
    @try {
        NSHTTPURLResponse* httpResponse = (NSHTTPURLResponse*)response;
        _statusCode = [httpResponse statusCode];
        int contentSize = [httpResponse expectedContentLength] > 0 ? [httpResponse expectedContentLength] : 0;
        _mutableData = nil;
        _mutableData = [[NSMutableData alloc] initWithCapacity:contentSize];
	}
	@catch (NSException * exception) {
        RULog(@"%@",exception.description);
	}
    
}

/*!
 @function		connection:didReceiveData:
 @discussion	connection:didReceiveData: is called with a single
 immutable NSData object to the delegate,representing the next portion of the data loaded
 from the connection. 
 @param			connection	-	NSURLConnection object
 @param			data		-	received binary data
 @result		void
 */
- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    [self.mutableData appendData:data]; 
}

/*!
 @function		connection:didFailWithError:
 @discussion	connection:didFailWithError: will be called at
 most once, if an error occurs during a resource 
 @param			connection	-	NSURLConnection object
 @param			error		-	Error object having code description in it.
 @result		void
 */
- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    @try {
        _mutableData = nil;
        if([self.delegate respondsToSelector:@selector(handleError:)])
        {
            [self.delegate handleError:error];
        } else if(failureBlock) {
            failureBlock(error);
        }
	}
	@catch (NSException * exception) {
        RULog(@"%@",exception.description);
	}
}

/*!
 @function      connectionTimeOut
 @discussion    denied request if server is not responding whithin 10 sec.
 @return        void
 */
- (void)connectionTimeOut
{
    @try {
        NSError *error = nil;//set No network connectivity in object.		
        NSDictionary *userInfo = [[NSDictionary alloc] initWithObjectsAndKeys:kServerError,kError, nil];
        error = [NSError errorWithDomain:@"jp.co.rakuten.RUtilHTTPManager" code:kNoServerResponce userInfo:userInfo];
        
        if([self.delegate respondsToSelector:@selector(handleError:)])
        {
            [self.delegate handleError:error];
        } else if(failureBlock) {
            failureBlock(error);
        }
	}
	@catch (NSException * exception) {
        RULog(@"%@",exception.description);
	}
}
/*
 @function      connectionDidFinishLoading:
 @description   When the connection has finished and succeeded in downloading the response, the connectionDidFinishLoading: method will be called:
 @param         connection of type NSURLConnection
 @return        nil
 */
- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    @try {
        if(_statusCode == 200) {
            if([self.delegate respondsToSelector:@selector(handleReceivedData:)])
            {
                [self.delegate handleReceivedData:self.mutableData];
            } else if(completionBlock) {
                completionBlock(self.mutableData);
            }
        } else {
            NSString *string = [[NSString alloc] initWithData:self.mutableData encoding:NSUTF8StringEncoding];
            NSDictionary *errorInfo = nil;
            if (string) {
                 errorInfo = [NSDictionary dictionaryWithObject:string
                                                                      forKey:NSLocalizedDescriptionKey];
            }
            
            NSError *error = [NSError errorWithDomain:@"jp.co.rakuten.RUtilHTTPManager" code:_statusCode userInfo:errorInfo];
            if([self.delegate respondsToSelector:@selector(handleError:)])
            {
                [self.delegate handleError:error];
            } else if(failureBlock) {
                failureBlock(error);
            }
        }
    }
    @catch (NSException * exception) {
        RULog(@"%@",exception.description);
    }
}

- (BOOL)connection:(NSURLConnection *)connection canAuthenticateAgainstProtectionSpace:(NSURLProtectionSpace *)protectionSpace {
    return [protectionSpace.authenticationMethod isEqualToString:NSURLAuthenticationMethodServerTrust];
}

- (void)connection:(NSURLConnection *)connection didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge {
    [self connection:connection willSendRequestForAuthenticationChallenge:challenge];
}

- (void)connection:(NSURLConnection *)connection willSendRequestForAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge {
    if ([challenge.protectionSpace.authenticationMethod isEqualToString:NSURLAuthenticationMethodServerTrust]) {
        if ([trustedHosts containsObject:challenge.protectionSpace.host]) { // Bypass SSL for trusted hosts
            [challenge.sender useCredential:[NSURLCredential credentialForTrust:challenge.protectionSpace.serverTrust] forAuthenticationChallenge:challenge];
        }
    }
    [challenge.sender continueWithoutCredentialForAuthenticationChallenge:challenge];
}


/*
 @function      dealloc
 @description   Performs the functionality of canelling url connection and setting delgate to nil.
 @param         nil
 @return        nil
 */
-(void)dealloc
{
    self.delegate = nil;
    if(_urlConnection)
    {
        [_urlConnection cancel];
        _urlConnection = nil;
    }
    _mutableData = nil;
    self.urlRequest = nil;
}
@end