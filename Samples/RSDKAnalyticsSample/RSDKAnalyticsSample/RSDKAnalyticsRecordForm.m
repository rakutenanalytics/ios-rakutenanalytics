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

- (RSDKAnalyticsRecord *)record
{
    RSDKAnalyticsRecord *record = [RSDKAnalyticsRecord recordWithAccountId:self.accountId serviceId:self.serviceId];
    record.affiliateId  = self.affiliateId;
    record.goalId       = self.goalId;
    record.campaignCode = self.campaignCode;
    record.shopId       = self.shopId;

    record.contentLocale = [NSLocale localeWithLocaleIdentifier:self.contentLocale];
    record.currencyCode    = self.currencyCode;

    record.searchSelectedLocale = [NSLocale localeWithLocaleIdentifier:self.searchSelectedLocale];
    record.searchQuery            = self.searchQuery;
    record.searchMethod           = self.searchMethod;
    record.excludeWordSearchQuery = self.excludeWordSearchQuery;
    record.genre                  = self.genre;

    record.pageName       = self.pageName;
    record.pageType       = self.pageType;
    record.referrer       = self.referrer;
    record.navigationTime = self.navigationTime;
    record.checkpoints    = self.checkpoints;

    for (NSString *itemIdentifier in self.itemIdentifiers)
    {
        RSDKAnalyticsItem *item = [RSDKAnalyticsItem itemWithIdentifier:itemIdentifier];
        item.quantity = 3;
        item.price = 12;
        item.genre = self.genreForItems;
        [record addItem:item];
    }

    record.orderId       = self.orderId;
    record.cartState     = self.cartState;
    record.checkoutStage = self.checkoutStage;

    record.componentId       = self.componentId;
    record.componentTop      = self.componentTop;
    record.scrollDivId       = self.scrollDivId;
    record.scrollViewed      = self.scrollViewed;
    record.eventType         = self.eventType;
    record.requestCode       = self.requestCode;
    record.customParameters  = self.customParameters;

    return record;
}

#pragma mark - Fields

- (id)trackLocationField
{
    return @{FXFormFieldAction: @"trackLocationChanged:"};
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
