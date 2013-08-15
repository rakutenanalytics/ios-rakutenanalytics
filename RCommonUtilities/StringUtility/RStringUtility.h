/*
 Copyright: Copyright (C) 2012 Rakuten, Inc.  All Rights Reserved.
 
 
 File Name:  RStringUtility.h
 
 Description: This class is responsible for perform common functionalities
 1. checks for null string
 2. handles different conversions such as 
 a) bool to string
 b) integer to string
 c) long to string
 d) float to string
 e) date to string in a specific format(yyyy-MM-dd HH:mm:ss)
 f) date to string in a specific format(yyyyMMddHHmmss)
 3. Getting substring from string
 4. Getting device ID
 5. Getting unique 32 bit character string
 
 Author: Mandar Kadam
 
 Created: 5th-Jun-2012 
 
 Changed: 
 
 Version: 1.0
 
 *
 */

#import <Foundation/Foundation.h>

@interface RStringUtility : NSObject
//Check for Null string if null found return empty string
-(NSString *)checkforNullString:(NSString *)stringData;

//Converts bool to string 
-(NSString *)booltoStringConversion:(BOOL)isBool;

//Converts integer to string
-(NSString *)intToString:(int)inputValue;

//Converts long long to string
-(NSString *)longToString:(long long)inputValue;

////Converts float to string
-(NSString *)floatToString:(float)inputValue;

////Converts double to string
-(NSString *)doubleToString:(double)inputValue;

//Converts date(NSdate) to a formatted string i.e(yyyy-MM-dd HH:mm:ss)
-(NSString *)dateToStringFormat:(NSDate *)inputTime;

//Converts NSDate format to NSString format(date format:  @"yyyyMMddHHmmss")
-(NSString *)dateToStringConversion:(NSDate *)date;

//Getting formatted string from dictionary
-(NSString *)getFormattedString:(NSDictionary *)customParamDictionary
                withValueLength:(int)valueLength
               andWithKeyLength:(int)keylength
                        forJSON:(BOOL)isJSON;

//Getting string by replacing characters (':', ' ', '-') with blank
-(NSString *)conversion:(NSString *)dateString;

//Responsile for forming string depicting date in a specific format( adding following characters ':', ' ', '-')
-(NSString *)dateSpecificFormat:(NSString *)dateString;

//Responsible for getting substring
-(NSString *)getStringInRange:(NSString *)inputString withMaxStringLength:(int)maxStringLength;

//Generates a unique identifier which will act  as persistent/ session cookies
-(NSString *)getDeviceID;

//Generates a unique identifier for each session 
-(NSString *)getUUID;

//Returns string after trimming the special characters and returns only the alphanumeric characters present.
-(NSString *)getAplhaNumericCharacters:(NSString *)string; 

//Returns or checks if string is alphanumeric or not
-(BOOL) isAlphaNumeric:(NSString *)string;
@end
