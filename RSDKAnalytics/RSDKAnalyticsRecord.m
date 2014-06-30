//
//  RSDKAnalyticsRecord.m
//  RSDKAnalytics
//
//  Created by Julien Cayzac on 5/19/14.
//  Copyright (c) 2014 Rakuten, Inc. All rights reserved.
//

#import "RSDKAnalyticsRecord.h"
#import <RSDKSupport/RSDKAssert.h>

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
@end

@implementation RSDKAnalyticsRecord

#pragma mark - Initializers

- (instancetype)init
{
    RSDKALWAYSASSERT(@"Please use +[RSDKAnalyticsRecord recordWithAccountId:serviceId:]");
    return nil;
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
    }
    return self;
}

#pragma mark - Public methods

+ (instancetype)recordWithAccountId:(uint64_t)accountId serviceId:(int64_t)serviceId
{
    return [self.alloc initWithAccountId:accountId serviceId:serviceId];
}

- (NSDictionary *)propertiesDictionary
{
    NSMutableDictionary *dictionary = NSMutableDictionary.new;

    // {name: "acc", longName: "ACCOUNT_ID", fieldType: "INT", minValue: 0, userSettable: true}
    dictionary[@"acc"] = @(self.accountId);

    // {name: "easyid", longName: "EASY_ID", fieldType: "STRING", maxLength: 16, minLength: 3, userSettable: true}
    if (self.easyId)
    {
        dictionary[@"easyid"] = self.easyId;
    }

    // {name: "afid", longName: "AFFILIATE_ID", fieldType: "INT", userSettable: true}
    if (self.affiliateId != RSDKAnalyticsInvalidAffiliateId)
    {
        dictionary[@"afid"] = @(self.affiliateId);
    }

    // {name: "cc", longName: "CAMPAIGN_CODE", fieldType: "STRING", maxLength: 20, minLength: 0, userSettable: true}
    if (self.campaignCode)
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
    if (self.componentId)
    {
        dictionary[@"compid"] = self.componentId;
    }

    // {name: "comptop",longName: "COMPONENT_TOP",fieldType: "DOUBLE_ARRAY",userSettable: true}
    if (self.componentTop)
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
        dictionary[@"cycode"] = self.currencyCode;
    }

    // {name: "cp", longName: "CUSTOM_PARAMETERS", fieldType: "JSON"}
    if (self.customParameters)
    {
        dictionary[@"cp"] = self.customParameters;
    }

    // {name: "etype",longName: "EVENT_TYPE",fieldType: "STRING",userSettable: true}
    if (self.eventType)
    {
        dictionary[@"etype"] = self.eventType;
    }

    // {name: "esq", longName: "EXCLUDE_WORD_SEARCH_QUERY", fieldType: "STRING", maxLength: 1024, minLength: 0, userSettable: true}
    if (self.excludeWordSearchQuery)
    {
        dictionary[@"esq"] = self.excludeWordSearchQuery;
    }

    // {name: "genre", longName: "GENRE", definitionLevel: "RAL", fieldType: "STRING", maxLength: 200, minLength: 0, userSettable: true}
    if (self.genre)
    {
        dictionary[@"genre"] = self.genre;
    }

    // {name: "gol", longName: "GOAL_ID", fieldType: "STRING", maxLength: 10, minLength: 0, userSettable: true}
    if (self.goalId)
    {
        dictionary[@"gol"] = self.goalId;
    }

    // {name: "igenre", longName: "ITEM_GENRE", fieldType: "STRING_ARRAY", definitionLevel: "RAL", maxLength": 100, minLength: 0, userSettable: true}
    if (self.itemGenre)
    {
        dictionary[@"igenre"] = self.itemGenre;
    }

    // {name: "itemid", longName: "ITEM_ID", fieldType: "STRING_ARRAY", definitionLevel: "RAL", maxLength": 100, minLength: 0, userSettable: true}
    if (self.itemId)
    {
        dictionary[@"itemid"] = self.itemId;
    }

    // {name: "variation", longName: "ITEM_VARIATION", fieldType: "JSON_ARRAY", definitionLevel: "RAL", maxLength": 100, minLength: 0, userSettable: true}
    if (self.itemVariation)
    {
        dictionary[@"variation"] = self.itemVariation;
    }

    // {name: "mnavtime", longName: "MOBILE_NAVIGATION_TIME", fieldType: "INT", definitionLevel: "APP", userSettable: true}
    if (self.navigationTime >= 0.0)
    {
        dictionary[@"mnavtime"] = @((int64_t) round(self.navigationTime * 1000.0));
    }

    // {name: "ni", longName: "NUMBER_OF_ITEMS", fieldType: "INT_ARRAY", maxLength: 100, minLength: 0, minValue: 1, userSettable: true}
    if (self.numberOfItems)
    {
        dictionary[@"ni"] = self.numberOfItems;
    }

    // {name: "order_id", longName: "ORDER_ID", fieldType: "STRING", userSettable: true}
    if (self.orderId)
    {
        dictionary[@"order_id"] = self.orderId;
    }

    // {name": "oa", longName: "OR_AND", fieldType: "STRING", maxLength: 1, minLength: 0, validValues: ["o", "a"], userSettable: true}
    if (self.searchMethod != RSDKAnalyticsInvalidSearchMethod)
    {
        dictionary[@"oa"] = self.searchMethod == RSDKAnalyticsSearchMethodAnd ? @"a" : @"o";
    }

    // {name: "pgn", longName: "PAGE_NAME", fieldType: "STRING", maxLength: 1024, minLength: 0, userSettable: true}
    if (self.pageName)
    {
        dictionary[@"pgn"] = self.pageName;
    }

    // {name: "pgt", longName: "PAGE_TYPE", fieldType: "STRING", maxLength: 20, minLength: 0, userSettable: true}
    if (self.pageType)
    {
        dictionary[@"pgt"] = self.pageType;
    }

    // {name: "price", longName: "PRICE", fieldType: "DOUBLE_ARRAY", maxLength: 100, minLength: 0, userSettable: true}
    if (self.itemPrice)
    {
        dictionary[@"price"] = self.itemPrice;
    }

    // {name: "ref", longName: "REFERRER", fieldType: "URL", maxLength: 2048, minLength: 0, userSettable: false}
    if (self.referrer)
    {
        dictionary[@"ref"] = self.referrer;
    }

    // {name: "reqc", longName: "REQUEST_CODE", fieldType: "STRING", maxLength: 32, minLength: 0, userSettable: true}
    if (self.requestCode)
    {
        dictionary[@"reqc"] = self.requestCode;
    }

    // {name: "scroll", longName: "SCROLL_DIV_ID", fieldType: "STRING_ARRAY", maxLength: 100, minLength: 1, userSettable: true
    if (self.scrollDivId)
    {
        dictionary[@"scroll"] = self.scrollDivId;
    }

    // {name: "sresv", longName: "SCROLL_VIEWED", fieldType: "STRING_ARRAY", maxLength: 100, minLength: 1, userSettable: false}
    if (self.scrollViewed)
    {
        dictionary[@"sresv"] = self.scrollViewed;
    }

    // {name: "sq", longName: "SEARCH_QUERY", fieldType: "STRING", maxLength: 1024, minLength: 0, userSettable: true}
    if (self.searchQuery)
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
    if (self.shopId)
    {
        dictionary[@"shopid"] = self.shopId;
    }

    return dictionary;
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"<%@: %p, %@>", NSStringFromClass(self.class), self, self.propertiesDictionary];
}

