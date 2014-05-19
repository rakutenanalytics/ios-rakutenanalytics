//
//  RLoggingHelper.h
//  RSDKSupport
//
//  Created by Zachary Radke on 11/19/13.
//  Copyright (c) 2013 Rakuten Inc. All rights reserved.
//

#ifndef RDebugLog
    #if DEBUG
        #define RDebugLog(format, ...) NSLog((@"%s [Line %d] " format), __PRETTY_FUNCTION__, __LINE__, ##__VA_ARGS__)
    #else
        #define RDebugLog(...)
    #endif
#endif

#ifndef RAlwaysLog
    #define RAlwaysLog(format, ...) NSLog((@"%s [Line %d] " format), __PRETTY_FUNCTION__, __LINE__, ##__VA_ARGS__)
#endif
