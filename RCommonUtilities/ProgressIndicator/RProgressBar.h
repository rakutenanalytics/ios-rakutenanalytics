/**
 Copyright: Copyright (C) 2012 Rakuten, Inc.  All Rights Reserved.
 
 
 File Name:  RProgressBar.h
 
 Description:  Draws the progress bar 
 
 Author: Mandar Kadam
 
 Created:08th-Dec-2012
 
 Changed:
 
 Version: 1.0
 */
#import <UIKit/UIKit.h>

@interface RProgressBar : UIView
/** Setting the progress value.
 
 This method sets the maximum value of progress and the actual progress of control need to show
 with respect to maximum value.
 
 @param maxValue of type float.
 @param progress of type float.
 @param duration of type float.
 @return void. It returns nothing.
 */
- (void)setMaxProgress:(float)maxValue
      acquiredprogress:(float)progressValue
  andAnimationDuration:(float)duration;

/** Setting the progress bar's color attribute.
 
 This method sets the inner and outer border color of progress bar
 
 @param innerColor of type UIColor.
 @param outerBorderColor of type UIColor.
 @return void. It returns nothing.
 */
- (void)setProgressBarInnerColor:(UIColor *)innerColor
                     borderColor:(UIColor *)outerBorderColor;

/** Starts the progress bar loading.
 
 This method starts the loading of progress bar.
 
 @return void. It returns nothing.
 */
- (void)startLoading;

@end
