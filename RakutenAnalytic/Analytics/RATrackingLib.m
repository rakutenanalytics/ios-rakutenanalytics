/*
 Copyright: Copyright (C) 2012 Rakuten, Inc.  All Rights Reserved.
 
 
 File Name:  RATrackingLib.m
 
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
 
 Version: 1.0
 
 */
#import "RCommonUtilities/RNetworkManager.h"
#import "RCommonUtilities/RGeoLocationManager.h"
#import "RCommonUtilities/RGenericUtility.h"
#import "RATrackingLib.h"
#import "RADBHelper.h"
#import "RCommonUtilities/RDeviceInformation.h"
#import "RACommons.h"
#import "RARequestResponseHandler.h"
#import "RAJsonHelperUtil.h"
#import "RATrackingLib+Private.h"
#import "RCommonUtilities/RLicense.h"

const float kSecondsValue = 3600.00;
const float kDefaultThrottleDelay = 10;
const int kCurrencyCodeLength = 3;
#define kPredicateForCurrencyCode  @"^[a-zA-Z]+$"

//Buffered key value pair
NSString *const kOfflineCompressedPackageKey = @"cpkg_gzip";
NSString *const kOnlineCompressedPackageKey = @"cpkg_none";

dispatch_queue_t         backgroundQueue;

@interface RATrackingLib ()
{
    RStringUtility           *stringUtility;
    RDeviceInformation       *deviceInformation;
    RGeoLocationManager      *geoLocation;
    
    
    int                      integralPriceValue;
    int                      decimalPriceValue;
    
    NSString                 *price;
    
    //For Vector usage
    NSMutableArray           *itemsArray;
    NSMutableArray           *priceArray;
    NSMutableArray           *itemCountArray;
}
//Session cookie
@property(nonatomic, copy) NSString *ts;

//Start script time of the application,  it represents session start time of native app
@property(nonatomic, copy) NSString *ltm;

//Session cookie which will be set every time user terminates or goes in background
@property(nonatomic, copy) NSString *cks; 

////Persistent cookie. This is to identify the individual user
@property(nonatomic, copy) NSString *ckp;   

////It is a base64 encoding string data type
//A package containing compressed offline events buffered for package upload.
@property(nonatomic, copy) NSString *cpkg;

//User Agent or device ID
@property(nonatomic, copy) NSString *ua;

//Carrier or service provider
@property(nonatomic, copy) NSString *mcn;

//Storing the fprice value as string, concatenating the integral and decimal value
@property(nonatomic, copy) NSString *price;

@property(nonatomic, strong) NSTimer  *timerForThrottleDelay;

@property(nonatomic, strong) CLLocation *location;

/*network type - Network type such as Wi-Fi or WWAN
 1 – Wi-Fi
 2 – WWAN
 */
@property(nonatomic, assign)int mnetw;

//Online/Offline status
@property(nonatomic, assign)BOOL online;

//Time zone offset
@property(nonatomic, assign)float tzo;

//list of key-value pairs used to send any type of custom parameters to the track. Key repesents custom parameter name.
@property(nonatomic, strong)NSDictionary *customParamerters;


-(void)initiateConnectionWithRequestString:(NSString *)params withCompression:(BOOL)isCompression; 
-(void)checkForThrottleDelay;
-(void)fetchTrackingParameters;
-(void)checkForBufferedNonBufferedAndPerformAction:(NSString *)formattedJSONString;
-(void)checkForCurrecyCode;
-(void)checkOnTrackingParameters;
-(void)setDefaultValues;
-(NSString *)checkForString:(NSString *)string;
@end

@implementation RATrackingLib

static RATrackingLib *shared = nil;
static dispatch_once_t pred;

enum 
{
    CHK_OUT_10 = 10,
    CHK_OUT_20 = 20,
    CHK_OUT_30 = 30,
    CHK_OUT_40 = 40,
    CHK_OUT_50 = 50
};


@synthesize referer, goal, pageName, contentLanguage, searchQuery, requestResult, currencyCode;
@synthesize accountId, applicationId, checkOut, checkPoint, campaignCode, affiliateId, thDelay, bufferMode, price, pageLoadTime, customParamerters;
@synthesize ts, ltm, cks, ckp, cpkg, ua, mcn, timerForThrottleDelay, location, mnetw, online, tzo;
@synthesize genre;

