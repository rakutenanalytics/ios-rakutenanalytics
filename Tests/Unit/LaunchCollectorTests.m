@import XCTest;
#import <RAnalytics/RAnalytics.h>
#import "../../RAnalytics/Util/Private/_RAnalyticsHelpers.h"
#import "../../RAnalytics/Core/Private/_RAnalyticsExternalCollector.h"
#import "../../RAnalytics/Core/Private/_RAnalyticsLaunchCollector.h"
#import "../../RAnalytics/Core/Private/_RAnalyticsPrivateEvents.h"
#import <OCMock/OCMock.h>

@interface _RAnalyticsExternalCollector ()
+ (void)trackEvent:(NSString *)eventName;
+ (void)trackEvent:(NSString *)eventName parameters:(NSDictionary<NSString *, id> *)parameters;
- (instancetype)initInstance;
@end

@interface _RAnalyticsLaunchCollector ()
@property (nonatomic, nullable, readwrite, copy)    NSDate                  *initialLaunchDate;
@property (nonatomic, nullable, readwrite, copy)    NSDate                  *installLaunchDate;
@property (nonatomic, nullable, readwrite, copy)    NSDate                  *lastUpdateDate;
@property (nonatomic, nullable, readwrite, copy)    NSDate                  *lastLaunchDate;
@property (nonatomic, nullable, readwrite, copy)    NSString                *lastVersion;
@property (nonatomic, readwrite)                    NSUInteger              lastVersionLaunches;
@property (nonatomic, readwrite)                    BOOL                    isInitialLaunch;
@property (nonatomic, readwrite)                    BOOL                    isInstallLaunch;
@property (nonatomic, readwrite)                    BOOL                    isUpdateLaunch;
@property (nonatomic, readwrite)                    RAnalyticsOrigin     origin;
@property (nonatomic, nullable, readwrite)          UIViewController        *currentPage;
@property (nonatomic, nullable, readwrite, copy)    NSString                *pushTrackingIdentifier;

- (instancetype)initInstance;
- (void)resetToDefaults;
@end

@interface RAnalyticsManager ()
@property (nonatomic, nullable, copy) NSString *deviceIdentifier;
@end

@interface LaunchCollectorTests : XCTestCase
@property (nonatomic) _RAnalyticsLaunchCollector *collector;
@end

@implementation LaunchCollectorTests

- (void)setUp
{
    [super setUp];
    
    _RAnalyticsLaunchCollector *collector    = _RAnalyticsLaunchCollector.sharedInstance;
    collector.isInitialLaunch                   = NO;
    collector.isUpdateLaunch                    = NO;
    collector.isInstallLaunch                   = NO;
    collector.pushTrackingIdentifier            = nil;
    
    RAnalyticsManager.sharedInstance.deviceIdentifier = @"deviceIdentifier";
}

- (_RAnalyticsLaunchCollector *)defaultCollector
{
    _RAnalyticsLaunchCollector *collector = [_RAnalyticsLaunchCollector sharedInstance];
    collector.isInitialLaunch = NO;
    collector.isInstallLaunch = NO;
    collector.isUpdateLaunch = NO;
    return collector;
}

- (void)testInitThrows
{
    XCTAssertThrowsSpecificNamed([_RAnalyticsLaunchCollector.alloc init], NSException, NSInvalidArgumentException);
}

- (void)assertThatManagerTracksEvent:(NSString *)expectedEventName onNotification:(NSString *)notificationName
{
    RAnalyticsManager *manager = [RAnalyticsManager sharedInstance];
    id mockManager = OCMPartialMock(manager);

    XCTestExpectation *expectation = [self expectationWithDescription:expectedEventName];

    OCMStub([mockManager process:[OCMArg checkWithBlock:^BOOL(id obj) {
        RAnalyticsEvent *event = obj;
        XCTAssertNotNil(event.name);
        if ([event.name isEqualToString:expectedEventName]) {
            [expectation fulfill];
        }
        return YES;
    }]]);

    [NSNotificationCenter.defaultCenter postNotificationName:notificationName
                                                      object:nil];

    [self waitForExpectationsWithTimeout:5 handler:nil];
    [mockManager stopMocking];
}

- (void)testThatInitialLaunchEventIsTrackedWhenAppLaunchedForFirstTime
{
    _RAnalyticsLaunchCollector *collector = [self defaultCollector];
    collector.isInitialLaunch = YES;

    [self assertThatManagerTracksEvent:RAnalyticsInitialLaunchEventName
                        onNotification:UIApplicationDidFinishLaunchingNotification];

    XCTAssertFalse(collector.isInitialLaunch);
}

