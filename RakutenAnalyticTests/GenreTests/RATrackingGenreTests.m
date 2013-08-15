/*
 Copyright: Copyright (C) 2012 Rakuten, Inc.  All Rights Reserved.
 
 
 File Name:  RATrackingGenreTests.m
 
 Description: Test cases for genre field
 
 Author: Mandar Kadam
 
 Created: 14th-Jan-2013
 
 Changed:
 
 Version: 1.0
 **/

#import <SenTestingKit/SenTestingKit.h>
#import "RATrackingLib.h"
#import "RATrackingLib+Private.h"

@interface RATrackingGenreTests:SenTestCase
@property RATrackingLib *trackingLib;
@end

@implementation RATrackingGenreTests
- (void)setUp
{
    [super setUp];
    // Set-up code here.
    _trackingLib = [RATrackingLib getInstance];
}

- (void)tearDown {
}

//Test cases for Genre
- (void)testGenreWithValue
{
    NSString *expectedString = @"\"genre\":\"books\"";
    _trackingLib.genre = @"books";
    [_trackingLib track];
    NSString *formattedJSONString = [_trackingLib getFormattedString];
    
    NSRange textRange = [formattedJSONString rangeOfString:expectedString];
    STAssertTrue((textRange.location != NSNotFound), @"Genre not found");
}

- (void)testGenreWithEmpty
{
    NSString *expectedString = @"\"genre\"";
    _trackingLib.genre = @"";
    [_trackingLib track];
    NSString *formattedJSONString = [_trackingLib getFormattedString];
    NSRange textRange = [formattedJSONString rangeOfString:expectedString];
    STAssertTrue(!(textRange.location != NSNotFound), @"Genre not found");
}

- (void)testGenreWithNil
{
    NSString *expectedString = @"\"genre\"";
    _trackingLib.genre = nil;
    [_trackingLib track];
    NSString *formattedJSONString = [_trackingLib getFormattedString];
    
    NSRange textRange = [formattedJSONString rangeOfString:expectedString];
    STAssertTrue(!(textRange.location != NSNotFound), @"Genre not found");
}

- (void)testGenreWithNothing
{
    NSString *expectedString = @"\"genre\"";
    [_trackingLib track];
    NSString *formattedJSONString = [_trackingLib getFormattedString];

    NSRange textRange = [formattedJSONString rangeOfString:expectedString];
    STAssertTrue(!(textRange.location != NSNotFound), @"Genre not found");
}
@end