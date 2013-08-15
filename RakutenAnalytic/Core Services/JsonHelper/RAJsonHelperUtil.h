/*
 Copyright: Copyright (C) 2012 Rakuten, Inc.  All Rights Reserved.
 
 
 File Name:  RAJsonHelperUtil.h
 
 Description: This class is responsible for creating the JSON string using various object type and also providing method for getting the final string. 
 
 Author: Mandar Kadam
 
 Created: 23rd-Dec-2012
 
 Changed:
 
 Version: 1.0
 
 *
 */

#import <Foundation/Foundation.h>
#import "SBJSON/SBJsonWriter.h"

@interface RAJsonHelperUtil : NSObject

/** Forms the JSON string using the input
 
 Performs the functionality of creating the JSOn string using the key and value passed as input.
 
 @param keyName of type NSString.
 @param value of type NSString.
 */
- (void)addKey:(NSString *)keyName withValue:(NSString *)value;

/** Forms the JSON string using key and value as Dictionary
 
 Performs the functionality of creating the JSON string using key as string and value passed as NSdictionary.
 
 @param keyName of type NSString.
 @param value of type NSdictionary.
 */
- (void)addKey:(NSString *)keyName withValueAsDictionary:(NSMutableDictionary *)dictionary;


/** Returns the JSON representation string.
 
 Performs the functionality of getting the string in the JSOn format.
 
 @return It returns the JSOn formatted string.
 */
- (NSString *)getJSONFormattedString;

/** Forms dictionary using the JSON string
 
 Performs the functionality of creating the NSdictionary json string.
 
 @param json string of type NSString.
 @return string of type NSDictionary.
 */
- (NSDictionary *)getJSONDictionaryFromString:(NSString *)string;

/** Forms JSON string using NSDictionary
 
 Performs the functionality of creating the string using dictionary
 
 @param dictionary of type NSDictionary.
 @return dictionary of type NSDictionary.
 */
- (NSString *)getJSONFormattedStringFromDictionary:(NSDictionary *)dictionary;

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
                                      andCount:(NSArray *)count;


@end
