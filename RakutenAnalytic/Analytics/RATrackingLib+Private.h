/*
 Copyright: Copyright (C) 2012 Rakuten, Inc.  All Rights Reserved.
 
 
 File Name:  RATrackingLib+Private.h
 
 Description: Category class used specifically for testing the private methods of Tracking library.
 
 Author: Mandar Kadam
 
 Created: 3rd-Jan-2013
 
 Changed:
 
 Version: 1.0
 
 */

#import <Foundation/Foundation.h>
#import "RATrackingLib.h"

@interface RATrackingLib(RATrackingLib_Private)
//Getting the price.
- (NSString *)getPriceValue;

//Flush or clear vector data.
- (void)flushAndThenInitialiseVectorData;

//Returns the formatted string in the JSON format.
-(NSString *)getFormattedString;
@end