/*!
 @function		sharedInstance
 @discussion	This is singleton implementation of RakutenAnalytics
 shared instance.
 @param			none 
 @result		RATrackingLib instance
 */
+(RATrackingLib *)getInstance
{
    dispatch_once(&pred, ^{
        shared = [[RATrackingLib alloc] init];
        backgroundQueue = dispatch_queue_create("com.rat.rakuten", NULL);
        [shared setDefaultValues];
    });
    [shared enableGeoLocation:YES];
    return shared;
}


/*!
 @function		sharedInstance
 @discussion	This is singleton implementation of RakutenAnalytics
 shared instance.
 @param			none
 @result		RATrackingLib instance
 */
+(RATrackingLib *)getInstance:(BOOL)enableLocation
{
    dispatch_once(&pred, ^{
        shared = [[RATrackingLib alloc] init];
        backgroundQueue = dispatch_queue_create("com.rat.rakuten", NULL);
        [shared setDefaultValues];
    });
    [shared enableGeoLocation:enableLocation];
    return shared;
}
/*!
 @function		enableGeoLocation:
 @discussion	Perform the functionality of enabling or disabling the geolocation
 @param			enableGeoLocation or not of type BOOL
 @result		nil
 */
-(void)enableGeoLocation:(BOOL)enableLocation
{
    if( !enableLocation )
    {
        geoLocation = nil;
    }
    else
    {
        geoLocation = [[RGeoLocationManager alloc] init];
    }
}
/*!
 @function		setDefaultValues
 @discussion	Intialise all the configuration variables with default values
 Performs or initialise network manager, location manager, device manager and databse helper classes
 @param			nil 
 @result		returns object of RATrackingLib  
 */
-(void)setDefaultValues
{
    stringUtility = [[RStringUtility alloc] init];
    deviceInformation = [[RDeviceInformation alloc] init];
    
    [self clearTrackParameters];
    self.ltm = [stringUtility dateToStringFormat:[NSDate date]];
    
    // Registering to the notification, when user comes to vissible and background state.
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidBecomeActive:) 
                                                 name:UIApplicationDidBecomeActiveNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationWillResignActive:) name:UIApplicationWillResignActiveNotification object:nil];
    
    //Network manager will start notifying the network status
    [[RNetworkManager sharedManager] startNotifier];
    [RADBHelper sharedInstance];
    
    self.cks = [stringUtility getUUID];
    self.ckp = [stringUtility getDeviceID];
}
/*!
 @function		checkForCurrecyCode
 @discussion	Responsibility of this method is accept only 3chars of the input string. If special character found intialise currency code to nil
 @param			none 
 @result		none
 */
-(void)checkForCurrecyCode
{
    self.currencyCode = [stringUtility getStringInRange:self.currencyCode withMaxStringLength:kCurrencyCodeLength];
    NSPredicate *validCurrencyCodeTest = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", kPredicateForCurrencyCode];
    if( ![validCurrencyCodeTest evaluateWithObject:self.currencyCode] || [self.currencyCode length] < 3 )
    {
        RULog(@"Inavlid currency code");
        self.currencyCode = nil;
    }
    validCurrencyCodeTest = nil;
}

/*!
 @function		checkForCheckout
 @discussion	Responsibility of this method is accept only 3chars of the input string. If special character found intialise currency code to nil
 @param			none 
 @result		none
 */
-(void)checkForCheckout
{
    if( (self.checkOut != CHK_OUT_10 && self.checkOut != CHK_OUT_20 && self.checkOut != CHK_OUT_30 && self.checkOut != CHK_OUT_40 && self.checkOut != CHK_OUT_50) )
    {
        self.checkOut = -1;
    }
}

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
        andWholePrice:(long long int)wholePrice
{
    [self setItemParams:item numberOfItems:numOfItems withWholePrice:wholePrice andDecimalCount:0];
}

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
 @param item of type NSString.
 @param numOfItems of type integer.
 @param wholePrice of type long long int.
 @param decimalCount of type int.
 @return void it returns nothing.
 */
