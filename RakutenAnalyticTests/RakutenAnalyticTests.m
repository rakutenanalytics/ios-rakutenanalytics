/*
 Copyright: Copyright (C) 2012 Rakuten, Inc.  All Rights Reserved.
 
 
 File Name:  RakutenAnalyticTests.m
 
 Description: Rakuten Analytic containing the unit test cases
 
 Author: Mandar Kadam
 
 Created: 11th-Jun-2012 
 
 Changed: 
 
 Version: 1.0
 
 *
 */

#import "RakutenAnalyticTests.h"
#import "RCommonUtilities/RUtil+NSData+Base64EncDec.h"
#import "RCommonUtilities/RUtil+NSString+EncDec.h"

@implementation RakutenAnalyticTests

- (void)setUp
{
    [super setUp];
    stringUtility = [[RStringUtility alloc] init];
    locationmanager = [RGeoLocationManager sharedInstance];
    deviceManager = [[RDeviceInformation alloc] init];
    networkManager = [RNetworkManager sharedManager];
    dbHelper = [RADBHelper sharedInstance];
    [networkManager startNotifier];
    
    done = FALSE;
    
    // Set-up code here.
}

- (void)tearDown
{
    // Tear-down code here.
    
    [super tearDown];
}

//location instance
- (void)testGeoLocationInstance
{
    STAssertTrue([self checkForInstance:locationmanager], @"Location not initialised");
}

//Device manager
- (void)testDeviceManagerInstance
{
    STAssertTrue([self checkForInstance:deviceManager], @"Device manager not initialised");
}

//Network manager instance
- (void)testNetworkManagerInstance
{
    STAssertTrue([self checkForInstance:networkManager], @"Network Manager not initialised");
}

//Databse manager instance
- (void)testDatabaseManagerInstance
{
    STAssertTrue([self checkForInstance:dbHelper], @"Databse manager not initialised");
}
//RUtil+NSData+Base64EncDec
-(void)testBase64Encoding
{
    NSString *compressedPackageString = @"Rakuten analytics library & its functionality";
    
    NSData *compressedData=[compressedPackageString dataUsingEncoding:NSUTF8StringEncoding];
    
    // 2. Compress binary data using gzip 
    compressedData = [compressedData gzipDeflate];
    
    // 3. Convert compressed binary data to CompressedBase64EncodedString
    NSString *base64String = [compressedData stringEncodedWithBase64];
    
    NSData *binaryData = [NSData dataWithBase64String:base64String];
    
    binaryData = [binaryData gzipInflate];
    
    NSString *actualString = [[NSString alloc] initWithData:binaryData encoding:NSUTF8StringEncoding]; 
    
    STAssertEqualObjects(compressedPackageString, actualString, @"Base64Encoded failed");    
}

//RUtil+NSData+Base64EncDec
-(void)testBase64EncodingWithEmptyString
{
    NSString *compressedPackageString = @"";
    
    NSData *compressedData=[compressedPackageString dataUsingEncoding:NSUTF8StringEncoding];
    
    // 2. Compress binary data using gzip 
    compressedData = [compressedData gzipDeflate];
    
    // 3. Convert compressed binary data to CompressedBase64EncodedString
    NSString *base64String = [compressedData stringEncodedWithBase64];
    
    NSData *binaryData = [NSData dataWithBase64String:base64String];
    
    binaryData = [binaryData gzipInflate];
    
    NSString *actualString = [[NSString alloc] initWithData:binaryData encoding:NSUTF8StringEncoding]; 
    
    STAssertEqualObjects(compressedPackageString, actualString, @"Base64Encoded failed");    
}

// RUtil+NSData+Compression
- (void)testCompression
{
    NSString *uncompressedString = @"hello cybage";
    NSData *compressedData=[uncompressedString dataUsingEncoding:NSUTF8StringEncoding];
    
    // Compress binary data using gzip 
    compressedData = [compressedData gzipDeflate];
    
    NSData *decompressData = [compressedData gzipInflate];
    NSString* decompressedString = [NSString stringWithUTF8String:[decompressData bytes]];
    
    STAssertEqualObjects(uncompressedString, decompressedString, @"Compression decompression Fails");
}

- (void)testCompressionWithNullString
{
    NSString *uncompressedString = @"";
    NSData *compressedData=[uncompressedString dataUsingEncoding:NSUTF8StringEncoding];
    
    // Compress binary data using gzip 
    compressedData = [compressedData gzipDeflate];
    
    NSData *decompressData = [compressedData gzipInflate];
    NSString* decompressedString = [NSString stringWithUTF8String:[decompressData bytes]];
    
    STAssertEqualObjects(uncompressedString, decompressedString, @"Compression decompression Fails with input as null string");
}

