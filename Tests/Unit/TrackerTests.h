#import <XCTest/XCTest.h>
#import <RAnalytics/RAnalytics.h>
#import "MockedDatabase.h"

@protocol TrackerTestConfiguration <NSObject>
- (id<RAnalyticsTracker>)testedTracker;
@end

@interface TrackerTests : XCTestCase<TrackerTestConfiguration>
@property (nonatomic, copy) RAnalyticsState      *defaultState;
@property (nonatomic, copy) RAnalyticsEvent      *defaultEvent;
@property (nonatomic)       MockedDatabase          *database;
@property (nonatomic)       id<RAnalyticsTracker> tracker;
@property (nonatomic)       NSMutableArray          *mocks;

- (NSDictionary *)assertProcessEvent:(RAnalyticsEvent *)event
                               state:(RAnalyticsState *)state
                          expectType:(NSString *)etype;
- (NSDictionary *)assertProcessEvent:(RAnalyticsEvent *)event
     state:(RAnalyticsState *)state
   tracker:(RAnalyticsRATTracker *)tracker
                          expectType:(NSString *)etype;
- (void)stubRATResponseWithStatusCode:(int)status completionHandler:(void (^)(void))completion;
- (void)addMock:(id)mock;
- (void)invalidateTimerOfSender:(RAnalyticsSender *)sender;
@end