- (void)setItemParams:(NSString *)item
        numberOfItems:(int)numOfItems
       withWholePrice:(long long int)wholePrice
      andDecimalCount:(int)decimalCount
{
    if( [RGenericUtility isNotEmpty:item] && numOfItems != 0 )
    {
        [itemsArray addObject:item];
        [self setPriceWithValue:wholePrice andDecimal:decimalCount];
        [priceArray addObject:self.price];
        [itemCountArray addObject:[NSNumber numberWithInt:numOfItems]];
    }
}

/** Flush all the item vector information
 
 Performs the functionality of flushing all the vector data.
 
 @return void it returns nothing.
 */
- (void)resetItemParams
{
    itemsArray = nil;
    itemCountArray = nil;
    priceArray = nil;
}

/** Flushes and then initialises vector information variables
 
 Performs the functionality of flushing and then initialising all the vector information array.
 
 @return void it returns nothing.
 */
- (void)flushAndThenInitialiseVectorData
{
    [self resetItemParams];
    itemsArray = [[NSMutableArray alloc] init];
    itemCountArray = [[NSMutableArray alloc] init];
    priceArray = [[NSMutableArray alloc] init];
}

/*!
 @function		checkOnTrackingParameters
 @discussion	Check for tracking parameters satisfying the respective conditions
 @param			none 
 @result		none
 */
-(void)checkOnTrackingParameters
{
    [self checkForCurrecyCode];
    [self checkForCheckout];
    [self fetchTrackingParameters];
    self.affiliateId = [self checkForString:self.affiliateId];
    self.campaignCode = [self checkForString:self.campaignCode];
}

/*!
 @function		checkForString
 @discussion    initiate check for alphanumeric and perform opertion accordingly
 @param			none 
 @result		none
 */
-(NSString *)checkForString:(NSString *)string
{
    BOOL isAlphanumeric = [stringUtility isAlphaNumeric:string];
    if( isAlphanumeric  )
    {
        return string;
    }
    return nil;
}

/*!
 @function	 track
 @discussion
 1. Makes a call to collect the information of application
 @param	 none
 @result	 nil
 */
-(void)track
{
    self.customParamerters = nil;
    [self collectApplicationInformation];
}

/*!
 @function	 track
 @discussion	Same as track,
 1. Makes a call to collects the information of application
 2. Additional thing, it passes a list of key-value pairs which acts as a custom parameters to the track. Key repesents custom parameter name
 @param	 customVarialbes of type NSDictionary
 @result	 void
 */
-(void)track:(NSDictionary *)customVariables
{
    self.customParamerters = customVariables;
    [self collectApplicationInformation];
}

/*!
 @function	 collectApplicationInformation
 @discussion	Same as track,
 1. Sends a standard page name to data collection servers, along with Track
 Variables that have values.
 2. if online, construct's a predefined string which will be used for sending the
 data to server.
 3. if offline, insert the values in Database.

 @param	 It takes nothing as input.
 @result void
 */

-(void)collectApplicationInformation
{
    if( self.accountId > 0 && self.applicationId > 0 )
    {
        [self performDataOperation];
        if( !(self.online == TRUE && self.bufferMode == FALSE) )
        {
            [self checkForThrottleDelay];
        }
    }
}

- (void)performDataOperation
{
    dispatch_async(backgroundQueue, ^{
        @autoreleasepool
        {
            [self checkOnTrackingParameters];
            [deviceInformation fetchDeviceInformation];
            NSString *formattedString = [self getFormattedString];
            @synchronized([RATrackingLib getInstance])
            {
                // Insert all the record information ito DB
                [[RADBHelper sharedInstance] insertRecordWithValues:self.ts
                                                      andJSONString:formattedString];
            }
            [self checkForBufferedNonBufferedAndPerformAction:formattedString];
        }
    });   
}
/*!
 @function		checkForThrottleDelay
 @discussion	Set the timer based on the throttle delay and make a call for fetching records from Database.
 @param			none 
 @result		void
 */
-(void)checkForThrottleDelay
{
    //Check for throttle delay and accordingly call to initiate connection
    if( self.timerForThrottleDelay )
    {
        [self.timerForThrottleDelay invalidate];
        self.timerForThrottleDelay = nil;
    }
    
    if( self.thDelay <= 0 )
    {
        self.thDelay = kDefaultThrottleDelay;
    }
    self.timerForThrottleDelay = [NSTimer scheduledTimerWithTimeInterval:self.thDelay 
                                                                  target:self 
                                                                selector:@selector(fetchDataFromDBandSendOverNetwork) 
                                                                userInfo:nil 
                                                                 repeats:YES];
}

