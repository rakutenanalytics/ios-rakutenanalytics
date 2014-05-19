//
//  RSDKAnalyticsViewController.h
//  RSDKAnalyticsSample
//
//  Created by Julien Cayzac on 5/22/14.
//  Copyright (c) 2014 Rakuten, Inc. All rights reserved.
//

#import <FXForms/FXForms.h>

/////////////////////////////////////////////////////////////////

@interface RSDKAnalyticsViewController : FXFormViewController

/*
 * Reset the form.
 */
- (IBAction)resetForm;

/*
 * Build a new RSDKAnalyticsRecord from the values currently set
 * in the form, then spool it.
 */
- (IBAction)spool;
@end

