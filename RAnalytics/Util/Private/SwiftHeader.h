// Used if RAnalytics is built as a framework, use_frameworks! is used in Podfile
#if __has_include(<RAnalytics/RAnalytics-Swift.h>)
    #import <RAnalytics/RAnalytics-Swift.h>

// Used if RAnalytics is built as a static library, use_frameworks! is not used in Podfile
#elif __has_include("RAnalytics-Swift.h")
    #import "RAnalytics-Swift.h"
#endif
