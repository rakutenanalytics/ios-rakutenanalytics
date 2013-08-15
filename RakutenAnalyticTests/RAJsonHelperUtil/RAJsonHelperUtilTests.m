/*
 Copyright: Copyright (C) 2012 Rakuten, Inc.  All Rights Reserved.
 
 
 File Name:  RAJsonHelperUtilTests.m
 
 Description: Test cases for JSON helper utility class 
 
 Author: Mandar Kadam
 
 Created: 2nd-Jan-2013
 
 Changed:
 
 Version: 1.0
 
 *
 */

#import <SenTestingKit/SenTestingKit.h>
#import "RAJsonHelperUtil.h"

@interface RAJsonHelperUtilTests:SenTestCase 
@property RAJsonHelperUtil *jsonHelperUtil;
@end

@implementation RAJsonHelperUtilTests
- (void)setUp
{
    [super setUp];
    // Set-up code here.
    _jsonHelperUtil = [[RAJsonHelperUtil alloc] init];
}

- (void)tearDown {
}

//Vector information test cases

- (void)testVectorStringWithproperInput
{    
    NSString *dataString = @"{\"itemsvector\":{\"item\":[\"Books\",\"Media\",\"Stationary\"],\"num_items\":[123,12,12],\"price\":[\"2000\",\"4000\",\"5000\"]}}";
    
    NSArray *itemArray = [[NSArray alloc] initWithObjects: @"Books", @"Media", @"Stationary", nil];
    
    NSArray *countArray = [[NSArray alloc] initWithObjects: [NSNumber numberWithInt:123], [NSNumber numberWithInt:12], [NSNumber numberWithInt:12], nil];
    
    NSArray *priceArray = [[NSArray alloc] initWithObjects: @"2000", @"4000", @"5000", nil];
    
    [_jsonHelperUtil setJSONFormattedStringFromVector:itemArray withPrice:priceArray andCount:countArray];
    NSString *formattedString = [_jsonHelperUtil getJSONFormattedString];
    
    STAssertEqualObjects(formattedString, dataString, @"Data is not proper");
}

- (void)testVectorStringWithItemArray
{
    NSString *dataString = @"{}";
    
    NSArray *itemArray = [[NSArray alloc] initWithObjects: @"Books", @"Media", @"Stationary", nil];
    
    [_jsonHelperUtil setJSONFormattedStringFromVector:itemArray withPrice:nil andCount:nil];
    NSString *formattedString = [_jsonHelperUtil getJSONFormattedString];
    
    STAssertEqualObjects(formattedString, dataString, @"Data is not proper");
}

- (void)testVectorStringWithPriceArray
{
    NSString *dataString = @"{}";
    
    NSArray *priceArray = [[NSArray alloc] initWithObjects: @"2000", @"4000", @"5000", nil];
    
    [_jsonHelperUtil setJSONFormattedStringFromVector:nil withPrice:priceArray andCount:nil];
     NSString *formattedString = [_jsonHelperUtil getJSONFormattedString];
    
    STAssertEqualObjects(formattedString, dataString, @"Data is not proper");
}

- (void)testVectorStringWithCountArray
{
    NSString *dataString = @"{}";
    
    NSArray *countArray = [[NSArray alloc] initWithObjects: [NSNumber numberWithInt:123], [NSNumber numberWithInt:12], [NSNumber numberWithInt:12], nil];
    
    [_jsonHelperUtil setJSONFormattedStringFromVector:nil withPrice:nil andCount:countArray];
    NSString *formattedString = [_jsonHelperUtil getJSONFormattedString];
    
    STAssertEqualObjects(formattedString, dataString, @"Data is not proper");
}

- (void)testVectorStringWithEmptyArray
{
    NSString *dataString = @"{}";
    
    [_jsonHelperUtil setJSONFormattedStringFromVector:nil withPrice:nil andCount:nil];
    NSString *formattedString = [_jsonHelperUtil getJSONFormattedString];
    
    STAssertEqualObjects(formattedString, dataString, @"Data is not proper");
}

//
- (void)testKeyAndValueAsDictionary
{
    NSString *actualString = @"{\"Key\":{\"Shoes\":\"Price\"}}";
    NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
    [dictionary setValue:@"" forKey:@"Books"];
    [dictionary setValue:@"Price" forKey:@"Shoes"];
    [dictionary setValue:nil forKey:@"Cosmetics"];
    
    [_jsonHelperUtil addKey:@"Key" withValueAsDictionary:dictionary];
    
    NSString *expectedString = [_jsonHelperUtil getJSONFormattedString];
    STAssertEqualObjects(actualString, expectedString, @"Strings are not equal");
}

- (void)testKeyAndValueAsEmptyDictionary
{
    NSString *actualString = @"{}";
    NSMutableDictionary *dictionary = nil;
    
    [_jsonHelperUtil addKey:@"Key" withValueAsDictionary:dictionary];
    
    NSString *expectedString = [_jsonHelperUtil getJSONFormattedString];
    STAssertEqualObjects(actualString, expectedString, @"Strings are not equal");
}
- (void)testKeyAsNilAndValueAsDictionary
{
    NSString *actualString = @"{\"Key\":{\"\":\"Price\"}}";
    NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
    [dictionary setValue:@"Books" forKey:@""];
    [dictionary setValue:@"Price" forKey:@""];
    
    [_jsonHelperUtil addKey:@"Key" withValueAsDictionary:dictionary];
    
    NSString *expectedString = [_jsonHelperUtil getJSONFormattedString];
    STAssertEqualObjects(actualString, expectedString, @"Strings are not equal");
}

@end
