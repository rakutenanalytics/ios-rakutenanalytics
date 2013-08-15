/*
 Copyright: Copyright (C) 2012 Rakuten, Inc.  All Rights Reserved.
 
 
 File Name:  RATrackingLib.h
 
 Description:   
 This singleton class track() method is used by user to track his application.
 User can set various parameters for tracking. This class checks for Network
 status with the help of Network manager and checks for buffered or
 non-buffered mode. CLLocation object gets all the
 location information from the Location Manager. The DeviceInfo
 object gets all the device related information such as battery status, device
 OS version, orientation etc. All the data is collected and a predefined
 formatted string is formed. The string is then appended to url. Depending on
 the <var>bufferMode</var> the data is inserted in the database and the compressed
 package is formed.
 
 Author: Mandar Kadam
 
 Created: 2nd-May-2012 
 
 Changed: 
 
 Version: 3.0
 
 */

#import <Foundation/Foundation.h>
#import "RCommonUtilities/RLicenseInformation.h"

@interface RATrackingLib : NSObject
{
@private
    
    //Details of the previous page reference, if any. 
    //It is a string that keeps the previous page name or previous page URL
    NSString            *referer;
    
    //Milestone ID. Goals are specific strategies you'll leverage to accomplish your business objectives.
    //It is a string that will be identified as Goal
    NSString            *goal;
    
    //pageName variable contains the name of each page or screen
    NSString            *pageName;
    
    //Content Language
    NSString            *contentLanguage;
    
    //A way of setting the query term enable logging of search queries
    NSString            *searchQuery;
    
    //Request status for a page
    NSString            *requestResult;
    
    //Currency code
    NSString            *currencyCode;
    
    //Account ID for any group or product owner. e.g. ID for ichiba or Rakuten bank etc. 
    long long           accountId;
    
    //Application's ID - Represents one of the applications ID for a particular account holder i.e. An account can contain many applications ID.
    long long           applicationId;
    
    /*Variable for checkout
     user need to set the following numeric data for the corresponding stage:
     10 – Stage1 (login)
     20 – Stage2 (Shipping details)
     30 – Stage3 (Order Summary)
     40 – Stage4 (Payment)
     50 – Stage5 (Verification)
     */
    int                 checkOut;
    
    //Checkpoint - Setting the check point. 
    int                 checkPoint;
    
    //campaign code - Code to determine app is a part of a campaign
    NSString            *campaignCode;
    
    //affiliate - ID of an affiliate where the redirection need to be done
    NSString            *affiliateId;
    
    //OfflineThrottleDelay - will be used during offline mode and buffered upload mode
    int                 thDelay;
    
    //If this parameter is set, the analytic data will be uploaded in a buffered manner as explained in the next section.
    BOOL                bufferMode;
}
@property(readwrite, copy) NSString         *referer;
@property(readwrite, copy) NSString         *goal;
@property(readwrite, copy) NSString         *pageName;
@property(readwrite, copy) NSString         *contentLanguage;
@property(readwrite, copy) NSString         *searchQuery;
@property(readwrite, copy) NSString         *requestResult;
@property(readwrite, copy) NSString         *currencyCode;
@property(readwrite, copy) NSString         *campaignCode;
@property(readwrite, copy) NSString         *affiliateId;
@property(readwrite, copy) NSString         *genre;
@property(readwrite, assign) long long      accountId;
@property(readwrite, assign) long long      applicationId;
@property(readwrite, assign) int            checkOut;
@property(readwrite, assign) int            checkPoint;
@property(readwrite, assign) int            thDelay;
@property(readwrite, assign) BOOL           bufferMode;
@property(readwrite, assign) int            pageLoadTime;

/** Rakuten Analytics SDK initialization.
 
 Initialise the Analytics library with geo location set to false.
 
 @return It returns Rakuten Analytics library object.
 */
+(RATrackingLib *)getInstance;


