import Foundation

/// Consent storage surface required for privacy-control startup migration.
protocol PrivacyControlConsentMigrating: Sendable {
    var isPrivacyControlEnabled: Bool { get }

    /// Returns granular categories whose persisted consent is still `undetermined`.
    func typesWithoutConsent() -> [DataCollectionType]

    /// Persists the current SDK privacy version when every granular category has explicit consent.
    func persistPrivacyVersionIfAllConsentsDetermined()
}
