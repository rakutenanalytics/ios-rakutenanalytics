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
    var dataServiceIdentifier: String? { get }

    @available(iOS 12.0, *)
    var subscribers: [String: Carrierable]? { get }

    @available(iOS, introduced: 4.0, deprecated: 12.0)
    var subscriber: Carrierable? { get }

    @available(iOS 12.0, *)
    var serviceSubscriberCellularProvidersDidUpdateNotifier: ((String) -> Void)? { get set }

    @available(iOS, introduced: 4.0, deprecated: 12.0)
    var subscriberDidUpdateNotifier: ((Carrierable) -> Void)? { get set }

    @available(iOS 12.0, *)
    var serviceCurrentRadioAccessTechnology: [String: String]? { get }

    @available(iOS, introduced: 7.0, deprecated: 12.0)
    var currentRadioAccessTechnology: String? { get }
}

extension CTTelephonyNetworkInfo: TelephonyNetworkInfoHandleable {
    /// - Note: It solves a compiler error because the compiler can't match Carrierable and CTCarrier.
    var subscriberDidUpdateNotifier: ((Carrierable) -> Void)? {
        get {
            subscriberCellularProviderDidUpdateNotifier as? ((Carrierable) -> Void)? ?? nil
        }
        set {
            subscriberCellularProviderDidUpdateNotifier = newValue
        }
    }

    /// - Note: It solves a compiler error because the compiler can't match Carrierable and CTCarrier.
    @available(iOS 12.0, *)
    var subscribers: [String: Carrierable]? {
        serviceSubscriberCellularProviders
    }

    /// - Note: It solves a compiler error because the compiler can't match Carrierable and CTCarrier.
    @available(iOS, introduced: 4.0, deprecated: 12.0)
    var subscriber: Carrierable? {
        subscriberCellularProvider
    }
}
