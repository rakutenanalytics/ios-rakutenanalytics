#import <Kiwi/Kiwi.h>
#import <AdSupport/AdSupport.h>
#import <RAnalytics/RAnalyticsEndpointSettable.h>

@interface RAnalyticsEndpointHandler : NSObject<RAnalyticsEndpointSettable>
@end
@implementation RAnalyticsEndpointHandler
@synthesize endpointURL;
@end

SPEC_BEGIN(RAnalyticsEndpointSettableTests)

describe(@"RAnalyticsEndpointSettable", ^{
    describe(@"endpoint", ^{
        it(@"should return https//endpoint.com when endpoint equals https//endpoint.com", ^{
            RAnalyticsEndpointHandler *analyticsEndpointHandler = RAnalyticsEndpointHandler.new;
            NSURL * _Nonnull endpoint = [NSURL URLWithString:@"https//endpoint.com"];
            analyticsEndpointHandler.endpointURL = endpoint;
            [[analyticsEndpointHandler.endpointURL should] equal:endpoint];
            [[analyticsEndpointHandler.endpointURL.absoluteString should] equal:endpoint.absoluteString];
        });
    });
});

SPEC_END
