//
//  RSDKAssert.h
//  RSDKSupport
//
//  Created by Gatti, Alessandro | Alex | SDTD on 5/31/13.
//  Copyright (c) 2013 Rakuten Inc. All rights reserved.
//

#ifndef RSDKASSERT

#if DEBUG

/** 
 * Triggers an assertion with the current assertion handler with the given
 * parameters.
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
 * Triggers an assertion with the current assertion handler if the given
 * predicate does not evaluate to a boolean TRUE value.
 */
#define RSDKASSERTIFNOT(predicate, ...) \
    do { \
        if (!(predicate)) { \
            RSDKALWAYSASSERT(__VA_ARGS__); \
        } \
    } while (0)

#else

/**
 * Triggers an assertion with the current assertion handler with the given
 * parameters.
 *
 * The production version of this macro does not do anything when executed.
 */
#define RSDKALWAYSASSERT(...)

/**
 * Triggers an assertion with the current assertion handler if the given
 * predicate does not evaluate to a boolean TRUE value.
 *
 * The prodution version of this macro does not do anything when executed.
 */
#define RSDKASSERTIFNOT(predicate, ...)

#endif // DEBUG

#endif // !RSDKASSERT
