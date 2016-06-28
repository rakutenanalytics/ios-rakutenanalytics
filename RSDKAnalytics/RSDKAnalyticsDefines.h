/*
 * © Rakuten, Inc.
 * authors: "Rakuten Ecosystem Mobile" <ecosystem-mobile@mail.rakuten.com>
 */
#import <Foundation/Foundation.h>

#ifndef DOXYGEN
    #if DEBUG
        #define RSDKAnalyticsDebugLog(...) NSLog(@"[RMSDK] Analytics: %@", ([NSString stringWithFormat:__VA_ARGS__]))
    #else
        #define RSDKAnalyticsDebugLog(...) do { } while(0)
    #endif
#endif

/**
 * Exports a global. Also works if the SDK is built as a dynamic framework (iOS 8+).
 */
#ifdef __cplusplus
#define RSDKA_EXPORT extern "C" __attribute__((visibility ("default")))
#else
#define RSDKA_EXPORT extern __attribute__((visibility ("default")))
#endif