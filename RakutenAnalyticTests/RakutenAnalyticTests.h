/*
 Copyright: Copyright (C) 2012 Rakuten, Inc.  All Rights Reserved.
 
 
 File Name:  RakutenAnalyticTests.h
 
 Description: Rakuten Analytic containing the unit test cases
 
 Author: Mandar Kadam
 
 Created: 11th-Jun-2012 
 
 Changed: 
 
 Version: 1.0
 
 *
 */

#import <SenTestingKit/SenTestingKit.h>
#import <CoreLocation/CoreLocation.h>
#import "RCommonUtilities/RGeoLocationManager.h"
#import "RCommonUtilities/RUtil+NSData+Compression.h"
#import "RCommonUtilities/RUtilHTTPManager.h"
#import "RCommonUtilities/RDeviceInformation.h"
#import "RCommonUtilities/RNetworkManager.h"
#import "RADBHelper.h"
#import "RCommonUtilities/RStringUtility.h"

@interface RakutenAnalyticTests : SenTestCase
{
    RStringUtility      *stringUtility;
    RGeoLocationManager *locationmanager;
    RUtilHTTPManager    *httpManager;
    RDeviceInformation *deviceManager;
    RNetworkManager     *networkManager;
    RADBHelper          *dbHelper;
    BOOL                done;
}
@end
