/*
 Copyright: Copyright (C) 2012 Rakuten, Inc.  All Rights Reserved.
 
 
 File Name:  ViewController.m
 
 Description:
 
 Author: Mandar Kadam
 
 Created: 15th-May-2012
 
 Changed:
 
 Version: 1.0
 
 */

#import "HomeViewController.h"
#import "RCommonUtilities/RDeviceInformation.h"

@implementation HomeViewController
@synthesize checkout;
@synthesize accountID;
@synthesize serviceID;
@synthesize referrer;
@synthesize goalID;
@synthesize pageName;
@synthesize contentLang;
@synthesize searchQuery;
@synthesize priceIntegral, priceDecimal;
@synthesize currencycode;
@synthesize checkpoint;
@synthesize campaigncode;
@synthesize affiliateID;
@synthesize scrollView;
@synthesize reqResultInput, throttleDelay, navTime, cp1, cp1Value, cp2, cp2Value, cp3, cp3Value;
@synthesize itemValue, wholePrice, decimalCount, itemCount;
@synthesize buffermodeControl, onoffLocation;
@synthesize genreValue;

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Release any cached data, images, etc that aren't in use.
}

- (void)viewDidLoad
{
    [super viewDidLoad];

	// Do any additional setup after loading the view, typically from a nib.
    [scrollView setContentSize:CGSizeMake(320, 3000)];
    
    buffermodeControl.selectedSegmentIndex = 0;
    [buffermodeControl addTarget:self
                         action:@selector(bmodeChanged:)
               forControlEvents:UIControlEventValueChanged];
    
   
    onoffLocation.selectedSegmentIndex = 1;
    [onoffLocation addTarget:self
                         action:@selector(enableDisableLocation:)
               forControlEvents:UIControlEventValueChanged];
        
    raRakutenAnalytics = [RATrackingLib getInstance] ;
}

- (void)enableDisableLocation:(id)sender
{
    raRakutenAnalytics = [RATrackingLib getInstance:onoffLocation.selectedSegmentIndex];
}
-(void)bmodeChanged:(id)sender
{
    raRakutenAnalytics.bufferMode = buffermodeControl.selectedSegmentIndex;
}

-(IBAction)showLicenses:(id)sender
{
    RLicenseInformation *licenseInfo = [[RLicenseInformation alloc] init];
    
    [raRakutenAnalytics registerForLicensing:licenseInfo];
    
    RLicense *ref = [licenseInfo getLicenseInformationForIndex:0];
    NSLog(@"\n\nProduct name: %@\nProduct version: %@\nProduct license: %@\n", [ref getProductName], [ref getProductVersion], [ref getProductLicense]);
}

-(IBAction)trackPressed:(id)sender
{
    NSLog(@"accountID: %lld", [accountID.text longLongValue] );
    raRakutenAnalytics.accountId =  [accountID.text longLongValue];
    //NSLog(@"int value:%lld", raRakutenAnalytics.acc);
    raRakutenAnalytics.applicationId = [serviceID.text longLongValue];
    raRakutenAnalytics.referer = referrer.text;
    raRakutenAnalytics.goal = goalID.text;
    raRakutenAnalytics.pageName = pageName.text;
    raRakutenAnalytics.checkOut = [checkout.text intValue];
    raRakutenAnalytics.contentLanguage = contentLang.text;
    raRakutenAnalytics.searchQuery = searchQuery.text;
    raRakutenAnalytics.currencyCode = currencycode.text;
    raRakutenAnalytics.checkPoint = [checkpoint.text intValue];
    raRakutenAnalytics.campaignCode=campaigncode.text;
    raRakutenAnalytics.affiliateId  = affiliateID.text;
    raRakutenAnalytics.thDelay = [throttleDelay.text intValue];;
    raRakutenAnalytics.requestResult = reqResultInput.text;
    raRakutenAnalytics.bufferMode = buffermodeControl.selectedSegmentIndex;
    raRakutenAnalytics.pageLoadTime = [navTime.text intValue];
    [raRakutenAnalytics setPriceWithValue:[priceIntegral.text longLongValue] andDecimal:[priceDecimal.text intValue]];
    raRakutenAnalytics.genre = genreValue.text;
    
    [raRakutenAnalytics track];
    
    //Check roaming
    RDeviceInformation *deviceInfo = [[RDeviceInformation alloc] init];
    [deviceInfo isRoaming];
    deviceInfo = nil;
}
     
-(IBAction)clearTrackParameters:(id)sender
{
    [raRakutenAnalytics clearTrackParameters];
}

-(IBAction)trackPressedWithParameters:(id)sender
{
    NSMutableDictionary * trackData = [[NSMutableDictionary alloc] init]; 
    [trackData setObject:cp1Value.text forKey:cp1.text];
    [trackData setObject:cp2Value.text forKey:cp2.text];
    [trackData setObject:cp3Value.text forKey:cp3.text];
    raRakutenAnalytics.accountId = [accountID.text longLongValue];
    raRakutenAnalytics.applicationId = [serviceID.text longLongValue];
    raRakutenAnalytics.referer = referrer.text;
    raRakutenAnalytics.requestResult = reqResultInput.text;
    raRakutenAnalytics.goal = goalID.text;
    raRakutenAnalytics.pageName = pageName.text;
    raRakutenAnalytics.checkOut = [checkout.text intValue];
    raRakutenAnalytics.contentLanguage = contentLang.text;
    raRakutenAnalytics.searchQuery = searchQuery.text;
    raRakutenAnalytics.currencyCode = currencycode.text;
    raRakutenAnalytics.checkPoint = [checkpoint.text intValue];
    raRakutenAnalytics.campaignCode= campaigncode.text;
    raRakutenAnalytics.affiliateId  = affiliateID.text;
    raRakutenAnalytics.thDelay = [throttleDelay.text intValue];
    raRakutenAnalytics.bufferMode = buffermodeControl.selectedSegmentIndex;
    raRakutenAnalytics.pageLoadTime = [navTime.text intValue];
    [raRakutenAnalytics setPriceWithValue:[priceIntegral.text longLongValue] andDecimal:[priceDecimal.text intValue]];
     raRakutenAnalytics.genre = genreValue.text;
        
    [raRakutenAnalytics track:trackData];
}

- (IBAction)addVector:(id)sender
{
    [raRakutenAnalytics setItemParams:itemValue.text
                        numberOfItems:[itemCount.text intValue]
                       withWholePrice:[wholePrice.text longLongValue]
                      andDecimalCount:[decimalCount.text intValue]];
}

- (void)viewDidUnload
{
    accountID = nil;
    serviceID = nil;
    referrer = nil;
    goalID = nil;
    pageName = nil;
    checkout = nil;
    contentLang = nil;
    searchQuery = nil;
    priceIntegral = nil;
    priceDecimal = nil;
    currencycode = nil;
    checkpoint = nil;
    campaigncode = nil;
    affiliateID = nil;
    scrollView = nil;
    reqResultInput = nil;
    throttleDelay = nil;
    navTime = nil;
    cp1 = nil;
    cp1Value = nil;
    cp2 = nil;
    cp2Value = nil;
    cp3 = nil;
    cp3Value = nil;
    itemValue = nil;
    wholePrice = nil;
    decimalCount = nil;
    itemCount = nil;
    genreValue = nil;

    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
	[super viewWillDisappear:animated];
}

- (void)viewDidDisappear:(BOOL)animated
{
	[super viewDidDisappear:animated];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
}

@end
