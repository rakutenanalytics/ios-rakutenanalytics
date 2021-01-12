@import XCTest;
#import <RAnalytics/RAnalytics.h>
#import <RDeviceIdentifier/RDeviceIdentifier.h>
#import <OCMock/OCMock.h>
#import <Kiwi/Kiwi.h>
#import "../../RAnalytics/Util/Private/_RAnalyticsHelpers.h"

@interface TestTrackerNoEndpoint : NSObject<RAnalyticsTracker>
@end
@implementation TestTrackerNoEndpoint
@end

@interface TestTracker : NSObject<RAnalyticsTracker>
@end
@implementation TestTracker
@synthesize endpointURL;
- (instancetype)init
{
    if (self = [super init])
    {

    }
    return self;
}
- (BOOL)processEvent:(RAnalyticsEvent *)event state:(RAnalyticsState *)state
{
    return YES;
}
@end

@interface RAnalyticsState ()
@property (nonatomic, nullable, readwrite) UIViewController *currentPage;
@end

@interface RAnalyticsManager ()
@property (nonatomic, nullable, copy) NSString *deviceIdentifier;
@property (nonatomic) BOOL locationManagerIsUpdating;
@property (nonatomic, strong) CLLocationManager *locationManager;

- (instancetype)initSharedInstance;
- (void)_startStopMonitoringLocationIfNeeded;
@end

@interface ManagerTests : XCTestCase
@end

@implementation ManagerTests
{
    RAnalyticsManager *_manager;
}

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"

- (void)setUp
{
    [super setUp];
    _manager = RAnalyticsManager.sharedInstance;
    _manager.deviceIdentifier = @"deviceIdentifier";
    _manager.shouldTrackLastKnownLocation = NO;
}

- (void)testInitThrows
{
    XCTAssertThrowsSpecificNamed([RAnalyticsManager.alloc init], NSException, NSInvalidArgumentException);
}

- (void)testAnalyticsManagerSharedInstanceIsNotNil
{
    XCTAssertNotNil(_manager);
}

- (void)testAnalyticsManagerSharedInstanceAreEqual
{
    XCTAssertEqualObjects(RAnalyticsManager.sharedInstance, RAnalyticsManager.sharedInstance);
}

- (void)testAnalyticsManagerAddExistingTypeTracker
{
    XCTAssertNoThrow([_manager addTracker:RAnalyticsRATTracker.sharedInstance]);
}

- (void)testAnalyticsManagerAddNewTypeTracker
{
    XCTAssertNoThrow([_manager addTracker:TestTracker.new]);
}

- (void)testProcessEvent
{
    RAnalyticsEvent *event = [RAnalyticsEvent.alloc initWithName:@"foo" parameters:nil];

    id mock = OCMPartialMock(RAnalyticsRATTracker.sharedInstance);
    [RAnalyticsManager.sharedInstance process:event];

    OCMVerify([mock processEvent:[OCMArg checkWithBlock:^BOOL(id obj) {
        return [obj isEqual:event];
    }] state:OCMOCK_ANY]);

    [mock stopMocking];
}

- (void)testStartMonitoringLocation
{
    id locationManagerMock = OCMClassMock(CLLocationManager.class);

    OCMStub([locationManagerMock performSelector:@selector(authorizationStatus)]).andReturn(kCLAuthorizationStatusAuthorizedAlways);

    _manager.shouldTrackLastKnownLocation = YES;

    XCTAssertTrue(_manager.locationManagerIsUpdating);

    [locationManagerMock stopMocking];
}

- (void)testStopMonitoringLocation
{
    id locationManagerMock = OCMClassMock(CLLocationManager.class);

    OCMStub([locationManagerMock performSelector:@selector(authorizationStatus)]).andReturn(kCLAuthorizationStatusAuthorizedAlways);

    _manager.shouldTrackLastKnownLocation = NO;

    XCTAssertFalse(_manager.locationManagerIsUpdating);

    [locationManagerMock stopMocking];
}

- (void)testStopMonitoringLocationOnResignActive
{
    _manager.locationManagerIsUpdating = YES;
    [NSNotificationCenter.defaultCenter postNotificationName:UIApplicationWillResignActiveNotification object:self];
    XCTAssertFalse(_manager.locationManagerIsUpdating);
}

- (void)testPageViewIsTrackedWhenShouldTrackPageViewIsTrue
{
    // Assert that page view event is processed by RAT Tracker when the AnalyticsManager's shouldTrackPageView property is true

    RAnalyticsState *state = [RAnalyticsState.alloc initWithSessionIdentifier:@"CA7A88AB-82FE-40C9-A836-B1B3455DECAB"
                                                             deviceIdentifier:@"deviceId"];
    UIViewController *currentPage = UIViewController.new;
    state.currentPage = currentPage;
    id event = [RAnalyticsEvent.alloc initWithName:RAnalyticsPageVisitEventName parameters:@{@"page_id": @"TestPage"}];

    id mock = OCMPartialMock(RAnalyticsManager.sharedInstance);
    OCMStub([mock shouldTrackPageView]).andReturn(YES);
    XCTAssertTrue([RAnalyticsRATTracker.sharedInstance processEvent:event state:state]);
    [mock stopMocking];
}