- (void)testThatInstallEventIsTrackedWhenAppLaunchedAfterInstall
{
    _RAnalyticsLaunchCollector *collector = [self defaultCollector];
    collector.isInstallLaunch = YES;

    [self assertThatManagerTracksEvent:RAnalyticsInstallEventName
                        onNotification:UIApplicationDidFinishLaunchingNotification];

    XCTAssertFalse(collector.isInstallLaunch);
}

- (void)testThatUpdateEventIsTrackedWhenAppLaunchedAfterUpdate
{
    _RAnalyticsLaunchCollector *collector = [self defaultCollector];
    collector.isUpdateLaunch = YES;

    [self assertThatManagerTracksEvent:RAnalyticsApplicationUpdateEventName
                        onNotification:UIApplicationDidFinishLaunchingNotification];

    XCTAssertFalse(collector.isUpdateLaunch);
}

- (void)testThatSessionStartEventIsTrackedWhenAppResumed
{
    [self assertThatManagerTracksEvent:RAnalyticsSessionStartEventName
                        onNotification:UIApplicationWillEnterForegroundNotification];
}

- (void)testSuspend
{
    [self assertThatManagerTracksEvent:RAnalyticsSessionEndEventName
                        onNotification:UIApplicationDidEnterBackgroundNotification];
}

- (void)testPresentTrackedVC
{
    _RAnalyticsLaunchCollector *collector = _RAnalyticsLaunchCollector.sharedInstance;
    collector.origin = RAnalyticsPushOrigin; // to check origin result against
    
    UIViewController *vc = UIViewController.new;
    
    id mockManager = OCMPartialMock(RAnalyticsManager.sharedInstance);
    
    [collector didPresentViewController:vc];
    
    OCMVerify([mockManager process:[OCMArg checkWithBlock:^BOOL(id obj) {
        RAnalyticsEvent *event = obj;
        XCTAssertNotNil(event);
        BOOL expected = ([event.name isEqualToString:RAnalyticsPageVisitEventName]);
        XCTAssertTrue(expected, @"Unexpected event processed: %@", event.name);
        return expected;
    }]]);
    XCTAssertTrue(collector.origin == RAnalyticsInternalOrigin);
    [mockManager stopMocking];
}

- (void)testPresentUntrackedVC
{
    _RAnalyticsLaunchCollector *collector = _RAnalyticsLaunchCollector.sharedInstance;
    collector.origin = RAnalyticsPushOrigin; // to check origin result against
    
    UINavigationController *vc = UINavigationController.new;
    
    id mockManager = OCMPartialMock(RAnalyticsManager.sharedInstance);
    
    [collector didPresentViewController:vc];
    
    OCMReject([mockManager process:[OCMArg isKindOfClass:RAnalyticsEvent.class]]);
    
    XCTAssertTrue(collector.origin == RAnalyticsPushOrigin);
    [mockManager stopMocking];
}

- (void)assertPushWithTrackingIdentifier:(NSString *)trackingIdentifier payload:(NSDictionary *)payload
{
    _RAnalyticsLaunchCollector *collector = _RAnalyticsLaunchCollector.sharedInstance;
    
    id mockManager = OCMPartialMock(RAnalyticsManager.sharedInstance);
    
    [collector processPushNotificationPayload:payload userAction:nil userText:nil];
    
    OCMVerify([mockManager process:[OCMArg checkWithBlock:^BOOL(id obj) {
        RAnalyticsEvent *event = obj;
        XCTAssertNotNil(event);
        BOOL expected = ([event.name isEqualToString:RAnalyticsPushNotificationEventName]);
        XCTAssertTrue(expected, @"Unexpected event processed: %@", event.name);
        XCTAssertTrue([event.parameters[RAnalyticsPushNotificationTrackingIdentifierParameter] hasPrefix:trackingIdentifier]);
        return expected;
    }]]);
    XCTAssertTrue([collector.pushTrackingIdentifier hasPrefix:trackingIdentifier]);
    [mockManager stopMocking];
}

- (void)testPushWithReportID
{
    [self assertPushWithTrackingIdentifier:@"rid:1234abcd" payload:@{@"rid":@"1234abcd",
                                                                     @"nid":@"abcd1234",
                                                                     @"aps":@{@"alert":@"a push alert"}}];
}

- (void)testPushWithNotificationID
{
    [self assertPushWithTrackingIdentifier:@"nid:abcd1234" payload:@{@"notification_id":@"abcd1234",
                                                                     @"aps":@{@"alert":@"a push alert"}}];
}

