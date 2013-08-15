/**
 Copyright: Copyright (C) 2012 Rakuten, Inc.  All Rights Reserved.
 
 
 File Name:  RLicense.h
 
 Description:  Keeps information of the license.
 
 Author: Mandar Kadam
 
 Created:04th-Feb-2012
 
 Changed:
 
 Version: 1.0
 */

#import <Foundation/Foundation.h>

@interface RLicense : NSObject
/** Initialises the licensing information
 
 This class initialises the licensing information.
 
 @param name of type NSString.
 @param version of type NSString
 @param licenseString of type NSString.
 @return It returns initialised object of licenseInformation.
 */
- (id)initWithLicensingInformation:(NSString *)name
                    productVersion:(NSString *)version
                        andLicense:(NSString *)licenseString;

/** Get the product name
 
 This class gets the product name
 
 @return It returns product name of type NSString.
 */
- (NSString *)getProductName;

/** Get the product version  
 
 This class gets the product version.
 
 @return It returns product version of type NSString.
 */
- (NSString *)getProductVersion;

/** Get the licensing information
 
 This class gets the licensing information.
 
 @return It returns product licenseInformation.
 */
- (NSString *)getProductLicense;
@end
