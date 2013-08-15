/*
 Reference from Rakuten iPhone Ichiba application code base
 Version: 1.6
 
 //
 //  HTMLLinkButton-Private.h
 //  Rakuten
 //
 //  Created by gaku.obata on 11/11/04.
 //  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
 //
 
 */

#import "HTMLLinkButton+Drawing.h"

@implementation HTMLLinkButton(HTMLLinkButton_Drawing)

-(void)setup {
	[self setTitle:_buttonTitle forState:UIControlStateNormal];
	[self setTitle:_buttonTitle forState:UIControlStateHighlighted];
	[self setTitleColor:_normalColor forState:UIControlStateNormal];
	[self setTitleColor:_highlightedColor forState:UIControlStateHighlighted];
	[self addTarget:self action:@selector(changeTextColor) forControlEvents:UIControlEventTouchDown];
	
    [self addTarget:self action:@selector(maintainTextColor) forControlEvents:UIControlEventTouchDragExit];
    [self addTarget:self action:@selector(maintainTextColor) forControlEvents:UIControlEventTouchCancel];
    [self addTarget:self action:@selector(maintainTextColor) forControlEvents:UIControlEventTouchCancel];
}

-(void)changeTextColor{
	if (_currentColor == _normalColor){
		_currentColor = _highlightedColor;
	}
	else{
		_currentColor = _normalColor;
	}
	[self setNeedsDisplay];
}

- (void)maintainTextColor {
    _currentColor = _normalColor;
	
    [self setNeedsDisplay];
}

-(void)touchUpInside{
	[self changeTextColor];
	[[UIApplication sharedApplication] openURL:[NSURL URLWithString:_url]];
}

@end
