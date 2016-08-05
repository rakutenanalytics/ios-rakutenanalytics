/*
 * © Rakuten, Inc.
 * authors: "Rakuten Ecosystem Mobile" <ecosystem-mobile@mail.rakuten.com>
 */
#import <RSDKAnalytics/RSDKAnalytics.h>

//--------------------------------------------------------------------------
// Definitions for the externs declared in the header file

const int64_t RSDKAnalyticsInvalidAffiliateId = INT64_MIN;
const int64_t RSDKAnalyticsInvalidCheckpoints = INT64_MIN;
const uint64_t RSDKAnalyticsInvalidCartState  = UINT64_MAX;
const NSTimeInterval RSDKAnalyticsInvalidNavigationTime = -1.0;

////////////////////////////////////////////////////////////////////////////

@interface RSDKAnalyticsRecord()
@property (nonatomic) uint64_t accountId;
@property (nonatomic) int64_t  serviceId;
@property (nonatomic, strong)  NSMutableArray *items;
@end

@implementation RSDKAnalyticsRecord

#pragma mark - Initializers

- (instancetype)init
{
    [self doesNotRecognizeSelector:_cmd];
    __builtin_unreachable();
}

- (instancetype)initWithAccountId:(uint64_t)accountId serviceId:(int64_t)serviceId
{
    if (self = [super init])
    {
        self.accountId = accountId;
        self.affiliateId = RSDKAnalyticsInvalidAffiliateId;
        self.cartState = RSDKAnalyticsInvalidCartState;
        self.checkoutStage = RSDKAnalyticsInvalidCheckoutStage;
        self.checkpoints = RSDKAnalyticsInvalidCheckpoints;
        self.contentLocale = NSLocale.currentLocale;
        self.navigationTime = RSDKAnalyticsInvalidNavigationTime;
        self.searchMethod = RSDKAnalyticsInvalidSearchMethod;
        self.serviceId = serviceId;
        self.items = NSMutableArray.new;
    }
    return self;
}

#pragma mark - Accessors

- (void)setContentLocale:(NSLocale * __nullable)contentLocale {
    contentLocale = contentLocale ?: NSLocale.currentLocale;

    if (![contentLocale isEqual:_contentLocale]) {
        _contentLocale = contentLocale.copy;
    }
}

#pragma mark - Public methods

+ (instancetype)recordWithAccountId:(uint64_t)accountId serviceId:(int64_t)serviceId
{
    return [self.alloc initWithAccountId:accountId serviceId:serviceId];
}

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
- (BOOL)addItem:(RSDKAnalyticsItem *)item
{
    if (self.items.count == 100)
    {
        return NO;
    }

    [self.items addObject:item.copy];
    return YES;
}

- (void)enumerateItemsWithBlock:(rsdk_analytics_item_enumeration_block_t)block
{
    if (!block)
    {
        return;
    }

    [self.items enumerateObjectsUsingBlock:block];
}