#pragma mark - Setters for RAT parameters with restrictions

- (void)setCampaignCode:(NSString *)campaignCode
{
    _campaignCode = [self _validateString:campaignCode propertyName:@"campaignCode" maxLength:20 predicate:nil];
}

//--------------------------------------------------------------------------

- (void)setCheckoutStage:(RSDKAnalyticsCheckoutStage)checkoutStage
{
    if (checkoutStage != RSDKAnalyticsCheckoutStage1Login &&
        checkoutStage != RSDKAnalyticsCheckoutStage2ShippingDetails &&
        checkoutStage != RSDKAnalyticsCheckoutStage3OrderSummary &&
        checkoutStage != RSDKAnalyticsCheckoutStage4Payment &&
        checkoutStage != RSDKAnalyticsCheckoutStage5Verification &&
        checkoutStage != RSDKAnalyticsInvalidCheckoutStage)
    {
        RSDKALWAYSASSERT(@"checkoutStage: Expected a RSDKAnalyticsCheckoutStage, got %d", (int) checkoutStage);
        _checkoutStage = RSDKAnalyticsInvalidCheckoutStage;
        return;
    }

    _checkoutStage = checkoutStage;
}

//--------------------------------------------------------------------------

- (void)setComponentId:(NSArray *)componentId
{
    _componentId = [self _validateArray:componentId propertyName:@"componentId" maxLength:-1 itemValidator:^BOOL(NSObject *item, int index)
    {
        // Silence -Wunused when DEBUG is not defined
        (void)index;

        BOOL ok = [item isKindOfClass:NSString.class];
        RSDKASSERTIFNOT(ok, @"componentId[%i]: Expected a NSString, found a %@", index, NSStringFromClass(item.class));
        return ok;
    }];
}

