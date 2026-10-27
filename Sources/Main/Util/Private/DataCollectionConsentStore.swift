import Foundation

/// Side effects triggered after a consent mutation (subsystem reconciliation via ``PrivacyConsentReactor``).
protocol DataCollectionConsentSideEffectHandling: Sendable {
    func afterConsentMutation(shouldClearRpCookies: Bool, bundle: EnvironmentBundle) async
}

enum ConsentRpCookieClearing {
    static func clear(from bundle: EnvironmentBundle) async {
        let urlsToCheck = Set(
            [bundle.endpointAddress, RATConstants.ProductionRat.endpointURL].compactMap { $0 }
        )
        guard !urlsToCheck.isEmpty else { return }

        await Task(priority: .utility) {
            for url in urlsToCheck {
                (HTTPCookieStorage.shared.cookies(for: url) ?? [])
                    .filter { $0.name == RATConstants.RpCookie.cookieName }
                    .forEach { HTTPCookieStorage.shared.deleteCookie($0) }
            }
        }.value
    }
}

/// Test-only handler that fans out through ``DataCollectionConsentChangeCoordinator`` instead of the reactor.
struct DefaultConsentSideEffectHandler: DataCollectionConsentSideEffectHandling {
    private let changeCoordinator: DataCollectionConsentChangeCoordinating

    init(changeCoordinator: DataCollectionConsentChangeCoordinating) {
        self.changeCoordinator = changeCoordinator
    }

    func afterConsentMutation(shouldClearRpCookies: Bool, bundle: EnvironmentBundle) async {
        if shouldClearRpCookies {
            await ConsentRpCookieClearing.clear(from: bundle)
        }
        await changeCoordinator.notifySubsystemsOfConsentChange()
    }
}

/// Side-effect handler for store unit tests that only exercise persistence and reads.
struct NoOpConsentSideEffectHandler: DataCollectionConsentSideEffectHandling {
    func afterConsentMutation(shouldClearRpCookies _: Bool, bundle _: EnvironmentBundle) async {
        // Intentionally no-op: store unit tests only exercise persistence and reads, not side effects.
    }
}

/// Protocol for reading and updating data collection consent state.
protocol DataCollectionConsentReadable: Sendable {
    /// When `false`, the Data Collection API is ignored and all categories are collected.
    var isPrivacyControlEnabled: Bool { get }

    /// Returns whether the given data collection category is enabled.
    /// When privacy control is disabled (build-time), always returns `true`.
    func isEnabled(_ category: DataCollectionType) -> Bool

    /// Tri-state consent for a persisted category when privacy control is enabled. Returns `nil` when privacy control is off, or for `.all`.
    func storedConsentState(for category: DataCollectionType) -> DataCollectionConsentState?

    /// Persists runtime consent for `category`. No-op when privacy control is disabled at build time.
    func setEnabled(_ enabled: Bool, for category: DataCollectionType) async
}

/// Stores and persists data collection consent state.
/// When `RATEnablePrivacyControl` is false (default), the runtime consent API has no effect and all
/// categories are collected (see `Bundle.isPrivacyControlEnabled`).
/// Values may remain stored while a category is disabled; gated data must not be **used** for analytics
/// (payloads, cookies, Geo, etc.) until the category is enabled—see category checks at collection time.
///
/// ## Consent mutation ordering
///
/// When ``setEnabled(_:for:)`` is awaited on the main actor:
/// 1. Consent is persisted on the main actor.
/// 2. ``PrivacyConsentReactor`` reconciles subsystems in a fixed order (Geo pause, Rp cookie clear,
///    app-to-web cookie refresh, WebView user agent) before ``setEnabled(_:for:)`` returns.
@MainActor
final class DataCollectionConsentStore: DataCollectionConsentReadable, PrivacyControlConsentMigrating, @unchecked Sendable {
    /// Shared instance for SDK-wide access. Uses UserDefaults and Bundle.main.
    nonisolated static let shared = DataCollectionConsentStore()

    private enum Keys {
        static let prefix = "RATDataCollection_"
        static let privacyVersion = RATConstants.PrivacyControl.privacyVersionKey

        static func key(for granular: DataCollectionType) -> String {
            switch granular {
            case .location: return "\(prefix)location"
            case .mobileNetwork: return "\(prefix)mobileNetwork"
            case .deviceInformation: return "\(prefix)deviceInformation"
            case .userInformation: return "\(prefix)userInformation"
            case .all:
                preconditionFailure("Storage key is only defined for granular categories")
            }
        }
    }

