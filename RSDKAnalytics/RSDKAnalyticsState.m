/*
 * © Rakuten, Inc.
 * authors: "Rakuten Ecosystem Mobile" <ecosystem-mobile@mail.rakuten.com>
 */
#import "RSDKAnalyticsState.h"
#import "_RSDKAnalyticsHelpers.h"

@interface RSDKAnalyticsState ()
@property (nonatomic, readwrite, copy) NSString *sessionIdentifier;
@property (nonatomic, readwrite, copy) NSString *deviceIdentifier;
@property (nonatomic, readwrite, copy) NSString *currentVersion;
@property (nonatomic, nullable, readwrite, copy) CLLocation *lastKnownLocation;
@property (nonatomic, nullable, readwrite, copy) NSString *advertisingIdentifier;
@property (nonatomic, nullable, readwrite, copy) NSDate *sessionStartDate;
@property (nonatomic, readwrite) BOOL loggedIn;
@property (nonatomic, readwrite, copy) NSString *userIdentifier;
@property (nonatomic, readwrite) RSDKAnalyticsLoginMethod loginMethod;
@property (nonatomic, readwrite) RSDKAnalyticsLogoutMethod logoutMethod;
@property (nonatomic, nullable, readwrite, copy) NSString *linkIdentifier;
@property (nonatomic, readwrite) RSDKAnalyticsOrigin origin;
@property (nonatomic, nullable, readwrite) UIViewController *lastVisitedPage;
@property (nonatomic, nullable, readwrite) UIViewController *currentPage;
@property (nonatomic, nullable, readwrite, copy) NSString *lastVersion;
@property (nonatomic) NSInteger lastVersionLaunches;
@property (nonatomic, nullable, readwrite, copy) NSDate *initialLaunchDate;
@property (nonatomic, nullable, readwrite, copy) NSDate *installLaunchDate;
@property (nonatomic, nullable, readwrite, copy) NSDate *lastLaunchDate;
@property (nonatomic, nullable, readwrite, copy) NSDate *lastUpdateDate;

@end

@implementation RSDKAnalyticsState

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wobjc-designated-initializers"
#pragma clang diagnostic ignored "-Wobjc-missing-super-calls"
- (instancetype)init
{
    [self doesNotRecognizeSelector:_cmd];
    return nil;
}
#pragma clang diagnostic pop

- (instancetype)initWithSessionIdentifier:(NSString *)sessionIdentifier
                         deviceIdentifier:(NSString *)deviceIdentifier
{
    NSParameterAssert(sessionIdentifier.length);
    NSParameterAssert(deviceIdentifier.length);

    if (self = [super init])
    {
        _sessionIdentifier = sessionIdentifier;
        _deviceIdentifier = deviceIdentifier;
        NSDictionary *bundleInfo = NSBundle.mainBundle.infoDictionary;
        NSString *currentVersion = bundleInfo[@"CFBundleShortVersionString"] ?: bundleInfo[@"CFBundleVersion"];
        _currentVersion = currentVersion;
    }
    return self;
}

#pragma mark - NSObject

- (NSUInteger)hash
{
    return self.sessionIdentifier.hash
         ^ self.deviceIdentifier.hash
         ^ self.currentVersion.hash
         ^ self.advertisingIdentifier.hash
         ^ self.lastKnownLocation.hash
         ^ self.sessionStartDate.hash
         ^ self.loggedIn
         ^ self.userIdentifier.hash
         ^ self.loginMethod
         ^ self.logoutMethod
         ^ self.linkIdentifier.hash
         ^ self.origin
         ^ self.lastVisitedPage.hash
         ^ self.currentPage.hash
         ^ self.lastVersion.hash
         ^ self.lastVersionLaunches
         ^ self.initialLaunchDate.hash
         ^ self.installLaunchDate.hash
         ^ self.lastLaunchDate.hash
         ^ self.lastUpdateDate.hash;
}

- (BOOL)isEqual:(id)object
{
    if (self == object)
    {
        return YES;
    }
    else if (![object isMemberOfClass:[self class]])
    {
        return NO;
    }
    else
    {
        RSDKAnalyticsState *other = object;
        return _RSDKAnalyticsObjects_equal(self.advertisingIdentifier, other.advertisingIdentifier)
            && _RSDKAnalyticsObjects_equal(self.sessionIdentifier, other.sessionIdentifier)
            && _RSDKAnalyticsObjects_equal(self.deviceIdentifier, other.deviceIdentifier)
            && _RSDKAnalyticsObjects_equal(self.currentVersion, other.currentVersion)
            && ([self.lastKnownLocation distanceFromLocation:other.lastKnownLocation] == 0)
            && _RSDKAnalyticsObjects_equal(self.sessionStartDate, other.sessionStartDate)
            && (self.loggedIn == other.loggedIn)
            && _RSDKAnalyticsObjects_equal(self.userIdentifier, other.userIdentifier)
            && (self.loginMethod == other.loginMethod)
            && (self.logoutMethod == other.logoutMethod)
            && _RSDKAnalyticsObjects_equal(self.linkIdentifier, other.linkIdentifier)
            && (self.origin == other.origin)
            && _RSDKAnalyticsObjects_equal(self.lastVisitedPage, other.lastVisitedPage)
            && _RSDKAnalyticsObjects_equal(self.currentPage, other.currentPage)
            && _RSDKAnalyticsObjects_equal(self.lastVersion, other.lastVersion)
            && (self.lastVersionLaunches == other.lastVersionLaunches)
            && _RSDKAnalyticsObjects_equal(self.initialLaunchDate, other.initialLaunchDate)
            && _RSDKAnalyticsObjects_equal(self.installLaunchDate, other.installLaunchDate)
            && _RSDKAnalyticsObjects_equal(self.lastLaunchDate, other.lastLaunchDate)
            && _RSDKAnalyticsObjects_equal(self.lastUpdateDate, other.lastUpdateDate);
    }
}

#pragma mark - NSCopying
- (instancetype)copyWithZone:(NSZone *)zone
{
    RSDKAnalyticsState *copy = [[RSDKAnalyticsState allocWithZone:zone] initWithSessionIdentifier:self.sessionIdentifier deviceIdentifier:self.deviceIdentifier];
    copy.advertisingIdentifier = self.advertisingIdentifier;
    copy.lastKnownLocation = self.lastKnownLocation;
    copy.sessionStartDate = self.sessionStartDate;
    copy.loggedIn = self.loggedIn;
    copy.userIdentifier = self.userIdentifier;
    copy.loginMethod = self.loginMethod;
    copy.logoutMethod = self.logoutMethod;
    copy.linkIdentifier = self.linkIdentifier;
    copy.origin = self.origin;
    copy.lastVisitedPage = self.lastVisitedPage;
    copy.currentPage = self.currentPage;
    copy.lastVersion = self.lastVersion;
    copy.lastVersionLaunches = self.lastVersionLaunches;
    copy.initialLaunchDate = self.initialLaunchDate;
    copy.installLaunchDate = self.installLaunchDate;
    copy.lastLaunchDate = self.lastLaunchDate;
    copy.lastUpdateDate = self.lastUpdateDate;
    return copy;
}

@end