//--------------------------------------------------------------------------

- (void)setComponentTop:(NSArray *)componentTop
{
    _componentTop = [self _validateArray:componentTop propertyName:@"componentTop" maxLength:-1 itemValidator:^BOOL(NSObject *item, int index)
    {
        // Silence -Wunused when DEBUG is not defined
        (void)index;

        RSDKASSERTIFNOT([item isKindOfClass:NSNumber.class], @"componentTop[%i]: Expected a NSNumber, found a %@", index, NSStringFromClass(item.class));
        return [item isKindOfClass:NSNumber.class];
    }];
}

//--------------------------------------------------------------------------

- (void)setCurrencyCode:(NSString *)currencyCode
{
    static NSSet *ISOCurrencyCodes;
    static dispatch_once_t once;
    dispatch_once(&once, ^
    {
        ISOCurrencyCodes = [NSSet setWithArray:NSLocale.ISOCurrencyCodes];
    });

    if (currencyCode)
    {
        NSString *normalizedCurrencyCode = currencyCode.uppercaseString;

        if ([ISOCurrencyCodes containsObject:normalizedCurrencyCode])
        {
            _currencyCode = normalizedCurrencyCode;
            return;
        }

        RSDKALWAYSASSERT(@"\"%@\" is not a recognized ISO-4217 currency code", currencyCode);
    }

    _currencyCode = nil;
}

//--------------------------------------------------------------------------

- (void)setCustomParameters:(NSDictionary *)customParameters
{
    if (!customParameters.count)
    {
        _customParameters = nil;
        return;
    }

    _customParameters = customParameters.copy;
}

//--------------------------------------------------------------------------

- (void)setEasyId:(NSString *)easyId
{
    _easyId = [self _validateString:easyId propertyName:@"easyId" maxLength:25 predicate:^BOOL(NSString *string)
    {
        return string.length >= 3;
    }];
}

//--------------------------------------------------------------------------

- (void)setExcludeWordSearchQuery:(NSString*)excludeWordSearchQuery
{
    _excludeWordSearchQuery = [self _validateString:excludeWordSearchQuery propertyName:@"excludeWordSearchQuery" maxLength:1024 predicate:nil];
}

//--------------------------------------------------------------------------

- (void)setGenre:(NSString*)genre
{
    _genre = [self _validateString:genre propertyName:@"genre" maxLength:200 predicate:nil];
}

//--------------------------------------------------------------------------

- (void)setGoalId:(NSString *)goalId
{
    _goalId = [self _validateString:goalId propertyName:@"goalId" maxLength:10 predicate:nil];
}

//--------------------------------------------------------------------------

