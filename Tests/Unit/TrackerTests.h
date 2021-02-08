#import <XCTest/XCTest.h>
#import <RAnalytics/RAnalytics.h>
#import <RAnalytics/RAnalytics-Swift.h>
#import <sqlite3.h>

NS_ASSUME_NONNULL_BEGIN

typedef void (^TrackerAssertBlock)(id payload);

@protocol TrackerTestConfiguration <NSObject>
- (id<RAnalyticsTracker>)testedTracker;
@end

@interface CurrentPage: UIViewController
@end

@interface TrackerTests : XCTestCase<TrackerTestConfiguration>
@property (nonatomic, copy) RAnalyticsState      *defaultState;
@property (nonatomic, copy) RAnalyticsEvent      *defaultEvent;
@property (nonatomic)       RAnalyticsDatabase   *database;
@property (nonatomic)       sqlite3              *connection;
@property (nonatomic, copy) NSString             *databaseTableName;
@property (nonatomic)       id<RAnalyticsTracker> tracker;
@property (nonatomic)       NSMutableArray          *mocks;

- (void)assertProcessEvent:(RAnalyticsEvent *)event
                     state:(RAnalyticsState *)state
                expectType:(NSString *)etype;

- (void)assertProcessEvent:(RAnalyticsEvent *)event
                     state:(RAnalyticsState *)state
               assertBlock:(TrackerAssertBlock)assertBlock;

- (void)assertProcessEvent:(RAnalyticsEvent *)event
                     state:(RAnalyticsState *)state
               expectEtype:(NSString *)etype
               assertBlock:(TrackerAssertBlock)assertBlock;

- (void)stubRATResponseWithStatusCode:(int)status completionHandler:(void (^)(void))completion;
- (void)addMock:(id)mock;
- (void)invalidateTimerOfSender:(RAnalyticsSender *)sender;
@end

NS_ASSUME_NONNULL_END
