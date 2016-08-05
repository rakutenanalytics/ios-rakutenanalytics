/*
 * © Rakuten, Inc.
 * authors: "Rakuten Ecosystem Mobile" <ecosystem-mobile@mail.rakuten.com>
 */
#import <RSDKAnalytics/RSDKAnalyticsDefines.h>

NS_ASSUME_NONNULL_BEGIN

@class RSDKAnalyticsItem;
@class RSDKAnalyticsRecord;

/**
 * Values for RSDKAnalyticsRecord.checkoutStage.
 *
 * @note **Swift 3+:** This enum is now called `RSDKAnalyticsRecord.CheckoutStage`.
 *
 * @enum RSDKAnalyticsCheckoutStage
 * @ingroup AnalyticsConstants
 */
typedef NS_ENUM(NSUInteger, RSDKAnalyticsCheckoutStage)
{
    /**
     * Invalid value.
     *
     * @note **Swift 3+:** This enum value is now called `RSDKAnalyticsRecord.CheckoutStage.invalid`.
     */
    RSDKAnalyticsInvalidCheckoutStage RSDKA_SWIFT3_NAME(invalid) = 0,

    /**
     * Stage 1 of checking out (login).
     *
     * @note **Swift 3+:** This enum value is now called `RSDKAnalyticsRecord.CheckoutStage.stage1Login`.
     */
    RSDKAnalyticsCheckoutStage1Login RSDKA_SWIFT3_NAME(stage1Login) = 10,

    /**
     * Stage 2 of checking out (shipping details).
     *
     * @note **Swift 3+:** This enum value is now called `RSDKAnalyticsRecord.CheckoutStage.stage2ShippingDetails`.
     */
    RSDKAnalyticsCheckoutStage2ShippingDetails RSDKA_SWIFT3_NAME(stage2ShippingDetails) = 20,

    /**
     * Stage 3 of checking out (order summary).
     *
     * @note **Swift 3+:** This enum value is now called `RSDKAnalyticsRecord.CheckoutStage.stage3OrderSummary`.
     */
    RSDKAnalyticsCheckoutStage3OrderSummary RSDKA_SWIFT3_NAME(stage3OrderSummary) = 30,

    /**
     * Stage 4 of checking out (payment).
     *
     * @note **Swift 3+:** This enum value is now called `RSDKAnalyticsRecord.CheckoutStage.stage4Payment`.
     */
    RSDKAnalyticsCheckoutStage4Payment RSDKA_SWIFT3_NAME(stage4Payment) = 40,

    /**
     * Stage 5 of checking out (verification).
     *
     * @note **Swift 3+:** This enum value is now called `RSDKAnalyticsRecord.CheckoutStage.stage5Verification`.
     */
    RSDKAnalyticsCheckoutStage5Verification RSDKA_SWIFT3_NAME(stage5Verification) = 50,
} RSDKA_SWIFT3_NAME(RSDKAnalyticsRecord.CheckoutStage);



/**
 * Values for RSDKAnalyticsRecord.searchMethod.
 *
 * @note **Swift 3+:** This enum is now called `RSDKAnalyticsRecord.SearchMethod`.
 *
 * @enum RSDKAnalyticsSearchMethod
 * @ingroup AnalyticsConstants
 */
typedef NS_ENUM(NSUInteger, RSDKAnalyticsSearchMethod)
{
    /**
     * Invalid value.
     *
     * @note **Swift 3+:** This enum value is now called `RSDKAnalyticsRecord.SearchMethod.invalid`.
     */
    RSDKAnalyticsInvalidSearchMethod RSDKA_SWIFT3_NAME(invalid) = 0,

    /**
     * `AND` operation.
     *
     * @note **Swift 3+:** This enum value is now called `RSDKAnalyticsRecord.SearchMethod.and`.
     */
    RSDKAnalyticsSearchMethodAnd RSDKA_SWIFT3_NAME(and) = 1,

    /**
     * `OR` operation.
     *
     * @note **Swift 3+:** This enum value is now called `RSDKAnalyticsRecord.SearchMethod.or`.
     */
    RSDKAnalyticsSearchMethodOr RSDKA_SWIFT3_NAME(or) = 2,
} RSDKA_SWIFT3_NAME(RSDKAnalyticsRecord.SearchMethod);