- (void)setItemGenre:(NSArray *)itemGenre
{
    _itemGenre = [self _validateArray:itemGenre propertyName:@"itemGenre" maxLength:100 itemValidator:^BOOL(NSObject *item, int index)
    {
        // Silence -Wunused when DEBUG is not defined
        (void)index;

        RSDKASSERTIFNOT([item isKindOfClass:NSString.class], @"itemGenre[%i]: Expected a NSString, found a %@", index, NSStringFromClass(item.class));
        return [item isKindOfClass:NSString.class];
    }];
}

//--------------------------------------------------------------------------

- (void)setItemId:(NSArray *)itemId
{
    _itemId = [self _validateArray:itemId propertyName:@"itemId" maxLength:100 itemValidator:^BOOL(NSObject *item, int index)
    {
        // Silence -Wunused when DEBUG is not defined
        (void)index;

        RSDKASSERTIFNOT([item isKindOfClass:NSString.class], @"itemId[%i]: Expected a NSString, found a %@", index, NSStringFromClass(item.class));
        return [item isKindOfClass:NSString.class];
    }];
}

//--------------------------------------------------------------------------

- (void)setItemVariation:(NSArray *)itemVariation
{
    _itemVariation = [self _validateArray:itemVariation propertyName:@"itemVariation" maxLength:100 itemValidator:^BOOL(NSObject *item, int index)
    {
        // Silence -Wunused when DEBUG is not defined
        (void)index;

        RSDKASSERTIFNOT([item isKindOfClass:NSArray.class] || [item isKindOfClass:NSDictionary.class], @"itemVariation[%i]: Expected either a NSArray or a NSDictionary, found a %@", index, NSStringFromClass(item.class));
        return [item isKindOfClass:NSArray.class] || [item isKindOfClass:NSDictionary.class];
    }];
}

//--------------------------------------------------------------------------

- (void)setNumberOfItems:(NSArray *)numberOfItems
{
    _numberOfItems = [self _validateArray:numberOfItems propertyName:@"numberOfItems" maxLength:100 itemValidator:^BOOL(NSNumber *item, int index)
    {
        // Silence -Wunused when DEBUG is not defined
        (void)index;

        if (![item isKindOfClass:NSNumber.class])
        {
            RSDKALWAYSASSERT(@"numberOfItems[%i]: Expected a NSNumber, found a %@", index, NSStringFromClass(item.class));
            return NO;
        }

        int64_t value = item.longLongValue;
        if (value < 1 || ![item isEqualToNumber:@(value)])
        {
            RSDKALWAYSASSERT(@"numberOfItems[%i]: Expected an integer strictly greater than 0, found %@", index, item);
            return NO;
        }

        return YES;
    }];
}

//--------------------------------------------------------------------------

- (void)setPageName:(NSString *)pageName
{
    _pageName = [self _validateString:pageName propertyName:@"pageName" maxLength:1024 predicate:nil];
}

//--------------------------------------------------------------------------

- (void)setPageType:(NSString *)pageType
{
    _pageType = [self _validateString:pageType propertyName:@"pageType" maxLength:20 predicate:nil];
}

//--------------------------------------------------------------------------

- (void)setItemPrice:(NSArray *)itemPrice
{
    _itemPrice = [self _validateArray:itemPrice propertyName:@"itemPrice" maxLength:100 itemValidator:^BOOL(NSNumber *item, int index)
    {
        // Silence -Wunused when DEBUG is not defined
        (void)index;

        RSDKASSERTIFNOT([item isKindOfClass:NSNumber.class], @"itemPrice[%i]: Expected a NSNumber, found a %@", index, NSStringFromClass(item.class));
        return [item isKindOfClass:NSNumber.class];
    }];
}

//--------------------------------------------------------------------------

- (void)setReferrer:(NSString *)referrer
{
    _referrer = [self _validateString:referrer propertyName:@"referrer" maxLength:2048 predicate:nil];
}

//--------------------------------------------------------------------------

- (void)setRequestCode:(NSString *)requestCode
{
    _requestCode = [self _validateString:requestCode propertyName:@"requestCode" maxLength:32 predicate:nil];
}