- (void)testPushWithAlertIsString
{
    [self assertPushWithTrackingIdentifier:@"msg:" payload:@{@"aps":@{@"alert":@"a push alert"}}];
}

- (void)testPushWithAlertHasTitleNoBody
{
    [self assertPushWithTrackingIdentifier:@"msg:" payload:@{@"aps":@{@"alert":@{@"title":@"a push alert title"}}}];
}

- (void)testPushWithAlertHasTitleAndBody
{
    [self assertPushWithTrackingIdentifier:@"msg:" payload:@{@"aps":@{@"alert":@{@"title":@"a push alert title",
                                                                                 @"body":@"a push alert body"}}}];
}

- (void)testPushNotTrackable
{
    _RAnalyticsLaunchCollector *collector = _RAnalyticsLaunchCollector.sharedInstance;
    
    id mockManager = OCMPartialMock(RAnalyticsManager.sharedInstance);
    
    [collector processPushNotificationPayload:@{@"foo":@"bar"} userAction:nil userText:nil];
    
    OCMReject([mockManager process:[OCMArg isKindOfClass:RAnalyticsEvent.class]]);
    
    XCTAssertNil(collector.pushTrackingIdentifier);
    [mockManager stopMocking];
}

- (void)test_UNNotificationResponseProcess_success
{
    UNMutableNotificationContent *content = UNMutableNotificationContent.new;
    content.title = @"UN notification";
    content.body = @"body";
    content.userInfo = @{@"rid":@"1234abcd",
                         @"nid":@"abcd1234",
                         @"aps":@{@"alert":@"a push alert"}};

    UNPushNotificationTrigger *trigger = [UNPushNotificationTrigger alloc]; // init is marked unavailable
    
    UNNotificationRequest *request = [UNNotificationRequest requestWithIdentifier:@"id_notification"
                                                                          content:content
                                                                          trigger:trigger];
    
    UNNotification *notification = UNNotification.new;
    [notification setValue:request
                    forKey:@"request"];
    
    UNTextInputNotificationResponse *response = UNTextInputNotificationResponse.new;
    [response setValue:@"Some user text"
                forKey:@"userText"];
    [response setValue:UNNotificationDefaultActionIdentifier
                forKey:@"actionIdentifier"];
    [response setValue:notification
                forKey:@"notification"];
    
    _RAnalyticsLaunchCollector *collector = _RAnalyticsLaunchCollector.sharedInstance;

    id mockManager = OCMPartialMock(RAnalyticsManager.sharedInstance);
    
    [collector processPushNotificationResponse:response];
    
    OCMVerify([mockManager process:[OCMArg checkWithBlock:^BOOL(id obj) {
        RAnalyticsEvent *event = obj;
        XCTAssertNotNil(event);
        BOOL expected = ([event.name isEqualToString:RAnalyticsPushNotificationEventName]);
        XCTAssertTrue(expected, @"Unexpected event processed: %@", event.name);
        XCTAssertTrue([event.parameters[RAnalyticsPushNotificationTrackingIdentifierParameter] hasPrefix:@"rid:1234abcd"]);
        return expected;
    }]]);
    
    XCTAssertTrue([collector.pushTrackingIdentifier hasPrefix:@"rid:1234abcd"]);
    [mockManager stopMocking];
}

- (void)test_UNNotificationResponseProcess_locationTrigger_failure
{
    UNMutableNotificationContent *content = UNMutableNotificationContent.new;
    content.title = @"UN notification";
    content.body = @"body";
    content.userInfo = @{@"rid":@"1234abcd",
                         @"nid":@"abcd1234",
                         @"aps":@{@"alert":@"a push alert"}};
    
    
    UNLocationNotificationTrigger *trigger = [UNLocationNotificationTrigger alloc]; // init is marked unavailable
    
    UNNotificationRequest *request = [UNNotificationRequest requestWithIdentifier:@"id_notification"
                                                                          content:content
                                                                          trigger:trigger];
    
    UNNotification *notification = UNNotification.new;
    [notification setValue:request
                    forKey:@"request"];
    
    UNTextInputNotificationResponse *response = UNTextInputNotificationResponse.new;
    [response setValue:@"Some user text"
                forKey:@"userText"];
    [response setValue:UNNotificationDefaultActionIdentifier
                forKey:@"actionIdentifier"];
    [response setValue:notification
                forKey:@"notification"];
    
    _RAnalyticsLaunchCollector *collector = _RAnalyticsLaunchCollector.sharedInstance;

    id mockManager = OCMPartialMock(RAnalyticsManager.sharedInstance);
    
    [collector processPushNotificationResponse:response];
    
    [[mockManager reject] process:[OCMArg checkWithBlock:^BOOL(id obj) {
        
        RAnalyticsEvent *event = obj;
        XCTAssertNotNil(event);
        BOOL expected = ([event.name isEqualToString:RAnalyticsPushNotificationEventName]);
        XCTAssertTrue(expected, @"Unexpected event processed: %@", event.name);
        XCTAssertTrue([event.parameters[RAnalyticsPushNotificationTrackingIdentifierParameter] hasPrefix:@"rid:1234abcd"]);
        return expected;
    }]];
    
    XCTAssertNil(collector.pushTrackingIdentifier);
    [mockManager stopMocking];
}

