/*
 * © Rakuten, Inc.
 * authors: "SDK Team | SDTD" <prj-rmsdk@mail.rakuten.com>
 */
@import Foundation;

#import <RakutenAPIs/RakutenAPIsDefines.h>

#ifndef DOXYGEN
    #if DEBUG
        #define RSDKAnalyticsDebugLog(...) NSLog(__VA_ARGS__)
    #else
        #define RSDKAnalyticsDebugLog(...) do { } while(0)
    #endif
#endif
