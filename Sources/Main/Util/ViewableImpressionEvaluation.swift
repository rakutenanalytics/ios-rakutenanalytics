import Foundation

struct ViewableImpressionEvaluationResult {
    let isVisible: Bool
    let firstVisibleTime: Date
    let hasTriggered: Bool
    let qualifies: Bool
    let remainingDwell: TimeInterval?
}

/// Input parameters for evaluating whether a viewable impression item qualifies.
struct ViewableImpressionEvaluationInput {
    let visibility: Double
    let isVisible: Bool
    let firstVisibleTime: Date
    let hasTriggered: Bool
    let minimumVisibility: Double
    let minimumDwell: TimeInterval
    let now: Date
}

struct ViewableImpressionEvaluation {
    static func evaluate(_ input: ViewableImpressionEvaluationInput) -> ViewableImpressionEvaluationResult {
        guard input.visibility > input.minimumVisibility else {
            return ViewableImpressionEvaluationResult(
                isVisible: false,
                firstVisibleTime: .distantPast,
                hasTriggered: false,
                qualifies: false,
                remainingDwell: nil
            )
        }

        var updatedIsVisible = input.isVisible
        var updatedFirstVisibleTime = input.firstVisibleTime
        var updatedHasTriggered = input.hasTriggered

        if !updatedIsVisible {
            updatedIsVisible = true
            updatedFirstVisibleTime = input.now
            updatedHasTriggered = false
        }

        let visibleDuration = input.now.timeIntervalSince(updatedFirstVisibleTime)
        if !updatedHasTriggered, visibleDuration >= input.minimumDwell {
            updatedHasTriggered = true
            return ViewableImpressionEvaluationResult(
                isVisible: updatedIsVisible,
                firstVisibleTime: updatedFirstVisibleTime,
                hasTriggered: updatedHasTriggered,
                qualifies: true,
                remainingDwell: nil
            )
        }

        let remaining = (updatedHasTriggered || input.minimumDwell <= 0) ? nil : max(0, input.minimumDwell - visibleDuration)
        return ViewableImpressionEvaluationResult(
            isVisible: updatedIsVisible,
            firstVisibleTime: updatedFirstVisibleTime,
            hasTriggered: updatedHasTriggered,
            qualifies: false,
            remainingDwell: remaining
        )
    }
}
