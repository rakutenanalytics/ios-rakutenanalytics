@import XCTest;
#import <RAnalytics/RAnalytics.h>
#import "../RAnalytics/Util/Private/_RAnalyticsHelpers.h"
#import "../RAnalytics/Core/Private/_RAnalyticsExternalCollector.h"
#import "../RAnalytics/Core/Private/_RAnalyticsLaunchCollector.h"
#import "../RAnalytics/Core/Private/_RAnalyticsPrivateEvents.h"
#import <OCMock/OCMock.h>

@interface _RAnalyticsExternalCollector ()
+ (void)trackEvent:(NSString *)eventName;
+ (void)trackEvent:(NSString *)eventName parameters:(NSDictionary RSDKA_GENERIC(NSString *, id) *)parameters;
- (instancetype)initInstance;
@end

@interface _RAnalyticsLaunchCollector ()
@property (nonatomic, nullable, readwrite) UIViewController *currentPage;
@end

@interface RAnalyticsManager ()
@property (nonatomic, nullable, copy) NSString *deviceIdentifier;
@end

@interface ExternalCollectorTests : XCTestCase
@end

@implementation ExternalCollectorTests

- (void)setUp
{
    [super setUp];
    RAnalyticsManager.sharedInstance.deviceIdentifier = @"deviceIdentifier";
}

- (void)testInitThrows
{
    XCTAssertThrowsSpecificNamed([_RAnalyticsExternalCollector.alloc init], NSException, NSInvalidArgumentException);
}

/* Note:
 * The ExternalCollector singleton is initialised and observers are added when the AnalyticsManager's
 * `load` class method is called therefore it isn't possible to 'spy' on NSNotification's
 * addObserver method because by the time the tests are executed the observers have already been added.
 *
 * The collector tests below implicitly test that the observers have been added.
 */

- (void)testLoginCollector
{
    id mockCollector = OCMClassMock(_RAnalyticsExternalCollector.class);
    
    NSString *trackingIdentifier = @"trackingIdentifier";
    
    for (NSString *loginMethod in @[@"password", @"one_tap", @"other"])
    {
        [NSNotificationCenter.defaultCenter postNotificationName:[NSString stringWithFormat:@"com.rakuten.esd.sdk.events.login.%@", loginMethod]
                                                          object:trackingIdentifier];
        
        OCMVerify([mockCollector trackEvent:RAnalyticsLoginEventName]);
        XCTAssertTrue([_RAnalyticsExternalCollector.sharedInstance.trackingIdentifier isEqualToString:trackingIdentifier]);
    }
    
    [mockCollector stopMocking];
}

- (void)testLogoutCollector
{
    id mockCollector = OCMClassMock(_RAnalyticsExternalCollector.class);
    
    for (NSString *logoutMethod in @[@"local", @"global"])
    {
        [NSNotificationCenter.defaultCenter postNotificationName:[NSString stringWithFormat:@"com.rakuten.esd.sdk.events.logout.%@", logoutMethod]
                                                          object:nil];
        
        OCMVerify([mockCollector trackEvent:RAnalyticsLogoutEventName parameters:[OCMArg checkWithBlock:^BOOL(id obj) {
            XCTAssertNotNil(obj);
            return obj;
        }]]);
        XCTAssertNil(_RAnalyticsExternalCollector.sharedInstance.trackingIdentifier);
    }
    
    [mockCollector stopMocking];
}

- (void)testDiscoverCollectorEventNoParams
{
    NSDictionary *mapping = @{
                              @"visitPreview"           : _RAnalyticsPrivateEventDiscoverPreviewVisit,
                              @"tapShowMore"            : _RAnalyticsPrivateEventDiscoverPreviewShowMore,
                              @"visitPage"              : _RAnalyticsPrivateEventDiscoverPageVisit
                              };
    
    id mockCollector = OCMClassMock(_RAnalyticsExternalCollector.class);
    
    for (NSString *notification in mapping)
    {
        [NSNotificationCenter.defaultCenter postNotificationName:[NSString stringWithFormat:@"com.rakuten.esd.sdk.events.discover.%@", notification]
                                                          object:nil];
        
        OCMVerify([mockCollector trackEvent:mapping[notification] parameters:[OCMArg isNil]]);
    }
    [mockCollector stopMocking];
}

