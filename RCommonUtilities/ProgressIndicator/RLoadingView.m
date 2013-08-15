/**
 Copyright: Copyright (C) 2012 Rakuten, Inc.  All Rights Reserved.
 
 
 File Name:  RLoadingView
 
 Description:  Draws the progress bar
 
 Author: Mandar Kadam
 
 Created:04th-Feb-2012
 
 Changed:
 
 Version: 1.0
 */

#import "RLoadingView.h"
#import <QuartzCore/QuartzCore.h>

CGFloat const heightFactorForProgress = 0.15f;
CGFloat const heightFactorForLabels = 0.25f;
CGFloat const widthFactor = 0.85f;
CGFloat const offset = 5.0f;
CGFloat const defaultMaxValue = 100.0f;

@interface RLoadingView()
{
    float           controlHeight;
    float           controlWidth;
    ProgressMode    modeType;
}
//Checks the mode and load the progress indicator accordingly.
- (void)checkModeAndLoad;

//Gets the rect or frame of progress indicator view
- (void)setFrameOfControls;

//Sets the title and font of header and footer label.
- (void)setPropertiesToLabelWithText:(NSString *)title
                                font:(UIFont *)font
                            andLabel:(UILabel *)label;

//This method removes the progress indicator from the view.
- (void)dismiss;
@end

@implementation RLoadingView
@synthesize loadingHeaderLabel;
@synthesize loadingFooterLabel;
@synthesize progressBar = _progressBar;
@synthesize activityIndicator = _activityIndicator;

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
    withFooterTitle:(NSString *)footerTitle
{
    self = [super initWithFrame:frame];
    if (self) {
        [self setBackgroundColor:[UIColor clearColor]];
        // Initialization code
        loadingHeaderLabel = nil;
        loadingFooterLabel = nil;
        
        modeType = mode;
        [self checkModeAndLoad];
        
        UIFont *font = [UIFont fontWithName:@"Helvetica" size:12];
        
        if( headerTitle )
        {
            //Setting the frame of header title.
            loadingHeaderLabel = [[UILabel alloc] init];
            [self setPropertiesToLabelWithText:headerTitle
                                          font:font
                                      andLabel:loadingHeaderLabel];
            [self addSubview:loadingHeaderLabel];
            [loadingHeaderLabel setBackgroundColor:[UIColor clearColor]];
        }
        
        if( footerTitle )
        {
            //Setting the frame of footer title.
            loadingFooterLabel = [[UILabel alloc] init];
            [self setPropertiesToLabelWithText:footerTitle
                                          font:font
                                      andLabel:loadingFooterLabel];
            [self addSubview:loadingFooterLabel];
            [loadingFooterLabel setBackgroundColor:[UIColor clearColor]];
        }
    }
    return self;
}

/** Loads activity indicator view or progress bar.
 
 This method initilaize the activity indicator view or progress bar based on user input.
 
 @param mode of type ProgressMode.
 @return void. It returns nothing.
 */
