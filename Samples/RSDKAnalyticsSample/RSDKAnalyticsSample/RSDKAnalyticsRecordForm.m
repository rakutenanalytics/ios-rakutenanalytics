/*
 * © Rakuten, Inc.
 * authors: "Rakuten Mobile SDK Team | SDTD" <prj-rmsdk@mail.rakuten.com>
 */
#import "RSDKAnalyticsRecordForm.h"

/////////////////////////////////////////////////////////////////
// Subclass FXFormOptionPickerCell to show the selection indicator

@interface FXFormBaseCell()
- (void)setUp;
@end

@interface RSDKAnalyticsOptionPickerCell : FXFormOptionPickerCell
@end

@implementation RSDKAnalyticsOptionPickerCell
- (void)setUp
{
    [super setUp];
    self.pickerView.showsSelectionIndicator = YES;
    self.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
}
@end

@interface RSDKAnalyticsNumericFieldCell : FXFormTextFieldCell
@end

@implementation RSDKAnalyticsNumericFieldCell
- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
    static NSPredicate *predicate;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        predicate = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", @"^[0-9]*$"];
    });
    return [predicate evaluateWithObject:string];
}
@end


/////////////////////////////////////////////////////////////////
@implementation RSDKAnalyticsRecordForm

- (instancetype)init
{
    if ((self = [super init]))
    {
        self.trackIDFA = YES;
    }
    return self;
}

- (RSDKAnalyticsEvent *)event
{
    NSMutableDictionary *dictionary = NSMutableDictionary.new;

    NSMutableArray *itemIdentifiers = nil;
    NSMutableArray *itemQuantities  = nil;
    NSMutableArray *itemPrices      = nil;
    NSMutableArray *itemGenres      = nil;
    NSMutableArray *itemVariations  = nil;
    NSMutableArray *itemTags        = nil;

    NSUInteger itemCount = self.itemIdentifiers.count;
    if (itemCount)
    {
        itemIdentifiers = [NSMutableArray arrayWithCapacity:itemCount];
        itemQuantities  = [NSMutableArray arrayWithCapacity:itemCount];
        itemPrices      = [NSMutableArray arrayWithCapacity:itemCount];
        itemGenres      = [NSMutableArray arrayWithCapacity:itemCount];
        itemVariations  = [NSMutableArray arrayWithCapacity:itemCount];
        itemTags        = [NSMutableArray arrayWithCapacity:itemCount];

        for (NSString *itemIdentifier in self.itemIdentifiers)
        {
            [itemIdentifiers addObject:itemIdentifier];
            [itemQuantities  addObject:@3];
            [itemPrices      addObject:@12];

            [itemGenres      addObject:self.genreForItems?: @""];
            [itemVariations  addObject:@""];
            [itemTags        addObject:@""];
        }
    }

    // {name: "acc", longName: "ACCOUNT_ID", fieldType: "INT", minValue: 0, userSettable: true}
    dictionary[@"acc"] = @(self.accountId);

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
    if ([NSLocale localeWithLocaleIdentifier:self.contentLocale])
    {
        dictionary[@"cntln"] = [NSLocale localeWithLocaleIdentifier:self.contentLocale].localeIdentifier;
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
    if ([NSLocale localeWithLocaleIdentifier:self.searchSelectedLocale])
    {
        dictionary[@"lang"] = [NSLocale localeWithLocaleIdentifier:self.searchSelectedLocale].localeIdentifier;
    }

    // {name: "aid", longName: "SERVICE_ID", fieldType: "INT", userSettable: true}
    dictionary[@"aid"] = @(self.serviceId);

    // {name: "shopid", longName: "SHOP_ID", fieldType: "STRING", userSettable: true}
    if (self.shopId.length)
    {
        dictionary[@"shopid"] = self.shopId;
    }

    NSString *eventName = self.eventType ? [NSString stringWithFormat:@"%@%@",@"rat.",self.eventType] : @"rat.generic";
    return [RSDKAnalyticsEvent.alloc initWithName:eventName parameters:dictionary.copy];
}

#pragma mark - Fields

- (id)trackIDFAField
{
    return @{FXFormFieldAction: @"trackIDFAChanged:"};
}

- (id)trackLocationField
{
    return @{FXFormFieldAction: @"trackLocationChanged:"};
}

- (id)useStagingField
{
    return @{FXFormFieldAction: @"useStagingChanged:"};
}

- (id)accountIdField
{
    return @{FXFormFieldHeader: @"Environment",
             FXFormFieldType: FXFormFieldTypeUnsigned,
             FXFormFieldCell: RSDKAnalyticsNumericFieldCell.class};
}

- (id)serviceIdField
{
    return @{FXFormFieldType: FXFormFieldTypeUnsigned,
             FXFormFieldCell: RSDKAnalyticsNumericFieldCell.class};
}

- (id)affiliateIdField
{
    return @{FXFormFieldType: FXFormFieldTypeUnsigned,
             FXFormFieldCell: RSDKAnalyticsNumericFieldCell.class};
}

- (id)contentLocaleField
{
    id field = self.genericLocaleField_.mutableCopy;
    [field addEntriesFromDictionary:@{FXFormFieldHeader: @"Region",
                                      FXFormFieldTitle: @"Locale"}];
    return field;

}

- (id)currencyCodeField
{
    static NSMutableDictionary *currencies;
    static dispatch_once_t once;
    dispatch_once(&once, ^
    {
        currencies = NSMutableDictionary.new;
        for (NSString *currency in NSLocale.ISOCurrencyCodes)
        {
            NSString *displayName = [NSLocale.currentLocale displayNameForKey:NSLocaleCurrencyCode value:currency];
            if (displayName)
            {
                currencies[currency] = displayName;
            }
        }
    });

    return @{FXFormFieldOptions: [currencies.allKeys sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)],
             FXFormFieldValueTransformer: ^(id input)
             {
                 return currencies[input];
             },
             FXFormFieldCell: RSDKAnalyticsOptionPickerCell.class,
             FXFormFieldTitle: @"Currency",
             };
}

