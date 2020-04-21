#import "TrackerTests.h"
#import <OCMock/OCMock.h>
#import <OHHTTPStubs/OHHTTPStubs.h>

#import "../../RAnalytics/Util/Private/_RAnalyticsHelpers.h"
#import "../../RAnalytics/Core/Private/_RAnalyticsDatabase.h"

@interface RAnalyticsState ()
@property (nonatomic, readwrite, copy)              NSString                    *sessionIdentifier;
@property (nonatomic, readwrite, copy)              NSString                    *deviceIdentifier;
@property (nonatomic, readwrite, copy)              NSString                    *currentVersion;
@property (nonatomic, nullable, readwrite, copy)    CLLocation                  *lastKnownLocation;
@property (nonatomic, nullable, readwrite, copy)    NSString                    *advertisingIdentifier;
@property (nonatomic, nullable, readwrite, copy)    NSDate                      *sessionStartDate;
@property (nonatomic, readwrite, getter=isLoggedIn) BOOL                         loggedIn;
@property (nonatomic, nullable, readwrite, copy)    NSString                    *userIdentifier;
@property (nonatomic, readwrite)                    RAnalyticsLoginMethod     loginMethod;
@property (nonatomic, readwrite)                    RAnalyticsOrigin          origin;
@property (nonatomic, nullable, readwrite, copy)    NSString                    *lastVersion;
@property (nonatomic)                               NSUInteger                   lastVersionLaunches;
@property (nonatomic, nullable, readwrite, copy)    NSDate                      *initialLaunchDate;
@property (nonatomic, nullable, readwrite, copy)    NSDate                      *installLaunchDate;
@property (nonatomic, nullable, readwrite, copy)    NSDate                      *lastLaunchDate;
@property (nonatomic, nullable, readwrite, copy)    NSDate                      *lastUpdateDate;
@property (nonatomic, nullable, readwrite)          UIViewController            *currentPage;
@end

@interface RAnalyticsManager ()
@property(nonatomic, strong) NSMutableSet<id<RAnalyticsTracker>> *trackers;
@end

@interface RAnalyticsSender ()
@property (nonatomic) NSTimeInterval            uploadTimerInterval;
@property (nonatomic) NSTimer                  *uploadTimer;
@end

@implementation TrackerTests

- (void)setUp
{
    [super setUp];
    _mocks = NSMutableArray.new;

    CLLocation *location = [[CLLocation alloc] initWithLatitude:-56.6462520 longitude:-36.6462520];

    CurrentPage *currentPage = [CurrentPage.alloc init];
    currentPage.view.frame = CGRectMake(0, 0, 200, 200);

    NSDateComponents *dateComponents = [NSDateComponents.alloc init];
    dateComponents.calendar = [NSCalendar calendarWithIdentifier:NSCalendarIdentifierGregorian];
    dateComponents.day    = 10;
    dateComponents.month  = 6;
    dateComponents.year   = 2016;
    dateComponents.hour   = 9;
    dateComponents.minute = 15;
    dateComponents.second = 30;
    NSDate *sessionStartDate = dateComponents.date;

    dateComponents.day = 1;
    NSDate *initialLaunchDate = dateComponents.date;

    dateComponents.day = 3;
    NSDate *lastLaunchDate = dateComponents.date;

    dateComponents.day = 2;
    NSDate *lastUpdateDate = dateComponents.date;

    _defaultState = [RAnalyticsState.alloc initWithSessionIdentifier:@"CA7A88AB-82FE-40C9-A836-B1B3455DECAB"
                                                       deviceIdentifier:@"deviceId"];
    _defaultState.advertisingIdentifier = @"adId";
    _defaultState.lastKnownLocation     = location;
    _defaultState.sessionStartDate      = sessionStartDate;
    _defaultState.userIdentifier        = @"userId";
    _defaultState.loginMethod           = RAnalyticsOneTapLoginLoginMethod;
    _defaultState.origin                = RAnalyticsInternalOrigin;
    _defaultState.lastVersion           = @"1.0";
    _defaultState.initialLaunchDate     = initialLaunchDate;
    _defaultState.installLaunchDate     = [initialLaunchDate dateByAddingTimeInterval:-10];
    _defaultState.lastLaunchDate        = lastLaunchDate;
    _defaultState.lastUpdateDate        = lastUpdateDate;
    _defaultState.lastVersionLaunches   = 10;
    _defaultState.currentPage           = currentPage;

    _defaultEvent = [RAnalyticsEvent.alloc initWithName:[_RATEventPrefix stringByAppendingString:@"defaultEvent"]
                                                parameters:@{@"param1": @"value1"}];

    // Mock the database
    _database = MockedDatabase.new;
    
    id dbMock = OCMClassMock(_RAnalyticsDatabase.class);
    [self addMock:dbMock];
    
    OCMStub([dbMock databaseWithConnection:[OCMArg anyPointer]]).andReturn(_database);

    // Mock the SDKTracker singleton so that each test gets a fresh one
    _tracker = [self testedTracker];
    if (_tracker)
    {
        id trackerMock = OCMClassMock(_tracker.class);
        [[[[trackerMock stub] classMethod] andReturn:_tracker] sharedInstance];
        [self addMock:trackerMock];
    }
}

- (void)tearDown {
    [OHHTTPStubs removeAllStubs];
    [_mocks enumerateObjectsUsingBlock:^(id mock, __unused NSUInteger idx, __unused BOOL *stop) {
        [mock stopMocking];
    }];

    _mocks    = nil;
    _tracker  = nil;
    _database = nil;
    [super tearDown];
}

#pragma mark Helpers

- (id<RAnalyticsTracker>)testedTracker
{
    return nil;
}

- (void)invalidateTimerOfSender:(RAnalyticsSender *)sender
{
    [sender.uploadTimer invalidate];
    sender.uploadTimer = nil;
}

- (void)addMock:(id)mock
{
    [_mocks addObject:mock];
}

- (NSDictionary *)assertProcessEvent:(RAnalyticsEvent *)event
                               state:(RAnalyticsState *)state
                          expectType:(NSString *)etype
{
    XCTAssertNotNil(event);
    XCTAssert([_tracker processEvent:event state:state]);
    id payload = _database.latestAddedJSON;
    XCTAssertNotNil(payload);
    if (etype) XCTAssertEqualObjects(payload[@"etype"], etype);
    return payload;
}

- (void)stubRATResponseWithStatusCode:(int)status completionHandler:(void (^)(void))completion
{
    [OHHTTPStubs stubRequestsPassingTest:^BOOL(NSURLRequest *request) {
        return [request.URL.absoluteString isEqualToString:RAnalyticsRATTracker.endpointAddress.absoluteString];
    } withStubResponse:^OHHTTPStubsResponse * _Nonnull(__unused NSURLRequest * _Nonnull request) {
        dispatch_async(dispatch_get_main_queue(), ^{

            if (completion) completion();
        });

        return [[OHHTTPStubsResponse responseWithData:[NSData data] statusCode:status headers:nil] responseTime:2.0];
    }];
}

@end

