/*
 * © Rakuten, Inc.
 * authors: "Rakuten Ecosystem Mobile" <ecosystem-mobile@mail.rakuten.com>
 */
#import "RSDKAnalyticsEvent.h"
#import "_RSDKAnalyticsHelpers.h"

// Standard event names
NSString *const RSDKAnalyticsInitialLaunchEventName     = @"_rem_init_launch";
NSString *const RSDKAnalyticsSessionStartEventName      = @"_rem_launch";
NSString *const RSDKAnalyticsSessionEndEventName        = @"_rem_end_session";
NSString *const RSDKAnalyticsApplicationUpdateEventName = @"_rem_update";
NSString *const RSDKAnalyticsLoginEventName             = @"_rem_login";
NSString *const RSDKAnalyticsLogoutEventName            = @"_rem_logout";
NSString *const RSDKAnalyticsInstallEventName           = @"_rem_install";
NSString *const RSDKAnalyticsPageVisitEventName         = @"_rem_visit";
NSString *const RSDKAnalyticsPushNotificationEventName  = @"_rem_push_notify";


// Standard event parameters
NSString *const RSDKAnalyticsLogoutMethodEventParameter                    = @"logout_method";
NSString *const RSDKAnalyticPushNotificationTrackingIdentifierParameter    = @"tracking_id";

// Standard event parameter values
NSString *const RSDKAnalyticsLocalLogoutMethod          = @"local";
NSString *const RSDKAnalyticsGlobalLogoutMethod         = @"global";



@interface RSDKAnalyticsEvent ()
@property (nonatomic, readwrite, copy) NSString *name;
@property (nonatomic, readwrite, copy) NSDictionary *parameters;
@end

@implementation RSDKAnalyticsEvent

- (instancetype)init
{
    [self doesNotRecognizeSelector:_cmd];
    __builtin_unreachable();
}

- (instancetype)initWithName:(NSString *)name parameters:(NSDictionary RSDKA_GENERIC(NSString *, id) * __nullable)parameters
{
    NSParameterAssert(name.length);
    if ((self = [super init]))
    {
        _name = name.copy;
        _parameters = parameters.copy;
    }
    return self;
}

#pragma mark - NSObject

- (NSUInteger)hash
{
    return self.name.hash ^ self.parameters.hash;
}

- (BOOL)isEqual:(id)object
{
    if (self == object)
    {
        return YES;
    }
    else if (![object isMemberOfClass:[self class]] || (self.hash != [object hash]))
    {
        return NO;
    }
    else
    {
        RSDKAnalyticsEvent *other = object;
        return _RSDKAnalyticsObjectsEqual(self.name, other.name) && _RSDKAnalyticsObjectsEqual(self.parameters, other.parameters);
    }
}

#pragma mark - NSSecureCoding

+ (BOOL)supportsSecureCoding
{
    return YES;
}

- (instancetype)initWithCoder:(NSCoder *)decoder
{
    NSString *name = [decoder decodeObjectOfClass:NSString.class forKey:NSStringFromSelector(@selector(name))];
    NSDictionary *parameters = [decoder decodeObjectOfClass:NSDictionary.class forKey:NSStringFromSelector(@selector(parameters))];
    return [self initWithName:name parameters:parameters];
}

- (void)encodeWithCoder:(NSCoder *)coder
{
    [coder encodeObject:self.name forKey:NSStringFromSelector(@selector(name))];
    [coder encodeObject:self.parameters forKey:NSStringFromSelector(@selector(parameters))];
}

#pragma mark - NSCopying
- (instancetype)copyWithZone:(NSZone *)zone
{
    return [[RSDKAnalyticsEvent allocWithZone:zone] initWithName:self.name parameters:self.parameters];
}

#pragma mark - Tracking
- (void)track
{
    [[RSDKAnalyticsManager sharedInstance] process:self];
}

@end
