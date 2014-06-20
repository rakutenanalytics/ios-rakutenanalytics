//
//  RSDKAnalyticsRecord.h
//  RSDKAnalytics
//
//  Created by Julien Cayzac on 5/19/14.
//  Copyright (c) 2014 Rakuten, Inc. All rights reserved.
//

@import Foundation;


/**
 * Values for [RSDKAnalyticsRecord checkoutStage].
 *
 * @since 2.0.0
 */
typedef NS_ENUM(NSInteger, RSDKAnalyticsCheckoutStage)
{
    /**
     * Invalid value.
     *
     * @since 2.0.0
     */
    RSDKAnalyticsInvalidCheckoutStage = 0,

    /**
     * Stage 1 of checking out (login).
     *
     * @since 2.0.0
     */
    RSDKAnalyticsCheckoutStage1Login = 10,

    /**
     * Stage 2 of checking out (shipping details).
     *
     * @since 2.0.0
     */
    RSDKAnalyticsCheckoutStage2ShippingDetails = 20,

    /**
     * Stage 3 of checking out (order summary).
     *
     * @since 2.0.0
     */
    RSDKAnalyticsCheckoutStage3OrderSummary = 30,

    /**
     * Stage 4 of checking out (payment).
     *
     * @since 2.0.0
     */
    RSDKAnalyticsCheckoutStage4Payment = 40,

    /**
     * Stage 5 of checking out (verification).
     *
     * @since 2.0.0
     */
    RSDKAnalyticsCheckoutStage5Verification = 50,
};



/**
 * Values for [RSDKAnalyticsRecord searchMethod].
 *
 * @since 2.0.0
 */
typedef NS_ENUM(NSInteger, RSDKAnalyticsSearchMethod)
{
    /**
     * Invalid value.
     *
     * @since 2.0.0
     */
    RSDKAnalyticsInvalidSearchMethod = 0,

    /**
     * AND operation.
     *
     * @since 2.0.0
     */
    RSDKAnalyticsSearchMethodAnd = 1,

    /**
     * OR operation.
     *
     * @since 2.0.0
     */
    RSDKAnalyticsSearchMethodOr = 2,
};



/**
 * Special value for [RSDKAnalyticsRecord affiliateId], corresponding to an invalid value.
 *
 * @since 2.0.0
 */
FOUNDATION_EXTERN const int64_t RSDKAnalyticsInvalidAffiliateId;

/**
 * Special value for [RSDKAnalyticsRecord checkpoints], corresponding to an invalid value.
 *
 * @since 2.0.0
 */
FOUNDATION_EXTERN const int64_t RSDKAnalyticsInvalidCheckpoints;

/**
 * Special value for [RSDKAnalyticsRecord cartState], corresponding to an invalid value.
 *
 * @since 2.0.0
 */
FOUNDATION_EXTERN const uint64_t RSDKAnalyticsInvalidCartState;

/**
 * Special value for [RSDKAnalyticsRecord navigationTime], corresponding to an invalid value.
 *
 * @since 2.0.0
 */
FOUNDATION_EXTERN const NSTimeInterval RSDKAnalyticsInvalidNavigationTime;



/**
 * This class represents a single analytics record. Records are added to the
 * database and uploaded to RAT using [RSDKAnalyticsManager spoolRecord:].
 *
 * @note The properties below are named after the long names of RAT parameters in the
 * [RAT Generic IDL](https://git.dev.rakuten.com/projects/RG/repos/rg/browse/ratGeneric.idl)
 * document. For more information about each property, please see the
 * [RAT Specification](https://rakuten.atlassian.net/wiki/display/SDK/RAT+Specification).
 *
 * @since 2.0.0
 */
@interface RSDKAnalyticsRecord : NSObject

