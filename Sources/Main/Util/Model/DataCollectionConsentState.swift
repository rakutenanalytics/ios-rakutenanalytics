import Foundation

/// Persisted consent value for a single data collection category when privacy control is enabled.
///
/// Tri-state: granted, denied, or not yet stored (undetermined).
public enum DataCollectionConsentState: Equatable, Sendable {
    /// User or host app explicitly allowed collection for this category.
    case granted

    /// User or host app explicitly denied collection for this category.
    case denied

    /// No value stored yet (e.g. new install or new category) — collection must not be treated as granted.
    case undetermined
}
