/**
 Copyright: Copyright (C) 2012 Rakuten, Inc.  All Rights Reserved.
 
 
 File Name:  RLoadingView.h
 
 Description:  Draws the progress bar
 
 Author: Mandar Kadam
 
 Created:04th-Feb-2012
 
 Changed:
 
 Version: 1.0
 */

#import <UIKit/UIKit.h>
#import "RProgressBar.h"

typedef enum {
	/** Progress is shown using an UIActivityIndicatorView. This is the default. */
	ActivityIndeterminate,
	/** Progress is shown in custom format */
	ProgressDeterminate
}ProgressMode;

/**
  Displays a view containing a progress indicator and two optional labels for short messages.
 
  This class draws the view based on the input given to the constructor.
 
  This view supports four modes of operation:
  - ActivityIndeterminate - shows a UIActivityIndicatorView with labels
  - ProgressDeterminate - shows a custom progress indicator with labels
 
  All two modes can have optional labels assigned:
  - If the labelText(header label) property is set and non-empty then a label containing the provided content is placed above the
    indicator view.
  - If the the detailsLabelText property is set then another label is placed below the indicator view.
 */
@interface RLoadingView : UIView
@property(nonatomic, strong)UILabel                     *loadingHeaderLabel;
@property(nonatomic, strong)UILabel                     *loadingFooterLabel;
@property(nonatomic, strong)RProgressBar                *progressBar;
@property(nonatomic, strong)UIActivityIndicatorView     *activityIndicator;

/** Initialise the progress indicator
 
 This method performs all the basic things inorder to load the progress indicator.
 It acts as constructor for initialising the progress bar or indicator view.
 
 @param frame of type CGRect.
 @param mode of type ProgressMode.
 @param headerTitle of type NSString.
 @param footerTitle of type NSString.
 @return It returns initialised object of Progress indicator view.
 */ 
- (id)initWithFrame:(CGRect)frame
           withMode:(ProgressMode)mode
    withHeaderTitle:(NSString *)headerTitle
    withFooterTitle:(NSString *)footerTitle;

/** Setting the progress value.
 
 This method sets the maximum value of progress and the actual progress of control need to show
 with respect to maximum value.
 
 @param maxValue of type float.
 @param acquiredLimit of type float.
 @param animationDuartion of type float
 @return void. It returns nothing.
 */
- (void)setMaxProgress:(float)maxValue
      progressAcquired:(float)acquiredLimit
  andAnimationDuration:(float)duration;

/** Setting the progress bar's color attribute.
 
 This method sets the inner and outer border color of progress bar
 
 @param innerColor of type UIColor.
 @param outerBorderColor of type UIColor.
 @return void. It returns nothing.
 */
- (void)setProgressBarInnerColor:(UIColor *)innerColor
                     borderColor:(UIColor *)outerBorderColor;

/** Setting the color of activity indicator view.
 
 This method sets the the color of activity indicator view
 
 @param color of type UIColor.
 @return void. It returns nothing.
 */
- (void)setActivityColor:(UIColor *)color;
@end
