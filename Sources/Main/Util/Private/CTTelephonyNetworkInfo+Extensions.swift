import Foundation
import CoreTelephony

// MARK: - Carrierable

protocol Carrierable {
    var carrierName: String? { get }
    var mobileCountryCode: String? { get }
    var mobileNetworkCode: String? { get }
    var isoCountryCode: String? { get }
    var allowsVOIP: Bool { get }
}

extension CTCarrier: Carrierable {
}

// MARK: - TelephonyNetworkInfoHandleable

/// - Note: NSObjectProtocol is used for calling `responds(to:)` method in `TelephonyHandler` class.
protocol TelephonyNetworkInfoHandleable: NSObjectProtocol {
    @available(iOS 13.0, *)
    var safeDataServiceIdentifier: String? { get }

    @available(iOS 12.0, *)
    var subscribers: [String: Carrierable]? { get }

    @available(iOS 12.0, *)
    var serviceSubscriberCellularProvidersDidUpdateNotifier: ((String) -> Void)? { get set }

    @available(iOS 12.0, *)
    var serviceCurrentRadioAccessTechnology: [String: String]? { get }
}

extension CTTelephonyNetworkInfo: TelephonyNetworkInfoHandleable {
    /// - Returns: `CTTelephonyNetworkInfo`'s `dataServiceIdentifier` if the app runs on the iOS device, `nil` otherwise if the app runs on the iOS simulator.
    ///
    /// - Note: `dataServiceIdentifier` returns error logs on the simulator.
    @available(iOS 13.0, *)
    var safeDataServiceIdentifier: String? {
        #if targetEnvironment(simulator)
        return nil
        #else
        return dataServiceIdentifier
        #endif
    }

    /// - Note: It solves a compiler error because the compiler can't match Carrierable and CTCarrier.
    @available(iOS 12.0, *)
    var subscribers: [String: Carrierable]? {
        serviceSubscriberCellularProviders
    }
}
