/**
 Copyright: Copyright (C) 2012 Rakuten, Inc.  All Rights Reserved.
 
 
 File Name:  RLicenseinformations.m
 
 Description:  Keeps the collection of licensing information.
 
 Author: Mandar Kadam
 
 Created:06th-Feb-2012
 
 Changed:
 
 Version: 1.0
 */

#import "RLicenseinformation.h"

@interface RLicenseInformation()
@property(nonatomic, strong)NSMutableArray *licensingArray;
@end

@implementation RLicenseInformation
@synthesize licensingArray;

- (id)init
{
    if(self = [super init])
    {
        self.licensingArray = [[NSMutableArray alloc] init];
    }
    return self;
}

/** Adds the license Info in collection
 
 This class gets array of objects containing different licensing information.
 
 @return void. It returns nothing.
 */
- (void)addLicense:(RLicense *)license
{
    [self.licensingArray addObject:license];
}

/** Gets the license Info
 
 This class gets license model information for the respective index.
 
 @param licenseIndex of type int, here license index is zero based.
 @return It returns license.
 */
- (RLicense *)getLicenseInformationForIndex:(int)licenseIndex
{
    @try
    {
        if( [self.licensingArray count] > licenseIndex)
        {
            return [self.licensingArray objectAtIndex:licenseIndex];
        }
    }
    @catch (NSException *exception)
    {
        return nil;
    }
    return nil;
}

/** License count held by registered SDK.
 
 This class gets total count of licenses held..
 
 @return It returns total count of license held by the SDK component.
 */
- (int)getTotalLicenseCount;
{
    return [self.licensingArray count];
}

@end
