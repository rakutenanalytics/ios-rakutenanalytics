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
@property (nonatomic, readwrite, getter=isLoggedIn) BOOL loggedIn;
@property (nonatomic, nullable, readwrite, copy) NSString *userIdentifier;
@property (nonatomic, readwrite) RSDKAnalyticsLoginMethod loginMethod;
@property (nonatomic, readwrite) RSDKAnalyticsOrigin origin;
@property (nonatomic, nullable, readwrite, copy) NSString *lastVersion;
@property (nonatomic) NSUInteger lastVersionLaunches;
@property (nonatomic, nullable, readwrite, copy) NSDate *initialLaunchDate;
@property (nonatomic, nullable, readwrite, copy) NSDate *installLaunchDate;
@property (nonatomic, nullable, readwrite, copy) NSDate *lastLaunchDate;
@property (nonatomic, nullable, readwrite, copy) NSDate *lastUpdateDate;
@property (nonatomic, nullable, readwrite) UIViewController *lastVisitedPage;
@property (nonatomic, nullable, readwrite) UIViewController *currentPage;
@end

@implementation RSDKAnalyticsState

- (instancetype)init
{
    [self doesNotRecognizeSelector:_cmd];
    __builtin_unreachable();
}

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
         ^ self.sessionStartDate.hash
         ^ self.isLoggedIn
         ^ self.userIdentifier.hash
         ^ self.loginMethod
         ^ self.origin
         ^ self.lastVersion.hash
         ^ self.lastVersionLaunches
         ^ self.initialLaunchDate.hash
         ^ self.installLaunchDate.hash
         ^ self.lastLaunchDate.hash
         ^ self.lastUpdateDate.hash
         ^ self.lastVisitedPage.hash
         ^ self.currentPage.hash;
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
        return _RSDKAnalyticsObjectsEqual(self.advertisingIdentifier, other.advertisingIdentifier)
            && _RSDKAnalyticsObjectsEqual(self.sessionIdentifier, other.sessionIdentifier)
            && _RSDKAnalyticsObjectsEqual(self.deviceIdentifier, other.deviceIdentifier)
            && _RSDKAnalyticsObjectsEqual(self.currentVersion, other.currentVersion)
            && ([self.lastKnownLocation distanceFromLocation:other.lastKnownLocation] == 0)
            && _RSDKAnalyticsObjectsEqual(self.sessionStartDate, other.sessionStartDate)
            && (self.isLoggedIn == other.isLoggedIn)
            && _RSDKAnalyticsObjectsEqual(self.userIdentifier, other.userIdentifier)
            && (self.loginMethod == other.loginMethod)
            && (self.origin == other.origin)
            && _RSDKAnalyticsObjectsEqual(self.lastVersion, other.lastVersion)
            && (self.lastVersionLaunches == other.lastVersionLaunches)
            && _RSDKAnalyticsObjectsEqual(self.initialLaunchDate, other.initialLaunchDate)
            && _RSDKAnalyticsObjectsEqual(self.installLaunchDate, other.installLaunchDate)
            && _RSDKAnalyticsObjectsEqual(self.lastLaunchDate, other.lastLaunchDate)
            && _RSDKAnalyticsObjectsEqual(self.lastUpdateDate, other.lastUpdateDate)
            && _RSDKAnalyticsObjectsEqual(self.lastVisitedPage, other.lastVisitedPage)
            && _RSDKAnalyticsObjectsEqual(self.currentPage, other.currentPage);
    }
}

#pragma mark - NSCopying
- (instancetype)copyWithZone:(NSZone *)zone
{
    RSDKAnalyticsState *copy = [[RSDKAnalyticsState allocWithZone:zone] initWithSessionIdentifier:self.sessionIdentifier deviceIdentifier:self.deviceIdentifier];
    copy.advertisingIdentifier = self.advertisingIdentifier;
    copy.lastKnownLocation = self.lastKnownLocation;
    copy.sessionStartDate = self.sessionStartDate;
    copy.loggedIn = self.isLoggedIn;
    copy.userIdentifier = self.userIdentifier;
    copy.loginMethod = self.loginMethod;
    copy.origin = self.origin;
    copy.lastVersion = self.lastVersion;
    copy.lastVersionLaunches = self.lastVersionLaunches;
    copy.initialLaunchDate = self.initialLaunchDate;
    copy.installLaunchDate = self.installLaunchDate;
    copy.lastLaunchDate = self.lastLaunchDate;
    copy.lastUpdateDate = self.lastUpdateDate;
    copy.lastVisitedPage = self.lastVisitedPage;
    copy.currentPage = self.currentPage;
    return copy;
}

@end
