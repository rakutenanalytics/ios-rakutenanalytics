/*
 * © Rakuten, Inc.
 * authors: "Rakuten Ecosystem Mobile" <ecosystem-mobile@mail.rakuten.com>
 */
@import XCTest;
#if __has_include(<UserNotifications/UserNotifications.h>)
#import <UserNotifications/UserNotifications.h>
#import <RSDKAnalytics/RSDKAnalytics.h>
#import <OCMock/OCMock.h>
#import "../RSDKAnalytics/Private/_RSDKAnalyticsLaunchCollector.h"

@interface _RSDKAnalyticsLaunchCollector()
@property (nonatomic) RSDKAnalyticsOrigin origin;
@end

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

- (void)testUNSetDelegateMethodReplaced
{
    UNUserNotificationCenter *center = UNUserNotificationCenter.currentNotificationCenter;
    XCTAssertTrue([center respondsToSelector:@selector(_r_autotrack_setUserNotificationCenterDelegate:)]);
    XCTAssertTrue([center respondsToSelector:@selector(setDelegate:)]);
}

- (void)testUNSetDelegateMethodSwizzlesDidReceiveNotification
{
    UNUserNotificationCenter *center = UNUserNotificationCenter.currentNotificationCenter;
    UNDelegate *delegate = UNDelegate.new;
    center.delegate = delegate;
    XCTAssertTrue([center.delegate respondsToSelector:@selector(_r_autotrack_userNotificationCenter:didReceiveNotificationResponse:withCompletionHandler:)]);
    XCTAssertTrue([center.delegate respondsToSelector:@selector(userNotificationCenter:didReceiveNotificationResponse:withCompletionHandler:)]);
}

- (void)testDidReceiveUNNotification
{
    UNUserNotificationCenter *center = UNUserNotificationCenter.currentNotificationCenter;
    UNDelegate *delegate = UNDelegate.new;
    center.delegate = delegate;
    
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
    
    id mockManager = OCMPartialMock(RSDKAnalyticsManager.sharedInstance);
    
    [center.delegate userNotificationCenter:center didReceiveNotificationResponse:response withCompletionHandler:^{ /* empty */ }];
    
    OCMVerify([mockManager process:[OCMArg checkWithBlock:^BOOL(id obj) {
        RSDKAnalyticsEvent *event = obj;
        XCTAssertNotNil(event);
        BOOL expected = ([event.name isEqualToString:RSDKAnalyticsPushNotificationEventName]);
        XCTAssertTrue(expected, @"Unexpected event processed: %@", event.name);
        XCTAssertTrue([event.parameters[RSDKAnalyticPushNotificationTrackingIdentifierParameter] isEqualToString:@"rid:1234abcd"]);
        return expected;
    }]]);
    
    [mockManager stopMocking];
}

@end

#pragma clang diagnostic pop

#endif
