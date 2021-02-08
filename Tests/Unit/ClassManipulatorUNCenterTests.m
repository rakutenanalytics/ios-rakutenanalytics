@import XCTest;
#if __has_include(<UserNotifications/UserNotifications.h>)
#import <UserNotifications/UserNotifications.h>
#import <RAnalytics/RAnalytics.h>
#import <OCMock/OCMock.h>

@interface UNDelegate : NSObject <UNUserNotificationCenterDelegate>
@end

@implementation UNDelegate
- (void)userNotificationCenter:(UNUserNotificationCenter *)center didReceiveNotificationResponse:(UNNotificationResponse *)response withCompletionHandler:(void(^)(void))completionHandler
{
    completionHandler();
}
@end

@interface ClassManipulatorUNCenterTests : XCTestCase
@property (nonatomic, copy) NSURL *url;
@end

@implementation ClassManipulatorUNCenterTests

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wundeclared-selector"
#pragma clang diagnostic ignored "-Warc-repeated-use-of-weak"

- (void)testUNSetDelegateMethodReplaced
{
    UNUserNotificationCenter *center = UNUserNotificationCenter.currentNotificationCenter;
    XCTAssertTrue([center respondsToSelector:@selector(r_autotrack_setUserNotificationCenterDelegate:)]);
    XCTAssertTrue([center respondsToSelector:@selector(setDelegate:)]);
}

- (void)testUNSetDelegateMethodSwizzlesDidReceiveNotification
{
    UNUserNotificationCenter *center = UNUserNotificationCenter.currentNotificationCenter;
    UNDelegate *delegate = UNDelegate.new;
    center.delegate = delegate;
    XCTAssertTrue([center.delegate respondsToSelector:@selector(r_autotrack_userNotificationCenter:didReceiveNotificationResponse:withCompletionHandler:)]);
    XCTAssertTrue([center.delegate respondsToSelector:@selector(userNotificationCenter:didReceiveNotificationResponse:withCompletionHandler:)]);
}

- (void)testUNSetDelegateMethodSwizzlesDidReceiveNotification_setToNil
{
    UNUserNotificationCenter *center = UNUserNotificationCenter.currentNotificationCenter;
    UNDelegate *delegate = UNDelegate.new;
    center.delegate = delegate;
    XCTAssertTrue([center.delegate respondsToSelector:@selector(r_autotrack_userNotificationCenter:didReceiveNotificationResponse:withCompletionHandler:)]);
    XCTAssertTrue([center.delegate respondsToSelector:@selector(userNotificationCenter:didReceiveNotificationResponse:withCompletionHandler:)]);

    center.delegate = nil;
    XCTAssertNil(center.delegate);
    XCTAssertTrue([delegate respondsToSelector:@selector(r_autotrack_userNotificationCenter:didReceiveNotificationResponse:withCompletionHandler:)]);
    XCTAssertTrue([delegate respondsToSelector:@selector(userNotificationCenter:didReceiveNotificationResponse:withCompletionHandler:)]);
}

- (void)testDidReceiveUNNotification
{
    UNUserNotificationCenter *center = UNUserNotificationCenter.currentNotificationCenter;
    UNDelegate *delegate = UNDelegate.new;
    center.delegate = delegate;
    
    UNTextInputNotificationResponse *response = [self _createTestResponse];
     
    id mockManager = OCMPartialMock(RAnalyticsManager.sharedInstance);
    
    [center.delegate userNotificationCenter:center didReceiveNotificationResponse:response withCompletionHandler:^{ /* empty */ }];
    
    OCMVerify([mockManager process:[OCMArg checkWithBlock:^BOOL(id obj) {
        RAnalyticsEvent *event = obj;
        XCTAssertNotNil(event);
        BOOL expected = ([event.name isEqualToString:RAnalyticsPushNotificationEventName]);
        XCTAssertTrue(expected, @"Unexpected event processed: %@", event.name);
        XCTAssertTrue([event.parameters[RAnalyticsPushNotificationTrackingIdentifierParameter] isEqualToString:@"rid:1234abcd"]);
        return expected;
    }]]);
    
    [mockManager stopMocking];
}

- (void)testDidReceiveUNNotification_shouldNotProcessEvent_ifTrackingIdentifierIsAlreadyInAppGroup
{
    UNUserNotificationCenter *center = UNUserNotificationCenter.currentNotificationCenter;
    UNDelegate *delegate = UNDelegate.new;
    center.delegate = delegate;
    
    UNTextInputNotificationResponse* response = [self _createTestResponse];
    
    id trackingMock = OCMClassMock([RAnalyticsPushTrackingUtility class]);
    OCMStub([trackingMock analyticsEventHasBeenSentWith: [OCMArg any]]).andReturn(true);
     
    id mockManager = OCMPartialMock(RAnalyticsManager.sharedInstance);
    XCTestExpectation* expectation = [XCTestExpectation.new initWithDescription:@"should not be called"];
    [expectation setInverted:true];
    
    OCMStub([mockManager process:[OCMArg any]]).andDo(^(NSInvocation *invocation){ [expectation fulfill]; });
    
    [center.delegate userNotificationCenter:center didReceiveNotificationResponse:response withCompletionHandler:^{ /* empty */ }];
    
    [self waitForExpectations:@[expectation] timeout:1];

    [mockManager stopMocking];
    [trackingMock stopMocking];
}

-(UNTextInputNotificationResponse*) _createTestResponse {
    UNMutableNotificationContent *content = UNMutableNotificationContent.new;
    content.title = @"UN notification";
    content.body = @"body";
    content.userInfo = @{@"rid":@"1234abcd",
                         @"nid":@"abcd1234",
                         @"aps":@{@"alert":@"a push alert"}};
    
    UNPushNotificationTrigger *trigger = [UNPushNotificationTrigger alloc]; // init is marked unavailable
    
    UNNotificationRequest *request = [UNNotificationRequest requestWithIdentifier:@"id_notification" content:content trigger:trigger];
    
    UNNotification *notification = UNNotification.new;
    [notification setValue:request forKey:@"request"];
    
    UNTextInputNotificationResponse *response = UNTextInputNotificationResponse.new;
    [response setValue:@"Some user text" forKey:@"userText"];
    [response setValue:UNNotificationDefaultActionIdentifier forKey:@"actionIdentifier"];
    [response setValue:notification forKey:@"notification"];
    return response;
}

@end

#pragma clang diagnostic pop

#endif
