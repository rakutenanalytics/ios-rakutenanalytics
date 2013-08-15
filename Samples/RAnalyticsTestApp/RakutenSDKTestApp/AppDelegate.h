/*
 Copyright: Copyright (C) 2012 Rakuten, Inc.  All Rights Reserved.
 
 
 File Name:  AppDelegate.h
 
 Description:  
 
 Author: Mandar Kadam
 
 Created: 15th-May-2012
 
 Changed:
 
 Version: 1.0
 
 */

#import <UIKit/UIKit.h>

@class HomeViewController;

@interface AppDelegate : UIResponder <UIApplicationDelegate>
{
    UINavigationController *navigationController;
}

@property (strong, nonatomic) UIWindow *window;


@end
