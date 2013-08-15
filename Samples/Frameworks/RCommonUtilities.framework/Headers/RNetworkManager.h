/*
 Copyright: Copyright (C) 2012 Rakuten, Inc.  All Rights Reserved.
 
 
 File Name:  RNetworkManager.h
 
 Description: This class is designed to get the network status update asynchronously instead of using a polling mechanism. 
 This class is designed as a singleton class which manages network state and behavior. This class listens to various network 
 status notifications and updates the core components accordingly. This class will maintain availability of network status 
 before making any network call  
 
 Author: Mandar Kadam
 
 Created: 5th-Jun-2012  
 
 Changed: 
 
 Version: 1.0
 
 *
 */

#import <Foundation/Foundation.h>
#import "Reachibility.h"


@interface RNetworkManager : NSObject
{
@private
    //Specifies whether network is reachable or not
    bool              reachableStatus;
    
    //Specifies the network type of application
	NetworkStatus     networkType;
    
    //Check for 
    Reachability    *internetReach;
    Reachability    *wifiReach;
}
@property(nonatomic,assign)	bool reachableStatus;
@property(nonatomic,assign)	NetworkStatus networkType;

+ (id)sharedManager;

//Returns status of reachibility as true or false
- (bool)isReachable;

//returs the network status as Wifi or WWAN
- (NetworkStatus)networkType;

//Start listening for reachability notifications on the current run loop
- (BOOL)startNotifier;
- (void)stopNotifier;

@end