/*!
 @function		getFormattedString
 @discussion	Method used for formatting string inorder to 
 @param			none 
 @result		NSMutableDictionary with all the key value pairs
 */
-(NSString *)getFormattedString
{
    
    //Getting the track parameters other than location data in JSON format.
    RAJsonHelperUtil *jsonHelperTrackParameters = [[RAJsonHelperUtil alloc] init];
    
    [jsonHelperTrackParameters addKey:kVersion withValue:[[NSBundle mainBundle] objectForInfoDictionaryKey:kCFBundleVersion]];
    [jsonHelperTrackParameters addKey:kAccountIdentifier withValue:[stringUtility longToString:self.accountId]];
    [jsonHelperTrackParameters addKey:kApplicationIdentifier withValue:[stringUtility longToString:self.applicationId]];
    [self setJSONStringForLocation:jsonHelperTrackParameters];
    [jsonHelperTrackParameters addKey:kScriptStartTime withValue:self.ltm];
    [jsonHelperTrackParameters addKey:kTimeZoneOffset withValue:[stringUtility floatToString:self.tzo]];
    [jsonHelperTrackParameters addKey:kResolution withValue:deviceInformation.res];
    [jsonHelperTrackParameters addKey:kSessionCookie withValue:[stringUtility checkforNullString:self.cks]];
    [jsonHelperTrackParameters addKey:kPersisitentCookie withValue:[stringUtility checkforNullString:self.ckp]];
    [jsonHelperTrackParameters addKey:kUserAgent withValue:[stringUtility checkforNullString:self.ckp]];
    [jsonHelperTrackParameters addKey:kOnline withValue:[stringUtility booltoStringConversion:self.online]];
    [jsonHelperTrackParameters addKey:kTimeStamp withValue:self.ts];
    [jsonHelperTrackParameters addKey:kContentLanguage withValue:[stringUtility checkforNullString:self.contentLanguage]];
    [jsonHelperTrackParameters addKey:kReferrer withValue:[stringUtility checkforNullString:self.referer]];
    [jsonHelperTrackParameters addKey:kGoalID withValue:[stringUtility checkforNullString:self.goal]];
    [jsonHelperTrackParameters addKey:kPageName withValue:[stringUtility checkforNullString:self.pageName]];
    [jsonHelperTrackParameters addKey:kSearchQuery withValue:[stringUtility checkforNullString:self.searchQuery]];
    [jsonHelperTrackParameters addKey:kCheckOut withValue:[stringUtility intToString:self.checkOut]];
    [jsonHelperTrackParameters addKey:kPrice withValue:self.price];
    [jsonHelperTrackParameters addKey:kCurrencyCode withValue:[stringUtility checkforNullString:self.currencyCode]];
    [jsonHelperTrackParameters addKey:kCheckpoint withValue:[stringUtility intToString:self.checkPoint]];
    [jsonHelperTrackParameters addKey:kCampaignCode withValue:[stringUtility checkforNullString:self.campaignCode]];
    [jsonHelperTrackParameters addKey:kAffilaiteID withValue:[stringUtility checkforNullString:self.affiliateId]];
    [jsonHelperTrackParameters addKey:kRequestResult withValue:[stringUtility checkforNullString:self.requestResult]];
    [jsonHelperTrackParameters addKey:kNavigationTime withValue:[stringUtility intToString:self.pageLoadTime]];
    [jsonHelperTrackParameters addKey:kBattery withValue:[stringUtility intToString:deviceInformation.batteryLevel]];
    [jsonHelperTrackParameters addKey:kOSVersion withValue:[NSString stringWithFormat:@"iOS %@",deviceInformation.systemVersion]];
    [jsonHelperTrackParameters addKey:kOrientation withValue:[stringUtility intToString:deviceInformation.orientation]];
    [jsonHelperTrackParameters addKey:kNetworkType withValue:[stringUtility intToString:self.mnetw]];
    [jsonHelperTrackParameters addKey:kCarrierName withValue:self.mcn];
    [jsonHelperTrackParameters addKey:kDeviceLanguage withValue:[stringUtility checkforNullString:deviceInformation.deviceLanguage]];
    [jsonHelperTrackParameters addKey:kGenre withValue:[stringUtility checkforNullString:self.genre]];
    
    //Converting BOOL to int for setting the powerstatus
    int powerStatusValue =  (deviceInformation.isDevicePluggedToPower) ? 1 : 0;
    
    [jsonHelperTrackParameters addKey:kPowerStatus withValue:[stringUtility intToString:powerStatusValue]];
    
    //String creation for Vector
    [jsonHelperTrackParameters setJSONFormattedStringFromVector:itemsArray withPrice:priceArray andCount:itemCountArray];
    
    //RULog(@"\n\n\n\n\nvectorJSONString : %@\n\n\n\n\n", vectorJSONString);
    
    [self flushAndThenInitialiseVectorData];
    
    if( self.customParamerters )
    {
        [self setJSONStringForCustomParameters:jsonHelperTrackParameters];
    }
    
    //RULog(@"data is: %@", [jsonHelperTrackParameters getJSONFormattedString]);
    return [jsonHelperTrackParameters getJSONFormattedString];
}
/*!
 @function		getJSONStringForLocation
 @discussion	Method used for getting the location information in a JSON string format.
 @param			none
 @result		returns string in JSON format. 
 */
