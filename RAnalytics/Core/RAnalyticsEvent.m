#import "RAnalyticsEvent.h"
#import "_RAnalyticsHelpers.h"
#import <RAnalytics/RAnalyticsPushTrackingUtility.h>

// Standard event names
NSString *const RAnalyticsInitialLaunchEventName         = @"_rem_init_launch";
NSString *const RAnalyticsSessionStartEventName          = @"_rem_launch";
NSString *const RAnalyticsSessionEndEventName            = @"_rem_end_session";
NSString *const RAnalyticsApplicationUpdateEventName     = @"_rem_update";
NSString *const RAnalyticsLoginEventName                 = @"_rem_login";
NSString *const RAnalyticsLoginFailureEventName          = @"_rem_login_failure";
NSString *const RAnalyticsLogoutEventName                = @"_rem_logout";
NSString *const RAnalyticsInstallEventName               = @"_rem_install";
NSString *const RAnalyticsPageVisitEventName             = @"_rem_visit";
NSString *const RAnalyticsPushNotificationEventName      = @"_rem_push_notify";
NSString *const RAnalyticsSSOCredentialFoundEventName    = @"_rem_sso_credential_found";
NSString *const RAnalyticsLoginCredentialFoundEventName  = @"_rem_login_credential_found";
NSString *const RAnalyticsCredentialStrategiesEventName  = @"_rem_credential_strategies";

// Custom event name
NSString *const RAnalyticsCustomEventName                = @"_analytics_custom";

// Standard event parameters
NSString *const RAnalyticsLogoutMethodEventParameter                    = @"logout_method";
NSString *const RAnalyticsPushNotificationTrackingIdentifierParameter    = @"tracking_id";

// Custom event parameters
NSString *const RAnalyticsCustomEventNameParameter                    = @"eventName";
NSString *const RAnalyticsCustomEventDataParameter                    = @"eventData";
NSString *const RAnalyticsCustomEventTopLevelObjectParameter          = @"topLevelObject";

// Standard event parameter values
NSString *const RAnalyticsLocalLogoutMethod          = @"local";
NSString *const RAnalyticsGlobalLogoutMethod         = @"global";



@interface RAnalyticsEvent ()
@property (nonatomic, readwrite, copy) NSString *name;
@property (nonatomic, readwrite, copy) NSDictionary *parameters;
@end

@implementation RAnalyticsEvent

- (instancetype)init
{
    [self doesNotRecognizeSelector:_cmd];
    __builtin_unreachable();
}

- (instancetype)initWithName:(NSString *)name parameters:(NSDictionary<NSString *, id> * __nullable)parameters
{
    NSParameterAssert(name.length);
    if ((self = [super init]))
    {
        _name = name.copy;
        _parameters = parameters.copy;
    }
    return self;
}

- (instancetype)initWithPushNotificationPayload:(NSDictionary*) pushNotificationPayload
{
    NSMutableDictionary *parameters = NSMutableDictionary.new;
    NSString *trackingId = [RAnalyticsPushTrackingUtility trackingIdentifierFromPayload:pushNotificationPayload];
    
    if (trackingId)
    {
        parameters[RAnalyticsPushNotificationTrackingIdentifierParameter] = trackingId;
    }

    return [self initWithName:RAnalyticsPushNotificationEventName parameters:parameters];
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
        RAnalyticsEvent *other = object;
        return _RAnalyticsObjectsEqual(self.name, other.name) && _RAnalyticsObjectsEqual(self.parameters, other.parameters);
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
    return [[RAnalyticsEvent allocWithZone:zone] initWithName:self.name parameters:self.parameters];
}

#pragma mark - Tracking
- (void)track
{
    [[RAnalyticsManager sharedInstance] process:self];
}

@end
