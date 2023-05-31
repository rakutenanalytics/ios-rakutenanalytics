import Foundation
import UIKit
import CoreLocation
import CoreTelephony
import SystemConfiguration

// MARK: - Date extension

extension Date {
    /// Convert a timestamp to ms.
    var toRatTimestamp: TimeInterval {
        max(0, round(timeIntervalSince1970 * 1000.0))
    }
}

// MARK: - CLLocation extension

extension CLLocation {
    /// The RAT timestamp in ms.
    var ratTimestamp: TimeInterval {
        timestamp.toRatTimestamp
    }
}

// MARK: - AutomaticFieldsBuildable protocol

protocol AutomaticFieldsBuildable {
    init(bundle: EnvironmentBundle,
         deviceCapability: DeviceCapability,
         screenHandler: Screenable,
         telephonyNetworkInfoHandler: TelephonyNetworkInfoHandleable,
         notificationHandler: NotificationObservable,
         analyticsStatusBarOrientationGetter: StatusBarOrientationGettable?,
         reachability: ReachabilityType?)
    func addCommonParameters(_ payload: NSMutableDictionary, state: RAnalyticsState)
    func addLocation(_ payload: NSMutableDictionary,
                     state: RAnalyticsState,
                     addActionParameters: Bool)
}

// MARK: - AutomaticFieldsBuilder

/// This class adds the automatic fields to the RAT Payload.
final class AutomaticFieldsBuilder: AutomaticFieldsBuildable {
    /// The start time of RAnalyticsRATTracker creation
    private let startTime: String

    /// the bundle
    private let bundle: EnvironmentBundle

    /// The device Handler
    private let deviceHandler: DeviceHandleable

    /// The telephony handler
    private var telephonyHandler: TelephonyHandleable

    /// The status bar orientation handler
    private let statusBarOrientationHandler: MoriGettable

    /// The user agent handler
    private let userAgentHandler: UserAgentHandleable

    /// The notification handler
    private let notificationHandler: NotificationObservable

    /// The reachability class handling the network status.
    private let reachability: ReachabilityType?

    /// The reachability status
    private var reachabilityStatus: NSNumber? {
        guard let value = reachability?.flags?.reachabilityStatus.rawValue else {
            return nil
        }
        return NSNumber(value: value)
    }

    /// Creates a new instance of `AutomaticFieldsBuilder`.
    init(bundle: EnvironmentBundle,
         deviceCapability: DeviceCapability,
         screenHandler: Screenable,
         telephonyNetworkInfoHandler: TelephonyNetworkInfoHandleable,
         notificationHandler: NotificationObservable,
         analyticsStatusBarOrientationGetter: StatusBarOrientationGettable?,
         reachability: ReachabilityType?) {
        self.startTime = NSDate().toString
        self.bundle = bundle
        self.deviceHandler = DeviceHandler(device: deviceCapability,
                                           screen: screenHandler)
        self.telephonyHandler = TelephonyHandler(telephonyNetworkInfo: telephonyNetworkInfoHandler,
                                                 notificationCenter: notificationHandler)
        self.statusBarOrientationHandler = RStatusBarOrientationHandler(application: analyticsStatusBarOrientationGetter)
        self.userAgentHandler = UserAgentHandler(bundle: bundle)
        self.notificationHandler = notificationHandler
        self.reachability = reachability

        // Reallocate telephonyNetworkInfo when the app becomes active
        _ = notificationHandler.observe(forName: UIApplication.didBecomeActiveNotification,
                                        object: nil,
                                        queue: nil) { _ in
            self.telephonyHandler.update(telephonyNetworkInfo: CTTelephonyNetworkInfo())
        }
    }

