/*
 * © Rakuten, Inc.
 * authors: "Rakuten Ecosystem Mobile" <ecosystem-mobile@mail.rakuten.com>
 */
#import <Foundation/Foundation.h>

#ifndef DOXYGEN
#   if DEBUG
#       define RSDKAnalyticsDebugLog(...) NSLog(@"[RMSDK] Analytics: %@", ([NSString stringWithFormat:__VA_ARGS__]))
#   else
#       define RSDKAnalyticsDebugLog(...) do { } while(0)
#   endif
#endif

/**
 * Exports a global. Also works if the SDK is built as a dynamic framework (iOS 8+).
 */
#ifdef __cplusplus
#   define RSDKA_EXPORT extern "C" __attribute__((visibility ("default")))
#else
#   define RSDKA_EXPORT extern __attribute__((visibility ("default")))
#endif

/**
 * Support for Swift renaming.
 *
 * Before Xcode 8, swift_name() wouldn't accept dots so it was impossible to
 * create nested types from ObjC. Hence the two versions of the macro.
 */
#if __has_attribute(swift_name)
#   if __apple_build_version__ >= 8000000
#       define RSDKA_SWIFT2_NAME(t)
#       define RSDKA_SWIFT3_NAME(t) __attribute__((swift_name(#t)))
#   else
#       define RSDKA_SWIFT2_NAME(t) __attribute__((swift_name(#t)))
#       define RSDKA_SWIFT3_NAME(t)
#   endif
#else
#   define RSDKA_SWIFT2_NAME(t)
#   define RSDKA_SWIFT3_NAME(t)
#endif

/**
 * Xcode 6-compatible generic support
 */
#if __has_feature(objc_generics)
#   define RSDKA_GENERIC(...) <__VA_ARGS__>
#else
#   define RSDKA_GENERIC(...)
#endif
