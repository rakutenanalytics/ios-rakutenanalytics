@import XCTest;
#import <RSDKAnalytics/RSDKAnalytics.h>
#import "../RSDKAnalytics/Private/_RSDKAnalyticsHelpers.h"
#import "../RSDKAnalytics/Private/_RSDKAnalyticsExternalCollector.h"
#import "../RSDKAnalytics/Private/_RSDKAnalyticsLaunchCollector.h"
#import "../RSDKAnalytics/Private/_RSDKAnalyticsPrivateEvents.h"
#import <RSDKDeviceInformation/RSDKDeviceInformation.h>
#import <OCMock/OCMock.h>

@interface _RSDKAnalyticsExternalCollector ()
+ (void)trackEvent:(NSString *)eventName;
+ (void)trackEvent:(NSString *)eventName parameters:(NSDictionary RSDKA_GENERIC(NSString *, id) *)parameters;
- (instancetype)initInstance;
@end

@interface _RSDKAnalyticsLaunchCollector ()
@property (nonatomic, nullable, readwrite, copy)    NSDate                  *initialLaunchDate;
@property (nonatomic, nullable, readwrite, copy)    NSDate                  *installLaunchDate;
@property (nonatomic, nullable, readwrite, copy)    NSDate                  *lastUpdateDate;
@property (nonatomic, nullable, readwrite, copy)    NSDate                  *lastLaunchDate;
@property (nonatomic, nullable, readwrite, copy)    NSString                *lastVersion;
@property (nonatomic, readwrite)                    NSUInteger              lastVersionLaunches;
@property (nonatomic, readwrite)                    BOOL                    isInitialLaunch;
@property (nonatomic, readwrite)                    BOOL                    isInstallLaunch;
@property (nonatomic, readwrite)                    BOOL                    isUpdateLaunch;
@property (nonatomic, readwrite)                    RSDKAnalyticsOrigin     origin;
@property (nonatomic, nullable, readwrite)          UIViewController        *lastVisitedPage;
@property (nonatomic, nullable, readwrite)          UIViewController        *currentPage;
@property (nonatomic, nullable, readwrite, copy)    NSString                *pushTrackingIdentifier;

- (instancetype)initInstance;
- (void)resetToDefaults;
@end

@interface RSDKAnalyticsManager ()
@property (nonatomic, nullable, copy) NSString *deviceIdentifier;
@end

@interface LaunchCollectorTests : XCTestCase
@property (nonatomic) _RSDKAnalyticsLaunchCollector *collector;
@end

@implementation LaunchCollectorTests

- (void)setUp
{
    [super setUp];
    
    _RSDKAnalyticsLaunchCollector *collector    = _RSDKAnalyticsLaunchCollector.sharedInstance;
    collector.isInitialLaunch                   = NO;
    collector.isUpdateLaunch                    = NO;
    collector.isInstallLaunch                   = NO;
    collector.pushTrackingIdentifier            = nil;
    
    RSDKAnalyticsManager.sharedInstance.deviceIdentifier = @"deviceIdentifier";
}

- (void)testInitThrows
{
    SEL initSelector = @selector(init);
    
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
    XCTAssertThrowsSpecificNamed([_RSDKAnalyticsLaunchCollector.sharedInstance performSelector:initSelector], NSException, NSInvalidArgumentException);
#pragma clang diagnostic pop
}

- (void) testDealloc
{
    __weak _RSDKAnalyticsLaunchCollector *weakCollector;
    @autoreleasepool
    {
        _RSDKAnalyticsLaunchCollector *collector = [_RSDKAnalyticsLaunchCollector.alloc initInstance];
        weakCollector = collector;
    }
    XCTAssertNil(weakCollector);
}

