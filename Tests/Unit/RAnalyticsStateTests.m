@import XCTest;
#import <RAnalytics/RAnalytics-Swift.h>
#import <OCMock/OCMock.h>
@import CoreLocation.CLLocation;

@interface StateTests : XCTestCase
@property (nonatomic) NSCalendar *calendar;
@end

@implementation StateTests

- (void)setUp
{
    [super setUp];
    _calendar = [NSCalendar.alloc initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
}

- (RAnalyticsState *)defaultState
{
    CLLocation *location = [[CLLocation alloc] initWithLatitude:-56.6462520 longitude:-36.6462520];
    UIViewController *currentPage = [UIViewController.alloc init];
    currentPage.view.frame = CGRectMake(0, 0, 100, 100);

    NSDateComponents *dateComponents = [NSDateComponents.alloc init];
    [dateComponents setDay:10];
    [dateComponents setMonth:6];
    [dateComponents setYear:2016];
    [dateComponents setHour:9];
    [dateComponents setMinute:15];
    [dateComponents setSecond:30];
    NSDate *sessionStartDate = [_calendar dateFromComponents:dateComponents];

    [dateComponents setDay:10];
    [dateComponents setMonth:6];
    [dateComponents setYear:2016];
    NSDate *initialLaunchDate = [_calendar dateFromComponents:dateComponents];

    [dateComponents setDay:12];
    [dateComponents setMonth:7];
    [dateComponents setYear:2016];
    NSDate *lastLaunchDate = [_calendar dateFromComponents:dateComponents];

    [dateComponents setDay:11];
    [dateComponents setMonth:7];
    [dateComponents setYear:2016];
    NSDate *lastUpdateDate = [_calendar dateFromComponents:dateComponents];

    RAnalyticsState *state = [RAnalyticsState.alloc initWithSessionIdentifier:@"CA7A88AB-82FE-40C9-A836-B1B3455DECAB" deviceIdentifier:@"deviceId"];
    state.advertisingIdentifier = @"adId";
    state.lastKnownLocation = location;
    state.sessionStartDate = sessionStartDate;
    state.userIdentifier = @"userId";
    state.loginMethod = RAnalyticsOneTapLoginLoginMethod;
    state.origin = RAnalyticsInternalOrigin;
    state.lastVersion = @"1.0";
    state.initialLaunchDate = initialLaunchDate;
    state.lastLaunchDate = lastLaunchDate;
    state.lastUpdateDate = lastUpdateDate;
    state.lastVersionLaunches = 10;
    return state;
}

- (void)testAnalyticsStateWithoutSetting
{
    id mockBundle = [OCMockObject niceMockForClass:[NSBundle class]];
    NSBundle *correctMainBundle = [NSBundle bundleForClass:self.class];
    [[[[mockBundle stub] classMethod] andReturn:correctMainBundle] mainBundle];

    RAnalyticsState *state = [RAnalyticsState.alloc initWithSessionIdentifier:@"CA7A88AB-82FE-40C9-A836-B1B3455DECAB" deviceIdentifier:@"deviceId"];
    XCTAssertNotNil(state);
    XCTAssertNotNil(state.sessionIdentifier);
    XCTAssertTrue([state.sessionIdentifier isEqualToString:@"CA7A88AB-82FE-40C9-A836-B1B3455DECAB"]);

    XCTAssertNotNil(state.deviceIdentifier);
    XCTAssertTrue([state.deviceIdentifier isEqualToString:@"deviceId"]);

    XCTAssertNotNil(state.currentVersion);
    XCTAssertTrue([state.currentVersion isEqualToString:@"2.0"]);

    XCTAssertNil(state.advertisingIdentifier);
    XCTAssertNil(state.lastKnownLocation);
    XCTAssertNil(state.sessionStartDate);
    XCTAssertTrue(!state.loggedIn);
    XCTAssertNil(state.userIdentifier);
    XCTAssertNil(state.lastVersion);
    XCTAssertNil(state.initialLaunchDate);
    XCTAssertNil(state.lastLaunchDate);
    XCTAssertNil(state.lastUpdateDate);
    XCTAssertTrue(state.lastVersionLaunches == 0);
    XCTAssert(state.loginMethod == RAnalyticsOtherLoginMethod);
    XCTAssert(state.origin == RAnalyticsInternalOrigin);
}

- (void)testAnalyticsStateWithSetting
{
    id mockBundle = [OCMockObject niceMockForClass:[NSBundle class]];
    NSBundle *correctMainBundle = [NSBundle bundleForClass:self.class];
    [[[[mockBundle stub] classMethod] andReturn:correctMainBundle] mainBundle];

    RAnalyticsState *state = [self defaultState];

    XCTAssertNotNil(state);
    XCTAssertNotNil(state.sessionIdentifier);
    XCTAssertTrue([state.sessionIdentifier isEqualToString:@"CA7A88AB-82FE-40C9-A836-B1B3455DECAB"]);

    XCTAssertNotNil(state.deviceIdentifier);
    XCTAssertTrue([state.deviceIdentifier isEqualToString:@"deviceId"]);

    XCTAssertNotNil(state.currentVersion);
    XCTAssertTrue([state.currentVersion isEqualToString:@"2.0"]);

    XCTAssertNotNil(state.advertisingIdentifier);
    XCTAssertTrue([state.advertisingIdentifier isEqualToString:@"adId"]);

    XCTAssertNotNil(state.lastKnownLocation);
    XCTAssertTrue(state.lastKnownLocation.coordinate.latitude == -56.6462520);
    XCTAssertTrue(state.lastKnownLocation.coordinate.longitude == -36.6462520);

    XCTAssertTrue(state.loginMethod == RAnalyticsOneTapLoginLoginMethod);
    XCTAssertTrue(state.origin == RAnalyticsInternalOrigin);

    XCTAssertNotNil(state.sessionStartDate);
    NSDateComponents *components = [_calendar components:NSCalendarUnitDay | NSCalendarUnitMonth | NSCalendarUnitYear | NSCalendarUnitHour | NSCalendarUnitMinute | NSCalendarUnitSecond fromDate:state.sessionStartDate];
    NSInteger year = [components year];
    NSInteger month = [components month];
    NSInteger day = [components day];
    NSInteger hour = [components hour];
    NSInteger minute = [components minute];
    NSInteger second = [components second];
    XCTAssertTrue(year == 2016);
    XCTAssertTrue(month == 6);
    XCTAssertTrue(day == 10);
    XCTAssertTrue(hour == 9);
    XCTAssertTrue(minute == 15);
    XCTAssertTrue(second == 30);

    XCTAssertNotNil(state.lastVersion);
    XCTAssertTrue([state.lastVersion isEqualToString:@"1.0"]);

    XCTAssertNotNil(state.initialLaunchDate);
    components = [_calendar components:NSCalendarUnitDay | NSCalendarUnitMonth | NSCalendarUnitYear fromDate:state.initialLaunchDate];
    year = [components year];
    month = [components month];
    day = [components day];
    XCTAssertTrue(year == 2016);
    XCTAssertTrue(month == 6);
    XCTAssertTrue(day == 10);

    XCTAssertNotNil(state.lastLaunchDate);
    components = [_calendar components:NSCalendarUnitDay | NSCalendarUnitMonth | NSCalendarUnitYear fromDate:state.lastLaunchDate];
    year = [components year];
    month = [components month];
    day = [components day];
    XCTAssertTrue(year == 2016);
    XCTAssertTrue(month == 7);
    XCTAssertTrue(day == 12);

    XCTAssertNotNil(state.lastUpdateDate);
    components = [_calendar components:NSCalendarUnitDay | NSCalendarUnitMonth | NSCalendarUnitYear fromDate:state.lastUpdateDate];
    year = [components year];
    month = [components month];
    day = [components day];
    XCTAssertTrue(year == 2016);
    XCTAssertTrue(month == 7);
    XCTAssertTrue(day == 11);

    XCTAssertTrue(state.lastVersionLaunches == 10);
}

- (void)testCopy
{
    id mockBundle = [OCMockObject niceMockForClass:[NSBundle class]];
    NSBundle *correctMainBundle = [NSBundle bundleForClass:self.class];
    [[[[mockBundle stub] classMethod] andReturn:correctMainBundle] mainBundle];

    RAnalyticsState *state = [self defaultState];
    RAnalyticsState *copy = [state copy];

    XCTAssertEqualObjects(state, copy);
    XCTAssertNotEqual(state, copy);

    XCTAssertNotNil(copy);
    XCTAssertNotNil(copy.sessionIdentifier);
    XCTAssertTrue([copy.sessionIdentifier isEqualToString:@"CA7A88AB-82FE-40C9-A836-B1B3455DECAB"]);

    XCTAssertNotNil(copy.deviceIdentifier);
    XCTAssertTrue([copy.deviceIdentifier isEqualToString:@"deviceId"]);

    XCTAssertNotNil(copy.currentVersion);
    XCTAssertTrue([copy.currentVersion isEqualToString:@"2.0"]);

    XCTAssertNotNil(copy.advertisingIdentifier);
    XCTAssertTrue([copy.advertisingIdentifier isEqualToString:@"adId"]);

    XCTAssertTrue(copy.loginMethod == RAnalyticsOneTapLoginLoginMethod);
    XCTAssertTrue(copy.origin == RAnalyticsInternalOrigin);

    XCTAssertNotNil(copy.lastKnownLocation);
    XCTAssertTrue(copy.lastKnownLocation.coordinate.latitude == -56.6462520);
    XCTAssertTrue(copy.lastKnownLocation.coordinate.longitude == -36.6462520);

    XCTAssertNotNil(copy.sessionStartDate);
    NSDateComponents *components = [_calendar components:NSCalendarUnitDay | NSCalendarUnitMonth | NSCalendarUnitYear | NSCalendarUnitHour | NSCalendarUnitMinute | NSCalendarUnitSecond fromDate:copy.sessionStartDate];
    NSInteger year = [components year];
    NSInteger month = [components month];
    NSInteger day = [components day];
    NSInteger hour = [components hour];
    NSInteger minute = [components minute];
    NSInteger second = [components second];
    XCTAssertTrue(year == 2016);
    XCTAssertTrue(month == 6);
    XCTAssertTrue(day == 10);
    XCTAssertTrue(hour == 9);
    XCTAssertTrue(minute == 15);
    XCTAssertTrue(second == 30);

    XCTAssertNotNil(copy.lastVersion);
    XCTAssertTrue([copy.lastVersion isEqualToString:@"1.0"]);

    XCTAssertNotNil(copy.initialLaunchDate);
    components = [_calendar components:NSCalendarUnitDay | NSCalendarUnitMonth | NSCalendarUnitYear fromDate:copy.initialLaunchDate];
    year = [components year];
    month = [components month];
    day = [components day];
    XCTAssertTrue(year == 2016);
    XCTAssertTrue(month == 6);
    XCTAssertTrue(day == 10);

    XCTAssertNotNil(copy.lastLaunchDate);
    components = [_calendar components:NSCalendarUnitDay | NSCalendarUnitMonth | NSCalendarUnitYear fromDate:copy.lastLaunchDate];
    year = [components year];
    month = [components month];
    day = [components day];
    XCTAssertTrue(year == 2016);
    XCTAssertTrue(month == 7);
    XCTAssertTrue(day == 12);

    XCTAssertNotNil(copy.lastUpdateDate);
    components = [_calendar components:NSCalendarUnitDay | NSCalendarUnitMonth | NSCalendarUnitYear fromDate:copy.lastUpdateDate];
    year = [components year];
    month = [components month];
    day = [components day];
    XCTAssertTrue(year == 2016);
    XCTAssertTrue(month == 7);
    XCTAssertTrue(day == 11);

    XCTAssertTrue(copy.lastVersionLaunches == 10);
}

- (void)testStatesWithSamePropertiesAreEqual
{
    RAnalyticsState *state = [self defaultState];
    RAnalyticsState *other = state.copy;
    XCTAssertEqualObjects(state, other);
}

- (void)testStatesWithDifferentPropertiesAreNotEqual
{
    RAnalyticsState *state = [self defaultState];
    RAnalyticsState *other = [RAnalyticsState.alloc initWithSessionIdentifier:@"CA7A88AB-82FE-40C9-A836-B1B3455DECAB"
                                                                   deviceIdentifier:@"differentDeviceId"];
    XCTAssertNotEqualObjects(state, other);
}

- (void)testStateIsNotEqualToDifferentObject
{
    RAnalyticsState *state = [self defaultState];
    XCTAssertNotEqualObjects(state, UIView.new);
}

- (void)testHashIsIdenticalWhenObjectsEqual
{
    RAnalyticsState *state = [self defaultState];
    RAnalyticsState *other = state.copy;
    XCTAssertEqualObjects(state, other);
    XCTAssertEqual(state.hash, other.hash);
}

- (void)testHashIsDifferentWhenPropertiesAreDifferent
{
    RAnalyticsState *state = [self defaultState];
    RAnalyticsState *other = [RAnalyticsState.alloc initWithSessionIdentifier:@"CA7A88AB-82FE-40C9-A836-B1B3455DECAB"
                                                                   deviceIdentifier:@"differentDeviceId"];
    XCTAssertNotEqualObjects(state, other);
    XCTAssertNotEqual(state.hash, other.hash);
}

@end
