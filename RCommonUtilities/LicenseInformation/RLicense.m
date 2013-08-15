/**
 Copyright: Copyright (C) 2012 Rakuten, Inc.  All Rights Reserved.
 
 
 File Name:  RLicenseInformation.m
 
 Description:  Handles all the registration and unregistering of licensing information.
 
 Author: Mandar Kadam
 
 Created:06th-Feb-2012
 
 Changed:
 
 Version: 1.0
 */

#import "RLicense.h"

@interface RLicense()
@property(nonatomic, copy)NSString *productName;
@property(nonatomic, copy)NSString *productVersion;
@property(nonatomic, copy)NSString *licenseInfoString;
@end

@implementation RLicense
@synthesize productName;
@synthesize productVersion;
@synthesize licenseInfoString;

/** Initialises the licensing information
 
 This class initialises the licensing information.
 
 @param name of type NSString.
 @param version of type NSString
 @param licenseString of type NSString.
 @return It returns initialised object of licenseInformation.
 */
- (id)initWithLicensingInformation:(NSString *)name
                    productVersion:(NSString *)version
                        andLicense:(NSString *)licenseString
{
    if( self = [super init])
    {
        self.productName = name;
        self.productVersion = version;
        self.licenseInfoString = licenseString;
    }
    return self;
}

/** Get the product name
 
 This class gets the product name
 
 @return It returns product name of type NSString.
 */
- (NSString *)getProductName
{
    return self.productName;
}

/** Get the product version
 
 This class gets the product version.
 
 @return It returns product version of type NSString.
 */
- (NSString *)getProductVersion
{
    return self.productVersion;
}

/** Get the licensing information
 
 This class gets the licensing information.
 
 @return It returns product licenseInformation.
 */
- (NSString *)getProductLicense
{
    return self.licenseInfoString;
}

- (void)dealloc{
    self.productName = nil;
    self.productVersion = nil;
    self.licenseInfoString = nil;
}

@end