- (void)testInitialLaunch
{
    _RSDKAnalyticsLaunchCollector *collector = _RSDKAnalyticsLaunchCollector.sharedInstance;
    collector.isInitialLaunch = YES;
    
    id mockManager = OCMPartialMock(RSDKAnalyticsManager.sharedInstance);

    [NSNotificationCenter.defaultCenter postNotificationName:UIApplicationDidFinishLaunchingNotification
                                                      object:nil];
    
    OCMVerify([mockManager process:[OCMArg checkWithBlock:^BOOL(id obj) {
        RSDKAnalyticsEvent *event = obj;
        XCTAssertNotNil(event);
        BOOL expected = ([event.name isEqualToString:RSDKAnalyticsInitialLaunchEventName] ||
                         [event.name isEqualToString:RSDKAnalyticsSessionStartEventName]);
        XCTAssertTrue(expected, @"Unexpected event processed: %@", event.name);
        return expected;
    }]]);
    XCTAssertFalse(collector.isInitialLaunch);
    [mockManager stopMocking];
}

- (void)testInstallLaunch
{
    _RSDKAnalyticsLaunchCollector *collector = _RSDKAnalyticsLaunchCollector.sharedInstance;
    collector.isInstallLaunch = YES;
    
    id mockManager = OCMPartialMock(RSDKAnalyticsManager.sharedInstance);
    
    [NSNotificationCenter.defaultCenter postNotificationName:UIApplicationDidFinishLaunchingNotification
                                                      object:nil];
    
    OCMVerify([mockManager process:[OCMArg checkWithBlock:^BOOL(id obj) {
        RSDKAnalyticsEvent *event = obj;
        XCTAssertNotNil(event);
        BOOL expected = ([event.name isEqualToString:RSDKAnalyticsInstallEventName] ||
                         [event.name isEqualToString:RSDKAnalyticsSessionStartEventName]);
        XCTAssertTrue(expected, @"Unexpected event processed: %@", event.name);
        return expected;
    }]]);
    XCTAssertFalse(collector.isInstallLaunch);
    [mockManager stopMocking];
}

- (void)testUpdateLaunch
{
    _RSDKAnalyticsLaunchCollector *collector = _RSDKAnalyticsLaunchCollector.sharedInstance;
    collector.isUpdateLaunch = YES;
    
    id mockManager = OCMPartialMock(RSDKAnalyticsManager.sharedInstance);
    
    [NSNotificationCenter.defaultCenter postNotificationName:UIApplicationDidFinishLaunchingNotification
                                                      object:nil];
    
    OCMVerify([mockManager process:[OCMArg checkWithBlock:^BOOL(id obj) {
        RSDKAnalyticsEvent *event = obj;
        XCTAssertNotNil(event);
        BOOL expected = ([event.name isEqualToString:RSDKAnalyticsInstallEventName] ||
                         [event.name isEqualToString:RSDKAnalyticsSessionStartEventName] ||
                         [event.name isEqualToString:RSDKAnalyticsApplicationUpdateEventName]);
        XCTAssertTrue(expected, @"Unexpected event processed: %@", event.name);
        return expected;
    }]]);
    XCTAssertFalse(collector.isUpdateLaunch);
    [mockManager stopMocking];
}

- (void)testResume
{
    id mockManager = OCMPartialMock(RSDKAnalyticsManager.sharedInstance);
    
    [NSNotificationCenter.defaultCenter postNotificationName:UIApplicationWillEnterForegroundNotification
                                                      object:nil];
    
    OCMVerify([mockManager process:[OCMArg checkWithBlock:^BOOL(id obj) {
        RSDKAnalyticsEvent *event = obj;
        XCTAssertNotNil(event);
        BOOL expected = ([event.name isEqualToString:RSDKAnalyticsSessionStartEventName]);
        XCTAssertTrue(expected, @"Unexpected event processed: %@", event.name);
        return expected;
    }]]);
    [mockManager stopMocking];
}