- (void)setJSONStringForLocation:(RAJsonHelperUtil *)helperUtil
{
    NSString *tms = @"";
    if( geoLocation )
    {
        if ([geoLocation isLocationKnown])
        {
            tms = [stringUtility dateToStringConversion:self.location.timestamp];
        }
    }
    float speed = self.location.speed;
       
    NSMutableDictionary *locationInfo = [NSMutableDictionary dictionary];;
    [locationInfo setValue:[stringUtility doubleToString:self.location.coordinate.longitude] forKey:kLongitude];
    [locationInfo setValue:[stringUtility doubleToString:self.location.coordinate.latitude] forKey:kLatitude];
    [locationInfo setValue:[stringUtility floatToString:speed] forKey:kSpeed];
    [locationInfo setValue:[stringUtility floatToString:self.location.horizontalAccuracy] forKey:kHorizontalAccuracy];
    [locationInfo setValue:[stringUtility floatToString:self.location.verticalAccuracy] forKey:kVerticalAccuracy];
    [locationInfo setValue:[stringUtility floatToString:self.location.altitude] forKey:kAltitude];
    [locationInfo setValue:tms forKey:kLocationTimeStamp];
    
    RULog(@"[stringUtility doubleToString:self.location.coordinate.longitude]: %@", [stringUtility doubleToString:self.location.coordinate.longitude]);
    
    [helperUtil addKey:kLocation withValueAsDictionary:locationInfo];
    //locationInfo = nil;
}

/*!
 @function		getJSONStringForCustomParameters
 @discussion	Method used for getting the cuatom parameter information in a JSON string format.
 @param			none
 @result		returns string in JSON format.
 */
- (void)setJSONStringForCustomParameters:(RAJsonHelperUtil *)helperUtil
{
    NSMutableDictionary *formattedCustomDictionary = [NSMutableDictionary dictionary];
    @try {
        if ([self.customParamerters count]) {
            NSArray *keyArray =  [self.customParamerters allKeys];
            int count = [keyArray count];
            if( count > 0 )
            {
                for (int keyArrayCount = 0; keyArrayCount < count; keyArrayCount++)
                {
                    NSString *value = [self.customParamerters objectForKey:[keyArray objectAtIndex:keyArrayCount]];
                    value = [stringUtility getStringInRange:value withMaxStringLength:kMaxCustomParameterValueLength];
                    RULog(@"value is value is\n\n\n : %@", value);
                    
                    NSString *key = [keyArray objectAtIndex:keyArrayCount];
                    key = [stringUtility getStringInRange:key withMaxStringLength:kMaxCustomParameterKeyLength];
                    RULog(@"key is key is \n\n\n : %@", key);
                    
                    [formattedCustomDictionary setValue:value forKey:key];
                }
            }
        }
    }
    @catch (NSException *exception) {
        RULog(@"%@", exception.description);
    }
    self.customParamerters = formattedCustomDictionary;
    [helperUtil addKey:kCustomParameterKey withValueAsDictionary:formattedCustomDictionary];
    formattedCustomDictionary = nil;
}