/**
 * Special value for RSDKAnalyticsRecord.affiliateId, corresponding to an invalid value.
 *
 * @note **Swift 3+:** This value is now called `RSDKAnalyticsRecord.invalidAffiliateId`.
 *
 * @ingroup AnalyticsConstants
 */
RSDKA_EXPORT const int64_t RSDKAnalyticsInvalidAffiliateId RSDKA_SWIFT3_NAME(RSDKAnalyticsRecord.invalidAffiliateId);

/**
 * Special value for RSDKAnalyticsRecord.checkpoints, corresponding to an invalid value.
 *
 * @note **Swift 3+:** This value is now called `RSDKAnalyticsRecord.invalidCheckpoints`.
 *
 * @ingroup AnalyticsConstants
 */
RSDKA_EXPORT const int64_t RSDKAnalyticsInvalidCheckpoints RSDKA_SWIFT3_NAME(RSDKAnalyticsRecord.invalidCheckpoints);

/**
 * Special value for RSDKAnalyticsRecord.cartState, corresponding to an invalid value.
 *
 * @note **Swift 3+:** This value is now called `RSDKAnalyticsRecord.invalidCartState`.
 *
 * @ingroup AnalyticsConstants
 */
RSDKA_EXPORT const uint64_t RSDKAnalyticsInvalidCartState RSDKA_SWIFT3_NAME(RSDKAnalyticsRecord.invalidCartState);

/**
 * Special value for RSDKAnalyticsRecord.navigationTime, corresponding to an invalid value.
 *
 * @note **Swift 3+:** This value is now called `RSDKAnalyticsRecord.invalidNavigationTime`.
 *
 * @ingroup AnalyticsConstants
 */
RSDKA_EXPORT const NSTimeInterval RSDKAnalyticsInvalidNavigationTime RSDKA_SWIFT3_NAME(RSDKAnalyticsRecord.invalidNavigationTime);


/**
 * Block called back when enumerating items with RSDKAnalyticsRecord::enumerateItemsWithBlock:.
 *
 * @param item       Current item of the enumeration.
 * @param index      Current index.
 * @param stop [out] Setting this to `YES` will stop the enumerator, i.e. the block won't be called for any subsequent item.
 */
typedef void(^rsdk_analytics_item_enumeration_block_t)(RSDKAnalyticsItem *item, NSUInteger index, BOOL *stop);

/**
 * A single analytics record. Records are added to the
 * database and uploaded to RAT using RSDKAnalyticsManager::spoolRecord:.
 *
 * @note The properties below are named after the long names of RAT parameters in the
 * [RAT Generic IDL](https://git.rakuten-it.com/projects/RG/repos/rg/browse/ratGeneric.idl)
 * document. For more information about each property, please see the
 * [RAT Specification](https://rakuten.atlassian.net/wiki/display/SDK/RAT+Specification).
 *
 * @warning No validation is performed on the various properties exposed by this class:
 * it is up to application developers to ensure they use values that are supported by RAT.
 * The [RAT Generic IDL](https://git.rakuten-it.com/projects/RG/repos/rg/browse/ratGeneric.idl)
 * has the most up-to-date information about each field's requirement.
 *
 * @class RSDKAnalyticsRecord RSDKAnalyticsRecord.h <RSDKAnalytics/RSDKAnalyticsRecord.h>
 *
 * @deprecated Use RSDKAnalyticsEvent instead.
 */
