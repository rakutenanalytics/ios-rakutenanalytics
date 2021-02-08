#import <Kiwi/Kiwi.h>
#import "../../RAnalytics/Util/Private/_UserIdentifierSelector.h"
#import <RAnalytics/RAnalytics.h>
#import <RAnalytics/RAnalytics-Swift.h>

#pragma clang diagnostic ignored "-Wundeclared-selector"

SPEC_BEGIN(UserIdentifierSelectorTests)

describe(@"_UserIdentifierSelector", ^{
    NSString *originalUserIdentifier = RAnalyticsManager.sharedInstance.externalCollector.userIdentifier;
    NSString *originalTrackingIdentifier = RAnalyticsManager.sharedInstance.externalCollector.trackingIdentifier;
    
    afterAll(^{
        [RAnalyticsManager.sharedInstance setUserIdentifier:originalUserIdentifier];
        [RAnalyticsManager.sharedInstance.externalCollector performSelector:@selector(setTrackingIdentifier:) withObject:originalTrackingIdentifier];
    });
    
    describe(@"selectedTrackingIdentifier", ^{
        context(@"trackingIdentifier is nil", ^{
            beforeEach(^{
                [RAnalyticsManager.sharedInstance setUserIdentifier:nil];
                [RAnalyticsManager.sharedInstance.externalCollector performSelector:@selector(setTrackingIdentifier:) withObject:nil];
            });
            
            it(@"should return userID when userID is set to non-empty value", ^{
                [[RAnalyticsManager.sharedInstance.externalCollector should] receive:@selector(setTrackingIdentifier:) withCount:0];
                [RAnalyticsManager.sharedInstance setUserIdentifier:@"userID"];
                [[RAnalyticsManager.sharedInstance.externalCollector.userIdentifier should] equal:@"userID"];
                [[[_UserIdentifierSelector selectedTrackingIdentifier] should] equal:@"userID"];
            });
            
            it(@"should return nil when userID is nil", ^{
                [[RAnalyticsManager.sharedInstance.externalCollector should] receive:@selector(setTrackingIdentifier:) withCount:0];
                [RAnalyticsManager.sharedInstance setUserIdentifier:nil];
                [[RAnalyticsManager.sharedInstance.externalCollector.userIdentifier should] beNil];
                [[[_UserIdentifierSelector selectedTrackingIdentifier] should] equal:@"NO_LOGIN_FOUND"];
            });
        });
        
        context(@"trackingIdentifier is not nil", ^{
            beforeEach(^{
                [RAnalyticsManager.sharedInstance setUserIdentifier:nil];
                [RAnalyticsManager.sharedInstance.externalCollector performSelector:@selector(setTrackingIdentifier:) withObject:@"trackingID"];
            });
            
            it(@"should return userID when userID is set to non-empty value", ^{
                [RAnalyticsManager.sharedInstance setUserIdentifier:@"userID"];
                [[RAnalyticsManager.sharedInstance.externalCollector.trackingIdentifier should] equal:@"trackingID"];
                [[RAnalyticsManager.sharedInstance.externalCollector.userIdentifier should] equal:@"userID"];
                [[[_UserIdentifierSelector selectedTrackingIdentifier] should] equal:@"userID"];
            });
            
            it(@"should return trackingID when userID is nil", ^{
                [[RAnalyticsManager.sharedInstance.externalCollector.trackingIdentifier should] equal:@"trackingID"];
                [[RAnalyticsManager.sharedInstance.externalCollector.userIdentifier should] beNil];
                [[[_UserIdentifierSelector selectedTrackingIdentifier] should] equal:@"trackingID"];
            });
        });
    });
});

SPEC_END