- (void)test_UNNotificationResponseProcess_noTrigger_failure
{
    UNMutableNotificationContent *content = UNMutableNotificationContent.new;
    content.title = @"UN notification";
    content.body = @"body";
    content.userInfo = @{@"rid":@"1234abcd",
                         @"nid":@"abcd1234",
                         @"aps":@{@"alert":@"a push alert"}};
    
    UNNotificationRequest *request = [UNNotificationRequest requestWithIdentifier:@"id_notification"
                                                                          content:content
                                                                          trigger:nil];
    
    UNNotification *notification = UNNotification.new;
    [notification setValue:request
                    forKey:@"request"];
    
    UNTextInputNotificationResponse *response = UNTextInputNotificationResponse.new;
    [response setValue:@"Some user text"
                forKey:@"userText"];
    [response setValue:UNNotificationDefaultActionIdentifier
                forKey:@"actionIdentifier"];
    [response setValue:notification
                forKey:@"notification"];
    
    _RAnalyticsLaunchCollector *collector = _RAnalyticsLaunchCollector.sharedInstance;

    id mockManager = OCMPartialMock(RAnalyticsManager.sharedInstance);
    
    [collector processPushNotificationResponse:response];
    
    [[mockManager reject] process:[OCMArg checkWithBlock:^BOOL(id obj) {
        
        RAnalyticsEvent *event = obj;
        XCTAssertNotNil(event);
        BOOL expected = ([event.name isEqualToString:RAnalyticsPushNotificationEventName]);
        XCTAssertTrue(expected, @"Unexpected event processed: %@", event.name);
        XCTAssertTrue([event.parameters[RAnalyticsPushNotificationTrackingIdentifierParameter] hasPrefix:@"rid:1234abcd"]);
        return expected;
    }]];
    
    XCTAssertNil(collector.pushTrackingIdentifier);
    [mockManager stopMocking];
}

- (void)testResetToDefaults
{
    _RAnalyticsLaunchCollector *collector = _RAnalyticsLaunchCollector.sharedInstance;
    collector.installLaunchDate     = [NSDate date];
    collector.lastUpdateDate        = [NSDate date];
    collector.lastLaunchDate        = [NSDate date];
    collector.lastVersion           = @"v1.0";
    collector.lastVersionLaunches   = 10;
    
    NSUserDefaults *defaults = OCMPartialMock(NSUserDefaults.standardUserDefaults);
    NSDate *date = [NSDate distantPast];
    
    OCMStub([defaults objectForKey:@"com.rakuten.esd.sdk.properties.analytics.launchInformation.installLaunchDate"]).andReturn(date);
    OCMStub([defaults objectForKey:@"com.rakuten.esd.sdk.properties.analytics.launchInformation.lastUpdateDate"]).andReturn(date);
    OCMStub([defaults objectForKey:@"com.rakuten.esd.sdk.properties.analytics.launchInformation.lastLaunchDate"]).andReturn(date);
    OCMStub([defaults stringForKey:@"com.rakuten.esd.sdk.properties.analytics.launchInformation.lastVersion"]).andReturn(@"v100");
    OCMStub([defaults objectForKey:@"com.rakuten.esd.sdk.properties.analytics.launchInformation.lastVersionLaunches"]).andReturn(@(100));
    
    [collector resetToDefaults];
    
    XCTAssertTrue([collector.installLaunchDate isEqualToDate:date]);
    XCTAssertTrue([collector.lastUpdateDate isEqualToDate:date]);
    XCTAssertTrue([collector.lastLaunchDate isEqualToDate:date]);
    XCTAssertTrue([collector.lastVersion isEqualToString:@"v100"]);
    XCTAssertTrue(collector.lastVersionLaunches == 100);
}

@end