DEPRECATED_MSG_ATTRIBUTE("Use RSDKAnalyticsEvent instead from now on.")
RSDKA_EXPORT @interface RSDKAnalyticsRecord : NSObject<NSSecureCoding, NSCopying>

/**
 * Create a new record object.
 *
 * @param accountId  Account identifier, e.g. `1` for Rakuten Ichiba Japan, `3` for Rakuten Books, etc.
 * @param serviceId  Service identifier, e.g. `14` for Singapore Mall.
 * @return New RSDKAnalyticsRecord object.
 *
 * @see
 *   - accountId
 *   - serviceId
 *   - RSDKAnalyticsManager::spoolRecord:
 *
 * @note For a list of valid account and service identitifiers, please refer to
 * [this JSON file](https://git.rakuten-it.com/projects/RG/repos/rg/browse/aid_acc_Map.json).
 */
+ (instancetype)recordWithAccountId:(uint64_t)accountId serviceId:(int64_t)serviceId;

/**
 * Return a dictionary object containing all the receiver's properties that have valid
 * values, using RAT parameters names for keys.
 *
 * @return The receiver's properties, as a dictionary.
 *
 * @note For a list of RAT parameters and their names, see the [RAT Generic IDL](https://git.rakuten-it.com/projects/RG/repos/rg/browse/ratGeneric.idl)
 * document.
 */
- (NSDictionary RSDKA_GENERIC(NSString *, id) *)propertiesDictionary;

#pragma mark - Environment

/**
 * @name Environment
 */

/**
 * Account identifier, e.g.\ `1` for Rakuten Ichiba Japan, `3` for Rakuten Books, etc.
 *
 * @note This value will be sent as the **acc** (`ACCOUNT_ID`) RAT parameter. See
 * the [RAT Generic IDL](https://git.rakuten-it.com/projects/RG/repos/rg/browse/ratGeneric.idl)
 * for more information.
 */
@property (nonatomic, readonly) uint64_t accountId;

/**
 * Service identifier, e.g.\ `14` for Singapore Mall.
 *
 * @note This value will be sent as the **aid** (`SERVICE_ID`) RAT parameter. See
 * the [RAT Generic IDL](https://git.rakuten-it.com/projects/RG/repos/rg/browse/ratGeneric.idl)
 * for more information.
 */
@property (nonatomic, readonly) int64_t serviceId;

/**
 * User identifier.
 *
 * This identifies the currently logged-in user, and can be obtained by calling RIdInformationAPI::requestEncryptedEasyIdWithAccessToken:completion:.
 *
 * @note This value will be sent as the **userid** (`USER_ID`) RAT parameter. See
 * the [RAT Generic IDL](https://git.rakuten-it.com/projects/RG/repos/rg/browse/ratGeneric.idl)
 * for more information.
 */
@property (nonatomic, copy, nullable) NSString *userId;

/**
 * Affiliate identifier. Set to @ref RSDKAnalyticsInvalidAffiliateId by default.
 *
 * This is the identifier of an affiliate the user has been redirected from.
 *
 * @note This value will be sent as the **afid** (`AFFILIATE_ID`) RAT parameter. See
 * the [RAT Generic IDL](https://git.rakuten-it.com/projects/RG/repos/rg/browse/ratGeneric.idl)
 * for more information.
 */
@property (nonatomic) int64_t affiliateId;

/**
 * Goal identifier. Not set by default.
 *
 * Goals are application-specific values corresponding to business objectives, for
 * instance **Create happy customers**, **Improve conversion rate**.
 *
 * @note This value will be sent as the **gol** (`GOAL_ID`) RAT parameter. See
 * the [RAT Generic IDL](https://git.rakuten-it.com/projects/RG/repos/rg/browse/ratGeneric.idl)
 * for more information.
 */
@property (nonatomic, copy, nullable) NSString *goalId;

