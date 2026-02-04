import Foundation

struct ViewableImpressionEvaluationResult {
    let isVisible: Bool
    let firstVisibleTime: Date
    let hasTriggered: Bool
    let qualifies: Bool
    let remainingDwell: TimeInterval?
}

struct ViewableImpressionEvaluation {
    static func evaluate(visibility: Double,
                         isVisible: Bool,
                         firstVisibleTime: Date,
                         hasTriggered: Bool,
                         minimumVisibility: Double,
                         minimumDwell: TimeInterval,
                         now: Date) -> ViewableImpressionEvaluationResult {
        guard visibility > minimumVisibility else {
            return ViewableImpressionEvaluationResult(
                isVisible: false,
                firstVisibleTime: .distantPast,
                hasTriggered: false,
                qualifies: false,
                remainingDwell: nil
            )
        }

        var updatedIsVisible = isVisible
        var updatedFirstVisibleTime = firstVisibleTime
        var updatedHasTriggered = hasTriggered

        if !updatedIsVisible {
            updatedIsVisible = true
            updatedFirstVisibleTime = now
            updatedHasTriggered = false
        }

        let visibleDuration = now.timeIntervalSince(updatedFirstVisibleTime)
        if !updatedHasTriggered, visibleDuration >= minimumDwell {
            updatedHasTriggered = true
            return ViewableImpressionEvaluationResult(
                isVisible: updatedIsVisible,
                firstVisibleTime: updatedFirstVisibleTime,
                hasTriggered: updatedHasTriggered,
                qualifies: true,
                remainingDwell: nil
            )
        }

        let remaining = (updatedHasTriggered || minimumDwell <= 0) ? nil : max(0, minimumDwell - visibleDuration)
        return ViewableImpressionEvaluationResult(
            isVisible: updatedIsVisible,
            firstVisibleTime: updatedFirstVisibleTime,
            hasTriggered: updatedHasTriggered,
            qualifies: false,
            remainingDwell: remaining
        )
    }
}
