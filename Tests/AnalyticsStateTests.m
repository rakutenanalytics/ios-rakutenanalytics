/*
 * © Rakuten, Inc.
 * authors: "Rakuten Ecosystem Mobile" <ecosystem-mobile@mail.rakuten.com>
 */
@import XCTest;
#import <RSDKAnalytics/RSDKAnalyticsState.h>
#import <OCMock/OCMock.h>

@interface RSDKAnalyticsState ()
@property (nonatomic, readwrite, copy) NSString *sessionIdentifier;
@property (nonatomic, readwrite, copy) NSString *deviceIdentifier;
@property (nonatomic, readwrite, copy) NSString *currentVersion;
@property (nonatomic, nullable, readwrite, copy) CLLocation *lastKnownLocation;
@property (nonatomic, nullable, readwrite, copy) NSString *advertisingIdentifier;
@property (nonatomic, nullable, readwrite, copy) NSDate *sessionStartDate;
@end

@interface AnalyticsStateTests : XCTestCase
@property (nonatomic) NSCalendar *calendar;
@end

@implementation AnalyticsStateTests

- (void)setUp
{
    [super setUp];
    _calendar = [NSCalendar.alloc initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
}

- (RSDKAnalyticsState *)defaultState
{
    CLLocation *location = [[CLLocation alloc] initWithLatitude:-56.6462520 longitude:-36.6462520];

    NSDateComponents *dateComponents = [NSDateComponents.alloc init];
    [dateComponents setDay:10];
    [dateComponents setMonth:6];
    [dateComponents setYear:2016];
    [dateComponents setHour:9];
    [dateComponents setMinute:15];
    [dateComponents setSecond:30];
    NSDate *sessionStartDate = [_calendar dateFromComponents:dateComponents];

    RSDKAnalyticsState *state = [RSDKAnalyticsState.alloc initWithSessionIdentifier:@"CA7A88AB-82FE-40C9-A836-B1B3455DECAB" deviceIdentifier:@"deviceId"];
    state.advertisingIdentifier = @"adId";
    state.lastKnownLocation = location;
    state.sessionStartDate = sessionStartDate;
    return state;
}

- (void)testAnalyticsStateWithoutSetting
{
    id mockBundle = [OCMockObject niceMockForClass:[NSBundle class]];
    NSBundle *correctMainBundle = [NSBundle bundleForClass:self.class];
    [[[[mockBundle stub] classMethod] andReturn:correctMainBundle] mainBundle];

    RSDKAnalyticsState *state = [RSDKAnalyticsState.alloc initWithSessionIdentifier:@"CA7A88AB-82FE-40C9-A836-B1B3455DECAB" deviceIdentifier:@"deviceId"];
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
}

- (void)testAnalyticsStateWithSetting
{
    id mockBundle = [OCMockObject niceMockForClass:[NSBundle class]];
    NSBundle *correctMainBundle = [NSBundle bundleForClass:self.class];
    [[[[mockBundle stub] classMethod] andReturn:correctMainBundle] mainBundle];

    RSDKAnalyticsState *state = [self defaultState];

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
}

- (void)testCopy
{
    id mockBundle = [OCMockObject niceMockForClass:[NSBundle class]];
    NSBundle *correctMainBundle = [NSBundle bundleForClass:self.class];
    [[[[mockBundle stub] classMethod] andReturn:correctMainBundle] mainBundle];

    RSDKAnalyticsState *state = [self defaultState];
    RSDKAnalyticsState *copy = [state copy];

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

    XCTAssertNotNil(copy.lastKnownLocation);
    XCTAssertTrue(copy.lastKnownLocation.coordinate.latitude == -56.6462520);
    XCTAssertTrue(copy.lastKnownLocation.coordinate.longitude == -36.6462520);

    XCTAssertNotNil(state.sessionStartDate);
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
}

@end
