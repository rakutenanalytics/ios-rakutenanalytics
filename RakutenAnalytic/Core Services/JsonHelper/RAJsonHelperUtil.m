/*
 Copyright: Copyright (C) 2012 Rakuten, Inc.  All Rights Reserved.
 
 
 File Name:  RAJsonHelperUtil.m
 
 Description: This class is responsible for creating the JSON string using various object type and also providing method for getting the final string. 
 
 Author: Mandar Kadam
 
 Created: 23rd-Dec-2012
 
 Changed:
 
 Version: 1.0
 
 *
 */

#import "RAJsonHelperUtil.h"
#import "RGenericUtility.h"
#import "SBJson/NSObject+SBJson.h"
#import "RACommons.h"

@interface RAJsonHelperUtil()
{
    SBJsonWriter *jsonWriter;
    NSMutableDictionary *parametersDictionary;
}
@end

@implementation RAJsonHelperUtil

- (id)init
{
    if( self = [super init] )
    {
        jsonWriter = [[SBJsonWriter alloc] init];
        parametersDictionary = [NSMutableDictionary dictionary];
    }
    return  self;
}

/** Forms the JSON string using the input
 
 Performs the functionality of creating the JSON string using the key and value passed as input.
 
 @param keyName of type NSString.
 @param value of type NSString.
 @return It returns nothing.
 */
- (void)addKey:(NSString *)keyName withValue:(NSString *)value
{
    if( [RGenericUtility isNotEmpty:keyName] && [RGenericUtility isNotEmpty:value] )
    {
        [parametersDictionary setValue:value forKey:keyName];
    }
}

/** Forms the JSON string using key and value as Dictionary
 
 Performs the functionality of creating the JSON string using key as string and value passed as NSdictionary.
 
 @param keyName of type NSString.
 @param dictionary of type NSdictionary.
 */
- (void)addKey:(NSString *)keyName withValueAsDictionary:(NSMutableDictionary *)dictionary
{
    NSMutableDictionary *verifiedDictionary = [NSMutableDictionary dictionary];
    
    if( [RGenericUtility isNotEmpty:keyName] && [RGenericUtility isNotEmpty:dictionary] && [dictionary count] > 0 )
    {
        for(id key in dictionary) {
            id value = [dictionary objectForKey:key];
            if ([RGenericUtility isNotEmpty:value])
            {
                [verifiedDictionary setValue:value forKey:key];
            }
        }
        if( [RGenericUtility isNotEmpty:verifiedDictionary])
            [parametersDictionary setValue:verifiedDictionary forKey:keyName];
    }
}

/** Returns the JSOn representation string.
 
 Performs the functionality of getting the string in the JSOn format.
 
@return It returns the JSOn formatted string.
 */
- (NSString *)getJSONFormattedString
{
    return [jsonWriter stringWithObject:parametersDictionary];
}

- (NSDictionary *)getJSONDictionaryFromString:(NSString *)string
{
    return [string JSONValue];
}

/** Returns the JSON representation string using the input.
 
 Performs the functionality of getting the string in the JSON format using the NSDictionary.
 
 @param  dictionary of type NSDictionary.
 @return It returns the JSON formatted string.
 */
- (NSString *)getJSONFormattedStringFromDictionary:(NSDictionary *)dictionary
{
    return [jsonWriter stringWithObject:dictionary];
}

/** Forms JSON string using vector information
 
 Performs the functionality of creating the string using vector information.
 It concatinates the value and forms a json string as output.
 
 @param items of type NSArray
 @param price of type NSArray
 @param count of type NSArray.
 @return json string of type NSString.
 */
- (NSString *)setJSONFormattedStringFromVector:(NSArray *)items
                                     withPrice:(NSArray *)price
                                      andCount:(NSArray *)count
{
    NSString *jsonString = nil;
    if( [RGenericUtility isNotEmpty:items] && [RGenericUtility isNotEmpty:price] && [RGenericUtility isNotEmpty:count])
    {
        NSDictionary * jsonDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
                                             items, kItemVectorKey,
                                             price, kPriceVectorKey,
                                             count, kNumberOfItemsVectorKey,
                                             nil];
        [parametersDictionary setValue:jsonDictionary forKey:kItemVectorString];
    }
    return jsonString;
}

- (void)dealloc
{
    [parametersDictionary removeAllObjects];
    parametersDictionary = nil;
    jsonWriter = nil;
}
@end
