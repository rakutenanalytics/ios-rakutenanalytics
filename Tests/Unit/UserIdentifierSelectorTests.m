#import <Kiwi/Kiwi.h>
#import "../../RAnalytics/Core/Private/_RAnalyticsExternalCollector.h"
#import "../../RAnalytics/Util/Private/_UserIdentifierSelector.h"

#pragma clang diagnostic ignored "-Wundeclared-selector"

SPEC_BEGIN(UserIdentifierSelectorTests)

describe(@"_UserIdentifierSelector", ^{
    NSString *originalUserIdentifier = _RAnalyticsExternalCollector.sharedInstance.userIdentifier;
    NSString *originalTrackingIdentifier = _RAnalyticsExternalCollector.sharedInstance.trackingIdentifier;
    
    afterAll(^{
        [RAnalyticsManager.sharedInstance setUserIdentifier:originalUserIdentifier];
        [_RAnalyticsExternalCollector.sharedInstance performSelector:@selector(setTrackingIdentifier:) withObject:originalTrackingIdentifier];
    });
    
    describe(@"selectedTrackingIdentifier", ^{
        context(@"trackingIdentifier is nil", ^{
            beforeEach(^{
                [RAnalyticsManager.sharedInstance setUserIdentifier:nil];
                [_RAnalyticsExternalCollector.sharedInstance performSelector:@selector(setTrackingIdentifier:) withObject:nil];
            });
            
            it(@"should return userID when userID is set to non-empty value", ^{
                [[_RAnalyticsExternalCollector.sharedInstance should] receive:@selector(setTrackingIdentifier:) withCount:0];
                [RAnalyticsManager.sharedInstance setUserIdentifier:@"userID"];
                [[_RAnalyticsExternalCollector.sharedInstance.userIdentifier should] equal:@"userID"];
                [[[_UserIdentifierSelector selectedTrackingIdentifier] should] equal:@"userID"];
            });
            
            it(@"should return nil when userID is nil", ^{
                [[_RAnalyticsExternalCollector.sharedInstance should] receive:@selector(setTrackingIdentifier:) withCount:0];
                [RAnalyticsManager.sharedInstance setUserIdentifier:nil];
                [[_RAnalyticsExternalCollector.sharedInstance.userIdentifier should] beNil];
                [[[_UserIdentifierSelector selectedTrackingIdentifier] should] equal:@"NO_LOGIN_FOUND"];
            });
        });
        
        context(@"trackingIdentifier is not nil", ^{
            beforeEach(^{
                [RAnalyticsManager.sharedInstance setUserIdentifier:nil];
                [_RAnalyticsExternalCollector.sharedInstance performSelector:@selector(setTrackingIdentifier:) withObject:@"trackingID"];
            });
            
            it(@"should return userID when userID is set to non-empty value", ^{
                [RAnalyticsManager.sharedInstance setUserIdentifier:@"userID"];
                [[_RAnalyticsExternalCollector.sharedInstance.trackingIdentifier should] equal:@"trackingID"];
                [[_RAnalyticsExternalCollector.sharedInstance.userIdentifier should] equal:@"userID"];
                [[[_UserIdentifierSelector selectedTrackingIdentifier] should] equal:@"userID"];
            });
            
            it(@"should return trackingID when userID is nil", ^{
                [[_RAnalyticsExternalCollector.sharedInstance.trackingIdentifier should] equal:@"trackingID"];
                [[_RAnalyticsExternalCollector.sharedInstance.userIdentifier should] beNil];
                [[[_UserIdentifierSelector selectedTrackingIdentifier] should] equal:@"trackingID"];
            });
        });
    });
});

SPEC_END
