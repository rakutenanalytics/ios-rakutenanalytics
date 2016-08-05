/*
 * © Rakuten, Inc.
 * authors: "Rakuten Ecosystem Mobile" <ecosystem-mobile@mail.rakuten.com>
 */
#import "RSDKAnalyticsEvent.h"
#import "_RSDKAnalyticsHelpers.h"

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

- (instancetype)initWithName:(NSString *)name parameters:(NSDictionary RSDKA_GENERIC(NSString *, id) *)parameters
{
    NSParameterAssert(name.length);
    if ((self = [super init]))
    {
        _name = name;
        _parameters = parameters;
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
        return _RSDKAnalyticsObjects_equal(self.name, other.name) && _RSDKAnalyticsObjects_equal(self.parameters, other.parameters);
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
