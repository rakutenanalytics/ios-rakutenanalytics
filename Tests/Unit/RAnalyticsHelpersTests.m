#import <Kiwi/Kiwi.h>
#import <RAnalytics/RAnalytics.h>
#import "../../RAnalytics/Util/Private/_RAnalyticsHelpers.h"

SPEC_BEGIN(RAnalyticsHelpersTests)

describe(@"RAnalyticsHelpers", ^{
    describe(@"_RAnalyticsSharedApplication", ^{
        it(@"should not return nil", ^{
            [[_RAnalyticsSharedApplication() should] beNonNil];
        });
    });

    describe(@"_RAnalyticsEndpointAddress", ^{
        beforeEach(^{
            RAnalyticsManager* manager = [RAnalyticsManager nullMock];
            [RAnalyticsManager stub:@selector(sharedInstance) andReturn:manager];
        });
        
        it(@"should return user-defined RAT url if user set RAT url in app info.plist", ^{
            [[NSBundle mainBundle] stub:@selector(objectForInfoDictionaryKey:) andReturn:@"https://example.com" withArguments:@"RATEndpoint"];
            
            NSURL* url = _RAnalyticsEndpointAddress();
            
            [[url should] equal:[NSURL URLWithString:@"https://example.com"]];
        });
        
        it(@"should return production RAT url if user did not set RAT url in app info.plist", ^{
            NSURL* url = _RAnalyticsEndpointAddress();
            
            [[url should] equal:[NSURL URLWithString:@"https://rat.rakuten.co.jp/"]];
        });
    });
    
    describe(@"_RAnalyticsIsAppleClass", ^{
        it(@"should return true if the class is an Apple class", ^{
            [[theValue(_RAnalyticsIsAppleClass(UIViewController.class)) should] beYes];
        });
        
        it(@"should return false if the class is a non-Apple class", ^{
            [[theValue(_RAnalyticsIsAppleClass(RAnalyticsManager.class)) should] beNo];
        });
        
        it(@"should return false if the class pointer is Nil", ^{
            [[theValue(_RAnalyticsIsAppleClass(Nil)) should] beNo];
        });
    });

    describe(@"_RAnalyticsUseDefaultSharedCookieStorage", ^{
        it(@"should return false if user set 'disable shared cookie storage' key to true in app info.plist", ^{
            [[NSBundle mainBundle] stub:@selector(objectForInfoDictionaryKey:) andReturn:@(YES) withArguments:@"RATDisableSharedCookieStorage"];

            BOOL useSharedStorage = _RAnalyticsUseDefaultSharedCookieStorage();

            [[@(useSharedStorage) should] beFalse];
        });

        it(@"should return true if user set 'disable shared cookie storage' key to false in app info.plist", ^{
            [[NSBundle mainBundle] stub:@selector(objectForInfoDictionaryKey:) andReturn:@(NO) withArguments:@"RATDisableSharedCookieStorage"];

            BOOL useSharedStorage = _RAnalyticsUseDefaultSharedCookieStorage();

            [[@(useSharedStorage) should] beTrue];
        });

        it(@"should return true if 'disable shared cookie storage' key is not set in app info.plist", ^{
            [[NSBundle mainBundle] stub:@selector(objectForInfoDictionaryKey:) andReturn:nil withArguments:@"RATDisableSharedCookieStorage"];

            BOOL useSharedStorage = _RAnalyticsUseDefaultSharedCookieStorage();

            [[@(useSharedStorage) should] beTrue];
        });
    });
});

SPEC_END


