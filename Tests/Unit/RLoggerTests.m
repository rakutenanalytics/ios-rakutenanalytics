#import <Kiwi/Kiwi.h>
#import <AdSupport/AdSupport.h>
#import "../../RAnalytics/Core/Private/_RLogger.h"

#pragma clang diagnostic ignored "-Wundeclared-selector"

SPEC_BEGIN(RLoggerTests)

describe(@"_RLogger", ^{
    describe(@"loggingLevel", ^{
        it(@"should return RLoggingLevelError by default", ^{
            [[theValue(_RLogger.loggingLevel) should] equal:theValue(RLoggingLevelError)];
        });
    });
    
    describe(@"log:message:", ^{
        it(@"should return message from this level: RLoggingLevelVerbose", ^{
            _RLogger.loggingLevel = RLoggingLevelVerbose;
            [[[_RLogger verbose:@"test"] should] equal:@"test"];
            [[[_RLogger debug:@"test"] should] equal:@"test"];
            [[[_RLogger info:@"test"] should] equal:@"test"];
            [[[_RLogger warning:@"test"] should] equal:@"test"];
            [[[_RLogger error:@"test"] should] equal:@"test"];
            [[[_RLogger error:@"test %@", @"hello"] should] equal:@"test hello"];
        });
        
        it(@"should return message from this level: RLoggingLevelDebug", ^{
            _RLogger.loggingLevel = RLoggingLevelDebug;
            [[[_RLogger verbose:@"test"] should] beNil];
            [[[_RLogger debug:@"test"] should] equal:@"test"];
            [[[_RLogger info:@"test"] should] equal:@"test"];
            [[[_RLogger warning:@"test"] should] equal:@"test"];
            [[[_RLogger error:@"test"] should] equal:@"test"];
            [[[_RLogger error:@"test %@", @"hello"] should] equal:@"test hello"];
        });
        
        it(@"should return message from this level: RLoggingLevelInfo", ^{
            _RLogger.loggingLevel = RLoggingLevelInfo;
            [[[_RLogger verbose:@"test"] should] beNil];
            [[[_RLogger debug:@"test"] should] beNil];
            [[[_RLogger info:@"test"] should] equal:@"test"];
            [[[_RLogger warning:@"test"] should] equal:@"test"];
            [[[_RLogger error:@"test"] should] equal:@"test"];
            [[[_RLogger error:@"test %@", @"hello"] should] equal:@"test hello"];
        });
        
        it(@"should return message from this level: RLoggingLevelWarning", ^{
            _RLogger.loggingLevel = RLoggingLevelWarning;
            [[[_RLogger verbose:@"test"] should] beNil];
            [[[_RLogger debug:@"test"] should] beNil];
            [[[_RLogger info:@"test"] should] beNil];
            [[[_RLogger warning:@"test"] should] equal:@"test"];
            [[[_RLogger error:@"test"] should] equal:@"test"];
            [[[_RLogger error:@"test %@", @"hello"] should] equal:@"test hello"];
        });
        
        it(@"should return message from this level: RLoggingLevelError", ^{
            _RLogger.loggingLevel = RLoggingLevelError;
            [[[_RLogger verbose:@"test"] should] beNil];
            [[[_RLogger debug:@"test"] should] beNil];
            [[[_RLogger info:@"test"] should] beNil];
            [[[_RLogger warning:@"test"] should] beNil];
            [[[_RLogger error:@"test"] should] equal:@"test"];
            [[[_RLogger error:@"test %@", @"hello"] should] equal:@"test hello"];
        });
        
        it(@"should return nil from this level: RLoggingLevelNone", ^{
            _RLogger.loggingLevel = RLoggingLevelNone;
            [[[_RLogger verbose:@"test"] should] beNil];
            [[[_RLogger debug:@"test"] should] beNil];
            [[[_RLogger info:@"test"] should] beNil];
            [[[_RLogger warning:@"test"] should] beNil];
            [[[_RLogger error:@"test"] should] beNil];
            [[[_RLogger error:@"test %@", @"hello"] should] beNil];
        });
    });
});

SPEC_END
