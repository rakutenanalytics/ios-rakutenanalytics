/*
 Copyright: Copyright (C) 2012 Rakuten, Inc.  All Rights Reserved.
 
 
 File Name:  RStringUtility.m
 
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

#import "RStringUtility.h"
#import "RUtil+NSString+EncDec.h"
#import "RUtilLogger.h"

NSString *const kDateFormat = @"yyyyMMddHHmmss";
NSString *const kTimeStampFormat = @"yyyy-MM-dd HH:mm:ss";

@interface RStringUtility()
{
    NSDateFormatter *dateFormatter;
    NSString *commonString;
}
@property(nonatomic, strong)NSDateFormatter *dateFormatter;
@property(nonatomic, copy)NSString *commonString;
@end

@implementation RStringUtility
@synthesize dateFormatter;
@synthesize commonString;

- (id) init
{
    if( (self = [super init]) )
    {
        self.dateFormatter = [[NSDateFormatter alloc] init];
        self.commonString = @"";
    }
    return self;
}
/*!
 @function		booltoStringConversion
 @discussion	Convertsbool to NString(i.re true or false) 
 @param			takes bool as input for conversion to NSString 
 @result		returns NSString value
 */
-(NSString *)booltoStringConversion:(BOOL)isBool
{
    self.commonString = @"";
    if( isBool )
    {
        self.commonString = [NSString stringWithFormat:@"%@", @"TRUE"];
    }
    else
    {
        self.commonString = [NSString stringWithFormat:@"%@", @"FALSE"];
    }
    return self.commonString;
}

/*!
 @function		intToString
 @discussion	Check for -1 if found return empty string else convert integer to string and send as string
 @param			inputValue of type integer 
 @result		returns integer data in string format
 */
-(NSString *)intToString:(int)inputValue
{
    self.commonString = @"";
    if( inputValue == -1 )
    {
        return self.commonString; 
    }
    self.commonString = [NSString stringWithFormat:@"%d", inputValue];
    return self.commonString;
}

/*!
 @function		longToString
 @discussion	Check for -1 if found return empty string else convert long to string and send as string
 @param			inputValue of type long 
 @result		returns long data in string format
 */
-(NSString *)longToString:(long long)inputValue
{
    self.commonString = @"";
    if( inputValue == -1 )
    {
        return self.commonString; 
    }
    self.commonString = [NSString stringWithFormat:@"%lld", inputValue];
    return self.commonString;
}

/*!
 @function		floatToString
 @discussion	Check for -1 if found return empty string else convert float to string and send as string 
 @param			inputValue of type float
 @result		returns float value in string format */
-(NSString *)floatToString:(float)inputValue
{
    self.commonString = @"";
    if( inputValue == -1.0 )
    {
        return self.commonString; 
    }
    self.commonString = [NSString stringWithFormat:@"%f", inputValue];
    return self.commonString;
}

/*!
 @function		doubleToString
 @discussion	Check for -1 if found return empty string else convert double to string and send as string 
 @param			inputValue of type double
 @result		returns double value in string format */
-(NSString *)doubleToString:(double)inputValue
{
    self.commonString = @"";
    if( inputValue == -1.0 )
    {
        return self.commonString; 
    }
    self.commonString = [NSString stringWithFormat:@"%f", inputValue]; 
    return (self.commonString);
}

/*!
 @function		checkforNullString
 @discussion	Checks string passed is null string or not, oif null initialise it with empty data else return the same string
 @param			stringData of type NSString  
 @result		returns verified string
 */
-(NSString *)checkforNullString:(NSString *)stringData
{
    if ((stringData == (id)[NSNull null]) || stringData.length == 0 )
    {
        stringData = @"";
    }
    return stringData;
}

/*!
 @function		dateToStringFormat:
 @discussion	Converts the string in a particular date format
 @param			inputTime of type NSString  
 @result		returns date in a particular format(yyyy-MM-dd HH:mm:ss) string
 */
-(NSString *)dateToStringFormat:(NSDate *)inputTime
{
    [self.dateFormatter setDateFormat:kTimeStampFormat];
    
    NSString *dateInString = [self.dateFormatter stringFromDate:inputTime];
    dateInString = [self checkforNullString:dateInString];
    return dateInString;
}

/*!
 @function		dateToStringConversion:
 @discussion	Converts NSDate format to NSString format(date format:  @"yyyyMMddHHmmss")
 @param			NSDate  
 @result		NSString: date in string format( format:  @"yyyyMMddHHmmss")
 */
-(NSString *)dateToStringConversion:(NSDate *)date
{
    [self.dateFormatter setDateFormat:kDateFormat];
    
    NSString *dateInString = [self.dateFormatter stringFromDate:date];
    dateInString = [self checkforNullString:dateInString];
    return dateInString;
}

/*!
 @function		getStringInRange: withMaxStringLength:
 @discussion	Perform the functionality of returning the string with the specified max characters(substring calculation)
 @param			inputTime of type NSString  
 @param         maxStringLenght of type int
 @result		returns string with max string length specified
 */
-(NSString *)getStringInRange:(NSString *)inputString withMaxStringLength:(int)maxStringLength
{
    if( [inputString length] > maxStringLength )
    {
        NSString *shortString = [inputString substringWithRange:NSMakeRange(0, maxStringLength)];
        return shortString;
    }
    return inputString;
}

