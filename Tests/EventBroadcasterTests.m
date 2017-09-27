/*
 * © Rakuten, Inc.
 * authors: "Rakuten Ecosystem Mobile" <ecosystem-mobile@mail.rakuten.com>
 */
@import XCTest;
#import <RAnalyticsBroadcast/RAnalyticsBroadcast.h>
#import <RSDKAnalytics/RSDKAnalytics.h>
#import "../RSDKAnalytics/Private/_RSDKAnalyticsExternalCollector.h"
#import <OCMock/OCMock.h>

@interface _RSDKAnalyticsExternalCollector ()
+ (void)trackEvent:(NSString *)eventName parameters:(NSDictionary RSDKA_GENERIC(NSString *, id) *)parameters;
@end

@interface EventBroadcasterTests : XCTestCase

@end

@implementation EventBroadcasterTests

- (void)testSendEvent
{
    id mockCollector = OCMClassMock(_RSDKAnalyticsExternalCollector.class);
    
    NSString *name = @"blah";
    NSDictionary *object = @{@"foo":@"bar"};
    NSDictionary *expected = @{@"eventName":name, @"eventData":object};
    [RABEventBroadcaster sendEventName:name dataObject:object];
    
    OCMVerify([mockCollector trackEvent:RSDKAnalyticsCustomEventName parameters:expected]);
}

- (void)testSendEventNoData
{
    id mockCollector = OCMClassMock(_RSDKAnalyticsExternalCollector.class);
    
    NSString *name = @"blah";
    NSDictionary *expected = @{@"eventName":name};
    [RABEventBroadcaster sendEventName:name dataObject:nil];
    
    OCMVerify([mockCollector trackEvent:RSDKAnalyticsCustomEventName parameters:expected]);
}

@end