- (NSDictionary *)propertiesDictionary
{
    NSMutableDictionary *dictionary = NSMutableDictionary.new;

    NSMutableArray *itemIdentifiers = nil;
    NSMutableArray *itemQuantities  = nil;
    NSMutableArray *itemPrices      = nil;
    NSMutableArray *itemGenres      = nil;
    NSMutableArray *itemVariations  = nil;
    NSMutableArray *itemTags        = nil;

    NSUInteger itemCount = _items.count;
    if (itemCount)
    {
        itemIdentifiers = [NSMutableArray arrayWithCapacity:itemCount];
        itemQuantities  = [NSMutableArray arrayWithCapacity:itemCount];
        itemPrices      = [NSMutableArray arrayWithCapacity:itemCount];
        itemGenres      = [NSMutableArray arrayWithCapacity:itemCount];
        itemVariations  = [NSMutableArray arrayWithCapacity:itemCount];
        itemTags        = [NSMutableArray arrayWithCapacity:itemCount];

        __block BOOL hasGenres     = NO;
        __block BOOL hasVariations = NO;
        __block BOOL hasTags       = NO;
        [self enumerateItemsWithBlock:^(RSDKAnalyticsItem *item, NSUInteger __unused index, BOOL __unused *stop) {
            [itemIdentifiers addObject:item.identifier];
            [itemQuantities  addObject:@(item.quantity)];
            [itemPrices      addObject:@(item.price)];

            [itemGenres      addObject:item.genre     ?: @""];
            [itemVariations  addObject:item.variation ?: @""];
            [itemTags        addObject:[item.tags componentsJoinedByString:@"/"] ?: NSNull.null];

            if (item.genre.length)
            {
                hasGenres = YES;
            }

            if (item.variation.count)
            {
                hasVariations = YES;
            }

            if (item.tags.count)
            {
                hasTags = YES;
            }
        }];

        if (!hasGenres)
        {
            itemGenres = nil;
        }

        if (!hasVariations)
        {
            itemVariations = nil;
        }

        if (!hasTags)
        {
            itemTags = nil;
        }
    }

    // {name: "acc", longName: "ACCOUNT_ID", fieldType: "INT", minValue: 0, userSettable: true}
    dictionary[@"acc"] = @(_accountId);

    // {name: "userid", longName: "USER_ID", fieldType: "STRING", maxLength: 200, minLength: 0, userSettable: true}
    if (self.userId.length)
    {
        dictionary[@"userid"] = self.userId;
    }

    // {name: "afid", longName: "AFFILIATE_ID", fieldType: "INT", userSettable: true}
    if (self.affiliateId != RSDKAnalyticsInvalidAffiliateId)
    {
        dictionary[@"afid"] = @(self.affiliateId);
    }

    // {name: "cc", longName: "CAMPAIGN_CODE", fieldType: "STRING", maxLength: 20, minLength: 0, userSettable: true}
    if (self.campaignCode.length)
    {
        dictionary[@"cc"] = self.campaignCode;
    }

    // {name: "cart", longName: "CART_STATE", fieldType: "INT", minValue: 0, userSettable: true}
    if (self.cartState != RSDKAnalyticsInvalidCartState)
    {
        dictionary[@"cart"] = @(self.cartState);
    }

    // {name: "chkout", longName: "CHECKOUT", fieldType: "INT", validValues: [10, 20, 30, 40, 50], userSettable: true}
    if (self.checkoutStage != RSDKAnalyticsInvalidCheckoutStage)
    {
        dictionary[@"chkout"] = @(self.checkoutStage);
    }

    // {name: "chkpt", longName: "CHECKPOINTS", fieldType: "INT", userSettable: true}
    if (self.checkpoints != RSDKAnalyticsInvalidCheckpoints)
    {
        dictionary[@"chkpt"] = @(self.checkpoints);
    }

    // {name: "compid",longName: "COMPONENT_ID",fieldType: "STRING_ARRAY",userSettable: true}
    if (self.componentId.count)
    {
        dictionary[@"compid"] = self.componentId;
    }

    // {name: "comptop",longName: "COMPONENT_TOP",fieldType: "DOUBLE_ARRAY",userSettable: true}
    if (self.componentTop.count)
    {
        dictionary[@"comptop"] = self.componentTop;
    }

    // {name: "cntln", longName: "CONTENT_LANGUAGE", fieldType: "STRING", maxLength: 16, minLength: 0, userSettable: false}
    if (self.contentLocale)
    {
        dictionary[@"cntln"] = self.contentLocale.localeIdentifier;
    }

    // {name: "cycode", longName: "CURRENCY_CODE", fieldType: "STRING", maxLength: 3, minLength: 0, userSettable: true}
    if (self.currencyCode)
    {
        dictionary[@"cycode"] = self.currencyCode.uppercaseString;
    }

    // {name: "cp", longName: "CUSTOM_PARAMETERS", fieldType: "JSON"}
    if (self.customParameters.count)
    {
        dictionary[@"cp"] = self.customParameters;
    }

    // {name: "etype",longName: "EVENT_TYPE",fieldType: "STRING",userSettable: true}
    if (self.eventType.length)
    {
        dictionary[@"etype"] = self.eventType;
    }

    // {name: "esq", longName: "EXCLUDE_WORD_SEARCH_QUERY", fieldType: "STRING", maxLength: 1024, minLength: 0, userSettable: true}
    if (self.excludeWordSearchQuery.length)
    {
        dictionary[@"esq"] = self.excludeWordSearchQuery;
    }

    // {name: "genre", longName: "GENRE", definitionLevel: "RAL", fieldType: "STRING", maxLength: 200, minLength: 0, userSettable: true}
    if (self.genre.length)
    {
        dictionary[@"genre"] = self.genre;
    }

    // {name: "tag", longName: "SELECTED_TAGS", fieldType: "STRING_ARRAY", maxLength: 8, minLength: 1, userSettable: true}
    if (self.selectedTags.count)
    {
        dictionary[@"tag"] = self.selectedTags;
    }

    // {name: "gol", longName: "GOAL_ID", fieldType: "STRING", maxLength: 10, minLength: 0, userSettable: true}
    if (self.goalId.length)
    {
        dictionary[@"gol"] = self.goalId;
    }

    // {name: "igenre", longName: "ITEM_GENRE", fieldType: "STRING_ARRAY", definitionLevel: "RAL", maxLength": 100, minLength: 0, userSettable: true}
    if (itemGenres.count)
    {
        dictionary[@"igenre"] = itemGenres;
    }

    // {name: "itemid", longName: "ITEM_ID", fieldType: "STRING_ARRAY", definitionLevel: "RAL", maxLength": 100, minLength: 0, userSettable: true}
    if (itemIdentifiers.count)
    {
        dictionary[@"itemid"] = itemIdentifiers;
    }

    // {name: "variation", longName: "ITEM_VARIATION", fieldType: "JSON_ARRAY", definitionLevel: "RAL", maxLength": 100, minLength: 0, userSettable: true}
    if (itemVariations.count)
    {
        dictionary[@"variation"] = itemVariations;
    }

    // { name: "itag", longName: "Tag array", fieldType: "STRING_ARRAY", maxLength: 100, minLength: 0, userSettable: true},
    if (itemTags.count)
    {
        dictionary[@"itag"] = itemTags;
    }

    // {name: "mnavtime", longName: "MOBILE_NAVIGATION_TIME", fieldType: "INT", definitionLevel: "APP", userSettable: true}
    if (self.navigationTime >= 0.0)
    {
        dictionary[@"mnavtime"] = @((int64_t) round(self.navigationTime * 1000.0));
    }

    // {name: "ni", longName: "NUMBER_OF_ITEMS", fieldType: "INT_ARRAY", maxLength: 100, minLength: 0, minValue: 1, userSettable: true}
    if (itemQuantities.count)
    {
        dictionary[@"ni"] = itemQuantities;
    }

    // {name: "order_id", longName: "ORDER_ID", fieldType: "STRING", userSettable: true}
    if (self.orderId.length)
    {
        dictionary[@"order_id"] = self.orderId;
    }

    // {name": "oa", longName: "OR_AND", fieldType: "STRING", maxLength: 1, minLength: 0, validValues: ["o", "a"], userSettable: true}
    if (self.searchMethod != RSDKAnalyticsInvalidSearchMethod)
    {
        dictionary[@"oa"] = self.searchMethod == RSDKAnalyticsSearchMethodAnd ? @"a" : @"o";
    }

    // {name: "pgid", longName: "PAGE_ID", fieldType: "STRING", maxLength: 32, minLength: 1, userSettable: false},
    if (self.pageIdentifier.length)
    {
        dictionary[@"pgid"] = self.pageIdentifier;
    }

    // {name: "pgn", longName: "PAGE_NAME", fieldType: "STRING", maxLength: 1024, minLength: 0, userSettable: true}
    if (self.pageName.length)
    {
        dictionary[@"pgn"] = self.pageName;
    }

    // {name: "pgt", longName: "PAGE_TYPE", fieldType: "STRING", maxLength: 20, minLength: 0, userSettable: true}
    if (self.pageType.length)
    {
        dictionary[@"pgt"] = self.pageType;
    }

    // {name: "price", longName: "PRICE", fieldType: "DOUBLE_ARRAY", maxLength: 100, minLength: 0, userSettable: true}
    if (itemPrices.count)
    {
        dictionary[@"price"] = itemPrices;
    }

    // {name: "ref", longName: "REFERRER", fieldType: "URL", maxLength: 2048, minLength: 0, userSettable: false}
    if (self.referrer.length)
    {
        dictionary[@"ref"] = self.referrer;
    }

    // {name: "reqc", longName: "REQUEST_CODE", fieldType: "STRING", maxLength: 32, minLength: 0, userSettable: true}
    if (self.requestCode.length)
    {
        dictionary[@"reqc"] = self.requestCode;
    }

    // {name: "scroll", longName: "SCROLL_DIV_ID", fieldType: "STRING_ARRAY", maxLength: 100, minLength: 1, userSettable: true
    if (self.scrollDivId.count)
    {
        dictionary[@"scroll"] = self.scrollDivId;
    }

    // {name: "sresv", longName: "SCROLL_VIEWED", fieldType: "STRING_ARRAY", maxLength: 100, minLength: 1, userSettable: false}
    if (self.scrollViewed.count)
    {
        dictionary[@"sresv"] = self.scrollViewed;
    }

    // {name: "sq", longName: "SEARCH_QUERY", fieldType: "STRING", maxLength: 1024, minLength: 0, userSettable: true}
    if (self.searchQuery.length)
    {
        dictionary[@"sq"] = self.searchQuery;
    }

    // {name: "lang", longName: "SEARCH_SELECTED_LANGUAGE", maxLength: 16, minLength: 0, userSettable: true}
    if (self.searchSelectedLocale)
    {
        dictionary[@"lang"] = self.searchSelectedLocale.localeIdentifier;
    }

    // {name: "aid", longName: "SERVICE_ID", fieldType: "INT", userSettable: true}
    dictionary[@"aid"] = @(self.serviceId);

    // {name: "shopid", longName: "SHOP_ID", fieldType: "STRING", userSettable: true}
    if (self.shopId.length)
    {
        dictionary[@"shopid"] = self.shopId;
    }

    return dictionary;
}
#pragma clang diagnostic pop


