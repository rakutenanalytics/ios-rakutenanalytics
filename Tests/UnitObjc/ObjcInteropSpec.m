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

    describe(@"RAnalyticsManager", ^{
        describe(@"setWebTrackingCookieDomainWithBlock", ^{
            NSString *originalWebTrackingCookieDomain = RAnalyticsManager.sharedInstance.webTrackingCookieDomain;

            it(@"should be able to set a web tracking cookie domain block", ^{
                [RAnalyticsManager.sharedInstance setWebTrackingCookieDomainWithBlock:^NSString * _Nullable{
                    return @"mydomain.com";
                }];

                [[RAnalyticsManager.sharedInstance.webTrackingCookieDomain shouldEventually] equal:@"mydomain.com"];
            });

            afterEach(^{
                [RAnalyticsManager.sharedInstance setWebTrackingCookieDomainWithBlock:^NSString * _Nullable{
                    return originalWebTrackingCookieDomain;
                }];
            });
        });
    });
});

SPEC_END
