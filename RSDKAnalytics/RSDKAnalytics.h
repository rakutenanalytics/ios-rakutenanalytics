//
//  RSDKAnalytics.h
//  RSDKAnalytics
//
//  Created by Julien Cayzac on 5/19/14.
//  Copyright (c) 2014 Rakuten, Inc. All rights reserved.
//

@import Foundation;

#import "RSDKAnalyticsManager.h"
#import "RSDKAnalyticsRecord.h"


/**
 * Version of this library.
 *
 * @note This value is sent as the **ver** (`VERSION`) RAT parameter
 * and is used as a protocol version by the server-side parsers. See the
 * [RAT Generic IDL](https://git.dev.rakuten.com/projects/RG/repos/rg/browse/ratGeneric.idl)
 * for more information.
 *
 * @since 2.0.0
 */

FOUNDATION_EXTERN const NSString* const RSDKAnalyticsVersion;

