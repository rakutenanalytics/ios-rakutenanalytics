import Foundation

/// A subsystem that should refresh when runtime data-collection consent changes.
@MainActor
protocol DataCollectionConsentListener: AnyObject {
    /// Applies the latest consent state (e.g. refreshes location monitoring, cookies, or user agent).
    func reactToDataCollectionConsentDidChange() async
}

/// Dispatches runtime data-collection consent changes to registered listeners.
protocol DataCollectionConsentChangeCoordinating: Sendable {
    func subscribe(listener: any DataCollectionConsentListener) async
    func unsubscribe(listener: any DataCollectionConsentListener) async
    func notifySubsystemsOfConsentChange() async
}

/// Dispatches runtime data-collection consent changes to registered listeners.
///
/// Register with ``subscribe(listener:)`` and remove with ``unsubscribe(listener:)`` when appropriate.
/// Production consent mutations reconcile subsystems through ``PrivacyConsentReactor`` instead.
/// This coordinator remains available for tests and optional custom listeners.
/// Listeners are referenced weakly so this type does not extend their lifetime; defunct
/// registrations are removed when notifying or unsubscribing.
///
/// - Note: When ``DataCollectionConsentStore/setEnabled(_:for:)`` completes on the main actor, listeners
///   have already been notified. Background-thread mutations hop to the main actor before listener work runs.
///   Listener implementations must be `@MainActor` and perform UI- or location-related work there.
actor DataCollectionConsentChangeCoordinator: DataCollectionConsentChangeCoordinating {
    /// Shared instance for SDK-wide listener registration.
    static let shared = DataCollectionConsentChangeCoordinator()

    private final class WeakListener: @unchecked Sendable {
        weak var value: (any DataCollectionConsentListener)?

        init(_ value: any DataCollectionConsentListener) {
            self.value = value
        }
    }

    private var listeners: [WeakListener] = []

    /// Registers `listener` to receive ``DataCollectionConsentListener/reactToDataCollectionConsentDidChange()`` after consent updates.
    ///
    /// If the same object is already registered, this is a no-op.
    func subscribe(listener: any DataCollectionConsentListener) {
        listeners.removeAll { $0.value == nil }
        let alreadyRegistered = listeners.contains { box in
            guard let existing = box.value else { return false }
            return existing === listener
        }
        guard !alreadyRegistered else { return }
        listeners.append(WeakListener(listener))
    }

    /// Stops notifying `listener`. Also drops boxes whose reference is already nil.
    func unsubscribe(listener: any DataCollectionConsentListener) {
        listeners.removeAll { box in
            box.value.map { $0 === listener } ?? true
        }
    }

    /// Notifies all registered listeners in subscription order, awaiting each listener's work.
    func notifySubsystemsOfConsentChange() async {
        listeners.removeAll { $0.value == nil }
        let activeListeners = listeners.compactMap(\.value)
        for listener in activeListeners {
            await listener.reactToDataCollectionConsentDidChange()
        }
    }
}
