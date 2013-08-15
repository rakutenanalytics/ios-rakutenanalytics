/*
 Copyright: Copyright (C) 2012 Rakuten, Inc.  All Rights Reserved.
 
 
 File Name:  RACommons.h
 
 Description: Used for defined for various localized strings variables and also string constants
 
 Author: Mandar Kadam
 
 Created: 30th-April-2012 
 
 Changed: 
 
 Version: 1.0
 
 *
 */
#ifdef __OBJC__
#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#endif

#import <CoreTelephony/CTCarrier.h>
#import <CoreTelephony/CTTelephonyNetworkInfo.h>

#import "RUtilLogger.h"
#import "RStringUtility.h"

#import "RUtil+NSData+Compression.h"
#import "RUtil+NSData+Base64EncDec.h"
#import "RUtil+NSString+EncDec.h"

//Key value range constants
#define kMaxCustomParameterValueLength      15
#define kMaxCustomParameterKeyLength        20

//Location key names
#define kLongitude                          @"long"
#define kLatitude                           @"lat"
#define kSpeed                              @"speed"
#define kHorizontalAccuracy                 @"hacc"
#define kVerticalAccuracy                   @"vacc"
#define kAltitude                           @"alt"
#define kLocationTimeStamp                  @"tms"

//All the track parameters key names
#define kVersion                            @"ver"
#define kAccountIdentifier                  @"acc"
#define kApplicationIdentifier              @"aid"
#define kLocation                           @"loc"
#define kScriptStartTime                    @"ltm"
#define kTimeZoneOffset                     @"tzo"
#define kResolution                         @"res"
#define kSessionCookie                      @"cks"
#define kPersisitentCookie                  @"ckp"
#define kUserAgent                          @"ua"
#define kOnline                             @"online"
#define kTimeStamp                          @"ts"
#define kContentLanguage                    @"cntln"
#define kReferrer                           @"ref"
#define kGoalID                             @"gol"
#define kPageName                           @"pgn"
#define kSearchQuery                        @"sq"
#define kCheckOut                           @"chkout"
#define kPrice                              @"price"
#define kCurrencyCode                       @"cycode"
#define kCheckpoint                         @"chkpt"
#define kCampaignCode                       @"cc"
#define kAffilaiteID                        @"afid"
#define kRequestResult                      @"reqc"
#define kNavigationTime                     @"mnavtime"
#define kBattery                            @"mbat"
#define kOSVersion                          @"mos"
#define kOrientation                        @"mori"
#define kNetworkType                        @"mnetw"
#define kCarrierName                        @"mcn"
#define kItemVectorString                   @"itemsvector"
#define kPowerStatus                        @"powerstatus"
#define kDeviceLanguage                     @"dln"
#define kGenre                              @"genre"

//Vector key strings
#define kItemVectorKey                      @"item"
#define kPriceVectorKey                     @"price"
#define kNumberOfItemsVectorKey             @"num_items"

//Key for Custom parameter
#define kCustomParameterKey                 @"cp"

//Connection time out
#define kConnectionTimeOut                  30
// Bundle version
#define kCFBundleVersion                    @"CFBundleVersion"

#define kRakutenServiceURL                  @"https://rat.rd.rakuten.co.jp/rat.pl"

//Licensing description for JSON.
#define kJSON                       @"JSON"
#define kJSONVersion                 @""
#define kJSONLicense                 @"/* Rakuten Analytics Component uses JSON library\n\nCopyright (C) 2009 Stig Brautaset. All rights reserved.\n\nRedistribution and use in source and binary forms, with or without\nmodification, are permitted provided that the following conditions are met:\n\n* Redistributions of source code must retain the above copyright notice, this\nlist of conditions and the following disclaimer.\n\n* Redistributions in binary form must reproduce the above copyright notice,\nthis list of conditions and the following disclaimer in the documentation\nand/or other materials provided with the distribution.\n\n* Neither the name of the author nor the names of its contributors may be used\nto endorse or promote products derived from this software without specific\nprior written permission.\nTHIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS \"AS IS\"\nAND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE\nIMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE\nDISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE\nFOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL\nDAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR\n         SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER\nCAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,\nOR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE\nOF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.\n*/"