- (void)testPageViewIsNotTrackedWhenShouldTrackPageViewIsFalse
{
    // Assert that page view event is not processed by RAT Tracker when the AnalyticsManager's shouldTrackPageView property is false

    RAnalyticsState *state = [RAnalyticsState.alloc initWithSessionIdentifier:@"CA7A88AB-82FE-40C9-A836-B1B3455DECAB"
                                                             deviceIdentifier:@"deviceId"];
    UIViewController *currentPage = UIViewController.new;
    state.currentPage = currentPage;
    id event = [RAnalyticsEvent.alloc initWithName:RAnalyticsPageVisitEventName parameters:@{@"page_id": @"TestPage"}];

    id mock = OCMPartialMock(RAnalyticsManager.sharedInstance);
    OCMStub([mock shouldTrackPageView]).andReturn(NO);
    XCTAssertFalse([RAnalyticsRATTracker.sharedInstance processEvent:event state:state]);
    [mock stopMocking];
}

#pragma clang diagnostic pop

@end

#pragma clang diagnostic ignored "-Wundeclared-selector"

@implementation RAnalyticsManager(empty)
- (instancetype)initEmpty {
    self = [super init];
    return self;
}
@end

SPEC_BEGIN(RAnalyticsManagerTests)

describe(@"RAnalyticsManager", ^{
    describe(@"addTracker", ^{
        it(@"should set the expected endpoint to the added trackers endpointURL", ^{
            RAnalyticsManager *analyticsManager = [[RAnalyticsManager alloc] initEmpty];
            
            NSArray *trackers = [analyticsManager performSelector:@selector(trackers)];
            
            for(int i=0; i < 10; i++) { [analyticsManager addTracker:TestTracker.new]; }
            
            for(id<RAnalyticsTracker>tracker in trackers) {
                [[tracker.endpointURL should] equal:_RAnalyticsEndpointAddress()];
            }

            [analyticsManager setEndpointURL:[NSURL URLWithString:@"https://endpoint.com"]];
            
            for(id<RAnalyticsTracker>tracker in trackers) {
                [[tracker.endpointURL should] equal:[NSURL URLWithString:@"https://endpoint.com"]];
            }
            
            [analyticsManager setEndpointURL:nil];
            
            for(id<RAnalyticsTracker>tracker in trackers) {
                [[tracker.endpointURL should] equal:_RAnalyticsEndpointAddress()];
            }
        });
        it(@"should not set the expected endpoint to the added trackers that doesn't synthesize endpointURL", ^{
            RAnalyticsManager *analyticsManager = [[RAnalyticsManager alloc] initEmpty];
            for(int i=0; i < 10; i++) { [analyticsManager addTracker:TestTrackerNoEndpoint.new]; }
            NSArray *trackers = [analyticsManager performSelector:@selector(trackers)];
            for(id<RAnalyticsTracker>tracker in trackers) {
                [[tracker.endpointURL should] beNil];
            }
        });
    });
    // Note: RAnalyticsSessionEndEventName is added to the RAnalyticsConfiguration.plist file for the key: RATDisabledEventsList
    describe(@"process", ^{
        context(@"shouldTrackEventHandler is nil", ^{
            context(@"build time configuration file is missing", ^{
                it(@"should return true", ^{
                    RAnalyticsEvent *event = [RAnalyticsEvent.alloc initWithName:RAnalyticsSessionStartEventName parameters:nil];
                    RAnalyticsManager *analyticsManager = [[RAnalyticsManager alloc] initSharedInstance];
                    [analyticsManager performSelector:@selector(eventChecker) withObject:[[EventChecker alloc] initWithDisabledEventsAtBuildTime:nil]];
                    [[analyticsManager.shouldTrackEventHandler should] beNil];
                    [[theValue([analyticsManager process:event]) should] beTrue];
                });
            });
            context(@"build time configuration file exists", ^{
                it(@"should return false if the event is disabled at build time", ^{
                    RAnalyticsEvent *event = [RAnalyticsEvent.alloc initWithName:RAnalyticsSessionEndEventName parameters:nil];
                    RAnalyticsManager *analyticsManager = [[RAnalyticsManager alloc] initSharedInstance];
                    [[theValue([[NSBundle disabledEventsAtBuildTime] containsObject:RAnalyticsSessionEndEventName]) should] beTrue];
                    [[analyticsManager.shouldTrackEventHandler should] beNil];
                    [[theValue([analyticsManager process:event]) should] beFalse];
                });
                it(@"should return true if the event is not disabled at build time", ^{
                    RAnalyticsEvent *event = [RAnalyticsEvent.alloc initWithName:RAnalyticsSessionStartEventName parameters:nil];
                    RAnalyticsManager *analyticsManager = [[RAnalyticsManager alloc] initSharedInstance];
                    [[theValue([[NSBundle disabledEventsAtBuildTime] containsObject:RAnalyticsSessionStartEventName]) should] beFalse];
                    [[analyticsManager.shouldTrackEventHandler should] beNil];
                    [[theValue([analyticsManager process:event]) should] beTrue];
                });
            });
        });
        context(@"shouldTrackEventHandler is not nil", ^{
            context(@"build time configuration file is missing", ^{
                it(@"should return false if the event is disabled at runtime", ^{
                    RAnalyticsEvent *event = [RAnalyticsEvent.alloc initWithName:RAnalyticsSessionStartEventName parameters:nil];
                    RAnalyticsManager *analyticsManager = [[RAnalyticsManager alloc] initSharedInstance];
                    [analyticsManager performSelector:@selector(eventChecker) withObject:[[EventChecker alloc] initWithDisabledEventsAtBuildTime:nil]];
                    analyticsManager.shouldTrackEventHandler = ^BOOL(NSString * _Nonnull eventName) {
                        return ![eventName isEqualToString:RAnalyticsSessionStartEventName];
                    };
                    [[theValue([analyticsManager process:event]) should] beFalse];
                });
                it(@"should return true if the event is enabled at runtime", ^{
                    RAnalyticsEvent *event = [RAnalyticsEvent.alloc initWithName:RAnalyticsSessionStartEventName parameters:nil];
                    RAnalyticsManager *analyticsManager = [[RAnalyticsManager alloc] initSharedInstance];
                    [analyticsManager performSelector:@selector(eventChecker) withObject:[[EventChecker alloc] initWithDisabledEventsAtBuildTime:nil]];
                    analyticsManager.shouldTrackEventHandler = ^BOOL(NSString * _Nonnull eventName) {
                        return [eventName isEqualToString:RAnalyticsSessionStartEventName];
                    };
                    [[theValue([analyticsManager process:event]) should] beTrue];
                });
            });
            context(@"build time configuration file exists", ^{
                it(@"should return true if the event is disabled at build time and enabled at runtime", ^{
                    RAnalyticsEvent *event = [RAnalyticsEvent.alloc initWithName:RAnalyticsSessionEndEventName parameters:nil];
                    RAnalyticsManager *analyticsManager = [[RAnalyticsManager alloc] initSharedInstance];
                    [[theValue([[NSBundle disabledEventsAtBuildTime] containsObject:RAnalyticsSessionEndEventName]) should] beTrue];
                    analyticsManager.shouldTrackEventHandler = ^BOOL(NSString * _Nonnull eventName) {
                        return [eventName isEqualToString:RAnalyticsSessionEndEventName];
                    };
                    [[theValue([analyticsManager process:event]) should] beTrue];
                });
                it(@"should return true if the event is not disabled at build time and enabled at runtime", ^{
                    RAnalyticsEvent *event = [RAnalyticsEvent.alloc initWithName:RAnalyticsSessionStartEventName parameters:nil];
                    RAnalyticsManager *analyticsManager = [[RAnalyticsManager alloc] initSharedInstance];
                    [[theValue([[NSBundle disabledEventsAtBuildTime] containsObject:RAnalyticsSessionStartEventName]) should] beFalse];
                    analyticsManager.shouldTrackEventHandler = ^BOOL(NSString * _Nonnull eventName) {
                        return [eventName isEqualToString:RAnalyticsSessionStartEventName];
                    };
                    [[theValue([analyticsManager process:event]) should] beTrue];
                });
                it(@"should return false if the event is disabled at build time and disabled at runtime", ^{
                    RAnalyticsEvent *event = [RAnalyticsEvent.alloc initWithName:RAnalyticsSessionEndEventName parameters:nil];
                    RAnalyticsManager *analyticsManager = [[RAnalyticsManager alloc] initSharedInstance];
                    [[theValue([[NSBundle disabledEventsAtBuildTime] containsObject:RAnalyticsSessionEndEventName]) should] beTrue];
                    analyticsManager.shouldTrackEventHandler = ^BOOL(NSString * _Nonnull eventName) {
                        return ![eventName isEqualToString:RAnalyticsSessionEndEventName];
                    };
                    [[theValue([analyticsManager process:event]) should] beFalse];
                });
                it(@"should return false if the event is not disabled at build time and disabled at runtime", ^{
                    RAnalyticsEvent *event = [RAnalyticsEvent.alloc initWithName:RAnalyticsSessionStartEventName parameters:nil];
                    RAnalyticsManager *analyticsManager = [[RAnalyticsManager alloc] initSharedInstance];
                    [[theValue([[NSBundle disabledEventsAtBuildTime] containsObject:RAnalyticsSessionStartEventName]) should] beFalse];
                    analyticsManager.shouldTrackEventHandler = ^BOOL(NSString * _Nonnull eventName) {
                        return ![eventName isEqualToString:RAnalyticsSessionStartEventName];
                    };
                    [[theValue([analyticsManager process:event]) should] beFalse];
                });
            });
        });
    });
});

SPEC_END