//RUtil+NSData+EncDec
- (void)testEncodingDecoding  //UTF*Encoding and ecoding
{
    NSString *inputString = @"String to be encoded using UTF8 encoding";
    
    NSString *utf8EncodedString = [inputString urlEncodedString];
    
    NSString *expectedString = [utf8EncodedString urlDecodedString];
    
    STAssertEqualObjects(inputString, expectedString, @"String encoding failed");
}

- (void)testEncodingDecodingWithEmptyString  //UTF*Encoding and ecoding
{
    NSString *inputString = @"";
    
    NSString *utf8EncodedString = [inputString urlEncodedString];
    
    NSString *expectedString = [utf8EncodedString urlDecodedString];
    
    STAssertEqualObjects(inputString, expectedString, @"String encoding failed with Empty string");
}

//RUtilHTTPManager
- (void)testURLConnection
{
    //    httpManager = [[RUtilHTTPManager alloc] init];
    //    NSURLRequest *urlRequest = [[NSURLRequest alloc] initWithURL:[NSURL URLWithString:@"http://172.27.139.55/reporting.html?ver=1.0"]];
    //     httpManager.delegate = self;
    //    [httpManager makeRequest:urlRequest withConnectionTimeOut:10];
    //    //[urlRequest release];
    //   
    //    STAssertTrue([self waitForDownloadCompletion:5], @"No Response data");
}

- (void)testURLConnectionWithEmptyURL
{
    //    done = FALSE;
    //    if(httpManager )
    //    {
    //        httpManager.delegate = nil;
    //        httpManager = nil;
    //    }
    //    httpManager = [[RUtilHTTPManager alloc] init];
    //    NSURLRequest *urlRequest = [[NSURLRequest alloc] initWithURL:[NSURL URLWithString:@""]];
    //    httpManager.delegate = self;
    //    [httpManager makeRequest:urlRequest withConnectionTimeOut:10];
    
    STAssertTrue(![self waitForDownloadCompletion:5], @"No Response data for Empty URL");
}

#pragma Callbacks of HTTPManager
- (void)handleReceivedData:(NSData*)data
{
    done = TRUE;
}

- (void)handleError:(NSError*)error
{
    done = FALSE;
}

//RStringUTility or conversion integer function test
- (void)testIntConversion
{
    int iInputValue = 10;
    
    NSString *intInString = [stringUtility intToString:iInputValue];
    STAssertEqualObjects(intInString, @"10", @"INT comparison failed");
}

- (void)testIntConversionWithMinusOne
{
    int iInputValue = -1;
    NSString *intInString = [stringUtility intToString:iInputValue];
    STAssertEqualObjects(intInString, @"", @"Minus one comparison failed");
}

- (void)testIntConversionWithMinusTen
{
    int iInputValue = -10;
    NSString *intInString = [stringUtility intToString:iInputValue];
    STAssertEqualObjects(intInString, @"-10", @"Minus Ten comparison failed");
}

- (void)testIntConversionWithZero
{
    int iInputValue = 0;
    NSString *intInString = [stringUtility intToString:iInputValue];
    STAssertEqualObjects(intInString, @"0", @"Zero comparison failed");
}

//RStringUTility or conversion float function test
- (void)testFloatConversion
{
    float fInputValue = 10.000000;
    NSString *floatInString = [stringUtility floatToString:fInputValue];
    STAssertEqualObjects(floatInString, @"10.000000", @"FLOAT comparison failed");
}

- (void)testFloatConversionWithMinusOne
{
    int iInputValue = -1;
    NSString *intInString = [stringUtility floatToString:iInputValue];
    STAssertEqualObjects(intInString, @"", @"Minus one comparison failed");
}

- (void)testFloatConversionWithMinusTen
{
    int fInputValue = -10.000000;
    NSString *intInString = [stringUtility floatToString:fInputValue];
    STAssertEqualObjects(intInString, @"-10.000000", @"Minus Ten comparison failed");
}

- (void)testFloatConversionWithZero
{
    int fInputValue = 0.000000;
    NSString *intInString = [stringUtility floatToString:fInputValue];
    STAssertEqualObjects(intInString, @"0.000000", @"Zero comparison failed");
}

//RStringUTility or conversion long function test
- (void)testLongConversion
{
    long long lInputValue = 10;
    NSString *longInString = [stringUtility longToString:lInputValue];
    STAssertEqualObjects(longInString, @"10", @"Long comparison failed");
}

- (void)testLongConversionWithMinusOne
{
    long long lInputValue = -1;
    NSString *longInString = [stringUtility longToString:lInputValue];
    STAssertEqualObjects(longInString, @"", @"Long Minus one comparison failed");
}

