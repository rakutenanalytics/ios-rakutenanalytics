@import Foundation;

NS_ASSUME_NONNULL_BEGIN

/*
 * Exports a global, setting the proper visibility attributes so that it does not
 * get stripped at linktime.
 */
#ifdef __cplusplus
#define RSDKA_EXPORT extern "C" __attribute__((visibility ("default")))
#else
#define RSDKA_EXPORT extern __attribute__((visibility ("default")))
#endif

NS_ASSUME_NONNULL_END

/// @internal
RSDKA_EXPORT const NSString* const RAnalyticsVersion;

#ifdef DOXYGEN
/**
 * @defgroup AnalyticsConstants Constants and enumerations
 * @defgroup AnalyticsCore      Core Concepts
 * @defgroup AnalyticsEvents    Standard Events
 */
#endif