- (NSString *)description
{
    return [NSString stringWithFormat:@"<%@: %p, %@>", NSStringFromClass(self.class), self, self.propertiesDictionary];
}

#pragma mark - NSSecureCoding

+ (BOOL)supportsSecureCoding
{
    return YES;
}

- (instancetype)initWithCoder:(NSCoder *)decoder
{
    union
    {
        uint64_t unsignedValue;
        int64_t  signedValue;
    } value64;

    value64.signedValue     = [decoder decodeInt64ForKey:NSStringFromSelector(@selector(accountId))];
    uint64_t  accountId     = value64.unsignedValue;
    int64_t   serviceId     = [decoder decodeInt64ForKey:NSStringFromSelector(@selector(serviceId))];

    if (self = [self initWithAccountId:accountId serviceId:serviceId])
    {
        self.userId                 = [decoder decodeObjectOfClass:NSString.class forKey:NSStringFromSelector(@selector(userId))] ?:
                                      [decoder decodeObjectOfClass:NSString.class forKey:NSStringFromSelector(@selector(easyId))];
        self.affiliateId            = [decoder decodeInt64ForKey:NSStringFromSelector(@selector(affiliateId))];
        self.goalId                 = [decoder decodeObjectOfClass:NSString.class forKey:NSStringFromSelector(@selector(goalId))];
        self.campaignCode           = [decoder decodeObjectOfClass:NSString.class forKey:NSStringFromSelector(@selector(campaignCode))];
        self.shopId                 = [decoder decodeObjectOfClass:NSString.class forKey:NSStringFromSelector(@selector(shopId))];

        self.contentLocale          = [decoder decodeObjectOfClass:NSLocale.class forKey:NSStringFromSelector(@selector(contentLocale))];
        self.currencyCode           = [decoder decodeObjectOfClass:NSString.class forKey:NSStringFromSelector(@selector(currencyCode))];

        self.searchSelectedLocale   = [decoder decodeObjectOfClass:NSLocale.class forKey:NSStringFromSelector(@selector(searchSelectedLocale))];
        self.searchQuery            = [decoder decodeObjectOfClass:NSString.class forKey:NSStringFromSelector(@selector(searchQuery))];
        self.searchMethod           = [decoder decodeIntegerForKey:NSStringFromSelector(@selector(searchMethod))];
        self.excludeWordSearchQuery = [decoder decodeObjectOfClass:NSString.class forKey:NSStringFromSelector(@selector(excludeWordSearchQuery))];
        self.genre                  = [decoder decodeObjectOfClass:NSString.class forKey:NSStringFromSelector(@selector(genre))];
        self.selectedTags           = [decoder decodeObjectOfClass:NSArray.class forKey:NSStringFromSelector(@selector(selectedTags))];

        self.pageIdentifier         = [decoder decodeObjectOfClass:NSString.class forKey:NSStringFromSelector(@selector(pageIdentifier))];
        self.pageName               = [decoder decodeObjectOfClass:NSString.class forKey:NSStringFromSelector(@selector(pageName))];
        self.pageType               = [decoder decodeObjectOfClass:NSString.class forKey:NSStringFromSelector(@selector(pageType))];
        self.referrer               = [decoder decodeObjectOfClass:NSString.class forKey:NSStringFromSelector(@selector(referrer))];
        self.navigationTime         = [decoder decodeDoubleForKey:NSStringFromSelector(@selector(navigationTime))];
        self.checkpoints            = [decoder decodeInt64ForKey:NSStringFromSelector(@selector(checkpoints))];

        NSArray *immutableItems     = [decoder decodeObjectOfClass:NSArray.class forKey:NSStringFromSelector(@selector(items))];
        self.items                  = immutableItems.mutableCopy;

        self.orderId                = [decoder decodeObjectOfClass:NSString.class forKey:NSStringFromSelector(@selector(orderId))];
        value64.signedValue         = [decoder decodeInt64ForKey:NSStringFromSelector(@selector(cartState))];
        self.cartState              = value64.unsignedValue;
        self.checkoutStage          = [decoder decodeIntegerForKey:NSStringFromSelector(@selector(checkoutStage))];

        self.componentId            = [decoder decodeObjectOfClass:NSArray.class forKey:NSStringFromSelector(@selector(componentId))];
        self.componentTop           = [decoder decodeObjectOfClass:NSArray.class forKey:NSStringFromSelector(@selector(componentTop))];
        self.customParameters       = [decoder decodeObjectOfClass:NSDictionary.class forKey:NSStringFromSelector(@selector(customParameters))];
        self.eventType              = [decoder decodeObjectOfClass:NSString.class forKey:NSStringFromSelector(@selector(eventType))];
        self.requestCode            = [decoder decodeObjectOfClass:NSString.class forKey:NSStringFromSelector(@selector(requestCode))];
        self.scrollDivId            = [decoder decodeObjectOfClass:NSArray.class forKey:NSStringFromSelector(@selector(scrollDivId))];
        self.scrollViewed           = [decoder decodeObjectOfClass:NSArray.class forKey:NSStringFromSelector(@selector(scrollViewed))];
    }

    return self;
}

