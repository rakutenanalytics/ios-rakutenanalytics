import Foundation

// MARK: - Reconciliation protocols

@MainActor
protocol GeoPrivacyConsentReconciling: AnyObject {
    func reconcileLocationCollectionWithPrivacyConsent()
}

@MainActor
protocol AnalyticsPrivacyConsentReconciling: AnyObject {
    func reconcileLastKnownLocationMonitoringAfterConsentChange()
    func refreshAppToWebCookiesAfterConsentChange() async
    func applyWebViewUserAgentAfterConsentChange()
}

// MARK: - PrivacyConsentReactor

/// Owns ordered privacy consent reconciliation across Geo, cookies, and WebView user agent.
///
/// ## Reaction order
///
/// After a consent mutation is persisted:
/// 1. Geo Tracker pause or resume
/// 2. Analytics last-known-location monitoring start/stop
/// 3. Rp cookie clear from shared storage (when user-information consent is denied)
/// 4. App-to-web (`ra_uid`) cookie refresh
/// 5. WebView user agent application
///
/// Host apps calling ``AnalyticsManager/set(dataCollection:enabled:)`` on the main actor can rely on Geo pause,
/// in-memory consent reads, and Rp cookie state reflecting the new value when the call returns.
/// App-to-web cookie refresh and WebView user agent application complete before ``setEnabled(_:for:)`` returns
/// when invoked on the main actor.
@MainActor
final class PrivacyConsentReactor {
    /// Shared instance coordinating production consent reconciliation.
    static let shared = PrivacyConsentReactor()

    private weak var geoReconciler: (any GeoPrivacyConsentReconciling)?
    private weak var analyticsReconciler: (any AnalyticsPrivacyConsentReconciling)?

    private init() {
        // Intentionally empty: restricts construction to ``shared``.
    }

    func register(geo: any GeoPrivacyConsentReconciling) {
        geoReconciler = geo
    }

    func register(analytics: any AnalyticsPrivacyConsentReconciling) {
        analyticsReconciler = analytics
    }

    func reconcileAfterConsentChange(shouldClearRpCookies: Bool, bundle: EnvironmentBundle) async {
        geoReconciler?.reconcileLocationCollectionWithPrivacyConsent()
        analyticsReconciler?.reconcileLastKnownLocationMonitoringAfterConsentChange()
        if shouldClearRpCookies {
            await ConsentRpCookieClearing.clear(from: bundle)
        }
        await analyticsReconciler?.refreshAppToWebCookiesAfterConsentChange()
        analyticsReconciler?.applyWebViewUserAgentAfterConsentChange()
    }
}

struct PrivacyConsentReactorSideEffectHandler: DataCollectionConsentSideEffectHandling {
    func afterConsentMutation(shouldClearRpCookies: Bool, bundle: EnvironmentBundle) async {
        await PrivacyConsentReactor.shared.reconcileAfterConsentChange(
            shouldClearRpCookies: shouldClearRpCookies,
            bundle: bundle
        )
    }
}
