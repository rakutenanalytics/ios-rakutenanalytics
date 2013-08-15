/*
 Copyright: Copyright (C) 2012 Rakuten, Inc.  All Rights Reserved.
 
 
 File Name:  RATrackingLibTests.m
 
 Description: Test cases for Tracking libraru class.
 
 Author: Mandar Kadam
 
 Created: 2nd-Jan-2013
 
 Changed:
 
 Version: 1.0
**/

#import <SenTestingKit/SenTestingKit.h>
#import "RATrackingLib.h"
#import "RATrackingLib+Private.h"

@interface RATrackingLibTests:SenTestCase
@property RATrackingLib *trackingLib;
@end

@implementation RATrackingLibTests
- (void)setUp
{
    [super setUp];
    // Set-up code here.
    _trackingLib = [RATrackingLib getInstance];
}

- (void)tearDown {
}

//Test cases for Price
- (void)testPriceWithWholePriceAndDecimalCount1
{
    NSString *price = @"4567";
    [_trackingLib setPriceWithValue:4567 andDecimal:-1];
    STAssertEqualObjects(price, [_trackingLib getPriceValue], @"Price does not match");
}

- (void)testPriceWithWholePriceAndDecimalCount2
{
    NSString *price = @"4567";
    [_trackingLib setPriceWithValue:4567 andDecimal:0];
    STAssertEqualObjects(price, [_trackingLib getPriceValue], @"Price does not match");
}

- (void)testPriceWithWholePriceAndDecimalCount3
{
    NSString *price = @"456.7";
    [_trackingLib setPriceWithValue:4567 andDecimal:1];
    STAssertEqualObjects(price, [_trackingLib getPriceValue], @"Price does not match");
}

- (void)testPriceWithWholePriceAndDecimalCount4
{
    NSString *price = @"45.67";
    [_trackingLib setPriceWithValue:4567 andDecimal:2];
    STAssertEqualObjects(price, [_trackingLib getPriceValue], @"Price does not match");
}

- (void)testPriceWithWholePriceAndDecimalCount5
{
    NSString *price = @"4.567";
    [_trackingLib setPriceWithValue:4567 andDecimal:3];
    STAssertEqualObjects(price, [_trackingLib getPriceValue], @"Price does not match");
}

- (void)testPriceWithWholePriceAndDecimalCount6
{
    NSString *price = @"0.4567";
    [_trackingLib setPriceWithValue:4567 andDecimal:4];
    STAssertEqualObjects(price, [_trackingLib getPriceValue], @"Price does not match");
}

- (void)testPriceWithWholePriceAndDecimalCount7
{
    NSString *price = @"0.04567";
    [_trackingLib setPriceWithValue:4567 andDecimal:5];
    STAssertEqualObjects(price, [_trackingLib getPriceValue], @"Price does not match");
}

- (void)testPriceWithWholePriceAndDecimalCount8
{
    NSString *price = @"0.0000004567";
    [_trackingLib setPriceWithValue:4567 andDecimal:10];
    STAssertEqualObjects(price, [_trackingLib getPriceValue], @"Price does not match");
}

- (void)testPriceWithWholePriceAndDecimalCount9
{
    NSString *price = @"-4567";
    [_trackingLib setPriceWithValue:-4567 andDecimal:-1];
    STAssertEqualObjects(price, [_trackingLib getPriceValue], @"Price does not match");
}

- (void)testPriceWithWholePriceAndDecimalCount10
{
    NSString *price = @"-4567";
    [_trackingLib setPriceWithValue:-4567 andDecimal:0];
    STAssertEqualObjects(price, [_trackingLib getPriceValue], @"Price does not match");
}

- (void)testPriceWithWholePriceAndDecimalCount11
{
    NSString *price = @"-456.7";
    [_trackingLib setPriceWithValue:-4567 andDecimal:1];
    STAssertEqualObjects(price, [_trackingLib getPriceValue], @"Price does not match");
}

- (void)testPriceWithWholePriceAndDecimalCount12
{
    NSString *price = @"-45.67";
    [_trackingLib setPriceWithValue:-4567 andDecimal:2];
    STAssertEqualObjects(price, [_trackingLib getPriceValue], @"Price does not match");
}

- (void)testPriceWithWholePriceAndDecimalCount13
{
    NSString *price = @"-4.567";
    [_trackingLib setPriceWithValue:-4567 andDecimal:3];
    STAssertEqualObjects(price, [_trackingLib getPriceValue], @"Price does not match");
}

- (void)testPriceWithWholePriceAndDecimalCount14
{
    NSString *price = @"-0.4567";
    [_trackingLib setPriceWithValue:-4567 andDecimal:4];
    STAssertEqualObjects(price, [_trackingLib getPriceValue], @"Price does not match");
}

- (void)testPriceWithWholePriceAndDecimalCount15
{
    NSString *price = @"-0.04567";
    [_trackingLib setPriceWithValue:-4567 andDecimal:5];
    STAssertEqualObjects(price, [_trackingLib getPriceValue], @"Price does not match");
}

- (void)testPriceWithWholePriceAndDecimalCount16
{
    NSString *price = @"-0.0000004567";
    [_trackingLib setPriceWithValue:-4567 andDecimal:10];
    STAssertEqualObjects(price, [_trackingLib getPriceValue], @"Price does not match");
}

- (void)testPriceWithWholePriceAndDecimalCount17
{
    NSString *price = @"-1";
    [_trackingLib setPriceWithValue:-1 andDecimal:-1];
    STAssertEqualObjects(price, [_trackingLib getPriceValue], @"Price does not match");
}

- (void)testPriceWithWholePriceAndDecimalCount18
{
    NSString *price = @"0";
    [_trackingLib setPriceWithValue:0 andDecimal:-1];
    STAssertEqualObjects(price, [_trackingLib getPriceValue], @"Price does not match");
}

- (void)testPriceWithWholePriceAndDecimalCount19
{
    NSString *price = @"0";
    [_trackingLib setPriceWithValue:0 andDecimal:0];
    STAssertEqualObjects(price, [_trackingLib getPriceValue], @"Price does not match");
}
@end