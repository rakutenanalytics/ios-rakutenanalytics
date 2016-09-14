/*
 * © Rakuten, Inc.
 * authors: "Rakuten Ecosystem Mobile" <ecosystem-mobile@mail.rakuten.com>
 */
#import <RSDKAnalytics/RSDKAnalyticsDefines.h>

NS_ASSUME_NONNULL_BEGIN

@class RSDKAnalyticsRecord;

/**
 * Hold information about a shop item.
 *
 * @par Swift 3
 * This class is exposed as **RSDKAnalyticsRecord.Item**.
 *
 * @see
 *  - RSDKAnalyticsRecord::addItem:
 *  - RSDKAnalyticsRecord::enumerateItemsWithBlock:
 *
 * @class RSDKAnalyticsItem RSDKAnalyticsItem.h <RSDKAnalytics/RSDKAnalyticsItem.h>
 *
 * @deprecated Use RSDKAnalyticsEvent instead. Manually create the parameters holding information about a shop item and pass them to an event object by using RATTracker::eventWithEventType:parameters:.
 */
DEPRECATED_MSG_ATTRIBUTE("Use RSDKAnalyticsEvent instead from now on. Manually create the parameters holding information about a shop item and pass them to an event object by using RATTracker::eventWithEventType:parameters:.")
RSDKA_EXPORT RSDKA_SWIFT3_NAME(RSDKAnalyticsRecord.Item) @interface RSDKAnalyticsItem : NSObject<NSSecureCoding, NSCopying>

/**
 * Item identifier. Not set by default.
 *
 * Item identifiers are of the form `shopId/itemId`. If the `shopId/` part is omitted,
 * the `itemId` is assumed to be a `productId`.
 *
 * @note This value will be appended to the **itemid** (`ITEM_ID`) RAT parameter. See
 * the [RAT Generic IDL](https://git.rakuten-it.com/projects/RG/repos/rg/browse/ratGeneric.idl)
 * for more information.
 */
@property (nonatomic, copy, nullable) NSString *identifier;

/**
 * Number of items. Defaults to `0`.
 *
 * @note This value will be appended to the **ni** (`NUMBER_OF_ITEMS`) RAT parameter. See
 * the [RAT Generic IDL](https://git.rakuten-it.com/projects/RG/repos/rg/browse/ratGeneric.idl)
 * for more information.
 */
@property (nonatomic) uint64_t quantity;

/**
 * Item price. Defaults to `0.0`.
 *
 * @note This value will be appended to the **price** (`PRICE`) RAT parameter. See
 * the [RAT Generic IDL](https://git.rakuten-it.com/projects/RG/repos/rg/browse/ratGeneric.idl)
 * for more information.
 */
@property (nonatomic) double price;

/**
 * Item genre. Not set by default.
 *
 * @note This value will be appended to the **igenre** (`ITEM_GENRE`) RAT parameter. See
 * the [RAT Generic IDL](https://git.rakuten-it.com/projects/RG/repos/rg/browse/ratGeneric.idl)
 * for more information.
 */
@property (nonatomic, copy, nullable) NSString *genre;

/**
 * Item variation. Not set by default.
 *
 * @note This value will appended to the **variation** (`ITEM_VARIATION`) RAT parameter. See
 * the [RAT Generic IDL](https://git.rakuten-it.com/projects/RG/repos/rg/browse/ratGeneric.idl)
 * for more information.
 */
@property (nonatomic, copy, nullable) NSDictionary RSDKA_GENERIC(NSString *, id) *variation;

/**
 * Item tags. Not set by default.
 *
 * @note This value will appended to the **itag** (`Tag array`) RAT parameter. See
 * the [RAT Generic IDL](https://git.rakuten-it.com/projects/RG/repos/rg/browse/ratGeneric.idl)
 * for more information.
 */
@property (nonatomic, copy, nullable) NSArray RSDKA_GENERIC(NSString *) *tags;

/**
 * Create a new item.
 *
 * @param identifier `[Optional]` Item identifier.
 */
+ (instancetype)itemWithIdentifier:(nullable NSString *)identifier;

@end

NS_ASSUME_NONNULL_END
