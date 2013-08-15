/*
 Copyright: Copyright (C) 2012 Rakuten, Inc.  All Rights Reserved.
 
 
 File Name:  ViewController.h
 
 Description:
 
 Author: Mandar Kadam
 
 Created: 15th-May-2012
 
 Changed:
 
 Version: 1.0
 
 */

#import <UIKit/UIKit.h>
#import "RakutenAnalytic/RATrackingLib.h"

@interface HomeViewController : UIViewController
{

     //User input textfields for various parameters
    IBOutlet UITextField *accountID;
    IBOutlet UITextField *serviceID;
    IBOutlet UITextField *referrer;
    IBOutlet UITextField *goalID;
    IBOutlet UITextField *pageName;
    IBOutlet UITextField *checkout;
    IBOutlet UITextField *contentLang;
    IBOutlet UITextField *searchQuery;
    IBOutlet UITextField *priceIntegral;
    IBOutlet UITextField *priceDecimal;
    IBOutlet UITextField *currencycode;
    IBOutlet UITextField *checkpoint;
    IBOutlet UITextField *campaigncode;
    IBOutlet UITextField *affiliateID;
    
    IBOutlet UIScrollView *scrollView;
    
    IBOutlet UITextField *reqResultInput;
    IBOutlet UITextField *throttleDelay;
    IBOutlet UITextField *navTime;
    IBOutlet UITextField *cp1;
    IBOutlet UITextField *cp1Value;
    IBOutlet UITextField *cp2;
    IBOutlet UITextField *cp2Value;
    IBOutlet UITextField *cp3;
    IBOutlet UITextField *cp3Value;
    IBOutlet UISegmentedControl *buffermodeControl;
    IBOutlet UISegmentedControl *onoffLocation;
    
    //Genre
    IBOutlet UITextField *genreValue;
    
    //Item vector
    IBOutlet UITextField *itemValue;
    IBOutlet UITextField *wholePrice;
    IBOutlet UITextField *decimalCount;
    IBOutlet UITextField *itemCount;
    
    RATrackingLib *raRakutenAnalytics;
}
@property (strong, nonatomic) IBOutlet UITextField *accountID;
@property (strong, nonatomic) IBOutlet UITextField *serviceID;
@property (strong, nonatomic) IBOutlet UITextField *referrer;
@property (strong, nonatomic) IBOutlet UITextField *goalID;
@property (strong, nonatomic) IBOutlet UITextField *pageName;
@property (strong, nonatomic) IBOutlet UITextField *checkout;
@property (strong, nonatomic) IBOutlet UITextField *contentLang;
@property (strong, nonatomic) IBOutlet UITextField *searchQuery;
@property (strong, nonatomic) IBOutlet UITextField *priceIntegral;
@property (strong, nonatomic) IBOutlet UITextField *currencycode;
@property (strong, nonatomic) IBOutlet UITextField *checkpoint;
@property (strong, nonatomic) IBOutlet UITextField *campaigncode;
@property (strong, nonatomic) IBOutlet UITextField *affiliateID;
@property (strong, nonatomic) IBOutlet UIScrollView *scrollView;
@property (strong, nonatomic) IBOutlet UITextField *priceDecimal;
@property (strong, nonatomic) IBOutlet UITextField *reqResultInput;
@property (strong, nonatomic) IBOutlet UITextField *throttleDelay;
@property (strong, nonatomic) IBOutlet UITextField *navTime;
@property (strong, nonatomic) IBOutlet UITextField *cp1;
@property (strong, nonatomic) IBOutlet UITextField *cp1Value;
@property (strong, nonatomic) IBOutlet UITextField *cp2;
@property (strong, nonatomic) IBOutlet UITextField *cp2Value;
@property (strong, nonatomic) IBOutlet UITextField *cp3;
@property (strong, nonatomic) IBOutlet UITextField *cp3Value;
@property (strong, nonatomic) IBOutlet UITextField *itemValue;
@property (strong, nonatomic) IBOutlet UITextField *wholePrice;
@property (strong, nonatomic) IBOutlet UITextField *decimalCount;
@property (strong, nonatomic) IBOutlet UITextField *itemCount;
@property (strong, nonatomic) IBOutlet UISegmentedControl *buffermodeControl;
@property (strong, nonatomic) IBOutlet UISegmentedControl *onoffLocation;
@property (strong, nonatomic) IBOutlet UITextField *genreValue;

-(IBAction)trackPressedWithParameters:(id)sender;
-(IBAction)clearTrackParameters:(id)sender;
-(IBAction)trackPressed:(id)sender;
-(IBAction)showLicenses:(id)sender;
@end
