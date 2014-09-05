//
//  RSDKAssert.h
//  RSDKSupport
//
//  Created by Gatti, Alessandro | Alex | SDTD on 5/31/13.
//  Copyright (c) 2013 Rakuten Inc. All rights reserved.
//

@import Foundation;

#if DEBUG || DOXYGEN

    /**
     * @ingroup SupportMacros
     *
     * Triggers an assertion with a message string, if `DEBUG` is defined.
     *
     * @param ... Format string followed by the parameters it might require.
     */
    #define RSDKALWAYSASSERT(...) \
        do { \
            [[NSAssertionHandler currentHandler] \
                handleFailureInFunction:[NSString stringWithCString:__PRETTY_FUNCTION__ \
                encoding:NSUTF8StringEncoding] \
                file:[NSString stringWithCString:__FILE__ encoding:NSUTF8StringEncoding] \
                lineNumber:__LINE__ \
                description:__VA_ARGS__]; \
        } while (0)

    /**
     * @ingroup SupportMacros
     *
     * Triggers an assertion with a message string if the given condition is not true
     * and `DEBUG` was defined.
     *
     * @param condition Contition to evaluate.
     * @param ...       Format string followed by the parameters it might require.
     */
    #define RSDKASSERTIFNOT(condition, ...) \
        do { \
            if (!(condition)) { \
                RSDKALWAYSASSERT(__VA_ARGS__); \
            } \
        } while (0)

#else
    #define RSDKALWAYSASSERT(...)
    #define RSDKASSERTIFNOT(predicate, ...)
#endif