    /// Add the automatic fields to the RAT Payload.
    ///
    /// - Parameters:
    ///    - payload: The payload to update.
    ///    - state: The state.
    func addCommonParameters(_ payload: NSMutableDictionary,
                             state: RAnalyticsState) {
        // MARK: acc
        payload[PayloadParameterKeys.acc] =
            (payload[PayloadParameterKeys.acc] as? NSNumber)?.positiveIntegerNumber ?? NSNumber(value: bundle.accountIdentifier)

        // MARK: aid
        payload[PayloadParameterKeys.aid] =
        (payload[PayloadParameterKeys.aid] as? NSNumber)?.positiveIntegerNumber ?? NSNumber(value: bundle.applicationIdentifier)

        // MARK: dln
        if let languageCode = bundle.languageCode {
            payload[PayloadParameterKeys.Language.dln] = languageCode
        }

        // MARK: model
        payload[PayloadParameterKeys.Device.model] = UIDevice.current.modelIdentifier

        // Telephony Handler
        telephonyHandler.reachabilityStatus = reachabilityStatus

        // MARK: mcn
        payload[PayloadParameterKeys.Telephony.mcn] = telephonyHandler.mcn

        // MARK: mcnd
        payload[PayloadParameterKeys.Telephony.mcnd] = telephonyHandler.mcnd

        // MARK: mnetw
        payload[PayloadParameterKeys.Telephony.mnetw] = telephonyHandler.mnetw ?? ""

        // MARK: mnetwd
        payload[PayloadParameterKeys.Telephony.mnetwd] = telephonyHandler.mnetwd ?? ""

        // MARK: simop
        if !telephonyHandler.simop.isEmpty {
            payload[PayloadParameterKeys.Telephony.simop] = telephonyHandler.simop
        }

        // MARK: simopn
        if !telephonyHandler.simopn.isEmpty {
            payload[PayloadParameterKeys.Telephony.simopn] = telephonyHandler.simopn
        }

        // MARK: mori
        payload[PayloadParameterKeys.Orientation.mori] = NSNumber(value: statusBarOrientationHandler.mori.rawValue)

        // MARK: online
        if let reachabilityStatus = reachabilityStatus {
            let isOnline = reachabilityStatus.uintValue != RATReachabilityStatus.offline.rawValue
            payload[PayloadParameterKeys.Network.online] = NSNumber(value: isOnline)
        }

        // MARK: ckp
        payload[PayloadParameterKeys.Identifier.ckp] = state.deviceIdentifier

        // MARK: ua
        payload[PayloadParameterKeys.UserAgent.ua] = userAgentHandler.value(for: state)

        // MARK: res
        payload[PayloadParameterKeys.Device.res] = deviceHandler.screenResolution

        // MARK: ltm
        payload[PayloadParameterKeys.Time.ltm] = startTime

        // MARK: cks
        payload[PayloadParameterKeys.Identifier.cks] = state.sessionIdentifier

        // MARK: tzo
        payload[PayloadParameterKeys.TimeZone.tzo] = NSNumber(value: Double(NSTimeZone.local.secondsFromGMT()) / 3600.0)

        payload.addEntries(from: state.corePayload)

        if deviceHandler.batteryState != .unknown {
            // MARK: powerstatus
            payload[PayloadParameterKeys.Device.powerStatus] = NSNumber(value: deviceHandler.batteryState != .unplugged ? 1 : 0)

            // MARK: mbat
            payload[PayloadParameterKeys.Device.mbat] = String(format: "%0.f", deviceHandler.batteryLevel * 100)
        }

        // MARK: cka
        if !state.advertisingIdentifier.isEmpty {
            payload[PayloadParameterKeys.Identifier.cka] = state.advertisingIdentifier
        }

        // MARK: userid
        if !state.userIdentifier.isEmpty && (payload[PayloadParameterKeys.Identifier.userid] as? String).isEmpty {
            payload[PayloadParameterKeys.Identifier.userid] = state.userIdentifier
        }

        // MARK: easyid
        if !state.easyIdentifier.isEmpty && (payload[PayloadParameterKeys.Identifier.easyid] as? String).isEmpty {
            payload[PayloadParameterKeys.Identifier.easyid] = state.easyIdentifier
        }
    }

    /// Add the RAT location fields to the RAT Payload.
    ///
    /// - Parameters:
    ///    - payload: The Payload to update.
    ///    - state: The state.
    ///    - addActionParameters: a boolean that indicates if action parameters must be added to the payload or not.
    func addLocation(_ payload: NSMutableDictionary,
                     state: RAnalyticsState,
                     addActionParameters: Bool) {
        // MARK: loc

        guard let locationModel = state.lastKnownLocation else {
            RLogger.debug(message: "Location can't be tracked because lastKnownLocation is nil.")
            return
        }

        let coordinate = CLLocationCoordinate2D(latitude: locationModel.latitude,
                                                longitude: locationModel.longitude)

        guard CLLocationCoordinate2DIsValid(coordinate) else {
            RLogger.debug(message: "Location can't be tracked because coordinates are invalid.")
            return
        }

        var locationPayload = locationModel.toDictionary

        if addActionParameters {
            locationPayload = locationModel.addAction(to: locationPayload)
        }

        payload[PayloadParameterKeys.Location.loc] = locationPayload
    }
}