/** Rakuten Analytics SDK initialization with geolocation.
 
 Initialise the Analytics library with geo location set to false default.
 User can set enable location using this method.
 
 @param enableLocation Parameter of type BOOL for enabling or disabling the location service.
 @return It returns Rakuten Analytics library object.
 */
+(RATrackingLib *)getInstance:(BOOL)enableLocation;

/** Tracks the user information.
 
 Sends a standard page name to data collection servers, along with Track 
 Variables that have values.
 
 if online, construct's a predefined string which will be used for sending the
 data to server.
 if offline, insert the values in Database. 
 
 @return It returns nothing.
 */
-(void)track;

/** Tracks the user info with custom variables.
 
 Same as track, except you can pass in a list of key-value pairs to send any type of custom parameters to the track. Key repesents custom parameter name.
 
 @param customVariables Parameter of type NSdictionary.
 @return It returns nothing.
 */
-(void)track:(NSDictionary *)customVariables;

/** Flushes or clears the previously stored data.
 
 This method is used to clear all the track parameters and sets the default values to the parameters.
 
 @return It returns nothing.
 */
-(void)clearTrackParameters;

/** Set the price with wholeNumber.
 
 Performs the functionality of setting the price with input as whole number.
 @param wholePrice Parameter of type long long int containing the whole price 
 @return void it returns nothing.
 */
- (void)setPriceWithValue:(long long int)wholePrice;

/** Set the price with wholeNumber and decimal count
 
 Performs the functionality of setting the price with two input parameters as whole number and decimal count.
 @param wholePrice Parameter of type long long int containing the whole price with decimal value in it.
 @param decimalCount Parameter of type int. Count of decimal count.
 @return void it returns nothing.
 */
- (void)setPriceWithValue:(long long int)wholePrice andDecimal:(int)decimalCount;

/** Sets item parameters
 
 On the cart and checkout pages, the parameter fields item, price and num_items should be a list instead of a single value.
 For example, when the user buys the first item, the fields should be item: [item_001], price:[1000], num_items:[1]. When the user buys the second item, the fields should be like item: [item_001, item_002], price:[1000, 2000], num_items:[1, 3].
 These fields will keep expanding as the user keep buying more and more items
 Finally parameters will be send as follows:
 {
 "itemsvector":
 {
 "item":" item_001, item_002",
 "num_items":"1,3",
 "price":"1000,2000"
 }
 }
 @param items Parameter of type NSString.
 @param numOfItems Parameter of type integer.
 @param wholePrice Parameter of type long long int.
 @return void it returns nothing.
 */
- (void)setItemParams:(NSString *)item
        numberOfItems:(int)numOfItems
       andWholePrice:(long long int)wholePrice;

/** Sets item parameters
 
 On the cart and checkout pages, the parameter fields item, price and num_items should be a list instead of a single value.
 For example, when the user buys the first item, the fields should be item: [item_001], price:[1000], num_items:[1]. When the user buys the second item, the fields should be like item: [item_001, item_002], price:[1000, 2000], num_items:[1, 3].
 These fields will keep expanding as the user keep buying more and more items
 Finally parameters will be send as follows:
 {
     "itemsvector":
     {
         "item":" item_001, item_002",
         "num_items":"1,3",
         "price":"1000,2000"
     }
 }
 @param items Parameter of type NSString.
 @param numOfItems Parameter of type integer.
 @param wholePrice Parameter of type long long int containing the whole price with decimal valve in it.
 @param decimalCount Parameter of type int. Count of decimal count.
 @return void it returns nothing.
 */
- (void)setItemParams:(NSString *)item
        numberOfItems:(int)numOfItems
       withWholePrice:(long long int)wholePrice
      andDecimalCount:(int)decimalCount;

/** Register for licensing
 
 Performs the functionality of initialising the object of RLicenseInformations.
 
 @param licenseInformation of type RLicenseInformation
 @return It returns nothing.
 */
-(void)registerForLicensing:(RLicenseInformation *)licenseInformation;

@end
