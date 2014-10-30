//
//  RSDKSupport.h
//  RSDKSupport
//
//  Created by Gatti, Alessandro | Alex | SDTD on 5/31/13.
//  Copyright (c) 2013 Rakuten Inc. All rights reserved.
//


// Modeling utilities
#import <RSDKSupport/RProperty.h>
#import <RSDKSupport/RBaseEntity.h>
#import <RSDKSupport/REntityJSONSerializer.h>
#import <RSDKSupport/NSValueTransformer+RDefaultTransformers.h>

// Networking utilities
#import <RSDKSupport/RNetworkOperation.h>
#import <RSDKSupport/RNetworkCertificateAuthenticator.h>
#import <RSDKSupport/RNetworkResponseSerializer.h>
#import <RSDKSupport/RNetworkRequestSerializer.h>
#import <RSDKSupport/RNetworkBaseClient.h>

// Categories
#import <RSDKSupport/NSValueTransformer+RBlockTransformations.h>
#import <RSDKSupport/NSData+RAExtensions.h>
#import <RSDKSupport/NSDictionary+RAExtensions.h>
#import <RSDKSupport/NSHTTPURLResponse+RAExtensions.h>
#import <RSDKSupport/NSString+RAExtensions.h>
#import <RSDKSupport/UIResponder+RErrorResponder.h>
#import <RSDKSupport/NSObject+RAccessibility.h>
#import <RSDKSupport/UIColor+RExtensions.h>

// Other utilities
#import <RSDKSupport/RLoggingHelper.h>
#import <RSDKSupport/RSDKAssert.h>
#import <RSDKSupport/RSDKError.h>


#ifdef DOXYGEN
	/**
	 * @defgroup SupportConstants Constants and enumerations
	 * @defgroup SupportTypes     Types definitions
	 * @defgroup SupportMacros    Preprocessor macros
	 */

	/**
	 * @ingroup SupportMacros
	 *
	 * Enables shorthand methods. Methods defined in the categories provided by
	 * this SDK component usually use a `r_` prefix. Defining this macro will
	 * also enable unprefixed aliases of the same methods.
	 */
	#define RSDKSupportShorthand

#endif
