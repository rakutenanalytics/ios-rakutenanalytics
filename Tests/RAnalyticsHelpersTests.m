#import <Kiwi/Kiwi.h>
#import <RAnalytics/RAnalytics.h>
#import "../RAnalytics/Util/Private/_RAnalyticsHelpers.h"

SPEC_BEGIN(RAnalyticsHelpersTests)

describe(@"RAnalyticsHelpers", ^{
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
        
        it(@"should return production RAT url if user did not set RAT url in app info.plist and staging should not be used", ^{
            [[RAnalyticsManager sharedInstance] stub:@selector(shouldUseStagingEnvironment) andReturn:theValue(NO)];
            
            NSURL* url = _RAnalyticsEndpointAddress();
            
            [[url should] equal:[NSURL URLWithString:@"https://rat.rakuten.co.jp/"]];
        });
        
        it(@"should return staging RAT url if user did not set RAT url in app info.plist and staging should be used", ^{
            [[RAnalyticsManager sharedInstance] stub:@selector(shouldUseStagingEnvironment) andReturn:theValue(YES)];
            
            NSURL* url = _RAnalyticsEndpointAddress();
            
            [[url should] equal:[NSURL URLWithString:@"https://stg.rat.rakuten.co.jp/"]];
        });
    });
});

SPEC_END


