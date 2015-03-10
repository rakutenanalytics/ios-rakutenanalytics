/*
 * © Rakuten, Inc.
 * authors: "Rakuten Mobile SDK Team | SDTD" <prj-rmsdk@mail.rakuten.com>
 */
@import Foundation;

#import <RakutenAPIs/RakutenAPIsDefines.h>

#ifndef DOXYGEN
    #if DEBUG
        #define RSDKAnalyticsDebugLog(...) NSLog(@"[RMSDK] Analytics: %@", ([NSString stringWithFormat:__VA_ARGS__]))
    #else
        #define RSDKAnalyticsDebugLog(...) do { } while(0)
    #endif
#endif
