//
//  RLoggingHelper.h
//  RSDKSupport
//
//  Created by Zachary Radke on 11/19/13.
//  Copyright (c) 2013 Rakuten Inc. All rights reserved.
//

@import Foundation;

#ifndef RDebugLog
    #if DEBUG || DOXYGEN
        /**
         * @ingroup SupportMacros
         *
         * When `DEBUG` is defined, send a formatted string to the current system logger,
         * otherwise does nothing.
         *
         * @param format Format string.
         * @param ...    Parameters required by the given format string.
         */
        #define RDebugLog(format, ...) NSLog((@"%s [Line %d] " format), __PRETTY_FUNCTION__, __LINE__, ##__VA_ARGS__)
    #else
        #define RDebugLog(...)
    #endif
#endif

#ifndef RAlwaysLog
    /**
     * @ingroup SupportMacros
     *
     * Send a formatted string to the current system logger, even when `DEBUG` is not defined.
     *
     * @param format Format string.
     * @param ...    Parameters required by the given format string.
     */
    #define RAlwaysLog(format, ...) NSLog((@"%s [Line %d] " format), __PRETTY_FUNCTION__, __LINE__, ##__VA_ARGS__)
#endif
