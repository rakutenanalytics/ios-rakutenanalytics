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
    return self.sessionIdentifier.hash ^ self.deviceIdentifier.hash ^ self.currentVersion.hash ^ self.advertisingIdentifier.hash ^ self.lastKnownLocation.hash ^ self.sessionStartDate.hash;
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
        return _RSDKAnalyticsObjects_equal(self.advertisingIdentifier, other.advertisingIdentifier) && _RSDKAnalyticsObjects_equal(self.sessionIdentifier, other.sessionIdentifier) && _RSDKAnalyticsObjects_equal(self.deviceIdentifier, other.deviceIdentifier) && _RSDKAnalyticsObjects_equal(self.currentVersion, other.currentVersion) && ([self.lastKnownLocation distanceFromLocation:other.lastKnownLocation] == 0) && _RSDKAnalyticsObjects_equal(self.sessionStartDate, other.sessionStartDate);
    }
}

#pragma mark - NSCopying
- (instancetype)copyWithZone:(NSZone *)zone
{
    RSDKAnalyticsState *copy = [[RSDKAnalyticsState allocWithZone:zone] initWithSessionIdentifier:self.sessionIdentifier deviceIdentifier:self.deviceIdentifier];
    copy.advertisingIdentifier = self.advertisingIdentifier;
    copy.lastKnownLocation = self.lastKnownLocation;
    copy.sessionStartDate = self.sessionStartDate;
    return copy;
}

@end
