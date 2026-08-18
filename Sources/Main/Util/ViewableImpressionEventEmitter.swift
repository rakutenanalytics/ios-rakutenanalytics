import Foundation

enum ViewableImpressionEventEmitter {
    static func buildItemPayloads(items: [ViewableImpressionQualifiedItemData],
                                  eventTimestamp: NSNumber) -> [[String: Any]] {
        guard !items.isEmpty else { return [] }
        return items.map { itemData in
            var itemParams: [String: Any] = [
                RAnalyticsEvent.Parameter.itemId: itemData.item.itemId,
                RAnalyticsEvent.Parameter.itemTitle: itemData.item.itemTitle,
                RAnalyticsEvent.Parameter.itemPosition: itemData.itemPosition,
                RAnalyticsEvent.Parameter.visibilityPercentage: itemData.visibilityPercentage,
                RAnalyticsEvent.Parameter.dwellTime: itemData.dwellTime,
                RAnalyticsEvent.Parameter.viewableImpressionTimestamp: eventTimestamp
                // viewport_bounds intentionally omitted from manual payload
            ]

            if let description = itemData.item.itemDescription {
                itemParams[RAnalyticsEvent.Parameter.itemDescription] = description
            }

            if let category = itemData.item.itemCategory {
                itemParams[RAnalyticsEvent.Parameter.itemCategory] = category
            }

            if let genre = itemData.item.itemGenre {
                itemParams[RAnalyticsEvent.Parameter.itemGenre] = genre
            }

            if let price = itemData.item.itemPrice {
                itemParams[RAnalyticsEvent.Parameter.itemPrice] = price
            }

            if let screenName = itemData.screenName, !screenName.isEmpty {
                itemParams[RAnalyticsEvent.Parameter.screenName] = screenName
            }

            return itemParams
        }
    }

    static func buildEventParameters(viewableData: [[String: Any]]) -> [String: Any]? {
        guard !viewableData.isEmpty else { return nil }
        return [
            RAnalyticsEvent.Parameter.viewableData: viewableData
        ]
    }
}
