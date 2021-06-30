import Foundation
import CoreTelephony

/// Mobile Network Type
/// - Note: This maps the values for the otherwise-undocumented MOBILE_NETWORK_TYPE RAT parameter.
@objc public enum RATMobileNetworkType: Int {
    case wifi = 1
    case cellularOther = 3
    case cellularLTE = 4
    case cellular5G = 5
}

/// The Telephony Handler handles the core telephony framework.
@objc public final class TelephonyHandler: NSObject {
    private var telephonyNetworkInfo: TelephonyHandleable
    private let notificationCenter: NotificationObservable
    private var retrievedCarrierKey: String? // used for iOS == 12.x
    private var currentCarrierName: String? // used for iOS <= 11.x
    private var currentCarrierRadio: String? // used for iOS <= 11.x
    @objc public var reachabilityStatus: NSNumber?

    /// Creates a new instance of `TelephonyHandler`.
    ///
    /// - Parameters:
    ///   - telephonyNetworkInfo: The telephony network info.
    ///   - notificationCenter: The notification center.
    ///
    /// - Returns: a new instance of `TelephonyHandler`.
    @objc public init(telephonyNetworkInfo: TelephonyHandleable,
                      notificationCenter: NotificationObservable) {
        self.telephonyNetworkInfo = telephonyNetworkInfo
        self.notificationCenter = notificationCenter

        super.init()

        configure()
    }

    private func configure() {
        if #available(iOS 13.0, *) {
            // Do nothing

        } else  if #available(iOS 12.0, *) {
            // Listen to changes in radio access technology, to detect LTE.
            _ = notificationCenter.observe(forName: .CTServiceRadioAccessTechnologyDidChange, object: nil, queue: nil) { notification in
                self.retrievedCarrierKey = notification.object as? String
            }

        } else {
            // Check immediately, then listen to changes.
            updateCarrierInfos()

            // Listen to changes in radio access technology, to detect LTE.
            _ = notificationCenter.observe(forName: .CTRadioAccessTechnologyDidChange, object: nil, queue: nil) { _ in
                DispatchQueue.main.async {
                    self.updateCarrierInfos()
                }
            }
        }
    }

    private func updateCarrierInfos() {
        if self.telephonyNetworkInfo.responds(to: #selector(getter: CTTelephonyNetworkInfo.subscriberCellularProvider)) {
            self.currentCarrierName = self.telephonyNetworkInfo.subscriberCellularProvider?.displayedCarrierName
        }

        if self.telephonyNetworkInfo.responds(to: #selector(getter: CTTelephonyNetworkInfo.currentRadioAccessTechnology)) {
            self.currentCarrierRadio = self.telephonyNetworkInfo.currentRadioAccessTechnology
        }
    }
}

// MARK: - Update

extension TelephonyHandler {
    /// Replace the current instance of telephonyNetworkInfo by a new one given as a parameter `telephonyNetworkInfo`.
    ///
    /// - Parameters:
    ///   - telephonyNetworkInfo: The telephony network info.
    @objc public func update(telephonyNetworkInfo: TelephonyHandleable) {
        self.telephonyNetworkInfo = telephonyNetworkInfo
    }
}

// MARK: - Carrier Key

extension TelephonyHandler {
    @available(iOS 12.0, *)
    private var selectedCarrierKey: String? {
        if #available(iOS 13.0, *) {
            return telephonyNetworkInfo.dataServiceIdentifier

        } else {
            return retrievedCarrierKey
        }
    }
}

// MARK: - mcn and mcnd

extension TelephonyHandler {
    /// - Returns: The name of the primary carrier.
    @objc public var mcn: String {
        if #available(iOS 12.0, *) {
            return primaryMcn

        } else {
            return currentCarrierName ?? ""
        }
    }

    @available(iOS 12.0, *)
    private var primaryMcn: String {
        guard let carrierKey = selectedCarrierKey,
              let carrier = telephonyNetworkInfo.serviceSubscriberCellularProviders?[carrierKey] else {
            return ""
        }
        return carrier.displayedCarrierName ?? ""
    }

    /// - Returns: The name of the secondary carrier.
    @objc public var mcnd: String {
        if #available(iOS 12.0, *) {
            return eSimMcn

        } else {
            return ""
        }
    }

    @available(iOS 12.0, *)
    private var eSimMcn: String {
        // Note: Only one eSIM can be enabled on iOS.
        // If there are more than one eSim, `serviceSubscriberCellularProviders.count` always equals to 2.
        let otherKey = telephonyNetworkInfo.serviceSubscriberCellularProviders?.filter {
            selectedCarrierKey != $0.key
        }.keys.first
        if let key = otherKey,
           let carrier = telephonyNetworkInfo.serviceSubscriberCellularProviders?[key] {
            return carrier.displayedCarrierName ?? ""
        }
        return ""
    }
}

// MARK: - mnetw and mnetwd

extension TelephonyHandler {
    /// - Returns: The network status of the primary carrier.
    @objc public var mnetw: NSNumber? {
        if #available(iOS 12.0, *) {
            return primaryMnetw

        } else {
            guard let radioName = currentCarrierRadio else {
                return networkType(for: "")
            }
            return networkType(for: radioName)
        }
    }

    @available(iOS 12.0, *)
    private var primaryMnetw: NSNumber? {
        guard let carrierKey = selectedCarrierKey,
              let radioName = telephonyNetworkInfo.serviceCurrentRadioAccessTechnology?[carrierKey] else {
            return networkType(for: "")
        }
        return networkType(for: radioName)
    }

    /// - Returns: The network status of the secondary carrier.
    @objc public var mnetwd: NSNumber? {
        if #available(iOS 12.0, *) {
            return eSimMnetwd

        } else {
            return networkType(for: "")
        }
    }

    @available(iOS 12.0, *)
    private var eSimMnetwd: NSNumber? {
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
        guard let value = reachabilityStatus?.intValue,
              let status = RATReachabilityStatus(rawValue: value) else {
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

private extension CTCarrier {
    /// - Returns: The carrier name maximum length.
    private static let carrierNameLengthMax: Int = 32

    /// - Returns: The displayed carrier name.
    var displayedCarrierName: String? {
        var name: String?

        if let carrierName = carrierName {
            name = carrierName[0..<min(CTCarrier.carrierNameLengthMax, carrierName.count)]
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
