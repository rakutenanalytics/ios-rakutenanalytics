import Foundation

// MARK: - TelephonyNetworkInfoHandleable

/// - Note: NSObjectProtocol is used for calling `responds(to:)` method in `TelephonyHandler` class.
protocol TelephonyNetworkInfoHandleable: NSObjectProtocol {
    var safeDataServiceIdentifier: String? { get }

    /// Forwarded from `CTTelephonyNetworkInfo` for consumers that need the system notifier.
    var serviceSubscriberCellularProvidersDidUpdateNotifier: ((String) -> Void)? { get set }

    var serviceCurrentRadioAccessTechnology: [String: String]? { get }
}

#if os(tvOS)

/// Stub used on tvOS where CoreTelephony is unavailable.
final class NoOpTelephonyNetworkInfo: NSObject, TelephonyNetworkInfoHandleable {
    var safeDataServiceIdentifier: String? { nil }
    var serviceSubscriberCellularProvidersDidUpdateNotifier: ((String) -> Void)?
    var serviceCurrentRadioAccessTechnology: [String: String]? { nil }
}

#endif
