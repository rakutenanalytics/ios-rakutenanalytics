import Foundation

protocol ViewableImpressionTrackState: AnyObject {
    var item: ViewableImpressionTrackable { get }
    var itemPosition: Int { get }
    var isVisible: Bool { get set }
    var firstVisibleTime: Date { get set }
    var hasTriggered: Bool { get set }
    var visibilityPercentage: Double { get set }
    var screenName: String? { get }
}

struct ViewableImpressionQualifiedItemData {
    let item: ViewableImpressionTrackable
    let dwellTime: TimeInterval
    let visibilityPercentage: Double
    let itemPosition: Int
    let screenName: String?
}

struct ViewableImpressionTrackStateProcessor {
    static func process(item: ViewableImpressionTrackState,
                        visibility: Double?,
                        now: Date,
                        minimumVisibility: Double,
                        minimumDwell: TimeInterval) -> (qualified: ViewableImpressionQualifiedItemData?, remaining: TimeInterval?) {
        guard let visibility = visibility else {
            item.isVisible = false
            item.firstVisibleTime = .distantPast
            item.hasTriggered = false
            item.visibilityPercentage = 0.0
            return (nil, nil)
        }

        item.visibilityPercentage = visibility

        let evaluation = ViewableImpressionEvaluation.evaluate(
            visibility: visibility,
            isVisible: item.isVisible,
            firstVisibleTime: item.firstVisibleTime,
            hasTriggered: item.hasTriggered,
            minimumVisibility: minimumVisibility,
            minimumDwell: minimumDwell,
            now: now
        )

        item.isVisible = evaluation.isVisible
        item.firstVisibleTime = evaluation.firstVisibleTime
        item.hasTriggered = evaluation.hasTriggered

        if evaluation.qualifies {
            let dwellTime = now.timeIntervalSince(item.firstVisibleTime)
            return (
                ViewableImpressionQualifiedItemData(
                    item: item.item,
                    dwellTime: dwellTime,
                    visibilityPercentage: visibility,
                    itemPosition: item.itemPosition,
                    screenName: item.screenName
                ),
                nil
            )
        }

        return (nil, evaluation.remainingDwell)
    }
}
