/*
 Copyright: Copyright (C) 2012 Rakuten, Inc.  All Rights Reserved.
 
 
 File Name:  RGenericUtility.m
 
 Description: Generic class/interface for fetching/performing common functionalities.
 1. Getting the framework bundle reference  by passing value as bundle name.
 This function will return the reference of the nsbundle whose name been passed as input parameter
 
 Author: Mandar Kadam
 
 Created:11th-June-2012
 
 Changed:
 
 Version: 1.0
 
 *
 */

#import "RGenericUtility.h"
#import "RUtil+NSString+EncURLComponent.h"

@implementation RGenericUtility
/*!
 @function		frameworkBundleWithBundleName:
 @description	Getting the framework bundle reference by passing value as bundle name.
 This function will return the reference of the nsbundle whose name been passed as input parameter
 @param			bundleName of type NSString
 @result		returns the bundle reference.
 */
+ (NSBundle *)frameworkBundleWithBundleName:(NSString *)bundleName
{
    static NSBundle* frameworkBundle = nil;
    NSString* mainBundlePath = [[NSBundle mainBundle] resourcePath];
    NSString* frameworkBundlePath = [mainBundlePath stringByAppendingPathComponent:bundleName];
    frameworkBundle = [NSBundle bundleWithPath:frameworkBundlePath];
    return frameworkBundle;
}

/*
 @function		isEmpty:
 @description	Checks if the object is empty
 @param			bundleName of type NSString
 @result		returns the bundle reference.
 */
+ (BOOL)isEmpty:(id)object
{
	return object == nil
	|| ([object respondsToSelector:@selector(length)]
		&& [(NSData *)object length] == 0)
	|| ([object respondsToSelector:@selector(count)]
		&& [(NSArray *)object count] == 0);
}

/*
 @function		isNotEmpty:
 @description	Getting the framework bundle reference by passing value as bundle name.
 This function will return the reference of the nsbundle whose name been passed as input parameter
 @param			bundleName of type NSString
 @result		returns the bundle reference.
 */
+ (BOOL)isNotEmpty:(id)object
{
	return object != nil
	&& (([object respondsToSelector:@selector(length)]
		 && [(NSData *)object length] > 0)
		|| ([object respondsToSelector:@selector(count)]
			&& [(NSArray *)object count] > 0));
}


/*
 @function      formKeyValuePair:withEncoding:
 @description   Performs the functionality of forming key-values separated by & and encode if required.
 @param         key value mapping and appending it to show a complete http body string.
 @param         boolean which checks whether encoding need to be done or not.
 @return        NSString object with all key value pair concatenated with & forming a complete string.
 */
+ (NSString*)formKeyValuePair:(NSDictionary*)params withEncoding:(BOOL)isEncoding
{
    NSMutableString* key_ValueStr = [NSMutableString string];
	
	for (NSString* key in params) {
        NSString* value = nil;
        if( isEncoding )
        {
            value = [[params objectForKey:key] encodeAsURLComponent];
        }
        else {
            value = [params objectForKey:key];
        }
		[key_ValueStr appendFormat:@"%@=%@&", key, value];
    }
    if (key_ValueStr.length > 0)[key_ValueStr deleteCharactersInRange:NSMakeRange(key_ValueStr.length-1, 1)];
    return key_ValueStr;
}


/*
 @function      getUserInformation
 @description   Responsible for showing the error message from the localizable strings for the given input key .
 @param         error key name
 @param         resource bundlename 
 @return        returns localizable error message description for the given input werror key.
 */
+ (NSString *)errorMessageForKey:(NSString *)errorKeyName inResourceBundle:(NSString *)bundleName
{
    NSBundle *bundle = [RGenericUtility frameworkBundleWithBundleName:bundleName];
    return [bundle localizedStringForKey:errorKeyName value:nil table:nil];
}
@end