/**
 * Create a new record object.
 *
 * @param accountId  Account identifier, e.g. `1` for Rakuten Ichiba Japan, `3` for Rakuten Books, etc.
 * @param serviceId  Service identifier, e.g. `14` for Singapore Mall.
 * @return New RSDKAnalyticsRecord object.
 * @see accountId
 * @see serviceId
 * @see [RSDKAnalyticsManager spoolRecord:]
 *
 * @note For a list of valid account and service identitifiers, please refer to
 * [this JSON file](https://git.dev.rakuten.com/projects/RG/repos/rg/browse/aid_acc_Map.json).
 *
 * @since 2.0.0
 */
+ (instancetype)recordWithAccountId:(uint64_t)accountId serviceId:(int64_t)serviceId;

/**
 * Return a dictionary object containing all the receiver's properties that have valid
 * values, using RAT parameters names for keys.
 *
 * @return The receiver's properties, as a dictionary.
 *
 * @note For a list of RAT parameters and their names, see the [RAT Generic IDL](https://git.dev.rakuten.com/projects/RG/repos/rg/browse/ratGeneric.idl)
 * document.
 *
 * @since 2.0.0
 */
- (NSDictionary *)propertiesDictionary;

#pragma mark - Environment

/**
 * @name Environment
 */

/**
 * Account identifier, e.g. `1` for Rakuten Ichiba Japan, `3` for Rakuten Books, etc.
 *
 * @note This value will be sent as the **acc** (`ACCOUNT_ID`) RAT parameter. See
 * the [RAT Generic IDL](https://git.dev.rakuten.com/projects/RG/repos/rg/browse/ratGeneric.idl)
 * for more information.
 *
 * @since 2.0.0
 */
@property (nonatomic, readonly) uint64_t accountId;

/**
 * Service identifier, e.g. `14` for Singapore Mall.
 *
 * @note This value will be sent as the **aid** (`SERVICE_ID`) RAT parameter. See
 * the [RAT Generic IDL](https://git.dev.rakuten.com/projects/RG/repos/rg/browse/ratGeneric.idl)
 * for more information.
 *
 * @since 2.0.0
 */
@property (nonatomic, readonly) int64_t serviceId;

/**
 * Easy ID. This identifies the currently logged-in user.
 *
 * @note This value will be sent as the **easyid** (`EASY_ID`) RAT parameter. See
 * the [RAT Generic IDL](https://git.dev.rakuten.com/projects/RG/repos/rg/browse/ratGeneric.idl)
 * for more information.
 *
 * @warning When setting this property, values over 25 characters in length will get ignored and
 * the property reset to `nil`.
 *
 * @since 2.1.0
 */
@property (nonatomic, copy) NSString *easyId;

/**
 * Affiliate identifier. Set to `RSDKAnalyticsInvalidAffiliateId` by default.
 *
 * This is the identifier of an affiliate the user has been redirected from.
 *
 * @note This value will be sent as the **afid** (`AFFILIATE_ID`) RAT parameter. See
 * the [RAT Generic IDL](https://git.dev.rakuten.com/projects/RG/repos/rg/browse/ratGeneric.idl)
 * for more information.
 *
 * @since 2.0.0
 */
@property (nonatomic) int64_t affiliateId;

/**
 * Goal identifier. Not set by default.
 *
 * Goals are application-specific values corresponding to business objectives, for
 * instance **Create happy customers**, **Improve conversion rate**.
 *
 * @note This value will be sent as the **gol** (`GOAL_ID`) RAT parameter. See
 * the [RAT Generic IDL](https://git.dev.rakuten.com/projects/RG/repos/rg/browse/ratGeneric.idl)
 * for more information.
 *
 * @warning When setting this property, values over 10 characters in length will get ignored and
 * the property reset to `nil`.
 *
 * @since 2.0.0
 */
@property (nonatomic, copy) NSString *goalId;

/**
 * Campaign code. Not set by default.
 *
 * @note This value will be sent as the **cc** (`CAMPAIGN_CODE`) RAT parameter. See
 * the [RAT Generic IDL](https://git.dev.rakuten.com/projects/RG/repos/rg/browse/ratGeneric.idl)
 * for more information.
 *
 * @warning When setting this property, values over 20 characters in length will get ignored and
 * the property reset to `nil`.
 *
 * @since 2.0.0
 */
