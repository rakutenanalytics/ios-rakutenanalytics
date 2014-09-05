@import Foundation;

/**
 * Hold information about a shop item.
 *
 * @see
 *  - RSDKAnalyticsRecord::addItem:
 *  - RSDKAnalyticsRecord::enumerateItemsWithBlock:
 *
 * @class RSDKAnalyticsItem RSDKAnalyticsItem.h RSDKAnalytics/RSDKAnalyticsItem.h
 */
@interface RSDKAnalyticsItem : NSObject<NSSecureCoding, NSCopying>

/**
 * Item identifier. Not set by default.
 *
 * Item identifiers are of the form `shopId/itemId`. If the `shopId/` part is omitted,
 * the `itemId` is assumed to be a `productId`.
 *
 * @note This value will be appended to the **itemid** (`ITEM_ID`) RAT parameter. See
 * the [RAT Generic IDL](https://git.dev.rakuten.com/projects/RG/repos/rg/browse/ratGeneric.idl)
 * for more information.
 */
@property (nonatomic, copy) NSString *identifier;

/**
 * Number of items. Defaults to `0`.
 *
 * @note This value will be appended to the **ni** (`NUMBER_OF_ITEMS`) RAT parameter. See
 * the [RAT Generic IDL](https://git.dev.rakuten.com/projects/RG/repos/rg/browse/ratGeneric.idl)
 * for more information.
 */
@property (nonatomic) uint64_t quantity;

/**
 * Item price. Defaults to `0.0`.
 *
 * @note This value will be appended to the **price** (`PRICE`) RAT parameter. See
 * the [RAT Generic IDL](https://git.dev.rakuten.com/projects/RG/repos/rg/browse/ratGeneric.idl)
 * for more information.
 */
@property (nonatomic) double price;

/**
 * Item genre. Not set by default.
 *
 * @note This value will be appended to the **igenre** (`ITEM_GENRE`) RAT parameter. See
 * the [RAT Generic IDL](https://git.dev.rakuten.com/projects/RG/repos/rg/browse/ratGeneric.idl)
 * for more information.
 */
@property (nonatomic, copy) NSString *genre;

/**
 * Item variation. Not set by default.
 *
 * @note This value will appended to the **variation** (`ITEM_VARIATION`) RAT parameter. See
 * the [RAT Generic IDL](https://git.dev.rakuten.com/projects/RG/repos/rg/browse/ratGeneric.idl)
 * for more information.
 */
@property (nonatomic, copy) NSDictionary *variation;

/**
 * Create a new item.
 *
 * @param identifier Item identifier.
 */
+ (instancetype)itemWithIdentifier:(NSString *)identifier;

@end