- (id)searchSelectedLocaleField
{
    id field = self.genericLocaleField_.mutableCopy;
    [field addEntriesFromDictionary:@{FXFormFieldHeader: @"Search",
                                      FXFormFieldTitle: @"Locale"}];
    return field;
}

- (id)searchQueryField
{
    return @{FXFormFieldTitle: @"Query"};
}

- (id)searchMethodField
{
    return @{FXFormFieldOptions: @[@(RSDKAnalyticsInvalidSearchMethod),
                                   @(RSDKAnalyticsSearchMethodAnd),
                                   @(RSDKAnalyticsSearchMethodOr)],
             FXFormFieldCell: RSDKAnalyticsOptionPickerCell.class,
             FXFormFieldTitle: @"Method",
             FXFormFieldValueTransformer: ^(id input)
             {
                 return @{@(RSDKAnalyticsInvalidSearchMethod): @"",
                          @(RSDKAnalyticsSearchMethodAnd):     @"AND",
                          @(RSDKAnalyticsSearchMethodOr):      @"OR",
                          }[input];
             },
             };
}

- (id)excludeWordSearchQueryField
{
    return @{FXFormFieldTitle: @"Exclude Word"};
}

- (id)pageNameField
{
    return @{FXFormFieldHeader: @"Navigation"};
}

- (id)referrerField
{
    return @{FXFormFieldTitle: @"Referrer URL",
             @"textField.keyboardType": @(UIKeyboardTypeURL)};
}

- (id)navigationTimeField
{
    return @{FXFormFieldTitle: @"Navigation Time (s)",
             @"textField.keyboardType": @(UIKeyboardTypeDecimalPad)};
}

- (id)genreForItemsField
{
    return @{FXFormFieldHeader: @"Items",
             FXFormFieldDefaultValue: @"dummyGenre"};
}

- (id)itemIdentifiersField
{
    return @{FXFormFieldInline: @YES,
             FXFormFieldTemplate: @{FXFormFieldDefaultValue: @"shopId/itemId",
                                    FXFormFieldType: FXFormFieldTypeText,
                                    FXFormFieldTitle: @"Add Item Id",
                                    },
             };
}

- (id)checkoutStageField
{
    return @{FXFormFieldOptions: @[@(RSDKAnalyticsInvalidCheckoutStage),
                                   @(RSDKAnalyticsCheckoutStage1Login),
                                   @(RSDKAnalyticsCheckoutStage2ShippingDetails),
                                   @(RSDKAnalyticsCheckoutStage3OrderSummary),
                                   @(RSDKAnalyticsCheckoutStage4Payment),
                                   @(RSDKAnalyticsCheckoutStage5Verification)],
             FXFormFieldCell: RSDKAnalyticsOptionPickerCell.class,
             FXFormFieldValueTransformer: ^(id input)
             {
                 return @{@(RSDKAnalyticsInvalidCheckoutStage):          @"",
                          @(RSDKAnalyticsCheckoutStage1Login):           @"1 Login",
                          @(RSDKAnalyticsCheckoutStage2ShippingDetails): @"2 Shipping Details",
                          @(RSDKAnalyticsCheckoutStage3OrderSummary):    @"3 Order Summary",
                          @(RSDKAnalyticsCheckoutStage4Payment):         @"4 Payment",
                          @(RSDKAnalyticsCheckoutStage5Verification):    @"5 Verification",
                          }[input];
             },
             };
}

- (id)cartStateField
{
    return @{FXFormFieldType: FXFormFieldTypeUnsigned,
             FXFormFieldCell: RSDKAnalyticsNumericFieldCell.class};
}

#pragma mark - Private methods

- (NSDictionary *)genericLocaleField_
{
    static NSMutableDictionary *localeIdentifiers;
    static dispatch_once_t once;
    dispatch_once(&once, ^
                  {
                      localeIdentifiers = NSMutableDictionary.new;
                      for (NSString *identifier in NSLocale.availableLocaleIdentifiers)
                      {
                          NSString *displayName = [NSLocale.currentLocale displayNameForKey:NSLocaleIdentifier
                                                                                      value:identifier];
                          if (displayName)
                          {
                              localeIdentifiers[identifier] = displayName;
                          }
                      }
                  });

    return @{FXFormFieldOptions: [localeIdentifiers.allKeys sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)],
             FXFormFieldValueTransformer: ^(id input)
             {
                 return localeIdentifiers[input];
             },
             FXFormFieldCell: RSDKAnalyticsOptionPickerCell.class,
             };
}

@end
