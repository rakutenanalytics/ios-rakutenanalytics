import Foundation

/// Result of processing a single item's viewable impression state.
struct ViewableImpressionProcessResult {
    /// The qualified item data if the item met visibility and dwell thresholds.
    let qualified: ViewableImpressionQualifiedItemData?
    /// Remaining dwell time in seconds before the item would qualify, if still accumulating.
    let remaining: TimeInterval?
}

struct ViewableImpressionTrackStateProcessor {
    static func process(item: ViewableImpressionTrackState,
                        visibility: Double?,
                        now: Date,
                        minimumVisibility: Double,
                        minimumDwell: TimeInterval) -> ViewableImpressionProcessResult {
        guard let visibility = visibility else {
            item.isVisible = false
            item.firstVisibleTime = .distantPast
            item.hasTriggered = false
            item.visibilityPercentage = 0.0
            return ViewableImpressionProcessResult(qualified: nil, remaining: nil)
        }

        item.visibilityPercentage = visibility

        let evaluation = ViewableImpressionEvaluation.evaluate(
            ViewableImpressionEvaluationInput(
                visibility: visibility,
                isVisible: item.isVisible,
                firstVisibleTime: item.firstVisibleTime,
                hasTriggered: item.hasTriggered,
                minimumVisibility: minimumVisibility,
                minimumDwell: minimumDwell,
                now: now
            )
        )

        item.isVisible = evaluation.isVisible
        item.firstVisibleTime = evaluation.firstVisibleTime
        item.hasTriggered = evaluation.hasTriggered

        if evaluation.qualifies {
            let dwellTime = now.timeIntervalSince(item.firstVisibleTime)
            return ViewableImpressionProcessResult(
                qualified: ViewableImpressionQualifiedItemData(
                    item: item.item,
                    dwellTime: dwellTime,
                    visibilityPercentage: visibility,
                    itemPosition: item.itemPosition,
                    screenName: item.screenName
                ),
                remaining: nil
            )
        }

        return ViewableImpressionProcessResult(qualified: nil, remaining: evaluation.remainingDwell)
    }
}
