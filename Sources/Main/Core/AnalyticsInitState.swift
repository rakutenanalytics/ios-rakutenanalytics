import Foundation

/// Whether the SDK is considered configured; send eligibility reads this instead of `AnalyticsManager`.
enum AnalyticsInitState {
    private(set) static var isConfigured: Bool = false

    /// Writes `isConfigured`; called from `AnalyticsManager` when configuration changes.
    static func applyIsConfigured(_ value: Bool) {
        isConfigured = value
    }
}