- (void)testSuspend
{
    id mockManager = OCMPartialMock(RSDKAnalyticsManager.sharedInstance);
    
    [NSNotificationCenter.defaultCenter postNotificationName:UIApplicationDidEnterBackgroundNotification
                                                      object:nil];
    
    OCMVerify([mockManager process:[OCMArg checkWithBlock:^BOOL(id obj) {
        RSDKAnalyticsEvent *event = obj;
        XCTAssertNotNil(event);
        BOOL expected = ([event.name isEqualToString:RSDKAnalyticsSessionEndEventName]);
        XCTAssertTrue(expected, @"Unexpected event processed: %@", event.name);
        return expected;
    }]]);
    [mockManager stopMocking];
}

- (void)testPresentTrackedVC
{
    _RSDKAnalyticsLaunchCollector *collector = _RSDKAnalyticsLaunchCollector.sharedInstance;
    collector.origin = RSDKAnalyticsPushOrigin; // to check origin result against
    
    UIViewController *vc = UIViewController.new;
    
    id mockManager = OCMPartialMock(RSDKAnalyticsManager.sharedInstance);
    
    [collector didPresentViewController:vc];
    
    OCMVerify([mockManager process:[OCMArg checkWithBlock:^BOOL(id obj) {
        RSDKAnalyticsEvent *event = obj;
        XCTAssertNotNil(event);
        BOOL expected = ([event.name isEqualToString:RSDKAnalyticsPageVisitEventName]);
        XCTAssertTrue(expected, @"Unexpected event processed: %@", event.name);
        return expected;
    }]]);
    XCTAssertTrue(collector.origin == RSDKAnalyticsInternalOrigin);
    [mockManager stopMocking];
}

- (void)testPresentUntrackedVC
{
    _RSDKAnalyticsLaunchCollector *collector = _RSDKAnalyticsLaunchCollector.sharedInstance;
    collector.origin = RSDKAnalyticsPushOrigin; // to check origin result against
    
    UINavigationController *vc = UINavigationController.new;
    
    id mockManager = OCMPartialMock(RSDKAnalyticsManager.sharedInstance);
    
    [collector didPresentViewController:vc];
    
    OCMReject([mockManager process:[OCMArg isKindOfClass:RSDKAnalyticsEvent.class]]);
    
    XCTAssertTrue(collector.origin == RSDKAnalyticsPushOrigin);
    [mockManager stopMocking];
}

- (void)assertPushWithTrackingIdentifier:(NSString *)trackingIdentifier payload:(NSDictionary *)payload
{
    _RSDKAnalyticsLaunchCollector *collector = _RSDKAnalyticsLaunchCollector.sharedInstance;
    
    id mockManager = OCMPartialMock(RSDKAnalyticsManager.sharedInstance);
    
    [collector processPushNotificationPayload:payload userAction:nil userText:nil];
    
    OCMVerify([mockManager process:[OCMArg checkWithBlock:^BOOL(id obj) {
        RSDKAnalyticsEvent *event = obj;
        XCTAssertNotNil(event);
        BOOL expected = ([event.name isEqualToString:RSDKAnalyticsPushNotificationEventName]);
        XCTAssertTrue(expected, @"Unexpected event processed: %@", event.name);
        XCTAssertTrue([event.parameters[RSDKAnalyticPushNotificationTrackingIdentifierParameter] hasPrefix:trackingIdentifier]);
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
    _RSDKAnalyticsLaunchCollector *collector = _RSDKAnalyticsLaunchCollector.sharedInstance;
    
    id mockManager = OCMPartialMock(RSDKAnalyticsManager.sharedInstance);
    
    [collector processPushNotificationPayload:@{@"foo":@"bar"} userAction:nil userText:nil];
    
    OCMReject([mockManager process:[OCMArg isKindOfClass:RSDKAnalyticsEvent.class]]);
    
    XCTAssertNil(collector.pushTrackingIdentifier);
    [mockManager stopMocking];
}

- (void)testResetToDefaults
{
    _RSDKAnalyticsLaunchCollector *collector = _RSDKAnalyticsLaunchCollector.sharedInstance;
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