/** Set the price with wholeNumber.
 
 Performs the functionality of setting the price with input as whole number.
 @param wholePrice Parameter of type long long int containing the whole price
 @return void it returns nothing.
 */
- (void)setPriceWithValue:(long long int)wholePrice
{
    [self setPriceWithValue:wholePrice andDecimal:0];
}

/** Set the price with wholePrice and decimal count
 
 Performs the functionality of setting the price with two input parameters as whole number and decimal count.
 @param wholePrice of type long long int.
 @param decimalCount of type int.
 @return void it returns nothing.
 */
- (void)setPriceWithValue:(long long int)wholePrice andDecimal:(int)decimalCount
{
    BOOL isPositive = YES;
    if( wholePrice < 0 )
    {
        isPositive = NO;
    }
    
    long long int absoluteNumber = llabs(wholePrice);
    
    NSMutableString *numberString = [NSMutableString stringWithFormat:@"%lld", absoluteNumber];
    int length = [numberString length];
    if( decimalCount > 0)
    {
        if( decimalCount < length )
        {
            int insertCharAtIndex = length - decimalCount;
            [numberString insertString:@"." atIndex:insertCharAtIndex];
        }
        else
        {
            int noOfZeros = decimalCount - length;
            for (int count = 0; count < noOfZeros; count++)
            {
                numberString = [NSMutableString stringWithFormat:@"0%@", numberString];
            }
            numberString = [NSMutableString stringWithFormat:@"0.%@", numberString];
        }
    }    
    if( isPositive == NO )
        numberString = [NSMutableString stringWithFormat:@"-%@", numberString];
    
    self.price = numberString;
}

/*!
 @function		clearTrackParameters
 @discussion	This method is used to clear all the track parameters and sets the default values to the parameters.
 @param			none 
 @result		nil
 */
-(void)clearTrackParameters
{
    self.referer = nil;
    self.goal = nil;
    self.pageName  = nil;
    self.contentLanguage = nil;
    self.searchQuery = nil;
    self.checkOut = -1;
    self.price = nil;
    self.currencyCode = nil;
    self.checkPoint = -1;
    self.campaignCode = nil;
    self.requestResult = nil;
    self.pageLoadTime = -1;
    self.thDelay = kDefaultThrottleDelay;
    self.bufferMode = FALSE;
    [self flushAndThenInitialiseVectorData];
}

/*!
 @function		initiateConnectionWithRequestString
 @discussion	Creates or forms url request and send to HTTPHandler class to send it over a network
 @param			requestString of typr NSString  
 @result		nil
 */
-(void)initiateConnectionWithRequestString:(NSString *)params withCompression:(BOOL)isCompression
{
    RULog(@"\n\nParams: %@\n\n", params);
    RARequestResponseHandler *requestResponseHandler = [[RARequestResponseHandler alloc] init];
    NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
    if (isCompression) 
    {
        [dictionary setObject:params forKey:kOfflineCompressedPackageKey];
        [requestResponseHandler makeRequestWithParameters:dictionary andTimeStamp:nil];
    }
    else 
    {
        [dictionary setObject:params forKey:kOnlineCompressedPackageKey];
        [requestResponseHandler makeRequestWithParameters:dictionary andTimeStamp:self.ts];
    }
}

/** Register for licensing
 
 Performs the functionality of initialising the object of RLicenseInformations.
 
 @param licenseInformation of type RLicenseInformations
 @return It returns nothing.
 */
-(void)registerForLicensing:(RLicenseInformation *)licenseInformation
{
    RLicense *license = [[RLicense alloc] initWithLicensingInformation:kJSON
                                                        productVersion:kJSONVersion
                                                            andLicense:kJSONLicense];
    [licenseInformation addLicense:license];
    license = nil;
}

/*!
 @function		applicationWillResignActive
 @discussion	Callback or notification which specifies application comes inactive mode
 @param			note of type NSNotification  
 @result		nil
*/
- (void)applicationWillResignActive:(UIApplication *)application
{
    /*
     Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
     Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
     */
    if (self.timerForThrottleDelay) {
        [self.timerForThrottleDelay invalidate];
        self.timerForThrottleDelay = nil;
    }
}