@property (nonatomic, copy) NSString *campaignCode;

/**
 * Shop identifier. Not set by default.
 *
 * @note This value will be sent as the **shopid** (`SHOP_ID`) RAT parameter. See
 * the [RAT Generic IDL](https://git.dev.rakuten.com/projects/RG/repos/rg/browse/ratGeneric.idl)
 * for more information.
 *
 * @since 2.0.0
 */
@property (nonatomic, copy) NSString *shopId;

#pragma mark - Region

/**
 * @name Region
 */

/**
 * Content locale. Set to the current locale by default.
 *
 * @note This value will be sent as the **cntln** (`CONTENT_LANGUAGE`) RAT parameter. See
 * the [RAT Generic IDL](https://git.dev.rakuten.com/projects/RG/repos/rg/browse/ratGeneric.idl)
 * for more information.
 *
 * @since 2.0.0
 */
@property (nonatomic, copy) NSLocale *contentLocale;

/**
 * Currency code, in [ISO-4217 format](http://en.wikipedia.org/wiki/ISO_4217).
 * Not set by default.
 *
 * @note This value will be sent as the **cycode** (`CURRENCY_CODE`) RAT parameter. See
 * the [RAT Generic IDL](https://git.dev.rakuten.com/projects/RG/repos/rg/browse/ratGeneric.idl)
 * for more information.
 *
 * @warning When setting this property, any value that is not exactly 3-character long is a
 * synonym of `nil`.
 *
 * @since 2.0.0
 */
@property (nonatomic, copy) NSString *currencyCode;

#pragma mark - Search

/**
 * @name Search
 */

/**
 * Search selected locale. Not set by default.
 *
 * @note This value will be sent as the **lang** (`SEARCH_SELECTED_LANGUAGE`) RAT parameter. See
 * the [RAT Generic IDL](https://git.dev.rakuten.com/projects/RG/repos/rg/browse/ratGeneric.idl)
 * for more information.
 *
 * @warning When setting this property, values over 16 characters in length will get ignored and
 * the property reset to `nil`.
 *
 * @since 2.0.0
 */
@property (nonatomic, copy) NSLocale *searchSelectedLocale;

/**
 * Search query. Not set by default.
 *
 * @note This value will be sent as the **sq** (`SEARCH_QUERY`) RAT parameter. See
 * the [RAT Generic IDL](https://git.dev.rakuten.com/projects/RG/repos/rg/browse/ratGeneric.idl)
 * for more information.
 *
 * @warning When setting this property, values over 1024 characters in length will get ignored and
 * the property reset to `nil`.
 *
 * @since 2.0.0
 */
@property (nonatomic, copy) NSString *searchQuery;

/**
 * OR/AND. Set to `RSDKAnalyticsInvalidSearchMethod` by default.
 *
 * @see RSDKAnalyticsSearchMethod
 *
 * @note This value will be sent as the **oa** (`OR_AND`) RAT parameter. See
 * the [RAT Generic IDL](https://git.dev.rakuten.com/projects/RG/repos/rg/browse/ratGeneric.idl)
 * for more information.
 *
 * @since 2.0.0
 */
@property (nonatomic) RSDKAnalyticsSearchMethod searchMethod;

/**
 * Exclude word search query. Not set by default.
 *
 * @note This value will be sent as the **esq** (`EXCLUDE_WORD_SEARCH_QUERY`) RAT parameter. See
 * the [RAT Generic IDL](https://git.dev.rakuten.com/projects/RG/repos/rg/browse/ratGeneric.idl)
 * for more information.
 *
 * @warning When setting this property, values over 1024 characters in length will get ignored and
 * the property reset to `nil`.
 *
 * @since 2.0.0
 */