/*!
 @function		getFormattedString:
 @discussion	Perform the functionality of converting dictionary/map into formatted string
 @param			customParamDictionary of type NSDictionary 
 @param         substring length of the value 
 @param         substring length of the key
 @result		returns string in a particular foramt i.e field1=value1, field2= value
 */
-(NSString *)getFormattedString:(NSDictionary *)customParamDictionary
                withValueLength:(int)valueLength
               andWithKeyLength:(int)keylength
                        forJSON:(BOOL)isJSON
{
    NSString *dataString = @"";
    @try {
        if ([customParamDictionary count]) {
            NSArray *keyArray =  [customParamDictionary allKeys];
            int count = [keyArray count];
            if( count > 0 )
            {
                for (int keyArrayCount = 0; keyArrayCount < count; keyArrayCount++)
                {
                    NSString *value = [customParamDictionary objectForKey:[keyArray objectAtIndex:keyArrayCount]];
                    value = [self getStringInRange:value withMaxStringLength:valueLength];
                    
                    NSString *key = [keyArray objectAtIndex:keyArrayCount];
                    key = [self getStringInRange:key withMaxStringLength:keylength];
                    
                    if( isJSON )
                    {
                        dataString = [dataString stringByAppendingFormat:@"\"%@\":\"%@\"", [key urlEncodedString], [value urlEncodedString]];
                    }
                    else {
                        dataString = [dataString stringByAppendingFormat:@"%@=%@", key, value];
                    }
                    if( keyArrayCount < count-1 )
                    {
                        dataString = [dataString stringByAppendingString:@","];
                    }
                }
            }
        }
    }
    @catch (NSException *exception) {
        RULog(@"%@",exception.description);
    }
    return dataString;
}

/*!
 @function		conversion:
 @discussion	Getting string by replacing characters (':', ' ', '-') with blank
 @param			dateString of type NSString  
 @result		returns string by replacing characters (':', ' ', '-') with blank
 */
-(NSString *)conversion:(NSString *)dateString
{
    self.commonString = dateString;
    self.commonString = [self.commonString stringByReplacingOccurrencesOfString:@"-" withString:@""];
    self.commonString = [self.commonString stringByReplacingOccurrencesOfString:@" " withString:@""];
    self.commonString = [self.commonString stringByReplacingOccurrencesOfString:@":" withString:@""];
    return self.commonString;
}

/*!
 @function		dateSpecificFormat:
 @discussion	Responsile for forming string depicting date in a specific format( adding following characters ':', ' ', '-')
 @param			dateString of type NSString  
 @result		returns string by adding following characters':', ' ', '-' to string
 */
-(NSString *)dateSpecificFormat:(NSString *)dateString
{
    NSMutableString *mutableDateString = [NSMutableString stringWithString:dateString];
    @try 
    {
        [mutableDateString insertString:@"-" atIndex:4];
        [mutableDateString insertString:@"-" atIndex:7];
        [mutableDateString insertString:@" " atIndex:10];
        [mutableDateString insertString:@":" atIndex:13];
        [mutableDateString insertString:@":" atIndex:16];
    }
    @catch (NSException *exception) {
    }
    return mutableDateString;
}

/*!
 @function		getDeviceID
 @discussion	Generates a unique identifier which will act  as persistent/ session cookies
 @param			nil  
 @result		returns unique identifier of device of type NSString
 */
-(NSString *)getDeviceID
{
    NSString *uuid = nil;
    if(uuid==nil || [uuid isEqualToString:@""])
    {
        CFUUIDRef theUUID = CFUUIDCreate(NULL);
        if (theUUID)
        {
            uuid = CFBridgingRelease(CFUUIDCreateString(kCFAllocatorDefault, theUUID));
            CFRelease(theUUID);
        }
    }
    return uuid;
}

/*!
 @function		getUUID
 @discussion	Generates a unique identifier for each session  
 @param			nil  
 @result		returns 32 bit character string of Type NSString
 */
-(NSString *)getUUID
{
    CFUUIDRef newUniqueId = CFUUIDCreate(kCFAllocatorDefault);
    NSString * uuidString = (__bridge_transfer NSString*)CFUUIDCreateString(kCFAllocatorDefault, newUniqueId);
    CFRelease(newUniqueId);
    
    return uuidString;
}

/*!
 @function		isAlphaNumeric
 @description	Check for alpha numeric characters   
 @param			string of type NSString  
 @result		returns true if aplhanumeric else false.
 */
-(BOOL)isAlphaNumeric:(NSString *)string
{
    NSCharacterSet *unwantedCharacters = 
    [[NSCharacterSet alphanumericCharacterSet] invertedSet];
    
    return ([string rangeOfCharacterFromSet:unwantedCharacters].location == NSNotFound) ? YES : NO;
}

/*!
 @function		getAplhaNumericCharacters
 @description	Generates a string with only alphanumeric charcters and trims other data  
 @param			string with special charcters or so  
 @result		returns trimmed string with alphanumeric charcter string
 */
-(NSString *)getAplhaNumericCharacters:(NSString *)string
{
    NSCharacterSet *charactersToRemove =
    [[ NSCharacterSet alphanumericCharacterSet ] invertedSet ];
    
    NSString *trimmedString =
    [string stringByTrimmingCharactersInSet:charactersToRemove ];
    return trimmedString;
}

-(void)dealloc
{
    self.commonString = nil;
    self.dateFormatter = nil;
}
@end
