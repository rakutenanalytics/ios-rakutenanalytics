@import XCTest;
#import <OCMock/OCMock.h>
#import <Kiwi/Kiwi.h>
#import <RAnalytics/RAnalyticsRATTracker.h>

#import "../../RAnalytics/Util/Private/_RAnalyticsHelpers.h"
#import "TrackerTests.h"

@interface RAnalyticsRATTracker ()
- (instancetype)initInstance;
@end

// These tests had to be moved into their own file due to the UnitTests-Swift.h import in RATTrackerTests.h causing compiler
// "Call to X is ambiguous" conflicts between Swift/Kiwi for the `describe` and `afterEach` definitions.
SPEC_BEGIN(RAnalyticsRATTrackerSpec)

describe(@"RAnalyticsRATTracker", ^{
    describe(@"endpointURL", ^{
        RAnalyticsRATTracker * ratTracker = [RAnalyticsRATTracker.alloc initInstance];
        NSURL *originalEndpointURL = ratTracker.endpointURL;
        RAnalyticsSender *sender = [ratTracker performSelector:@selector(sender)];
        RAnalyticsRpCookieFetcher *rpCookieFetcher = [ratTracker performSelector:@selector(rpCookieFetcher)];

        it(@"should set the expected endpoint to its sender and rpCookieFetcher", ^{
            ratTracker.endpointURL = [NSURL URLWithString:@"https://endpoint1.com"];
            [[sender.endpointURL should] equal:[NSURL URLWithString:@"https://endpoint1.com"]];
            [[rpCookieFetcher.endpointURL should] equal:[NSURL URLWithString:@"https://endpoint1.com"]];
            [[ratTracker.endpointURL should] equal:[NSURL URLWithString:@"https://endpoint1.com"]];

            ratTracker.endpointURL = [NSURL URLWithString:@"https://endpoint2.com"];
            [[sender.endpointURL should] equal:[NSURL URLWithString:@"https://endpoint2.com"]];
            [[rpCookieFetcher.endpointURL should] equal:[NSURL URLWithString:@"https://endpoint2.com"]];
            [[ratTracker.endpointURL should] equal:[NSURL URLWithString:@"https://endpoint2.com"]];
        });

        afterEach(^{
            ratTracker.endpointURL = originalEndpointURL;
        });
    });
});

SPEC_END
