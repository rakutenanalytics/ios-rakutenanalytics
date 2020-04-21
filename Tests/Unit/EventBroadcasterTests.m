@import XCTest;
#import <RAnalyticsBroadcast/RAnalyticsBroadcast.h>
#import <RAnalytics/RAnalytics.h>
#import "../../RAnalytics/Core/Private/_RAnalyticsExternalCollector.h"
#import <OCMock/OCMock.h>

@interface _RAnalyticsExternalCollector ()
+ (void)trackEvent:(NSString *)eventName parameters:(NSDictionary<NSString *, id> *)parameters;
@end

@interface EventBroadcasterTests : XCTestCase

@end

@implementation EventBroadcasterTests

- (void)testSendEvent
{
    id mockCollector = OCMClassMock(_RAnalyticsExternalCollector.class);
    
    NSString *name = @"blah";
    NSDictionary *object = @{@"foo":@"bar"};
    NSDictionary *expected = @{@"eventName":name, @"eventData":object};
    [RABEventBroadcaster sendEventName:name dataObject:object];
    
    OCMVerify([mockCollector trackEvent:RAnalyticsCustomEventName parameters:expected]);
}

- (void)testSendEventNoData
{
    id mockCollector = OCMClassMock(_RAnalyticsExternalCollector.class);
    
    NSString *name = @"blah";
    NSDictionary *expected = @{@"eventName":name};
    [RABEventBroadcaster sendEventName:name dataObject:nil];
    
    OCMVerify([mockCollector trackEvent:RAnalyticsCustomEventName parameters:expected]);
}

@end
