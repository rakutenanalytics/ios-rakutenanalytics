/**
 Copyright: Copyright (C) 2012 Rakuten, Inc.  All Rights Reserved.
 
 
 File Name:  RLicenseinformations.h
 
 Description:  Keeps the collection of licensing information.
 
 Author: Mandar Kadam
 
 Created:06th-Feb-2012
 
 Changed:
 
 Version: 1.0
 */

#import <Foundation/Foundation.h>
#import "RLicense.h"

@interface RLicenseInformation : NSObject

/** Gets the license Info 
 
 This class gets license model information for the respective index.
 
 @param licenseIndex of type int, here license index is zero based.
 @return It returns license info.
 */
- (RLicense *)getLicenseInformationForIndex:(int)licenseIndex;


/** License count held by registered SDK.
 
 This class gets total count of licenses held..
 
 @return It returns total count of license held by the SDK component.
 */
- (int)getTotalLicenseCount;

/** Adds license infor in collection.
 
 This class adds license model information in collections.
 @param licenseModel of type RLicense.
 @return void. It returns nothing.
 */
- (void)addLicense:(RLicense *)license;

@end
