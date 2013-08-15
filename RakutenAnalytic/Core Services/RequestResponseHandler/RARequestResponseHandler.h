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

#import <UIKit/UIKit.h>
#import "RUtilHTTPManager.h"
#import "RUtilHTTPManager+Post.h"

@interface RARequestResponseHandler : NSObject
{
@private
    
    //HTTPManager object reponsible performing url connection.
    RUtilHTTPManager        *httpManager;
}
//initiate the server request if network is available else return with an error.
-(void)makeRequestWithParameters:(NSMutableDictionary *)params
                    andTimeStamp:(NSString *)timestamp;

@end
