/*
 * © Rakuten, Inc.
 * authors: "Rakuten Ecosystem Mobile" <ecosystem-mobile@mail.rakuten.com>
 */
#import <RSDKAnalytics/RSDKAnalytics.h>

@implementation RSDKAnalyticsItem

+ (instancetype)itemWithIdentifier:(NSString *)identifier
{
    RSDKAnalyticsItem *item = RSDKAnalyticsItem.new;
    item.identifier = identifier;
    return item;
}

#pragma mark - NSSecureCoding
+ (BOOL)supportsSecureCoding
{
    return YES;
}

- (void)encodeWithCoder:(NSCoder *)coder
{
    union
    {
        uint64_t unsignedValue;
        int64_t  signedValue;
    } value64;

    [coder encodeObject:self.identifier    forKey:NSStringFromSelector(@selector(identifier))];
    value64.unsignedValue = self.quantity;
    [coder encodeInt64:value64.signedValue forKey:NSStringFromSelector(@selector(quantity))];
    [coder encodeDouble:self.price         forKey:NSStringFromSelector(@selector(price))];
    [coder encodeObject:self.genre         forKey:NSStringFromSelector(@selector(genre))];
    [coder encodeObject:self.variation     forKey:NSStringFromSelector(@selector(variation))];
    [coder encodeObject:self.tags          forKey:NSStringFromSelector(@selector(tags))];
}

- (id)initWithCoder:(NSCoder *)decoder
{
    union
    {
        uint64_t unsignedValue;
        int64_t  signedValue;
    } value64;

    if (self = [self init])
    {
        self.identifier = [decoder decodeObjectOfClass:NSString.class forKey:NSStringFromSelector(@selector(identifier))];

        value64.signedValue = [decoder decodeInt64ForKey:NSStringFromSelector(@selector(quantity))];
        self.quantity = value64.unsignedValue;

        self.price     = [decoder decodeDoubleForKey:NSStringFromSelector(@selector(price))];
        self.genre     = [decoder decodeObjectOfClass:NSString.class     forKey:NSStringFromSelector(@selector(genre))];
        self.variation = [decoder decodeObjectOfClass:NSDictionary.class forKey:NSStringFromSelector(@selector(variation))];
        self.tags      = [decoder decodeObjectOfClass:NSArray.class      forKey:NSStringFromSelector(@selector(tags))];
    }
    return self;
}

#pragma mark - NSCopying

- (id)copyWithZone:(NSZone __unused *)zone
{
    RSDKAnalyticsItem *item = [RSDKAnalyticsItem itemWithIdentifier:self.identifier];
    item.quantity   = self.quantity;
    item.price      = self.price;
    item.genre      = self.genre;
    if (self.variation)
    {
        item.variation = (__bridge_transfer NSDictionary *)(CFPropertyListCreateDeepCopy(kCFAllocatorDefault,
                                                                                         (__bridge CFPropertyListRef) self.variation,
                                                                                         kCFPropertyListImmutable));
    }
    if (self.tags.count)
    {
        item.tags = [NSMutableArray.alloc initWithArray:self.tags copyItems:YES];
    }

    return item;
}

#pragma mark - NSObject

- (NSString *)description
{
    return [NSString stringWithFormat:@"<%@: %p, %@>", NSStringFromClass(self.class), self, @{@"identifier": self.identifier,
                                                                                              @"quantity":   @(self.quantity),
                                                                                              @"price":      @(self.price),
                                                                                              @"genre":      self.genre,
                                                                                              @"variation":  self.variation,
                                                                                              @"tags":       self.tags,
                                                                                              }];
}

@end