- (void)encodeWithCoder:(NSCoder *)coder
{
    union
    {
        uint64_t unsignedValue;
        int64_t  signedValue;
    } value64;

    value64.unsignedValue = self.accountId;
    [coder encodeInt64:value64.signedValue          forKey:NSStringFromSelector(@selector(accountId))];
    [coder encodeInt64:self.serviceId               forKey:NSStringFromSelector(@selector(serviceId))];
    [coder encodeObject:self.userId                 forKey:NSStringFromSelector(@selector(userId))];
    [coder encodeInt64:self.affiliateId             forKey:NSStringFromSelector(@selector(affiliateId))];
    [coder encodeObject:self.goalId                 forKey:NSStringFromSelector(@selector(goalId))];
    [coder encodeObject:self.campaignCode           forKey:NSStringFromSelector(@selector(campaignCode))];
    [coder encodeObject:self.shopId                 forKey:NSStringFromSelector(@selector(shopId))];

    [coder encodeObject:self.contentLocale          forKey:NSStringFromSelector(@selector(contentLocale))];
    [coder encodeObject:self.currencyCode           forKey:NSStringFromSelector(@selector(currencyCode))];

    [coder encodeObject:self.searchSelectedLocale   forKey:NSStringFromSelector(@selector(searchSelectedLocale))];
    [coder encodeObject:self.searchQuery            forKey:NSStringFromSelector(@selector(searchQuery))];
    [coder encodeInteger:self.searchMethod          forKey:NSStringFromSelector(@selector(searchMethod))];
    [coder encodeObject:self.excludeWordSearchQuery forKey:NSStringFromSelector(@selector(excludeWordSearchQuery))];
    [coder encodeObject:self.genre                  forKey:NSStringFromSelector(@selector(genre))];
    [coder encodeObject:self.selectedTags           forKey:NSStringFromSelector(@selector(selectedTags))];

    [coder encodeObject:self.pageIdentifier         forKey:NSStringFromSelector(@selector(pageIdentifier))];
    [coder encodeObject:self.pageName               forKey:NSStringFromSelector(@selector(pageName))];
    [coder encodeObject:self.pageType               forKey:NSStringFromSelector(@selector(pageType))];
    [coder encodeObject:self.referrer               forKey:NSStringFromSelector(@selector(referrer))];
    [coder encodeDouble:self.navigationTime         forKey:NSStringFromSelector(@selector(navigationTime))];
    [coder encodeInt64:self.checkpoints             forKey:NSStringFromSelector(@selector(checkpoints))];

    [coder encodeObject:self.items                  forKey:NSStringFromSelector(@selector(items))];

    value64.unsignedValue = self.cartState;
    [coder encodeObject:self.orderId                forKey:NSStringFromSelector(@selector(orderId))];
    [coder encodeInt64:value64.signedValue          forKey:NSStringFromSelector(@selector(cartState))];
    [coder encodeInteger:self.checkoutStage         forKey:NSStringFromSelector(@selector(checkoutStage))];

    [coder encodeObject:self.componentId            forKey:NSStringFromSelector(@selector(componentId))];
    [coder encodeObject:self.componentTop           forKey:NSStringFromSelector(@selector(componentTop))];
    [coder encodeObject:self.customParameters       forKey:NSStringFromSelector(@selector(customParameters))];
    [coder encodeObject:self.eventType              forKey:NSStringFromSelector(@selector(eventType))];
    [coder encodeObject:self.requestCode            forKey:NSStringFromSelector(@selector(requestCode))];
    [coder encodeObject:self.scrollDivId            forKey:NSStringFromSelector(@selector(scrollDivId))];
    [coder encodeObject:self.scrollViewed           forKey:NSStringFromSelector(@selector(scrollViewed))];
}

