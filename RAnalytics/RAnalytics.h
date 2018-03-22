// Core
#import <RAnalytics/RAnalyticsDefines.h>
#import <RAnalytics/RAnalyticsManager.h>
#import <RAnalytics/RAnalyticsTracker.h>
#import <RAnalytics/RAnalyticsEvent.h>
#import <RAnalytics/RAnalyticsState.h>
#import <RAnalytics/RAnalyticsSender.h>

// RAT
#if __has_include(<RAnalytics/RATTracker.h>)
#import <RAnalytics/RATTracker.h>
#endif

/// @internal
RSDKA_EXPORT const NSString* const RAnalyticsVersion;

#ifdef DOXYGEN
/**
 * @defgroup AnalyticsConstants Constants and enumerations
 * @defgroup AnalyticsCore      Core Concepts
 * @defgroup AnalyticsEvents    Standard Events
 */
#endif
