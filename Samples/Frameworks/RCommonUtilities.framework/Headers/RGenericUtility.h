/*
 Copyright: Copyright (C) 2012 Rakuten, Inc.  All Rights Reserved.
 
 
 File Name:  RGenericUtility.h
 
 Description: Generic class/interface for fetching/performing common functionalities.
 1. Getting the framework bundle reference  by passing value as bundle name.
 This function will return the reference of the nsbundle whose name been passed as input parameter
 
 Author: Mandar Kadam
 
 Created:11th-June-2012
 
 Changed:
 
 Version: 1.0
 
 *
 */

#import <Foundation/Foundation.h>

@interface RGenericUtility : NSObject
//Function returns the refenece  of the nsbundle whose name been passed as input parameter
+ (NSBundle *)frameworkBundleWithBundleName:(NSString *)bundleName;

//Checks the id object is empty.
+ (BOOL)isEmpty:(id)object;

//Checks the id object is notEmpty.
+ (BOOL)isNotEmpty:(id)object;

//Forms key value pair in a format(key=value&,...) also decides whether encoding needs to be done or not
+ (NSString*)formKeyValuePair:(NSDictionary*)params withEncoding:(BOOL)isEncoding;

//Responsible for showing the error message from the localizable strings for the given input key.
+ (NSString *)errorMessageForKey:(NSString *)errorKeyName inResourceBundle:(NSString *)bundleName;
@end
