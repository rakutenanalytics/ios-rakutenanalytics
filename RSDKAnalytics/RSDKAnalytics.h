/*
 * © Rakuten, Inc.
 * authors: "Rakuten Mobile SDK Team | SDTD" <prj-rmsdk@mail.rakuten.com>
 */
#import <RSDKAnalytics/RSDKAnalyticsDefines.h>
#import <RSDKAnalytics/RSDKAnalyticsManager.h>
#import <RSDKAnalytics/RSDKAnalyticsRecord.h>
#import <RSDKAnalytics/RSDKAnalyticsItem.h>

/// @name Environment

/**
 * Version of this library.
 *
 * @note This value is sent as the **ver** (`VERSION`) RAT parameter
 * and is used as a protocol version by the server-side parsers. See the
 * [RAT Generic IDL](https://git.dev.rakuten.com/projects/RG/repos/rg/browse/ratGeneric.idl)
 * for more information.
 *
 * @ingroup AnalyticsConstants
 * @since 2.0.0
 */
RMSDK_EXPORT NSString* const RSDKAnalyticsVersion;

#ifdef DOXYGEN
    /**
     * @defgroup AnalyticsConstants Constants and enumerations
     */
#endif

