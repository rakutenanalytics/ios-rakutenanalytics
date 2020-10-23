// Core
#import <RAnalytics/RAnalyticsDefines.h>
#import <RAnalytics/RAnalyticsManager.h>
#import <RAnalytics/RAnalyticsTracker.h>
#import <RAnalytics/RAnalyticsEvent.h>
#import <RAnalytics/RAnalyticsState.h>
#import <RAnalytics/RAnalyticsSender.h>
#import <RAnalytics/RAnalyticsRpCookieFetcher.h>
#import <RAnalytics/RAnalyticsPushTrackingUtility.h>

// RAT
#if __has_include(<RAnalytics/RAnalyticsRATTracker.h>)
#import <RAnalytics/RAnalyticsRATTracker.h>
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