/*!
 @function		applicationDidBecomeActive
 @discussion	Callback or notification which specifies application comes in active mode
 @param			note of type NSNotification  
 @result		nil
 */
- (void)applicationDidBecomeActive:(UIApplication *)application
{
    /*
     Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
     */
    self.cks = [stringUtility getUUID];
    [self checkForThrottleDelay];
}


/*!
 @function		fetchDataFromDBandSendOverNetwork
 @discussion	Callback or notification which specifies application has gone in background mode
 @param			note of type NSNotification  
 @result		nil
 */
-(void)fetchDataFromDBandSendOverNetwork
{
    dispatch_async(backgroundQueue, ^{
        if( self.online && self.timerForThrottleDelay)
        {
            [self.timerForThrottleDelay invalidate];
            self.timerForThrottleDelay = nil;
        }
        
        NSString *compressedBase64EncodeString =  [[RADBHelper sharedInstance] fetchRecordsFromTable];
        if( compressedBase64EncodeString != nil )
        {
            [self initiateConnectionWithRequestString:compressedBase64EncodeString withCompression:TRUE];
        }
    });
}

/*!
 @function		fetchTrackingParameters
 @discussion	Responsible for setting all the parameters that are mandatory and calculated as per the specifications 
 @param			nil 
 @result		nil
 */
-(void)fetchTrackingParameters
{
    //Get the location information from location manager  class
    //location object will consist of long(longitude), lat(latitude), sp(spped)
    //hacc(horizontal accuracy), vacc(vertical accuracy), alt(altitude), ts(timestamp)
    if( geoLocation )
    {
        self.location = [geoLocation getCurrentLocation];
    }
    else
    {
        CLLocationCoordinate2D cord;
        cord.latitude = -1.0;
        cord.longitude = -1.0;
        location = [[CLLocation alloc] initWithCoordinate:cord altitude:-1.0 horizontalAccuracy:-1.0 verticalAccuracy:-1.0 timestamp:nil];
    }
    
    //mcn(carrier) get the carrier information of the device
    CTTelephonyNetworkInfo *netinfo = [[CTTelephonyNetworkInfo alloc] init];
    CTCarrier *car = [netinfo subscriberCellularProvider];
    self.mcn = [stringUtility checkforNullString:car.carrierName];
    
    
    //Calculating the time zone offset i.e  tzo(time zone offset)
    self.tzo = [[NSTimeZone localTimeZone] secondsFromGMT] / kSecondsValue ;
    
    self.ts = [stringUtility dateToStringFormat:[NSDate date]];
    
    // if isReachable is true that means application is in online mode
    self.online = [[RNetworkManager sharedManager] isReachable];
    
    self.mnetw = [[RNetworkManager sharedManager] networkType];
}

/*!
 @function		checkForBufferedNonBufferedAndPerformAction:
 @discussion	Responsible for checking if user is in online or offline and also look for buffered mde or non-buffered mode 
 @param			formatted string of type NSString 
 @result		nil
 */
-(void)checkForBufferedNonBufferedAndPerformAction:(NSString *)formattedJSONString
{
    if(self.online) 
    {
        // Check if user has perferred buffered mode or non-buffered mode
        //if non-buffered mode, form the URL string and send it over the network
        if(self.bufferMode == FALSE)
        {
            [self initiateConnectionWithRequestString:formattedJSONString withCompression:FALSE];
        }
    }
}

- (NSString *)getPriceValue
{
    return self.price;
}

-(void)dealloc
{
    [[RNetworkManager sharedManager] stopNotifier];
    self.genre = nil;
    self.location = nil;
    self.referer= nil;
    self.goal = nil;
    self.pageName  = nil;
    self.contentLanguage = nil;
    self.searchQuery = nil;
    self.currencyCode = nil;
    self.campaignCode = nil;
    self.requestResult = nil;
    self.affiliateId = nil;
    self.ts = nil;
    self.ltm = nil;
    self.cks = nil;
    self.ckp = nil;   
    self.cpkg = nil; 
    self.ua = nil;
    self.mcn = nil;
    self.price = nil;
    self.customParamerters = nil;
    stringUtility = nil;
    deviceInformation = nil;
    geoLocation = nil;
    [self resetItemParams];
}

@end
