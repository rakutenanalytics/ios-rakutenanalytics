/*
 * © Rakuten, Inc.
 * authors: "Rakuten Mobile SDK Team | SDTD" <prj-rmsdk@mail.rakuten.com>
 */
#import <RSDKAnalytics/RSDKAnalytics.h>

#ifndef RMSDK_ANALYTICS_VERSION
#warning "RMSDK_ANALYTICS_VERSION not defined. Code that depends on it might fail."
#define RMSDK_ANALYTICS_VERSION 0.0.0
#endif

/* RMSDK_EXPORT */ const NSString* const RSDKAnalyticsVersion = @ RMSDK_EXPAND_AND_QUOTE(RMSDK_ANALYTICS_VERSION);

RMSDK_REGISTER_MODULE_VERSION(RSDKAnalytics, RMSDK_ANALYTICS_VERSION);