@property (nonatomic, copy) NSString *excludeWordSearchQuery;

/**
 * Genre (search category). Not set by default.
 *
 * The RSDKSearch module allows to restrict product search queries to a certain
 * genre, which you can copy into this property.
 *
 * @note This value will be sent as the **genre** (`GENRE`) RAT parameter. See
 * the [RAT Generic IDL](https://git.dev.rakuten.com/projects/RG/repos/rg/browse/ratGeneric.idl)
 * for more information.
 *
 * @warning When setting this property, values over 200 characters in length will get ignored and 
 * the property reset to `nil`.
 *
 * @since 2.0.0
 */
@property (nonatomic, copy) NSString *genre;

#pragma mark - Navigation

/**
 * @name Navigation
 */

/**
 * Current page or screen name. Not set by default.
 *
 * @note This value will be sent as the **pgn** (`PAGE_NAME`) RAT parameter. See
 * the [RAT Generic IDL](https://git.dev.rakuten.com/projects/RG/repos/rg/browse/ratGeneric.idl)
 * for more information.
 *
 * @warning When setting this property, values over 1024 characters in length will get ignored and
 * the property reset to `nil`.
 *
 * @since 2.0.0
 */
@property (nonatomic, copy) NSString *pageName;

/**
 * Current page (or screen) type. Not set by default.
 *
 * @note This value will be sent as the **pgt** (`PAGE_TYPE`) RAT parameter. See
 * the [RAT Generic IDL](https://git.dev.rakuten.com/projects/RG/repos/rg/browse/ratGeneric.idl)
 * for more information.
 *
 * @warning When setting this property, values over 20 characters in length will get ignored and
 * the property reset to `nil`.
 *
 * @since 2.0.0
 */
@property (nonatomic, copy) NSString *pageType;

/**
 * Previous page name or URL. Not set by default.
 *
 * @note This value will be sent as the **ref** (`REFERRER`) RAT parameter. See
 * the [RAT Generic IDL](https://git.dev.rakuten.com/projects/RG/repos/rg/browse/ratGeneric.idl)
 * for more information.
 *
 * @warning When setting this property, values over 2048 characters in length will get ignored and
 * the property reset to `nil`.
 *
 * @since 2.0.0
 */
@property (nonatomic, copy) NSString *referrer;

/**
 * Navigation time. Set to `RSDKAnalyticsInvalidNavigationTime` by default.
 *
 * @note This value will be sent as the **mnavtime** (`MOBILE_NAVIGATION_TIME`) RAT parameter. See
 * the [RAT Generic IDL](https://git.dev.rakuten.com/projects/RG/repos/rg/browse/ratGeneric.idl)
 * for more information.
 *
 * @since 2.0.0
 */
@property (nonatomic) NSTimeInterval navigationTime;

/**
 * Checkpoints. Set to `RSDKAnalyticsInvalidCheckpoints` by default.
 *
 * Application developers can set this to any desired value. It will show up in RAT report.
 *
 * @note This value will be sent as the **chkpt** (`CHECKPOINTS`) RAT parameter. See
 * the [RAT Generic IDL](https://git.dev.rakuten.com/projects/RG/repos/rg/browse/ratGeneric.idl)
 * for more information.
 *
 * @since 2.0.0
 */
@property (nonatomic) int64_t checkpoints;

#pragma mark - Items

/**
 * @name Items
 */

/**
 * Item identifier. Not set by default.
 *
 * This contains an array of strings of the form "shopId/itemId".
 * If the shopId/ part is omitted, the itemId is assumed to be a productId.
 *
 * @note This value will be sent as the **itemid** (`ITEM_ID`) RAT parameter. See
 * the [RAT Generic IDL](https://git.dev.rakuten.com/projects/RG/repos/rg/browse/ratGeneric.idl)
 * for more information.
 *
 * @warning When setting this property, arrays should contain `NSString` objects only. Arrays
 * over 100 items in length will get ignored and the property reset to `nil`.
 *
 * @since 2.0.0
 */