    /// UserDefaults-backed storage; reads are thread-safe per platform guarantees.
    private nonisolated(unsafe) let userStorageHandler: UserStorageHandleable
    private nonisolated(unsafe) let bundle: EnvironmentBundle
    private nonisolated let sideEffectHandler: any DataCollectionConsentSideEffectHandling

    nonisolated init(userStorageHandler: UserStorageHandleable = UserDefaults.standard,
                     bundle: EnvironmentBundle = Bundle.main,
                     sideEffectHandler: any DataCollectionConsentSideEffectHandling = PrivacyConsentReactorSideEffectHandler()) {
        self.userStorageHandler = userStorageHandler
        self.bundle = bundle
        self.sideEffectHandler = sideEffectHandler
    }

    /// When false (default), privacy control is disabled and all data collection is enabled.
    nonisolated var isPrivacyControlEnabled: Bool {
        bundle.isPrivacyControlEnabled
    }

    /// Persisted privacy-control feature version, or `nil` when privacy control is off or no version has been stored yet.
    nonisolated var storedPrivacyVersion: Int? {
        guard isPrivacyControlEnabled else { return nil }
        return storedPrivacyVersionValue()
    }

    /// Granular categories with no stored consent (`undetermined`).
    nonisolated func typesWithoutConsent() -> [DataCollectionType] {
        guard isPrivacyControlEnabled else { return [] }
        return DataCollectionType.individualTypes.filter {
            consentStateValue(for: $0) == .undetermined
        }
    }

    /// Writes the current SDK privacy version when every granular category has an explicit granted/denied value.
    nonisolated func persistPrivacyVersionIfAllConsentsDetermined() {
        guard isPrivacyControlEnabled else { return }
        persistPrivacyVersionIfAllConsentsDeterminedValue()
    }

    nonisolated func storedConsentState(for category: DataCollectionType) -> DataCollectionConsentState? {
        guard isPrivacyControlEnabled else { return nil }
        guard category != .all else { return nil }
        return consentStateValue(for: category)
    }

    nonisolated func isEnabled(_ category: DataCollectionType) -> Bool {
        guard isPrivacyControlEnabled else { return true }
        if category == .all {
            return DataCollectionType.individualTypes.allSatisfy { isEnabledValue($0) }
        }
        return isEnabledValue(category)
    }

    func setEnabled(_ enabled: Bool, for category: DataCollectionType) async {
        guard isPrivacyControlEnabled else { return }

        let shouldClearRpCookies: Bool
        if category == .all {
            DataCollectionType.individualTypes.forEach {
                setEnabledValue(enabled, for: $0)
            }
            shouldClearRpCookies = !isEnabledValue(.userInformation)
        } else {
            setEnabledValue(enabled, for: category)
            shouldClearRpCookies = !isEnabledValue(.userInformation)
        }
        persistPrivacyVersionIfAllConsentsDeterminedValue()
        await sideEffectHandler.afterConsentMutation(shouldClearRpCookies: shouldClearRpCookies, bundle: bundle)
    }

    // MARK: - Private helpers

    private nonisolated func isEnabledValue(_ category: DataCollectionType) -> Bool {
        consentStateValue(for: category) == .granted
    }

    private nonisolated func consentStateValue(for category: DataCollectionType) -> DataCollectionConsentState {
        guard let object = userStorageHandler.object(forKey: Keys.key(for: category)) else {
            return .undetermined
        }
        switch object {
        case let value as Bool:
            return value ? .granted : .denied
        case let number as NSNumber:
            return number.boolValue ? .granted : .denied
        default:
            return .undetermined
        }
    }

    private nonisolated func storedPrivacyVersionValue() -> Int? {
        guard let object = userStorageHandler.object(forKey: Keys.privacyVersion) else { return nil }
        switch object {
        case let number as NSNumber: return number.intValue
        case let value as Int: return value
        default: return nil
        }
    }

    private nonisolated func allConsentsDeterminedValue() -> Bool {
        DataCollectionType.individualTypes.allSatisfy {
            consentStateValue(for: $0) != .undetermined
        }
    }

    private nonisolated func persistPrivacyVersionIfAllConsentsDeterminedValue() {
        guard allConsentsDeterminedValue() else { return }
        userStorageHandler.set(value: NSNumber(value: RATConstants.PrivacyControl.currentPrivacyVersion),
                               forKey: Keys.privacyVersion)
    }

    private nonisolated func setEnabledValue(_ enabled: Bool, for category: DataCollectionType) {
        userStorageHandler.set(value: NSNumber(value: enabled), forKey: Keys.key(for: category))
    }
}
