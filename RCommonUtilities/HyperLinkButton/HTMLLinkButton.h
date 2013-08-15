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

#import <UIKit/UIKit.h>

extern NSUInteger const HTMLLinkButtonDefaulltButtonNormalColor;
extern NSUInteger const HTMLLinkButtonDefaulltButtonHighlightedColor;

@interface HTMLLinkButton : UIButton {
    @private
	NSString            *_buttonTitle;
	NSString            *_url;
	UIColor             *_normalColor;
	UIColor             *_highlightedColor;
	UIColor             *_currentColor;
}
@property (nonatomic, copy) NSString    *buttonTitle;
@property (nonatomic, copy) NSString    *url;
@property (nonatomic, strong) UIColor   *normalColor;
@property (nonatomic, strong) UIColor   *highlightedColor;

//Performs the fuctionality of initialising the link button with normal and highlighted color.
-(id)initWithTitle:(NSString *)title url:(NSString *)url
       normalColor:(UIColor *)normalColor
  highlightedColor:(UIColor *)highlightedColor;

//Performs the fuctionality of initialising the link button with title and url to be linked.
-(id)initWithTitle:(NSString *)title url:(NSString *)url;

//Performs the fuctionality of setting the font to link button titlelabel
-(void)setTitleFont:(UIFont *)font;
@end
