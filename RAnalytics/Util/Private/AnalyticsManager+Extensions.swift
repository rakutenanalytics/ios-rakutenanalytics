import Foundation

// MARK: - AnalyticsManager dependencies

extension AnalyticsManager {
    var launchCollector: RAnalyticsLaunchCollector? {
        perform(Selector(("analyticsLaunchCollector")))?.takeUnretainedValue() as? RAnalyticsLaunchCollector
    }
    var externalCollector: RAnalyticsExternalCollector? {
        perform(Selector(("analyticsExternalCollector")))?.takeUnretainedValue() as? RAnalyticsExternalCollector
    }
}