//--------------------------------------------------------------------------

- (void)setScrollDivId:(NSArray *)scrollDivId
{
    if (scrollDivId.count < 1)
    {
        _scrollDivId = nil;
        return;
    }

    _scrollDivId = [self _validateArray:scrollDivId propertyName:@"scrollDivId" maxLength:100 itemValidator:^BOOL(NSNumber *item, int index)
    {
        // Silence -Wunused when DEBUG is not defined
        (void)index;

        RSDKASSERTIFNOT([item isKindOfClass:NSString.class], @"scrollDivId[%i]: Expected a NSString, found a %@", index, NSStringFromClass(item.class));
        return [item isKindOfClass:NSString.class];
    }];
}

//--------------------------------------------------------------------------

- (void)setScrollViewed:(NSArray *)scrollViewed
{
    if (scrollViewed.count < 1)
    {
        _scrollViewed = nil;
        return;
    }

    _scrollViewed = [self _validateArray:scrollViewed propertyName:@"scrollViewed" maxLength:100 itemValidator:^BOOL(NSNumber *item, int index)
    {
        // Silence -Wunused when DEBUG is not defined
        (void)index;

        RSDKASSERTIFNOT([item isKindOfClass:NSString.class], @"scrollViewed[%i]: Expected a NSString, found a %@", index, NSStringFromClass(item.class));
        return [item isKindOfClass:NSString.class];
    }];
}

//--------------------------------------------------------------------------

- (void)setSearchQuery:(NSString *)searchQuery
{
    _searchQuery = [self _validateString:searchQuery propertyName:@"searchQuery" maxLength:1024 predicate:nil];
}

//--------------------------------------------------------------------------

#pragma mark - Validation

- (NSString *)_validateString:(NSString *)string propertyName:(NSString *)propertyName maxLength:(NSInteger)maxLength predicate:(BOOL (^)(NSString *string))predicate
{
    // Silence -Wunused when DEBUG is not defined
    (void)propertyName;

    if (!string)
    {
        return nil;
    }

    if (![string isKindOfClass:NSString.class])
    {
        RSDKALWAYSASSERT(@"%@: Expected a NSString, found a %@", propertyName, NSStringFromClass(string.class));
        return nil;
    }

    unsigned long length = string.length;
    if (maxLength >= 0 && length > (unsigned long)maxLength)
    {
        RSDKALWAYSASSERT(@"%@: string too long (%lu > %lu)", propertyName, length, (unsigned long)maxLength);
        return nil;
    }

    if (predicate)
    {
        if (!predicate(string))
        {
            RSDKALWAYSASSERT(@"%@: validation failed", propertyName);
            return nil;
        }
    }

    // Ensure the returned value is immutable
    return string.copy;
}

