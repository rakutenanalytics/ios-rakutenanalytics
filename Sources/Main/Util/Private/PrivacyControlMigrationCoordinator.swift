import Foundation

/// Orchestrates privacy-control startup migration and dispatches ``RAnalyticsShowConsentCallback``.
///
/// Register the handler via ``AnalyticsManager/showConsentCallback(callback:)`` at launch, before SDK initialization
/// when possible. The coordinator notifies the app which granular categories still have no stored consent,
/// then persists ``RATConstants/PrivacyControl/privacyVersionKey`` only after every category is granted or denied.
@MainActor
final class PrivacyControlMigrationCoordinator {
    /// Shared instance used by ``AnalyticsManager`` at startup.
    static let shared = PrivacyControlMigrationCoordinator()

    private var registeredCallback: AnalyticsShowConsentCallback?
    private var hasDeliveredStartupNotification = false
    private var typesNeedingConsentContinuation: AsyncStream<[DataCollectionType]>.Continuation?

    /// Stream of startup consent-delivery payloads. Each coordinator instance yields independently (useful in tests).
    var typesNeedingConsentUpdates: AsyncStream<[DataCollectionType]> {
        typesNeedingConsentStream
    }

    private let typesNeedingConsentStream: AsyncStream<[DataCollectionType]>

    init() {
        var continuation: AsyncStream<[DataCollectionType]>.Continuation!
        typesNeedingConsentStream = AsyncStream { continuation = $0 }
        typesNeedingConsentContinuation = continuation
    }

    /// Registers the host handler and runs startup migration when privacy control is enabled.
    func registerShowConsentCallback(_ callback: @escaping AnalyticsShowConsentCallback,
                                     consentStore: PrivacyControlConsentMigrating = DataCollectionConsentStore.shared) {
        registeredCallback = callback
        runStartupMigrationIfNeeded(consentStore: consentStore)
    }

    /// Invoked during SDK startup after the consent store is available.
    func runStartupMigrationIfNeeded(consentStore: PrivacyControlConsentMigrating) {
        guard consentStore.isPrivacyControlEnabled else { return }

        let callback = registeredCallback
        let shouldNotify = callback != nil && !hasDeliveredStartupNotification
        guard let callback, shouldNotify else { return }

        hasDeliveredStartupNotification = true
        let typesNeedingConsent = consentStore.typesWithoutConsent()
        deliverTypesNeedingConsent(typesNeedingConsent, callback: callback)
        consentStore.persistPrivacyVersionIfAllConsentsDetermined()
    }

    private func deliverTypesNeedingConsent(_ types: [DataCollectionType],
                                            callback: AnalyticsShowConsentCallback) {
        callback(types)
        typesNeedingConsentContinuation?.yield(types)
    }
}
