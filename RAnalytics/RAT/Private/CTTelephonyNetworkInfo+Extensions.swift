import Foundation
import CoreTelephony

@objc public protocol TelephonyHandleable: NSObjectProtocol {
    @available(iOS 13.0, *)
    var dataServiceIdentifier: String? { get }

    @available(iOS 12.0, *)
    var serviceSubscriberCellularProviders: [String: CTCarrier]? { get }

    @available(iOS, introduced: 4.0, deprecated: 12.0)
    var subscriberCellularProvider: CTCarrier? { get }

    @available(iOS 12.0, *)
    var serviceSubscriberCellularProvidersDidUpdateNotifier: ((String) -> Void)? { get set }

    @available(iOS, introduced: 4.0, deprecated: 12.0)
    var subscriberCellularProviderDidUpdateNotifier: ((CTCarrier) -> Void)? { get set }

    @available(iOS 12.0, *)
    var serviceCurrentRadioAccessTechnology: [String: String]? { get }

    @available(iOS, introduced: 7.0, deprecated: 12.0)
    var currentRadioAccessTechnology: String? { get }
}

extension CTTelephonyNetworkInfo: TelephonyHandleable {
}