- (NSArray *)_validateArray:(NSArray *)array propertyName:(NSString *)propertyName maxLength:(NSInteger)maxLength itemValidator:(BOOL (^)(id item, int index))itemValidator
{
    // Silence -Wunused when DEBUG is not defined
    (void)propertyName;

    if (!array)
    {
        return nil;
    }

    if (![array isKindOfClass:NSArray.class])
    {
        RSDKALWAYSASSERT(@"%@: Expected a NSArray, found a %@", propertyName, NSStringFromClass(array.class));
        return nil;
    }

    unsigned long length = array.count;
    if (maxLength >= 0 && length > (unsigned long)maxLength)
    {
        RSDKALWAYSASSERT(@"%@: array too long (%lu > %lu)", propertyName, length, (unsigned long)maxLength);
        return nil;
    }

    if (itemValidator)
    {
        int index = -1;
        for (id item in array)
        {
            ++index;
            if (!itemValidator(item, index))
            {
                RSDKALWAYSASSERT(@"%@[%i]: validation failed", propertyName, index);
                return nil;
            }
        }
    }

    // Ensure the returned value is immutable
    return array.copy;
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
        self.easyId                 = [decoder decodeObjectOfClass:NSString.class forKey:NSStringFromSelector(@selector(easyId))];
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

        self.pageName               = [decoder decodeObjectOfClass:NSString.class forKey:NSStringFromSelector(@selector(pageName))];
        self.pageType               = [decoder decodeObjectOfClass:NSString.class forKey:NSStringFromSelector(@selector(pageType))];
        self.referrer               = [decoder decodeObjectOfClass:NSString.class forKey:NSStringFromSelector(@selector(referrer))];
        self.navigationTime         = [decoder decodeDoubleForKey:NSStringFromSelector(@selector(navigationTime))];
        self.checkpoints            = [decoder decodeInt64ForKey:NSStringFromSelector(@selector(checkpoints))];

        self.itemId                 = [decoder decodeObjectOfClass:NSArray.class forKey:NSStringFromSelector(@selector(itemId))];
        self.numberOfItems          = [decoder decodeObjectOfClass:NSArray.class forKey:NSStringFromSelector(@selector(numberOfItems))];
        self.itemPrice              = [decoder decodeObjectOfClass:NSArray.class forKey:NSStringFromSelector(@selector(itemPrice))];
        self.itemGenre              = [decoder decodeObjectOfClass:NSArray.class forKey:NSStringFromSelector(@selector(itemGenre))];
        self.itemVariation          = [decoder decodeObjectOfClass:NSArray.class forKey:NSStringFromSelector(@selector(itemVariation))];

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
    [coder encodeObject:self.easyId                 forKey:NSStringFromSelector(@selector(easyId))];
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

    [coder encodeObject:self.pageName               forKey:NSStringFromSelector(@selector(pageName))];
    [coder encodeObject:self.pageType               forKey:NSStringFromSelector(@selector(pageType))];
    [coder encodeObject:self.referrer               forKey:NSStringFromSelector(@selector(referrer))];
    [coder encodeDouble:self.navigationTime         forKey:NSStringFromSelector(@selector(navigationTime))];
    [coder encodeInt64:self.checkpoints             forKey:NSStringFromSelector(@selector(checkpoints))];

    [coder encodeObject:self.itemId                 forKey:NSStringFromSelector(@selector(itemId))];
    [coder encodeObject:self.numberOfItems          forKey:NSStringFromSelector(@selector(numberOfItems))];
    [coder encodeObject:self.itemPrice              forKey:NSStringFromSelector(@selector(itemPrice))];
    [coder encodeObject:self.itemVariation          forKey:NSStringFromSelector(@selector(itemVariation))];

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

    copy.easyId                 = self.easyId;
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
    copy.pageName               = self.pageName;
    copy.pageType               = self.pageType;
    copy.referrer               = self.referrer;
    copy.navigationTime         = self.navigationTime;
    copy.checkpoints            = self.checkpoints;
    copy.itemId                 = [NSArray.new initWithArray:self.itemId copyItems:YES];
    copy.numberOfItems          = [NSArray.new initWithArray:self.numberOfItems copyItems:YES];
    copy.itemPrice              = [NSArray.new initWithArray:self.itemPrice copyItems:YES];
    copy.itemGenre              = [NSArray.new initWithArray:self.itemGenre copyItems:YES];
    copy.itemVariation          = [NSArray.new initWithArray:self.itemVariation copyItems:YES];
    copy.orderId                = self.orderId;
    copy.cartState              = self.cartState;
    copy.checkoutStage          = self.checkoutStage;
    copy.componentId            = [NSArray.new initWithArray:self.componentId copyItems:YES];
    copy.componentTop           = [NSArray.new initWithArray:self.componentTop copyItems:YES];
    copy.customParameters       = [NSDictionary.new initWithDictionary:self.customParameters copyItems:YES];
    copy.eventType              = self.eventType;
    copy.requestCode            = self.requestCode;
    copy.scrollDivId            = [NSArray.new initWithArray:self.scrollDivId copyItems:YES];
    copy.scrollViewed           = [NSArray.new initWithArray:self.scrollViewed copyItems:YES];
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

@end

