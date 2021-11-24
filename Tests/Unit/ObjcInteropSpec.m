#import <Kiwi/Kiwi.h>
#import <RAnalytics/RAnalytics.h>

SPEC_BEGIN(ObjcInteropSpec)

describe(@"ObjcInterop", ^{
    describe(@"RAnalyticsRATTracker", ^{
        describe(@"setBatchingDelayWithBlock", ^{
            NSTimeInterval originalBatchingDelay = [[RAnalyticsRATTracker sharedInstance] batchingDelay];

            it(@"should set the expected batching delay", ^{
                [RAnalyticsRATTracker.sharedInstance setBatchingDelayWithBlock:^NSTimeInterval{
                    return 12.7;
                }];

                NSTimeInterval batchingDelay = [[RAnalyticsRATTracker sharedInstance] batchingDelay];
                [[theValue(batchingDelay) shouldEventually] equal:theValue(12.7)];
            });

            afterEach(^{
                [RAnalyticsRATTracker.sharedInstance setBatchingDelayWithBlock:^NSTimeInterval{
                    return originalBatchingDelay;
                }];
            });
        });
    });
});

SPEC_END