/**
 * Campaign code. Not set by default.
 *
 * @note This value will be sent as the **cc** (`CAMPAIGN_CODE`) RAT parameter. See
 * the [RAT Generic IDL](https://git.rakuten-it.com/projects/RG/repos/rg/browse/ratGeneric.idl)
 * for more information.
 */
@property (nonatomic, copy, nullable) NSString *campaignCode;

/**
 * Shop identifier. Not set by default.
 *
 * @note This value will be sent as the **shopid** (`SHOP_ID`) RAT parameter. See
 * the [RAT Generic IDL](https://git.rakuten-it.com/projects/RG/repos/rg/browse/ratGeneric.idl)
 * for more information.
 */
@property (nonatomic, copy, nullable) NSString *shopId;

#pragma mark - Region

/**
 * @name Region
 */

/**
 * Content locale. Set to the current locale by default.
 *
 * @note This value will be sent as the **cntln** (`CONTENT_LANGUAGE`) RAT parameter. See
 * the [RAT Generic IDL](https://git.rakuten-it.com/projects/RG/repos/rg/browse/ratGeneric.idl)
 * for more information.
 */
@property (nonatomic, copy, null_resettable) NSLocale *contentLocale;

/**
 * Currency code, in [ISO-4217 format](http://en.wikipedia.org/wiki/ISO_4217).
 * Not set by default.
 *
 * @note This value will be sent as the **cycode** (`CURRENCY_CODE`) RAT parameter. See
 * the [RAT Generic IDL](https://git.rakuten-it.com/projects/RG/repos/rg/browse/ratGeneric.idl)
 * for more information.
 */
@property (nonatomic, copy, nullable) NSString *currencyCode;

#pragma mark - Search

/**
 * @name Search
 */

/**
 * Search selected locale. Not set by default.
 *
 * @note This value will be sent as the **lang** (`SEARCH_SELECTED_LANGUAGE`) RAT parameter. See
 * the [RAT Generic IDL](https://git.rakuten-it.com/projects/RG/repos/rg/browse/ratGeneric.idl)
 * for more information.
 */
@property (nonatomic, copy, nullable) NSLocale *searchSelectedLocale;

/**
 * Search query. Not set by default.
 *
 * @note This value will be sent as the **sq** (`SEARCH_QUERY`) RAT parameter. See
 * the [RAT Generic IDL](https://git.rakuten-it.com/projects/RG/repos/rg/browse/ratGeneric.idl)
 * for more information.
 */
@property (nonatomic, copy, nullable) NSString *searchQuery;

/**
 * OR/AND. Set to RSDKAnalyticsInvalidSearchMethod by default.
 *
 * @note This value will be sent as the **oa** (`OR_AND`) RAT parameter. See
 * the [RAT Generic IDL](https://git.rakuten-it.com/projects/RG/repos/rg/browse/ratGeneric.idl)
 * for more information.
 */
@property (nonatomic) RSDKAnalyticsSearchMethod searchMethod;

/**
 * Exclude word search query. Not set by default.
 *
 * @note This value will be sent as the **esq** (`EXCLUDE_WORD_SEARCH_QUERY`) RAT parameter. See
 * the [RAT Generic IDL](https://git.rakuten-it.com/projects/RG/repos/rg/browse/ratGeneric.idl)
 * for more information.
 */
@property (nonatomic, copy, nullable) NSString *excludeWordSearchQuery;

/**
 * Genre (search category). Not set by default.
 *
 * @note This value will be sent as the **genre** (`GENRE`) RAT parameter. See
 * the [RAT Generic IDL](https://git.rakuten-it.com/projects/RG/repos/rg/browse/ratGeneric.idl)
 * for more information.
 */
@property (nonatomic, copy, nullable) NSString *genre;

/**
 * Selected tags, to limit the search. Not set by default.
 *
 * @note This value will be sent as the **tag** (`TAG`) RAT parameter. See
 * the [RAT Generic IDL](https://git.rakuten-it.com/projects/RG/repos/rg/browse/ratGeneric.idl)
 * for more information.
 */