@property (nonatomic, strong) NSArray *itemId;

/**
 * Number of items. Not set by default.
 *
 * @note This value will be sent as the **ni** (`NUMBER_OF_ITEMS`) RAT parameter. See
 * the [RAT Generic IDL](https://git.dev.rakuten.com/projects/RG/repos/rg/browse/ratGeneric.idl)
 * for more information.
 *
 * @warning When setting this property, arrays should contain `NSNumber` objects only, all of
 * which should be integers strictly greater than zero. Arrays over 100 items in length will
 * get ignored and the property reset to `nil`.
 *
 * @since 2.0.0
 */
@property (nonatomic, strong) NSArray *numberOfItems;

/**
 * Item prices. Not set by default.
 *
 * @note This value will be sent as the **price** (`PRICE`) RAT parameter. See
 * the [RAT Generic IDL](https://git.dev.rakuten.com/projects/RG/repos/rg/browse/ratGeneric.idl)
 * for more information.
 *
 * @warning When setting this property, arrays should contain `NSNumber` objects only. Arrays
 * over 100 items in length will get ignored and the property reset to `nil`.
 *
 * @since 2.0.0
 */
@property (nonatomic, strong) NSArray *itemPrice;

/**
 * Item genre. Not set by default.
 *
 * @note This value will be sent as the **igenre** (`ITEM_GENRE`) RAT parameter. See
 * the [RAT Generic IDL](https://git.dev.rakuten.com/projects/RG/repos/rg/browse/ratGeneric.idl)
 * for more information.
 *
 * @warning When setting this property, arrays should contain `NSString` objects only. Arrays
 * over 100 items in length will get ignored and the property reset to `nil`.
 *
 * @since 2.0.0
 */
@property (nonatomic, strong) NSArray *itemGenre;

/**
 * Item variation. Not set by default.
 *
 * @note This value will be sent as the **variation** (`ITEM_VARIATION`) RAT parameter. See
 * the [RAT Generic IDL](https://git.dev.rakuten.com/projects/RG/repos/rg/browse/ratGeneric.idl)
 * for more information.
 *
 * @warning When setting this property, arrays should only contain objects that can be
 * serialized using `NSJSONSerialization`. Arrays over 100 items in length will get ignored and
 * the property reset to `nil`.
 *
 * @since 2.0.0
 */
@property (nonatomic, strong) NSArray *itemVariation;

#pragma mark - Order

/**
 * @name Order
 */

/**
 * Order identifier. Not set by default.
 *
 * @note This value will be sent as the **order_id** (`ORDER_ID`) RAT parameter. See
 * the [RAT Generic IDL](https://git.dev.rakuten.com/projects/RG/repos/rg/browse/ratGeneric.idl)
 * for more information.
 *
 * @since 2.0.0
 */
@property (nonatomic, copy) NSString *orderId;

/**
 * Cart state. Set to `RSDKAnalyticsInvalidCartState` by default.
 *
 * @note This value will be sent as the **cart** (`CART_STATE`) RAT parameter. See
 * the [RAT Generic IDL](https://git.dev.rakuten.com/projects/RG/repos/rg/browse/ratGeneric.idl)
 * for more information.
 *
 * @since 2.0.0
 */
@property (nonatomic) uint64_t cartState;

/**
 * Checkout. Set to `RSDKAnalyticsInvalidCheckoutStage` by default.
 *
 * @see RSDKAnalyticsCheckoutStage
 *
 * @note This value will be sent as the **chkout** (`CHECKOUT`) RAT parameter. See
 * the [RAT Generic IDL](https://git.dev.rakuten.com/projects/RG/repos/rg/browse/ratGeneric.idl)
 * for more information.
 *
 * @since 2.0.0
 */
@property (nonatomic) RSDKAnalyticsCheckoutStage checkoutStage;

#pragma mark - Other

/**
 * @name Other
 */

