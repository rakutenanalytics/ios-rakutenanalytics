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
         userStorageHandler: UserStorageHandleable,
         consentStore: DataCollectionConsentReadable)
    func addSdkSourceIfNeeded(_ payload: NSMutableDictionary, event: RAnalyticsEvent)
    func addCommonParameters(_ payload: NSMutableDictionary,
                             state: RAnalyticsState,
                             event: RAnalyticsEvent)
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

    /// Consent store for privacy control gating.
    private let consentStore: DataCollectionConsentReadable

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
         userStorageHandler: UserStorageHandleable,
         consentStore: DataCollectionConsentReadable = DataCollectionConsentStore.shared) {
        self.startTime = NSDate().toString
        self.bundle = bundle
        self.consentStore = consentStore
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
           let sdkSource = event.parameters[PayloadParameterKeys.sdkSource] as? String, !sdkSource.isEmpty {
            payload[PayloadParameterKeys.sdkSource] = sdkSource
            return
        }

        // Always set to "main" if not set or empty
        payload[PayloadParameterKeys.sdkSource] = "main"
    }

    /// Add the automatic fields to the RAT Payload.
    ///
    /// Every event sent through RAT (including Geo `loc`) passes this method. It always sets root-level
    /// `privacy_mode` last so the current consent snapshot cannot be overwritten by other merged fields.
    ///
    /// - Parameters:
    ///    - payload: The payload to update.
    ///    - state: The state.
    func addCommonParameters(_ payload: NSMutableDictionary,
                             state: RAnalyticsState,
                             event _: RAnalyticsEvent) {
        // MARK: acc, aid (always include)
        payload[PayloadParameterKeys.acc] =
            (payload[PayloadParameterKeys.acc] as? NSNumber)?.positiveIntegerNumber ?? NSNumber(value: bundle.accountIdentifier)
        payload[PayloadParameterKeys.aid] =
            (payload[PayloadParameterKeys.aid] as? NSNumber)?.positiveIntegerNumber ?? NSNumber(value: bundle.applicationIdentifier)

        payload.addEntries(from: state.alwaysCollectedCorePayload)
        addDeviceInformationParameters(payload, state: state)
        addUserInformationParameters(payload, state: state)
        addMobileNetworkParameters(payload)

        // MARK: ltm, cks (always include - session)
        payload[PayloadParameterKeys.ltm] = startTime
        payload[PayloadParameterKeys.cks] = state.sessionIdentifier

        payload[PayloadParameterKeys.privacyMode] = PrivacyControlPayload.privacyModeString(bundle: bundle, consentStore: consentStore)
    }

    private func addDeviceInformationParameters(_ payload: NSMutableDictionary, state: RAnalyticsState) {
        guard consentStore.isEnabled(.deviceInformation) else {
            return
        }
        payload.addEntries(from: state.deviceInformationMosPayload)
        if let languageCode = bundle.languageCode {
            payload[PayloadParameterKeys.dln] = languageCode
        }
        payload[PayloadParameterKeys.model] = UIDevice.current.modelIdentifier
        payload[PayloadParameterKeys.mori] = NSNumber(value: statusBarOrientationHandler.mori.rawValue)
        payload[PayloadParameterKeys.ckp] = state.deviceIdentifier
        payload[PayloadParameterKeys.ua] = userAgentHandler.value(for: state)
        payload[PayloadParameterKeys.uaEnriched] = userAgentHandler.enrichedValue(for: state)
        payload[PayloadParameterKeys.res] = deviceHandler.screenResolution
        payload[PayloadParameterKeys.tzo] = NSNumber(value: Double(NSTimeZone.local.secondsFromGMT()) / 3600.0)
        if deviceHandler.includesBatteryMetrics {
            payload[PayloadParameterKeys.powerstatus] = NSNumber(value: deviceHandler.batteryPowerStatusValue)
            payload[PayloadParameterKeys.mbat] = String(format: "%0.f", deviceHandler.batteryLevelPercentage)
        }
        if !state.advertisingIdentifier.isEmpty {
            payload[PayloadParameterKeys.cka] = state.advertisingIdentifier
        }
        if payload[PayloadParameterKeys.etype] as? String == RAnalyticsEvent.Name.sessionEnd {
            payload[PayloadParameterKeys.devicePer] = AnalyticsDevicePermissionCollector.shared.collectPermissions()
        }
    }

    private func addUserInformationParameters(_ payload: NSMutableDictionary,
                                              state: RAnalyticsState) {
        guard consentStore.isEnabled(.userInformation) else {
            return
        }
        if !state.easyIdentifier.isEmpty, (payload[PayloadParameterKeys.easyid] as? String).isEmpty {
            payload[PayloadParameterKeys.easyid] = state.easyIdentifier
        }
    }

    private func addMobileNetworkParameters(_ payload: NSMutableDictionary) {
        guard consentStore.isEnabled(.mobileNetwork) else { return }
        telephonyHandler.reachabilityStatus = reachabilityStatus
        if let mcn = telephonyHandler.mcn, !mcn.isEmpty {
            payload[PayloadParameterKeys.mcn] = mcn
        }
        if let mcnd = telephonyHandler.mcnd, !mcnd.isEmpty {
            payload[PayloadParameterKeys.mcnd] = mcnd
        }
        payload[PayloadParameterKeys.mnetw] = telephonyHandler.mnetw ?? ""
        payload[PayloadParameterKeys.mnetwd] = telephonyHandler.mnetwd ?? ""
        if let reachabilityStatus = reachabilityStatus {
            let isOnline = reachabilityStatus.uintValue != RATReachabilityStatus.offline.rawValue
            payload[PayloadParameterKeys.online] = NSNumber(value: isOnline)
        }
    }

    /// Add the RAT location fields to the RAT Payload.
    ///
    /// `loc` is added only if **both** LOCATION consent is enabled **and** ``RAnalyticsState/lastKnownLocation`` is
    /// non-`nil` (set in ``AnalyticsManager`` when collection is allowed). Otherwise the payload has no `loc`.
    ///
    /// - Parameters:
    ///    - payload: The Payload to update.
    ///    - state: The state.
    ///    - addActionParameters: a boolean that indicates if action parameters must be added to the payload or not.
    func addLocation(_ payload: NSMutableDictionary,
                     state: RAnalyticsState,
                     addActionParameters: Bool) {
        // MARK: loc
        guard consentStore.isEnabled(.location) else {
            RLogger.debug(message: "Location not added to payload because data collection is disabled.")
            return
        }

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

        payload[PayloadParameterKeys.Loc.loc] = locationModel.toDictionary

        if addActionParameters {
            let requestLocationActionParameters = locationModel.requestLocationActionParameters()
            if !requestLocationActionParameters.isEmpty {
                payload[PayloadParameterKeys.ActionParams.actionParams] = requestLocationActionParameters
            }
            payload[PayloadParameterKeys.isaction] = locationModel.isAction
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