@property (nonatomic, copy, nullable) NSArray RSDKA_GENERIC(NSString *) *selectedTags;

#pragma mark - Navigation

/**
 * @name Navigation
 */

/**
 * Page identifier, used to identify unique page access within a user session. Not set by default.
 *
 * @note This value will be sent as the **pgid** (`PAGE_ID`) RAT parameter. See
 * the [RAT Generic IDL](https://git.rakuten-it.com/projects/RG/repos/rg/browse/ratGeneric.idl)
 * for more information.
 */
@property (nonatomic, copy, nullable) NSString *pageIdentifier;

/**
 * Current page or screen name. Not set by default.
 *
 * @note This value will be sent as the **pgn** (`PAGE_NAME`) RAT parameter. See
 * the [RAT Generic IDL](https://git.rakuten-it.com/projects/RG/repos/rg/browse/ratGeneric.idl)
 * for more information.
 */
@property (nonatomic, copy, nullable) NSString *pageName;

/**
 * Current page (or screen) type. Not set by default.
 *
 * @note This value will be sent as the **pgt** (`PAGE_TYPE`) RAT parameter. See
 * the [RAT Generic IDL](https://git.rakuten-it.com/projects/RG/repos/rg/browse/ratGeneric.idl)
 * for more information.
 */
@property (nonatomic, copy, nullable) NSString *pageType;

/**
 * Previous page name or URL. Not set by default.
 *
 * @note This value will be sent as the **ref** (`REFERRER`) RAT parameter. See
 * the [RAT Generic IDL](https://git.rakuten-it.com/projects/RG/repos/rg/browse/ratGeneric.idl)
 * for more information.
 */
@property (nonatomic, copy, nullable) NSString *referrer;

/**
 * Navigation time. Set to @ref RSDKAnalyticsInvalidNavigationTime by default.
 *
 * @note This value will be sent as the **mnavtime** (`MOBILE_NAVIGATION_TIME`) RAT parameter. See
 * the [RAT Generic IDL](https://git.rakuten-it.com/projects/RG/repos/rg/browse/ratGeneric.idl)
 * for more information.
 */
@property (nonatomic) NSTimeInterval navigationTime;

/**
 * Checkpoints. Set to @ref RSDKAnalyticsInvalidCheckpoints by default.
 *
 * Application developers can set this to any desired value. It will show up in RAT report.
 *
 * @note This value will be sent as the **chkpt** (`CHECKPOINTS`) RAT parameter. See
 * the [RAT Generic IDL](https://git.rakuten-it.com/projects/RG/repos/rg/browse/ratGeneric.idl)
 * for more information.
 */
@property (nonatomic) int64_t checkpoints;

#pragma mark - Items

/**
 * @name Items
 */

/**
 * Add an item to the record.
 *
 * @note A record can hold up to a hundred items.
 *
 * @param item `[Required]` An @ref RSDKAnalyticsItem instance to add to the receiver.
 * @return `YES` if the item could be inserted, `NO` if the maximum allowed number of items has already been reached.
 */
- (BOOL)addItem:(RSDKAnalyticsItem *)item;

/**
 * Enumerate items with block.
 *
 * @param block `[Required]` The block called for each item.
 */
- (void)enumerateItemsWithBlock:(rsdk_analytics_item_enumeration_block_t)block;

#pragma mark - Order

/**
 * @name Order
 */

/**
 * Order identifier. Not set by default.
 *
 * @note This value will be sent as the **order_id** (`ORDER_ID`) RAT parameter. See
 * the [RAT Generic IDL](https://git.rakuten-it.com/projects/RG/repos/rg/browse/ratGeneric.idl)
 * for more information.
 */
@property (nonatomic, copy, nullable) NSString *orderId;

