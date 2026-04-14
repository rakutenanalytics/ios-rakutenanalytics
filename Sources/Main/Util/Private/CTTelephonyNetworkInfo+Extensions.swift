import Foundation
import CoreTelephony

// MARK: - TelephonyNetworkInfoHandleable

/// - Note: NSObjectProtocol is used for calling `responds(to:)` method in `TelephonyHandler` class.
protocol TelephonyNetworkInfoHandleable: NSObjectProtocol {
    var safeDataServiceIdentifier: String? { get }

    /// Forwarded from `CTTelephonyNetworkInfo` for consumers that need the system notifier.
    var serviceSubscriberCellularProvidersDidUpdateNotifier: ((String) -> Void)? { get set }

    var serviceCurrentRadioAccessTechnology: [String: String]? { get }
}

extension CTTelephonyNetworkInfo: TelephonyNetworkInfoHandleable {
    /// - Returns: `CTTelephonyNetworkInfo`'s `dataServiceIdentifier` if the app runs on the iOS device, `nil` otherwise if the app runs on the iOS simulator.
    ///
    /// - Note: `dataServiceIdentifier` returns error logs on the simulator.
    var safeDataServiceIdentifier: String? {
        #if targetEnvironment(simulator)
        return nil
        #else
        return dataServiceIdentifier
        #endif
    }
}
