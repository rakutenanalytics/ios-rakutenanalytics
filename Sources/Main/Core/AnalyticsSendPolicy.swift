import Foundation

/// Default send gating for the SDK: host bundle manual-init flag + `AnalyticsInitState.isConfigured`.
enum AnalyticsSendPolicy {
    /// Returns a predicate that allows all sends when automatic init is enabled, otherwise requires `isConfigured`.
    static func makeDefaultSendPredicate(for bundle: EnvironmentBundle) -> () -> Bool {
        if !bundle.isManualInitializationEnabled {
            return { true }
        }
        return { AnalyticsInitState.isConfigured }
    }
}

/// Supplies `bundle` so dependency containers can build the default send predicate.
protocol AnalyticsHostBundleProviding {
    var bundle: EnvironmentBundle { get }
}

extension AnalyticsHostBundleProviding {
    /// Builds `AnalyticsSendPolicy.makeDefaultSendPredicate(for: bundle)`.
    func makeAnalyticsSendPredicate() -> () -> Bool {
        AnalyticsSendPolicy.makeDefaultSendPredicate(for: bundle)
    }
}