/**
 * Cart state. Set to @ref RSDKAnalyticsInvalidCartState by default.
 *
 * @note This value will be sent as the **cart** (`CART_STATE`) RAT parameter. See
 * the [RAT Generic IDL](https://git.rakuten-it.com/projects/RG/repos/rg/browse/ratGeneric.idl)
 * for more information.
 */
@property (nonatomic) uint64_t cartState;

/**
 * Checkout. Set to RSDKAnalyticsInvalidCheckoutStage by default.
 *
 * @note This value will be sent as the **chkout** (`CHECKOUT`) RAT parameter. See
 * the [RAT Generic IDL](https://git.rakuten-it.com/projects/RG/repos/rg/browse/ratGeneric.idl)
 * for more information.
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
 * the [RAT Generic IDL](https://git.rakuten-it.com/projects/RG/repos/rg/browse/ratGeneric.idl)
 * for more information.
 */
@property (nonatomic, nullable) NSArray RSDKA_GENERIC(NSString *) *componentId;

/**
 * Component top. Not set by default.
 *
 * @note This value will be sent as the **comptop** (`COMPONENT_TOP`) RAT parameter. See
 * the [RAT Generic IDL](https://git.rakuten-it.com/projects/RG/repos/rg/browse/ratGeneric.idl)
 * for more information.
 */
@property (nonatomic, nullable) NSArray RSDKA_GENERIC(NSNumber *) *componentTop;

/**
 * Custom parameters. Not set by default.
 *
 * @note This value will be sent as the **cp** (`CUSTOM_PARAMETERS`) RAT parameter. See
 * the [RAT Generic IDL](https://git.rakuten-it.com/projects/RG/repos/rg/browse/ratGeneric.idl)
 * for more information.
 */
@property (nonatomic, nullable) NSDictionary RSDKA_GENERIC(NSString *, id) *customParameters;

/**
 * Event type. Not set by default.
 *
 * @note This value will be sent as the **etype** (`EVENT_TYPE`) RAT parameter. See
 * the [RAT Generic IDL](https://git.rakuten-it.com/projects/RG/repos/rg/browse/ratGeneric.idl)
 * for more information.
 */
@property (nonatomic, copy, nullable) NSString *eventType;

/**
 * Request code. Not set by default.
 *
 * The [RAT Specification](https://rakuten.atlassian.net/wiki/display/SDK/RAT+Specification) states
 * that developers can set this to any value, though it is not clear for what purpose anybody would
 * actually want to do so.
 *
 * @note This value will be sent as the **reqc** (`REQUEST_CODE`) RAT parameter. See
 * the [RAT Generic IDL](https://git.rakuten-it.com/projects/RG/repos/rg/browse/ratGeneric.idl)
 * for more information.
 */
@property (nonatomic, copy, nullable) NSString *requestCode;

/**
 * Scroll div identifier. Not set by default.
 *
 * @note This value will be sent as the **scroll** (`SCROLL_DIV_ID`) RAT parameter. See
 * the [RAT Generic IDL](https://git.rakuten-it.com/projects/RG/repos/rg/browse/ratGeneric.idl)
 * for more information.
 */
@property (nonatomic, nullable) NSArray RSDKA_GENERIC(NSString *) *scrollDivId;

/**
 * Scroll viewed. Not set by default.
 *
 * @note This value will be sent as the **sresv** (`SCROLL_VIEWED`) RAT parameter. See
 * the [RAT Generic IDL](https://git.rakuten-it.com/projects/RG/repos/rg/browse/ratGeneric.idl)
 * for more information.
 */
@property (nonatomic, nullable) NSArray RSDKA_GENERIC(NSString *) *scrollViewed;

#pragma mark - Deprecated
/**
 * @name Deprecated
 */

/**
 * User identifier.
 *
 * @deprecated You should use #userId instead.
 */
@property (nonatomic, copy, nullable) NSString *easyId DEPRECATED_MSG_ATTRIBUTE("-easyId is deprecated: you should change your code to use -userId instead.");
@end

NS_ASSUME_NONNULL_END