#pragma mark - NSCopying

- (instancetype)copyWithZone:(NSZone __unused *)zone
{
    RSDKAnalyticsRecord *copy = [RSDKAnalyticsRecord recordWithAccountId:self.accountId serviceId:self.serviceId];

    copy.userId                 = self.userId;
    copy.affiliateId            = self.affiliateId;
    copy.goalId                 = self.goalId;
    copy.campaignCode           = self.campaignCode;
    copy.shopId                 = self.shopId;
    copy.contentLocale          = self.contentLocale;
    copy.currencyCode           = self.currencyCode;
    copy.searchSelectedLocale   = self.searchSelectedLocale;
    copy.searchQuery            = self.searchQuery;
    copy.searchMethod           = self.searchMethod;
    copy.excludeWordSearchQuery = self.excludeWordSearchQuery;
    copy.genre                  = self.genre;
    if (self.selectedTags.count)
    {
        copy.selectedTags       = [NSArray.alloc initWithArray:self.selectedTags copyItems:YES];
    }
    copy.pageIdentifier         = self.pageIdentifier;
    copy.pageName               = self.pageName;
    copy.pageType               = self.pageType;
    copy.referrer               = self.referrer;
    copy.navigationTime         = self.navigationTime;
    copy.checkpoints            = self.checkpoints;
    if (self.items.count)
    {
        copy.items              = [NSMutableArray.alloc initWithArray:self.items copyItems:YES];
    }
    copy.orderId                = self.orderId;
    copy.cartState              = self.cartState;
    copy.checkoutStage          = self.checkoutStage;
    if (self.componentId.count)
    {
        copy.componentId        = [NSArray.alloc initWithArray:self.componentId copyItems:YES];
    }
    if (self.componentTop.count)
    {
        copy.componentTop       = [NSArray.alloc initWithArray:self.componentTop copyItems:YES];
    }
    if (self.customParameters.count)
    {
        copy.customParameters = (__bridge_transfer NSDictionary *)(CFPropertyListCreateDeepCopy(kCFAllocatorDefault,
                                                                                                (__bridge CFPropertyListRef) self.customParameters,
                                                                                                kCFPropertyListImmutable));
    }
    copy.eventType              = self.eventType;
    copy.requestCode            = self.requestCode;
    if (self.scrollDivId.count)
    {
        copy.scrollDivId        = [NSArray.alloc initWithArray:self.scrollDivId copyItems:YES];
    }
    if (self.scrollViewed.count)
    {
        copy.scrollViewed       = [NSArray.alloc initWithArray:self.scrollViewed copyItems:YES];
    }
    return copy;
}

#pragma mark - NSObject

- (BOOL)isEqual:(id)object
{
    if (self == object)
    {
        return YES;
    }

    if (![object isKindOfClass:self.class])
    {
        return NO;
    }

    return [self.propertiesDictionary isEqual:[object propertiesDictionary]];
}

- (NSUInteger)hash
{
    return self.propertiesDictionary.hash;
}

# pragma mark - Deprecated

- (NSString *)easyId
{
    return self.userId;
}

- (void)setEasyId:(NSString *)easyId
{
    self.userId = easyId;
}

@end

