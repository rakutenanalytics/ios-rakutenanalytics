/*
 
 Reference from Rakuten iPhone Ichiba application code base
 Version: 1.6
 
 //
 //  HTMLLinkButton.h
 //  Rakuten
 //
 //  Created by gaku.obata on 11/11/04.
 //  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
 //
 
 */

#import "HTMLLinkButton.h"
#import "HTMLLinkButton+Drawing.h"

CGFloat const HTMLLinkButtonSize = 15.0;
NSString *const kFontName = @"Helvetica";

@interface HTMLLinkButton()
{
    UIFont  *fontValue;
}
@property(nonatomic, strong)UIFont *fontValue;
@end

@implementation HTMLLinkButton
@synthesize buttonTitle = _buttonTitle;
@synthesize normalColor = _normalColor;
@synthesize highlightedColor = _highlightedColor;
@synthesize url = _url;
@synthesize fontValue;

/*
 @function      initWithTitle: url: normalColor: highlightedColor:
 @description   Initialising the link button.
 @param1        button title of type string
 @param2        url to be opened on clicking the HTML link button
 @param3        normal color of type UIColor
 @param4        highlighted color of type UIColor
 @return        initialised object of link button.
 */
-(id)initWithTitle:(NSString *)title
               url:(NSString *)url
       normalColor:(UIColor *)normalColor
  highlightedColor:(UIColor *) highlightedColor{
	if (self = [super init]){
		self.buttonTitle = title;
		self.url = url;
		self.normalColor = normalColor;
		self.highlightedColor = highlightedColor;
		_currentColor = self.normalColor;
        self.fontValue = [UIFont fontWithName:kFontName size:HTMLLinkButtonSize];
		[self setup];
	}
	return self;
}

/*
 @function      initWithTitle: url: 
 @description   Initialising the link button.
 @param1        button title of type string
 @param2        url to be opened on clicking the HTML link button
 @return        initialised object of link button.
 */
-(id)initWithTitle:(NSString *)title url:(NSString *)url{
	UIColor *normalColor =
    [UIColor colorWithRed:221.0/255.0 green:15.0/255.0 blue:0.0/255.0 alpha:1.0];
	UIColor *highlightedColor = [UIColor darkGrayColor];
	
    return [self initWithTitle:title
                           url:url normalColor:normalColor
              highlightedColor:highlightedColor];
}

/*
 @function      drawRect
 @description   drawing the button by underlining it, inorder t depict it as hyperlink.
 @param1        rect of type CGRect defines the 
 @return        nil
 */
- (void)drawRect:(CGRect)rect {
    self.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
    //CGFloat w = rect.size.width;
	CGFloat h = rect.size.height;
	CGFloat titleWidth = [_buttonTitle sizeWithFont:self.fontValue].width;
	CGFloat titleHeight = [_buttonTitle sizeWithFont:self.fontValue].height;
	CGFloat descender = self.titleLabel.font.descender;
	CGFloat startX = 0.0f;
	CGFloat startY = (h + titleHeight) / 2.0 + descender;
	CGFloat endX = startX + titleWidth;
	CGFloat endY = startY;
    
	CGContextRef context = UIGraphicsGetCurrentContext();
	CGContextSetStrokeColorWithColor(context,
                                     _currentColor.CGColor);
	CGContextMoveToPoint(context, startX, startY);
	CGContextAddLineToPoint(context, endX, endY);
	CGContextStrokePath(context);
}

- (void)dealloc
{
	self.buttonTitle = nil;
    self.url = nil;
    self.normalColor = nil;
    self.highlightedColor = nil;
}

#pragma mark -
#pragma mark Setters

//Override
-(void)setFrame:(CGRect)frame{
	[super setFrame:frame];
	[self setNeedsDisplay];
}

-(void)setTitleFont:(UIFont *)font{
    self.fontValue = font;
	[self setNeedsDisplay];
}

//Override
-(void)setNormalColor:(UIColor *)color{
	if (_normalColor != color){
		_normalColor = color;
		[self setNeedsDisplay];
	}
}

//Override
-(void)setHighlightedColor:(UIColor *)color{
	if (_highlightedColor != color){
		_highlightedColor = color;
		[self setNeedsDisplay];
	}
}
@end

