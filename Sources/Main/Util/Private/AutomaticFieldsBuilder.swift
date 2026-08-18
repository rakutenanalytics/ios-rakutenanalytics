import Foundation
import UIKit
import CoreLocation
import SystemConfiguration
#if os(iOS)
import CoreTelephony
#endif

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
         reachability: ReachabilityType?,
         userStorageHandler: UserStorageHandleable)
    func addSdkSourceIfNeeded(_ payload: NSMutableDictionary, event: RAnalyticsEvent)
    func addCommonParameters(_ payload: NSMutableDictionary, state: RAnalyticsState)
    func addLocation(_ payload: NSMutableDictionary,
                     state: RAnalyticsState,
                     addActionParameters: Bool)
    func updateCarrierNames(mcn: String?, mcnd: String?)
    func getCarrierNames() -> (primary: String?, secondary: String?)
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
         reachability: ReachabilityType?,
         userStorageHandler: UserStorageHandleable) {
        self.startTime = NSDate().toString
        self.bundle = bundle
        self.deviceHandler = DeviceHandler(device: deviceCapability,
                                           screen: screenHandler)
        self.telephonyHandler = TelephonyHandler(telephonyNetworkInfo: telephonyNetworkInfoHandler,
                                                 notificationCenter: notificationHandler,
                                                 userStorageHandler: userStorageHandler)
        self.statusBarOrientationHandler = RStatusBarOrientationHandler(application: analyticsStatusBarOrientationGetter)
        self.userAgentHandler = UserAgentHandler(bundle: bundle)
        self.notificationHandler = notificationHandler
        self.reachability = reachability

        // Reallocate telephonyNetworkInfo when the app becomes active
        _ = notificationHandler.observe(forName: UIApplication.didBecomeActiveNotification,
                                        object: nil,
                                        queue: nil) { _ in
            #if os(iOS)
            self.telephonyHandler.update(telephonyNetworkInfo: CTTelephonyNetworkInfo())
            #elseif os(tvOS)
            self.telephonyHandler.update(telephonyNetworkInfo: NoOpTelephonyNetworkInfo())
            #endif
        }
    }

    /// Add sdk_source parameter to the payload if not already set.
    /// This allows extensions and wrappers to set sdk_source before calling process(),
    /// and the main SDK will not overwrite their values.
    ///
    /// - Parameters:
    ///   - payload: The payload dictionary.
    ///   - event: The event being processed (used to check event parameters for custom events).
    func addSdkSourceIfNeeded(_ payload: NSMutableDictionary, event: RAnalyticsEvent) {
        // Check if sdk_source is already set in payload (and not empty)
        if let existingValue = payload[PayloadParameterKeys.sdkSource] as? String, !existingValue.isEmpty {
            return
        }

        // For custom events, check event parameters since regular params don't get copied to payload
        if event.name == RAnalyticsEvent.Name.custom,
           let sdkSource = event.parameters["sdk_source"] as? String, !sdkSource.isEmpty {
            payload[PayloadParameterKeys.sdkSource] = sdkSource
            return
        }

        // Always set to "main" if not set or empty
        payload[PayloadParameterKeys.sdkSource] = "main"
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
        if let mcn = telephonyHandler.mcn, !mcn.isEmpty {
            payload[PayloadParameterKeys.Telephony.mcn] = mcn
        }

        // MARK: mcnd
        if let mcnd = telephonyHandler.mcnd, !mcnd.isEmpty {
            payload[PayloadParameterKeys.Telephony.mcnd] = mcnd
        }

        // MARK: mnetw
        payload[PayloadParameterKeys.Telephony.mnetw] = telephonyHandler.mnetw ?? ""

        // MARK: mnetwd
        payload[PayloadParameterKeys.Telephony.mnetwd] = telephonyHandler.mnetwd ?? ""

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

        // MARK: ua_enriched
        payload[PayloadParameterKeys.UserAgent.uaEnriched] = userAgentHandler.enrichedValue(for: state)

        // MARK: res
        payload[PayloadParameterKeys.Device.res] = deviceHandler.screenResolution

        // MARK: ltm
        payload[PayloadParameterKeys.Time.ltm] = startTime

        // MARK: cks
        payload[PayloadParameterKeys.Identifier.cks] = state.sessionIdentifier

        // MARK: tzo
        payload[PayloadParameterKeys.TimeZone.tzo] = NSNumber(value: Double(NSTimeZone.local.secondsFromGMT()) / 3600.0)

        payload.addEntries(from: state.corePayload)

        if deviceHandler.includesBatteryMetrics {
            // MARK: powerstatus
            payload[PayloadParameterKeys.Device.powerStatus] = NSNumber(value: deviceHandler.batteryPowerStatusValue)

            // MARK: mbat
            payload[PayloadParameterKeys.Device.mbat] = String(format: "%0.f", deviceHandler.batteryLevelPercentage)
        }

        // MARK: cka
        if !state.advertisingIdentifier.isEmpty {
            payload[PayloadParameterKeys.Identifier.cka] = state.advertisingIdentifier
        }

        // MARK: easyid
        if !state.easyIdentifier.isEmpty && (payload[PayloadParameterKeys.Identifier.easyid] as? String).isEmpty {
            payload[PayloadParameterKeys.Identifier.easyid] = state.easyIdentifier
        }

        // MARK: device_per
        if payload[PayloadParameterKeys.etype] as? String == RAnalyticsEvent.Name.sessionEnd {
            payload[PayloadParameterKeys.Device.devicePer] = AnalyticsDevicePermissionCollector.shared.collectPermissions()
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

        payload[PayloadParameterKeys.Location.loc] = locationModel.toDictionary

        if addActionParameters {
            let requestLocationActionParameters = locationModel.requestLocationActionParameters()
            if !requestLocationActionParameters.isEmpty {
                payload[PayloadParameterKeys.ActionParameters.actionParams] = requestLocationActionParameters
            }
            payload[PayloadParameterKeys.isAction] = locationModel.isAction
        }
    }

    /// Update the carrier names in the telephony handler
    ///
    /// - Parameters:
    ///   - mcn: The primary carrier name
    ///   - mcnd: The secondary carrier name
    func updateCarrierNames(mcn: String?, mcnd: String?) {
        telephonyHandler.mcn = mcn
        telephonyHandler.mcnd = mcnd
    }

    /// Get the current carrier names from the telephony handler
    ///
    /// - Returns: Tuple containing primary and secondary carrier names
    func getCarrierNames() -> (primary: String?, secondary: String?) {
        return (primary: telephonyHandler.mcn, secondary: telephonyHandler.mcnd)
    }
}