- (void)testDiscoverCollectorEventWithIdentifier
{
    NSDictionary *mapping = @{
                              @"tapPreview"             : _RAnalyticsPrivateEventDiscoverPreviewTap,
                              @"tapPage"                : _RAnalyticsPrivateEventDiscoverPageTap
                              };
    
    NSString *identifier = @"12345";
    
    id mockCollector = OCMClassMock(_RAnalyticsExternalCollector.class);
    
    for (NSString *notification in mapping)
    {
        [NSNotificationCenter.defaultCenter postNotificationName:[NSString stringWithFormat:@"com.rakuten.esd.sdk.events.discover.%@", notification]
                                                          object:identifier];
        
        OCMVerify([mockCollector trackEvent:mapping[notification] parameters:[OCMArg checkWithBlock:^BOOL(id obj) {
            
            XCTAssertTrue([obj isKindOfClass:NSDictionary.class]);
            XCTAssertTrue([obj[@"prApp"] isEqualToString:identifier]);
            return obj;
        }]]);
    }
    [mockCollector stopMocking];
}

- (void)testDiscoverCollectorEventWithIdentifierAndRedirect
{
    NSDictionary *mapping = @{
                              @"redirectPreview"        : _RAnalyticsPrivateEventDiscoverPreviewRedirect,
                              @"redirectPage"           : _RAnalyticsPrivateEventDiscoverPageRedirect
                              };
    
    NSString *identifier = @"12345";
    NSString *url = @"http://www.rakuten.co.jp";
    
    id mockCollector = OCMClassMock(_RAnalyticsExternalCollector.class);
    
    for (NSString *notification in mapping)
    {
        [NSNotificationCenter.defaultCenter postNotificationName:[NSString stringWithFormat:@"com.rakuten.esd.sdk.events.discover.%@", notification]
                                                          object:@{@"identifier":identifier,@"url":url}];
        
        OCMVerify([mockCollector trackEvent:mapping[notification] parameters:[OCMArg checkWithBlock:^BOOL(id obj) {
            
            XCTAssertTrue([obj isKindOfClass:NSDictionary.class]);
            XCTAssertTrue([obj[@"prApp"] isEqualToString:identifier]);
            XCTAssertTrue([obj[@"prStoreUrl"] isEqualToString:url]);
            return obj;
        }]]);
    }
    [mockCollector stopMocking];
}

- (void)testSSODialogCollector
{
    id mockCollector = OCMClassMock(_RAnalyticsExternalCollector.class);
    Class aClass = [UIViewController class];
    
    for (NSString *event in @[@"help", @"privacypolicy", @"forgotpassword", @"register"])
    {
        NSString *eventToVerify = [NSString stringWithFormat:@"%@.%@",aClass,event];
        [NSNotificationCenter.defaultCenter postNotificationName:@"com.rakuten.esd.sdk.events.ssodialog"
                                                          object:[NSString stringWithFormat:@"%@.%@",aClass,event]];
        
        OCMVerify([mockCollector trackEvent:RAnalyticsPageVisitEventName parameters:@{@"page_id":eventToVerify}]);
    }
    [mockCollector stopMocking];
}

- (void)testCredentialsCollector
{
    id mockCollector = OCMClassMock(_RAnalyticsExternalCollector.class);
    
    for (NSString *notification in
         @[@"ssocredentialfound",
           @"logincredentialfound"])
    {
        NSString *eventToVerify = [NSString stringWithFormat:@"%@.%@", @"com.rakuten.esd.sdk.events", notification];
        [NSNotificationCenter.defaultCenter postNotificationName:eventToVerify
                                                          object:nil];
        
        OCMVerify([mockCollector trackEvent:OCMOCK_ANY parameters:OCMOCK_ANY]);
    }
}

- (void)testCustomEventCollector
{
    id mockCollector = OCMClassMock(_RAnalyticsExternalCollector.class);
    
    NSDictionary *expected = @{@"eventName":@"blah",@"eventData":@{@"foo":@"bar"}};
    [NSNotificationCenter.defaultCenter postNotificationName:@"com.rakuten.esd.sdk.events.custom" object:expected];
    
    OCMVerify([mockCollector trackEvent:RAnalyticsCustomEventName parameters:expected]);
}

@end
