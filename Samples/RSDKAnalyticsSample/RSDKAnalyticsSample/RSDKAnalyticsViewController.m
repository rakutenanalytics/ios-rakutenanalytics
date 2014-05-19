//
//  RSDKAnalyticsViewController.m
//  RSDKAnalyticsSample
//
//  Created by Julien Cayzac on 5/22/14.
//  Copyright (c) 2014 Rakuten, Inc. All rights reserved.
//

#import "RSDKAnalyticsViewController.h"
#import "RSDKAnalyticsRecordForm.h"
#import <RSDKAnalytics/RSDKAnalytics.h>
#import <FontAwesomeKit/FAKFontAwesome.h>
#import <SVProgressHUD/SVProgressHUD.h>

/////////////////////////////////////////////////////////////////

@interface RSDKAnalyticsViewController ()
@end

@implementation RSDKAnalyticsViewController

#pragma mark - UIViewController methods

- (void)viewDidLoad
{
    [super viewDidLoad];


    /*
     * Register handlers for RSDKAnalayticsManager notifications
     */

    [NSNotificationCenter.defaultCenter addObserver:self
                                           selector:@selector(willUpload:)
                                               name:RSDKAnalyticsWillUploadNotification
                                             object:nil];

    [NSNotificationCenter.defaultCenter addObserver:self
                                           selector:@selector(didUpload:)
                                               name:RSDKAnalyticsUploadSuccessNotification
                                             object:nil];

    [NSNotificationCenter.defaultCenter addObserver:self
                                           selector:@selector(failedToUpload:)
                                               name:RSDKAnalyticsUploadFailureNotification
                                             object:nil];


    /*
     * Navigation items use an icon font.
     */

    id barButtonItemAttributes = @{UITextAttributeFont: [FAKFontAwesome iconFontWithSize:UIFont.buttonFontSize * 1.5]};
    [self.navigationItem.leftBarButtonItem setTitleTextAttributes:barButtonItemAttributes forState:UIControlStateNormal];
    [self.navigationItem.rightBarButtonItem setTitleTextAttributes:barButtonItemAttributes forState:UIControlStateNormal];


    /*
     * Make a swipe to the right open the menu.
     */
    UISwipeGestureRecognizer *leftMenuSwipe = [UISwipeGestureRecognizer.alloc initWithTarget:self.navigationItem.leftBarButtonItem.target
                                                                                      action:self.navigationItem.leftBarButtonItem.action];
    leftMenuSwipe.numberOfTouchesRequired = 1;
    leftMenuSwipe.direction = UISwipeGestureRecognizerDirectionRight;
    [self.view addGestureRecognizer:leftMenuSwipe];


    /*
     * Initialize the form with default content.
     */

    [self resetForm];
}

- (void)dealloc
{
    [NSNotificationCenter.defaultCenter removeObserver:self];
}

#pragma mark - Actions

- (IBAction)resetForm
{
    self.formController.form = RSDKAnalyticsRecordForm.new;
    [self.tableView reloadData];
}

- (IBAction)spool
{
    RSDKAnalyticsRecordForm *form = self.formController.form;
    RSDKAnalyticsManager.sharedInstance.locationTrackingEnabled = form.trackLocation;

    [RSDKAnalyticsManager spoolRecord:form.record];
    [SVProgressHUD showSuccessWithStatus:@"Spooled!"];
}

#pragma mark - Notification handlers

- (void)willUpload:(NSNotification *)notification
{
    NSArray *records = notification.object;
    NSLog(@"RSDKAnalytics will upload: %@", records);

    // TODO: show pending uploads in the UI

    static UIImage *image;
    static dispatch_once_t once;
    dispatch_once(&once, ^
    {
        FAKFontAwesome *icon = [FAKFontAwesome uploadIconWithSize:62];
        [icon setAttributes:@{NSForegroundColorAttributeName: UIColor.whiteColor}];
        image = [icon imageWithSize:CGSizeMake(56, 56)];
    });

    [SVProgressHUD showImage:image
                      status:[NSString stringWithFormat:@"Uploading %lu records…", (unsigned long)records.count]];
}

- (void)didUpload:(NSNotification *)notification
{
    NSArray *records = notification.object;
    NSLog(@"RSDKAnalytics did upload: %@", records);

    // TODO: show completed uploads in the UI

    [SVProgressHUD showSuccessWithStatus:[NSString stringWithFormat:@"Uploaded %lu records!", (unsigned long)records.count]];
}

- (void)failedToUpload:(NSNotification *)notification
{
    NSArray *records = notification.object;
    NSError *error = notification.userInfo[NSUnderlyingErrorKey];
    NSLog(@"RSDKAnalytics failed to upload: %@, reason = %@", records, error);

    // TODO: show failed uploads in the UI

    [SVProgressHUD showErrorWithStatus:[NSString stringWithFormat:@"Failed to upload %lu records:\n%@",
                                        (unsigned long)records.count,
                                        error.localizedDescription]];
}

@end