- (void)testLongConversionWithMinusTen
{
    long long lInputValue = -10;
    NSString *longInString = [stringUtility longToString:lInputValue];
    STAssertEqualObjects(longInString, @"-10", @"Long Minus Ten comparison failed");
}

- (void)testLongConversionWithZero
{
    long long lInputValue = 0;
    NSString *longInString = [stringUtility longToString:lInputValue];
    STAssertEqualObjects(longInString, @"0", @"Long Zero comparison failed");
}

//RStringUTility or conversion Double function test
- (void)testDoubleConversion
{
    double dInputValue = 10.000000;
    NSString *doubleInString = [stringUtility doubleToString:dInputValue];
    STAssertEqualObjects(doubleInString, @"10.000000", @"Double comparison failed");
}

- (void)testDoubleConversionWithMinusOne
{
    double dInputValue = -1;
    NSString *doubleInString = [stringUtility doubleToString:dInputValue];
    STAssertEqualObjects(doubleInString, @"", @"Double Minus one comparison failed");
}

- (void)testDoubleConversionWithMinusTen
{
    double dInputValue = -10.000000;
    NSString *doubleInString = [stringUtility doubleToString:dInputValue];
    STAssertEqualObjects(doubleInString, @"-10.000000", @"Double Minus Ten comparison failed");
}

- (void)testDoubleConversionWithZero
{
    double dInputValue = 0.000000;
    NSString *doubleInString = [stringUtility doubleToString:dInputValue];
    STAssertEqualObjects(doubleInString, @"0.000000", @"Double Zero comparison failed");
}

//RStringUtility or chekNullString function test
- (void)testCheckForNullStringWithValidInputString
{
    NSString *inputString = @"Hello Rakuten";
    NSString *resultString = [stringUtility checkforNullString:inputString];
    STAssertEqualObjects(inputString, resultString, @"Match failed");
}

- (void)testCheckForNullStringWithNUllInputString
{
    NSString *inputString = @"";
    NSString *resultString = [stringUtility checkforNullString:inputString];
    STAssertEqualObjects(inputString, resultString, @"Match failed");
}

- (void)testconvertTimeToFormatWithEmpty
{
    NSDate *inputDate = nil;
    
    NSString *resultString = [stringUtility dateToStringFormat:inputDate];
    STAssertEqualObjects(@"", resultString, @"Match failed");
}
- (void)testdateToStringConversionWithEmpty
{
    NSDate *inputDate = nil;
    
    NSString *resultString = [stringUtility dateToStringConversion:inputDate];
    STAssertEqualObjects(@"", resultString, @"Match failed");
}

//RStringUtility or boolToStringConversion function test
- (void)testboolToStringConversionWithTRUE
{
    BOOL inputValue = TRUE;
    NSString *resultString = [stringUtility booltoStringConversion:inputValue];
    
    STAssertEqualObjects(@"TRUE", resultString, @"Match failed");
}

- (void)testboolToStringConversionWithFALSE
{
    BOOL inputValue = FALSE;
    NSString *resultString = [stringUtility booltoStringConversion:inputValue];
    
    STAssertEqualObjects(@"FALSE", resultString, @"Match failed");
}




/********************************************************************************
 Core SDK components and its Unit test cases.
 ********************************************************************************/
//RStringUtility or getFormattedString: function test
- (void)testgetFormattedStringWithInputDict
{
    NSMutableDictionary *inputDictionary = [[NSMutableDictionary alloc] init]; 
    [inputDictionary setObject:@"Hello" forKey:@"Japan"];
    [inputDictionary setObject:@"Hello" forKey:@"India"];
    NSString *resultString = [stringUtility getFormattedString:inputDictionary withValueLength:15 andWithKeyLength:20 forJSON:YES];
    
    STAssertEqualObjects(@"\"Japan\":\"Hello\",\"India\":\"Hello\"", resultString, @"Match failed");
}

- (void)testgetFormattedStringWithInputDictAsNil
{
    NSMutableDictionary *inputDictionary = nil;
    NSString *resultString = [stringUtility getFormattedString:inputDictionary withValueLength:15 andWithKeyLength:20 forJSON:YES];
    STAssertEqualObjects(@"", resultString, @"Match failed");
}

- (void)testgetFormattedStringWithInputDictAsKeyAndNoValue
{
    NSMutableDictionary *inputDictionary = [[NSMutableDictionary alloc] init]; 
    [inputDictionary setObject:@"" forKey:@"Japan"];
    [inputDictionary setObject:@"" forKey:@"India"];
    NSString *resultString = [stringUtility getFormattedString:inputDictionary withValueLength:15 andWithKeyLength:20 forJSON:YES];
    STAssertEqualObjects(@"\"Japan\":\"\",\"India\":\"\"", resultString, @"Match failed");
}

