import Foundation

// MARK: - AnalyticsManager dependencies

@objc public extension AnalyticsManager {
    var launchCollector: RAnalyticsLaunchCollector? {
        perform(Selector(("analyticsLaunchCollector")))?.takeUnretainedValue() as? RAnalyticsLaunchCollector
    }
}