- (void)checkModeAndLoad
{
    if( modeType == ActivityIndeterminate)
    {
        self.activityIndicator = [[UIActivityIndicatorView alloc]
										 initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
		[self.activityIndicator startAnimating];
        [self.activityIndicator setFrame:CGRectZero];
		[self addSubview:self.activityIndicator];
    }
    else
    {        
        //Setting the frame for Progress bar
        CGRect frame = [self getFrameOfProgressBar];
        self.progressBar = [[RProgressBar alloc] initWithFrame:frame];
        [self addSubview:self.progressBar];
    }
    [self setBackgroundColor:[UIColor clearColor]];
}

/** Setting the color of activity indicator view.
 
 This method sets the the color of activity indicator view
 
 @param color of type UIColor.
 @return void. It returns nothing.
 */
- (void)setActivityColor:(UIColor *)color
{
    [self.activityIndicator setColor:color];
}

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
  andAnimationDuration:(float)duration
{
    if( maxValue <= 0 )
    {
        maxValue = defaultMaxValue;
    }
    [self.progressBar setMaxProgress:maxValue
                    acquiredprogress:acquiredLimit
                andAnimationDuration:duration];
    [self.progressBar startLoading];
}

/** Setting the progress bar's color attribute.
 
 This method sets the inner and outer border color of progress bar
 
 @param innerColor of type UIColor.
 @param outerBorderColor of type UIColor.
 @return void. It returns nothing.
 */
- (void)setProgressBarInnerColor:(UIColor *)innerColor
                     borderColor:(UIColor *)outerBorderColor;
{
    [self.progressBar setProgressBarInnerColor:innerColor
                                   borderColor:outerBorderColor];
}

- (float)getHeightForLabel:(UILabel *)label
{
    //Calculate the expected size based on the font and linebreak mode of your label
    // FLT_MAX here simply means no constraint in height
    CGSize maximumLabelSize = CGSizeMake((self.frame.size.width * widthFactor), FLT_MAX);

    CGSize expectedLabelSize = [label.text sizeWithFont:label.font constrainedToSize:maximumLabelSize lineBreakMode:label.lineBreakMode];

    //adjust the label the the new height.
    return expectedLabelSize.height;
}

/** Unloads or removes the progress indicator.
 
 This method removes the progress indicator from the view.
 
 @return void. It returns nothing.
 */
- (void)dismiss
{
    if( self.progressBar )
    {
        [self.progressBar removeFromSuperview];
        self.progressBar = nil;
    }
    if( self.activityIndicator )
    {
        [self.activityIndicator stopAnimating];
        [self.activityIndicator removeFromSuperview];
        self.activityIndicator = nil;
    }
    if( loadingFooterLabel )
    {
        [loadingFooterLabel removeFromSuperview];
        loadingFooterLabel = nil;
    }
    if( loadingHeaderLabel )
    {
        [loadingHeaderLabel removeFromSuperview];
        loadingHeaderLabel = nil;
    }
}

- (CGRect)getFrameOfProgressBar
{
    UIView *referenceView = nil;
    
    if( modeType == ActivityIndeterminate )
        referenceView = self.activityIndicator;
    else
        referenceView = self.progressBar;
    
    
    float heightOfProgressbar = (self.frame.size.height * heightFactorForProgress);
    float centerY = self.frame.size.height/2;
    float widthOfProgressbar = self.frame.size.width * widthFactor;
    
    float progressY = 0.0f;
    progressY = centerY - (heightOfProgressbar/2);
    if( loadingHeaderLabel && !loadingFooterLabel )
    {
        progressY = centerY + offset;
    }
    
    if( !loadingHeaderLabel && loadingFooterLabel )
    {
        progressY = centerY - offset;
    }
    
    float progressX = (self.frame.size.width - widthOfProgressbar)/2;
      
    return CGRectMake(progressX, progressY, widthOfProgressbar, heightOfProgressbar);
}

- (void)setFrameOfControls
{
    UIView *referenceView = nil;
    
    if( modeType == ActivityIndeterminate )
        referenceView = self.activityIndicator;
    else
        referenceView = self.progressBar;

    CGRect frame = [self getFrameOfProgressBar];
    [referenceView setFrame:frame];
    
    if( loadingHeaderLabel )
    {
        float heightOfHeaderLabel = [self getHeightForLabel:loadingHeaderLabel];
        [loadingHeaderLabel setFrame:CGRectMake(frame.origin.x, (frame.origin.y - offset - heightOfHeaderLabel), frame.size.width, heightOfHeaderLabel)];
    }
    
    if( loadingFooterLabel )
    {
        float heightOfFooterLabel = [self getHeightForLabel:loadingFooterLabel];
        [loadingFooterLabel setFrame:CGRectMake(frame.origin.x, (frame.origin.y + frame.size.height + offset), frame.size.width, heightOfFooterLabel)];
    }
}

// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    [self setBackgroundColor:[UIColor clearColor]];
    // Drawing code
    //Setting the frame of the progress bar
    [self setFrameOfControls];
}


- (void)setPropertiesToLabelWithText:(NSString *)title
                                font:(UIFont *)font
                            andLabel:(UILabel *)label
{
    [label setText:title];
    [label setTextAlignment:NSTextAlignmentCenter];
    [label setFont:font];
    [label setNumberOfLines:1];
    [label setLineBreakMode:NSLineBreakByWordWrapping];
    [label setBackgroundColor:[UIColor clearColor]];
}

- (void)dealloc
{
    [self dismiss];
}
@end
