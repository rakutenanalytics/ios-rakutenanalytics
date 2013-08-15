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

#import <UIKit/UIKit.h>
#import "HTMLLinkButton.h"

@interface HTMLLinkButton(HTMLLinkButton_Drawing)

//Sets or draws the button by setting all the properties.
-(void)setup;

//Method for changing the color of link button on touch down.
-(void)changeTextColor;

//Method invoked on button's touchupinside event.
-(void)touchUpInside;
@end
