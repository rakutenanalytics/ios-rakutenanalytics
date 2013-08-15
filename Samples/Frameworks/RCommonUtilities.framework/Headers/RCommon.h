/*
 Copyright: Copyright (C) 2012 Rakuten, Inc.  All Rights Reserved.
 
 
 File Name:  RCommon.h
 
 Description: Used for defined for various localized strings variables and also string constants
 
 Author: Mandar Kadam
 
 Created:11th-June-2012
 
 Changed: 
 
 Version: 1.0
 
 *
 */

#ifdef __OBJC__
#import <Foundation/Foundation.h>
#endif

// NO Network connection
#define kNoNetwork          NSLocalizedString(@"Network not available",@"")
#define kServerError		NSLocalizedString(@"Server_Error",@"")


#define kError				NSLocalizedString(@"error", @"")
#define kSuccess			NSLocalizedString(@"success", @"")

/** Error Codes **/
#define kNoNetworkErr       50015

#define kNoServerResponce   50017