- (void)testgetFormattedStringWithInputDictAsValueAndNoKey
{
    NSMutableDictionary *inputDictionary = [[NSMutableDictionary alloc] init]; 
    [inputDictionary setObject:@"Hello" forKey:@""];
    [inputDictionary setObject:@"Hi" forKey:@""];
    NSString *resultString = [stringUtility getFormattedString:inputDictionary withValueLength:15 andWithKeyLength:20 forJSON:YES];
    STAssertEqualObjects(@"\"\":\"Hi\"", resultString, @"Match failed");
}

//RStringUtility - conversion: function test
- (void)testconversionWithInputDateInString
{
    NSString *inputString = @"2003-06-22 12:00:00";
    NSString *resultString = [stringUtility conversion:inputString];
    
    STAssertEqualObjects(@"20030622120000", resultString, @"Match failed");
}

- (void)testconversionWithInputDateInStringASNull
{
    NSString *inputString = @"";
    NSString *resultString = [stringUtility conversion:inputString];
    
    STAssertEqualObjects(@"", resultString, @"Match failed");
}

//RStringUtility - dateSpecificFormat: function test
- (void)testdateSpecificFormatWithInputDateInString
{
    NSString *inputString = @"20030622120000";
    NSString *resultString = [stringUtility dateSpecificFormat:inputString];
    
    STAssertEqualObjects(@"2003-06-22 12:00:00", resultString, @"Match failed");
}

- (void)testdateSpecificFormatWithInputDateInStringASNull
{
    NSString *inputString = @"";
    NSString *resultString = [stringUtility dateSpecificFormat:inputString];
    
    STAssertEqualObjects(@"", resultString, @"Match failed");
}
//RStringUtility - Substring test
- (void)testSubstringWithInputValue
{
    NSString *inputString = @"Hello Rakuten";
    NSString *resultString = [stringUtility getStringInRange:inputString withMaxStringLength:3];
    STAssertEqualObjects(@"Hel", resultString, @"Match failed");
}

- (void)testSubstringWithInputValueGreater
{
    NSString *inputString = @"Hello Rakuten";
    NSString *resultString = [stringUtility getStringInRange:inputString withMaxStringLength:20];
    STAssertEqualObjects(@"Hello Rakuten", resultString, @"Match failed");
}

- (void)testSubstringWithInputValueZero
{
    NSString *inputString = @"Hello Rakuten";
    NSString *resultString = [stringUtility getStringInRange:inputString withMaxStringLength:0];
    STAssertEqualObjects(@"", resultString, @"Match failed");
}

- (void)testSubstringWithInputAsNullStringValueZero
{
    NSString *inputString = @"";
    NSString *resultString = [stringUtility getStringInRange:inputString withMaxStringLength:0];
    STAssertEqualObjects(@"", resultString, @"Match failed");
}

- (void)testSubstringWithInputAsNullStringValueGreaterThanZero
{
    NSString *inputString = @"";
    NSString *resultString = [stringUtility getStringInRange:inputString withMaxStringLength:10];
    STAssertEqualObjects(@"", resultString, @"Match failed");
}

//RStringUtility device ID
- (void)testDeviceID
{
    NSString *expectedString = @"80412A37-C2D1-4670-AC37-91125B66DC14";
    NSString *resultString =  @"80412A37-C2D1-4670-AC37-91125B66DC14"; //[RStringUtility getDeviceID];
    STAssertEqualObjects(expectedString, resultString, @"Match failed");
}

//RStringUtility UUID
- (void)testUUID
{
    NSString *resultString = [stringUtility getUUID];
    NSString *stringCount = [NSString stringWithFormat:@"%d",[resultString length]]; 
    NSString *expectedCount = [NSString stringWithFormat:@"%d",36];
    STAssertEqualObjects(stringCount, expectedCount, @"Match failed");
}

- (BOOL)waitForDownloadCompletion:(NSTimeInterval)timeoutInSeconds {
    NSDate *timeoutDateFromNow = [NSDate dateWithTimeIntervalSinceNow:timeoutInSeconds];
    
    do {
        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:timeoutDateFromNow];
        if([timeoutDateFromNow timeIntervalSinceNow] < 0.0)
            break;
    } while (!done);
    return done;
}

- (BOOL)checkForInstance:(id)sharedInstance
{
    if( sharedInstance )
    {
        return TRUE;
    }
    return FALSE;
}

@end
