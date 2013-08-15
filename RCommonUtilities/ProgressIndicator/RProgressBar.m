/**
 Copyright: Copyright (C) 2012 Rakuten, Inc.  All Rights Reserved.
 
 
 File Name:  RProgressBar.m
 
 Description:  Draws the progress bar
 
 Author: Mandar Kadam
 
 Created:08th-Dec-2012
 
 Changed:
 
 Version: 1.0
 */
#import "RProgressBar.h"
#import "RUtil+UIColor+HexEncoding.h"
#import <QuartzCore/QuartzCore.h>

float const offet = 1.0f;
float const kTimerPeriod = 0.01f;
float const kAnimationDuration = 1.0f;
#define kBarHexValue                @"bf0000"

@interface RProgressBar()
{
    //keeps the amount of progress made.
    float               acquiredProgressLimit;
    
    //Updated value which increments after particular time period.
    float               updatedValue;
    
    //Checks progress bar is already filled or not.
    BOOL                isAlreadyLoaded;
    
    //Rectangular bar with black border
    UIView              *bar;
    
    //Progress or incremental value.
	float               progress;
    
    //Timer
    NSTimer             *timer;
    
    //Progress bar animation duration.
    float               progressAnimationDuration;
}
/** Load progress of progress bar
 
 Performs the functionality of loading the progress bar status
 
 @param progress count of type float.
 @return It returns nothing.
 */
- (void)setProgress:(float)newProgress;

/** Change progress of user
 
 @return it returns nothing.
 */
- (void)changeProgress;
@end

@implementation RProgressBar

- (id)initWithFrame:(CGRect)frame
//Animation duration
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        isAlreadyLoaded = NO;
               
        updatedValue = 0.0f;
        progress = 0.0f;
        progressAnimationDuration = kAnimationDuration;
        
		self.layer.borderWidth = offet;
		self.layer.borderColor = [UIColor colorWithHexString:kBarHexValue].CGColor;
        //[UIColor colorWithHexString:kBarHexValue].CGColor;
		self.clipsToBounds = YES;
		self.layer.masksToBounds = YES;
		self.backgroundColor = [UIColor clearColor];
        
		bar = [[UIView alloc] initWithFrame:CGRectMake(offet, offet, progress*self.frame.size.width, self.frame.size.height-(offet * 2))];
		bar.backgroundColor = [UIColor colorWithHexString:kBarHexValue];
		[self addSubview:bar];
    }
    return self;
}

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
  andAnimationDuration:(float)duration
{
    if (maxValue > 0)
    {
        acquiredProgressLimit = (progressValue*self.frame.size.width)/maxValue;
        progressAnimationDuration = (duration<=0.0f) ? kAnimationDuration : duration;
    }
}

/** Setting the progress bar's color attribute.
 
 This method sets the inner and outer border color of progress bar
 
 @param innerColor of type UIColor.
 @param outerBorderColor of type UIColor.
 @return void. It returns nothing.
 */
- (void)setProgressBarInnerColor:(UIColor *)innerColor
                     borderColor:(UIColor *)outerBorderColor
{
    self.layer.borderColor = outerBorderColor.CGColor;
    [bar setBackgroundColor:innerColor];
}

/** Starts the progress bar loading.
 
 This method starts the loading of progress bar.
 
 @return void. It returns nothing.
 */
- (void)startLoading
{
    if( !timer )
    {
        timer = [NSTimer scheduledTimerWithTimeInterval:kTimerPeriod
                                                 target:self
                                               selector:@selector(changeProgress)
                                               userInfo:nil
                                                repeats:YES];
    }
}
/** Change progress of user
 
 @return it returns nothing.
 */
- (void)changeProgress
{
    if( updatedValue < acquiredProgressLimit)
    {
        //Draw Animation of progressBar
        updatedValue = updatedValue + (acquiredProgressLimit*kTimerPeriod)/progressAnimationDuration;
        if (isAlreadyLoaded)
        {
            updatedValue = acquiredProgressLimit;
            [timer invalidate];
            timer = nil;
        }
    }
    else
    {
        //Invalidate Timer
        isAlreadyLoaded = YES;
        [timer invalidate];
        timer = nil;
        updatedValue = acquiredProgressLimit;
    }
    [self setProgress:updatedValue];
}

/** Load progress of progress bar
 
 Performs the functionality of loading the progress bar status
 
 @param progress count of type float.
 @return It returns nothing.
 */
- (void)setProgress:(float)newProgress {
    progress = newProgress;
	bar.frame = CGRectMake(offet, 0, progress, self.frame.size.height);
}

- (void)dealloc {
    if( timer )
    {
        [timer invalidate];
        timer = nil;
    }
    [bar removeFromSuperview];
	bar = nil;
}


// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
    [bar setFrame:CGRectMake(offet, 0, progress*self.frame.size.width, self.frame.size.height-(offet * 2))];
}
@end
