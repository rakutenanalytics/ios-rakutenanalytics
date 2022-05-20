import Foundation
import CoreTelephony

/// Mobile Network Type
/// - Note: This maps the values for the otherwise-undocumented MOBILE_NETWORK_TYPE RAT parameter.
enum RATMobileNetworkType: Int {
    case wifi = 1
    case cellularOther = 3
    case cellularLTE = 4
    case cellular5G = 5
}

protocol TelephonyHandleable {
    var reachabilityStatus: NSNumber? { get set }
    var mcn: String { get }
    var mcnd: String { get }
    var mnetw: NSNumber? { get }
    var mnetwd: NSNumber? { get }
    func update(telephonyNetworkInfo: TelephonyNetworkInfoHandleable)
}

/// The Telephony Handler handles the core telephony framework.
final class TelephonyHandler: TelephonyHandleable {
    private var telephonyNetworkInfo: TelephonyNetworkInfoHandleable
    private let notificationCenter: NotificationObservable
    private var retrievedCarrierKey: String? // used for iOS == 12.x
    var reachabilityStatus: NSNumber?

    private var reachabilityStatusType: RATReachabilityStatus? {
        guard let value = reachabilityStatus?.intValue else {
            return nil
        }
        return RATReachabilityStatus(rawValue: value)
    }

    /// Creates a new instance of `TelephonyHandler`.
    ///
    /// - Parameters:
    ///   - telephonyNetworkInfo: The telephony network info.
    ///   - notificationCenter: The notification center.
    ///
    /// - Returns: a new instance of `TelephonyHandler`.
    init(telephonyNetworkInfo: TelephonyNetworkInfoHandleable,
         notificationCenter: NotificationObservable) {
        self.telephonyNetworkInfo = telephonyNetworkInfo
        self.notificationCenter = notificationCenter

        configure()
    }

    private func configure() {
        guard #available(iOS 13.0, *) else {
            // Listen to changes in radio access technology, to detect LTE.
            _ = notificationCenter.observe(forName: .CTServiceRadioAccessTechnologyDidChange, object: nil, queue: nil) { notification in
                self.retrievedCarrierKey = notification.object as? String
            }
            return
        }
    }
}

// MARK: - Update

extension TelephonyHandler {
    /// Replace the current instance of telephonyNetworkInfo by a new one given as a parameter `telephonyNetworkInfo`.
    ///
    /// - Parameters:
    ///   - telephonyNetworkInfo: The telephony network info.
    func update(telephonyNetworkInfo: TelephonyNetworkInfoHandleable) {
        self.telephonyNetworkInfo = telephonyNetworkInfo
    }
}

// MARK: - Carrier Key

extension TelephonyHandler {
    private var selectedCarrierKey: String? {
        if #available(iOS 13.0, *) {
            return telephonyNetworkInfo.safeDataServiceIdentifier

        } else {
            return retrievedCarrierKey
        }
    }
}

// MARK: - mcn and mcnd

extension TelephonyHandler {
    /// - Returns: The name of the primary carrier or empty string if the primary carrier is not registered (airplane mode or no primary sim).
    var mcn: String {
        guard let carrierKey = selectedCarrierKey,
              let radioName = telephonyNetworkInfo.serviceCurrentRadioAccessTechnology?[carrierKey],
              !radioName.isEmpty,
              let carrier = telephonyNetworkInfo.subscribers?[carrierKey] else {
            return ""
        }
        return carrier.displayedCarrierName ?? ""
    }

    /// - Returns: The name of the secondary carrier or empty string if the secondary carrier is not registered (airplane mode or no secondary sim).
    var mcnd: String {
        // Note: Only one eSIM can be enabled on iOS.
        // If there are more than one eSim, `serviceSubscriberCellularProviders.count` always equals to 2.
        let otherKey = telephonyNetworkInfo.subscribers?.filter {
            selectedCarrierKey != $0.key
        }.keys.first
        if let key = otherKey,
           let radioName = telephonyNetworkInfo.serviceCurrentRadioAccessTechnology?[key],
           !radioName.isEmpty,
           let carrier = telephonyNetworkInfo.subscribers?[key] {
            return carrier.displayedCarrierName ?? ""
        }
        return ""
    }
}

// MARK: - mnetw and mnetwd

extension TelephonyHandler {
    /// - Returns: The network status of the primary carrier.
    var mnetw: NSNumber? {
        guard let carrierKey = selectedCarrierKey,
              let radioName = telephonyNetworkInfo.serviceCurrentRadioAccessTechnology?[carrierKey] else {
            return networkType(for: "")
        }
        return networkType(for: radioName)
    }

    /// - Returns: The network status of the secondary carrier.
    var mnetwd: NSNumber? {
        guard let carrierKey = selectedCarrierKey else {
            return networkType(for: "")
        }

        // Note: Only one eSIM can be enabled on iOS.
        // If there are more than one eSIM, `serviceCurrentRadioAccessTechnology.count` always equals to 2.
        let otherKey = telephonyNetworkInfo.serviceCurrentRadioAccessTechnology?.filter {
            carrierKey != $0.key
        }.keys.first
        guard let key = otherKey,
              let radioName = telephonyNetworkInfo.serviceCurrentRadioAccessTechnology?[key] else {
            return networkType(for: "")
        }
        return networkType(for: radioName)
    }
}

// MARK: - Network Type

private extension TelephonyHandler {
    func networkType(for radioName: String) -> NSNumber? {
        guard let status = reachabilityStatusType else {
            return nil
        }

        switch status {
        case .wwan where radioName.isEmpty:
            return nil

        case .wwan where radioName.isLTE:
            return NSNumber(value: RATMobileNetworkType.cellularLTE.rawValue)

        case .wwan where radioName.is5G:
            return NSNumber(value: RATMobileNetworkType.cellular5G.rawValue)

        case .wwan:
            return NSNumber(value: RATMobileNetworkType.cellularOther.rawValue)

        case .wifi:
            return NSNumber(value: RATMobileNetworkType.wifi.rawValue)

        case .offline:
            return nil
        }
    }
}

// MARK: - CTCarrier

/// - Returns: The carrier name maximum length.
private let carrierNameLengthMax: Int = 32

private extension Carrierable {

    /// - Returns: The displayed carrier name.
    var displayedCarrierName: String? {
        var name: String?

        if let carrierName = carrierName {
            name = carrierName[0..<min(carrierNameLengthMax, carrierName.count)]
        }

        if !name.isEmpty && !mobileNetworkCode.isEmpty {
            return name
        }
        return nil
    }
}

// MARK: - Radio Access Technology

private extension String {
    var isLTE: Bool {
        self == CTRadioAccessTechnologyLTE
    }

    var is5G: Bool {
        if #available(iOS 14.1, *) {
            return self == CTRadioAccessTechnologyNR || self == CTRadioAccessTechnologyNRNSA
        }
        return false
    }
}

// MARK: - Network Type

extension String {
    var networkType: RATMobileNetworkType {
        if isLTE {
            return .cellularLTE

        } else if is5G {
            return .cellular5G

        } else {
            return .cellularOther
        }
    }
}
