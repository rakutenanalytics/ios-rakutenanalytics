/*
 Copyright: Copyright (C) 2012 Rakuten, Inc.  All Rights Reserved.
 
 
 File Name:  RARequestResponseHandler.h
 
 Description: This component is designed in order create object of HTTP connection i.e URL connection object and perform or initiate connection. Also stores the timestamp of each track record which is useful in deleteing record from Database once successfull response is acquired.
 
 Author: Mandar Kadam
 
 Created: 5th-Jun-2012  
 
 Changed: 
 
 Version: 1.0
 
 *
 */

#import "RARequestResponseHandler.h"
#import "RADBHelper.h"
#import "RACommons.h"

@interface RARequestResponseHandler ()
@property(nonatomic, copy) NSString *timeStampValue;
-(void)releaseURLConnection;
@end

@implementation RARequestResponseHandler
@synthesize timeStampValue;

/*!
 @function		init
 @description   initiliasing the request response class
 @result		initialised object of request respponse handler
 */
-(id)init
{
    if((self = [super init]))
    {
        self.timeStampValue = nil;
    }
    return self;
}

/*!
 @function		makeRequestWithURL:andTimeStamp:
 @description   responsible for initiating an request to server with timestamp value
 @param			params	-	NSString object
 @param			timestamp		-	timestamp of type NSString
 @result		void
 */
-(void)makeRequestWithParameters:(NSMutableDictionary *)params
                    andTimeStamp:(NSString *)timestamp
{
    self.timeStampValue = timestamp;
    
    httpManager = [[RUtilHTTPManager alloc] init];

    #ifdef DEBUG
        NSData *data = [httpManager synchronousRequestWithURL:kRakutenServiceURL parameters:params withConnectionTimeOut:kConnectionTimeOut];
        RULog(@"data is: %@ code: %d, params: %@", data, [httpManager statusCode], params);
    #else
        [httpManager synchronousRequestWithURL:kRakutenServiceURL parameters:params withConnectionTimeOut:kConnectionTimeOut];
    #endif
    
    if( [httpManager statusCode] == 200 )
    {
        [[RADBHelper sharedInstance] deleteRecordWithTimeStamp:self.timeStampValue];
        [self releaseURLConnection];
    }
};

/*!
 @function		releaseURLConnection
 @discussion	Releases the connection object i.e RUtilHTTPManager object
 @param			data - received binary data
 @result		void
 */
-(void)releaseURLConnection
{
    if( httpManager )
    {
        httpManager.delegate = nil;
        httpManager = nil;
    }
}
/*
 @function      dealloc
 @description   Performs the functionality of releasing the the http connection and assign it to nil.
 @param         nil
 @return        nil
 */
-(void)dealloc{
    [self releaseURLConnection];
}
@end