/**
 * Component id. Not set by default.
 *
 * @note This value will be sent as the **compid** (`COMPONENT_ID`) RAT parameter. See
 * the [RAT Generic IDL](https://git.dev.rakuten.com/projects/RG/repos/rg/browse/ratGeneric.idl)
 * for more information.
 *
 * @warning When setting this property, arrays should contain `NSString` objects only.
 *
 * @since 2.0.0
 */
@property (nonatomic, strong) NSArray *componentId;

/**
 * Component top. Not set by default.
 *
 * @note This value will be sent as the **comptop** (`COMPONENT_TOP`) RAT parameter. See
 * the [RAT Generic IDL](https://git.dev.rakuten.com/projects/RG/repos/rg/browse/ratGeneric.idl)
 * for more information.
 *
 * @warning When setting this property, arrays should contain `NSNumber` objects only.
 *
 * @since 2.0.0
 */
@property (nonatomic, strong) NSArray *componentTop;

/**
 * Custom parameters. Not set by default.
 *
 * @note This value will be sent as the **cp** (`CUSTOM_PARAMETERS`) RAT parameter. See
 * the [RAT Generic IDL](https://git.dev.rakuten.com/projects/RG/repos/rg/browse/ratGeneric.idl)
 * for more information.
 *
 * @warning No validation is performed on custom parameters, it is up to application
 * developers to ensure they use values that are supported by RAT. Specifically, keys
 * should not exceed 15 characters in length, while the length of string values should
 * not exceed 20 characters.
 *
 * @since 2.0.0
 */
@property (nonatomic, strong) NSDictionary *customParameters;

/**
 * Event type. Not set by default.
 *
 * @note This value will be sent as the **etype** (`EVENT_TYPE`) RAT parameter. See
 * the [RAT Generic IDL](https://git.dev.rakuten.com/projects/RG/repos/rg/browse/ratGeneric.idl)
 * for more information.
 *
 * @since 2.0.0
 */
@property (nonatomic, copy) NSString *eventType;

/**
 * Request code. Not set by default.
 *
 * The [RAT Specification](https://rakuten.atlassian.net/wiki/display/SDK/RAT+Specification) states
 * that developers can set this to any value, though it is not clear for what purpose anybody would
 * actually want to do so.
 *
 * @note This value will be sent as the **reqc** (`REQUEST_CODE`) RAT parameter. See
 * the [RAT Generic IDL](https://git.dev.rakuten.com/projects/RG/repos/rg/browse/ratGeneric.idl)
 * for more information.
 *
 * @warning When setting this property, values over 32 characters in length will get ignored and
 * the property reset to `nil`.
 *
 * @since 2.0.0
 */
@property (nonatomic, copy) NSString *requestCode;

/**
 * Scroll div identifier. Not set by default.
 *
 * @note This value will be sent as the **scroll** (`SCROLL_DIV_ID`) RAT parameter. See
 * the [RAT Generic IDL](https://git.dev.rakuten.com/projects/RG/repos/rg/browse/ratGeneric.idl)
 * for more information.
 *
 * @warning When setting this property, arrays should contain `NSString` objects only. Arrays
 * over 100 items in length will get ignored and the property reset to `nil`. An empty array
 * is a synonym of `nil`.
 *
 * @since 2.0.0
 */
@property (nonatomic, strong) NSArray *scrollDivId;

/**
 * Scroll viewed. Not set by default.
 *
 * @note This value will be sent as the **sresv** (`SCROLL_VIEWED`) RAT parameter. See
 * the [RAT Generic IDL](https://git.dev.rakuten.com/projects/RG/repos/rg/browse/ratGeneric.idl)
 * for more information.
 *
 * @warning When setting this property, arrays should contain `NSString` objects only. Arrays
 * over 100 items in length will get ignored and the property reset to `nil`. An empty array is
 * a synonym of `nil`.
 *
 * @since 2.0.0
 */
@property (nonatomic, strong) NSArray *scrollViewed;

@end

