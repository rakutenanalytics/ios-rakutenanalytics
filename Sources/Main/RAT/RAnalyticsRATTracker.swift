import Foundation
import CoreTelephony
import CoreLocation
import UIKit
#if canImport(RSDKUtils)
import RSDKUtils
#else // SPM version
import RSDKUtilsMain
#endif

// swiftlint:disable type_name
public typealias RAnalyticsRATShouldDuplicateEventCompletion = (_ eventName: String, _ duplicateAccId: Int64) -> Bool

/// Concrete implementation of @ref RAnalyticsTracker that sends events to RAT.
///
/// - Attention: Application developers **MUST** configure the instance by setting
/// the `RATAccountIdentifier` and `RATAppIdentifier` keys in their app's Info.plist.
@objc(RAnalyticsRATTracker) public final class RAnalyticsRATTracker: NSObject, Tracker {
    enum Constants {
        static let ratEventPrefix      = "rat."
        static let ratGenericEventName = "rat.generic"
        static let ratBatchingDelay: TimeInterval = 1.0 // Batching delay is 1 second by default
    }

    /// The identifer of the last-tracked visited page, if any.
    private var lastVisitedPageIdentifier: String?

    /// Carried-over origin, if the previous visit was skipped because it didn't qualify as a page for RAT.
    private var carriedOverOrigin: NSNumber?

    /// The start time of RAnalyticsRATTracker creation
    private let startTime: String

    /// Telephony Handler
    private var telephonyHandler: TelephonyHandleable

    /// Device Handler
    private let deviceHandler: DeviceHandleable

    /// User Agent Handler
    private let userAgentHandler: UserAgentHandleable

    /// Reachability Notifier
    private let reachabilityNotifier: ReachabilityNotifiable?

    /// Reachability Status
    var reachabilityStatus: NSNumber?

    /// Bundle
    private let bundle: EnvironmentBundle

    /// Status Bar Orientation Handler
    private let statusBarOrientationHandler: MoriGettable

    /// RPCookie fetcher is used to retrieve the cookie details on initialize
    /// - Note: marked as `@objc` for `RAnalyticsRATTrackerInitSpec`.
    @objc private let rpCookieFetcher: RAnalyticsRpCookieFetchable?

    /// Sender
    /// - Note: marked as `@objc` for this deprecated method:
    /// `@objc public static func endpointAddress() -> URL?`
    @objc private let sender: Sendable?

    /// The RAT Account Identifier
    ///
    /// - Note: This identifier is configured in the app's `Info.plist` for the key `RATAccountIdentifier`.
    ///
    /// - Warning: If this identifier is not configured in the app's `Info.plist`, a default value is set: `477`.
    ///
    /// - Warning: The type of this identifier must be `Number` in the app's `Info.plist`.
    public let accountIdentifier: Int64

    /// The RAT Application Identifier
    ///
    /// - Note: This identifier is configured in the app's `Info.plist` for the key `RATAppIdentifier`.
    ///
    /// - Warning: If this identifier is not configured in the app's `Info.plist`, a default value is set: `1`.
    ///
    /// - Warning: The type of this identifier must be `Number` in the app's `Info.plist`.
    public let applicationIdentifier: Int64

    /// The dependencies container
    private let dependenciesContainer: SimpleDependenciesContainable

    /// RAT accounts to duplicate events to
    var duplicateAccounts: Set<RATAccount>

    /// Enable or disable events from being duplicated at runtime.
    ///
    /// For example, to disable `AnalyticsManager.Event.Name.sessionStart`:
    /// `RAnalyticsRATTracker.shared().shouldDuplicateRATEventHandler = { eventName, acc in eventName != AnalyticsManager.Event.Name.sessionStart }`
    ///
    /// Note that it is also possible to prevent duplicate events at build time in the `RAnalyticsConfiguration.plist` file:
    /// 1) First create a `RAnalyticsConfiguration.plist` file and add it to your Xcode project.
    /// 2) Create a key `RATDuplicateAccounts` array
    /// 3) Add a dict with a `RATAccountIdentifier` and a `RATApplicationIdentifier` integer key
    /// 4) Add `RATNonDuplicatedEventsList` and add the array of non-duplicated events.
    ///
    /// For example, to disable all automatic tracking add the following to your `RAnalyticsConfiguration.plist` file:
    ///
    /// <key>RATDuplicateAccounts</key>
    /// <array>
    /// <dict>
    /// <key>RATAccountIdentifier</key>
    /// <integer>477</integer>
    /// <key>RATApplicationIdentifier</key>
    /// <integer>1</integer>
    /// <key>RATNonDuplicatedEventsList</key>
    /// <array>
    /// <string>_rem_init_launch</string>
    /// <string>_rem_launch</string>
    /// <string>_rem_end_session</string>
    /// <string>_rem_update</string>
    /// <string>_rem_login</string>
    /// <string>_rem_login_failure</string>
    /// <string>_rem_logout</string>
    /// <string>_rem_install</string>
    /// <string>_rem_visit</string>
    /// <string>_rem_push_received</string>
    /// <string>_rem_push_notify</string>
    /// <string>_rem_push_auto_register</string>
    /// <string>_rem_push_auto_unregister</string>
    /// <string>_rem_sso_credential_found</string>
    /// <string>_rem_login_credential_found</string>
    /// <string>_rem_credential_strategies</string>
    /// <string>_analytics_custom</string>
    /// </array>
    /// </dict>
    /// </array>
    @objc public var shouldDuplicateRATEventHandler: RAnalyticsRATShouldDuplicateEventCompletion?

    /// The RAT Endpoint URL.
    @objc public var endpointURL: URL? {
        get {
            sender?.endpointURL
        }

        set {
            sender?.endpointURL = newValue
            rpCookieFetcher?.endpointURL = newValue
        }
    }

    private static let singleton: RAnalyticsRATTracker = {
        RAnalyticsRATTracker(dependenciesContainer: SimpleDependenciesContainer())
    }()

    /// Retrieve the shared instance.
    ///
    /// - Returns: The shared instance.
    @objc(sharedInstance) public static func shared() -> RAnalyticsRATTracker {
        singleton
    }

    /// Creates a new instance of `RAnalyticsRATTracker`.
    ///
    /// - Parameters:
    ///   - dependenciesContainer: The dependencies container.
    ///
    /// - Returns: a new instance of `RAnalyticsRATTracker`.
    init(dependenciesContainer: SimpleDependenciesContainable) {
        // Retrieve the mandatory dependencies
        self.dependenciesContainer = dependenciesContainer
        let bundleContainer = dependenciesContainer.bundle
        let httpCookieStore = dependenciesContainer.httpCookieStore
        let notificationCenter = dependenciesContainer.notificationHandler
        let telephonyNetworkInfoHandler = dependenciesContainer.telephonyNetworkInfoHandler
        let device = dependenciesContainer.deviceCapability
        let screen = dependenciesContainer.screenHandler
        let session = dependenciesContainer.session

        // Sender
        self.sender = RAnalyticsSender(databaseConfiguration: dependenciesContainer.databaseConfiguration,
                                       bundle: bundleContainer,
                                       session: session)
        self.sender?.setBatchingDelayBlock(Constants.ratBatchingDelay)

        self.startTime = NSDate().toString

        // Attempt to read the IDs from the app's plist
        // If not found, use 477/1 as default values for account/application ID.
        self.accountIdentifier = bundleContainer.accountIdentifier
        self.applicationIdentifier = bundleContainer.applicationIdentifier

        // Bundle
        self.bundle = bundleContainer
        self.duplicateAccounts = Set(bundle.duplicateAccounts ?? [])

        // Status Bar Orientation Handler
        let analyticsStatusBarOrientationGetter = dependenciesContainer.analyticsStatusBarOrientationGetter
        statusBarOrientationHandler = RStatusBarOrientationHandler(application: analyticsStatusBarOrientationGetter)

        // Reachability Notifier
        reachabilityNotifier = ReachabilityNotifier(host: ReachabilityConstants.host,
                                                    callback: RAnalyticsRATTracker.reachabilityCallback)

        // Rp Cookie Fetcher
        self.rpCookieFetcher = RAnalyticsRpCookieFetcher(cookieStorage: httpCookieStore)
        self.rpCookieFetcher?.getRpCookieCompletionHandler { _, error in
            if let error = error {
                let errorReason = String(describing: error.localizedFailureReason)
                ErrorRaiser.raise(.detailedError(domain: ErrorDomain.ratTrackerErrorDomain,
                                                 code: ErrorCode.rpCookieCantBeFetched.rawValue,
                                                 description: ErrorDescription.rpCookieCantBeFetched,
                                                 reason: "RAnalyticsRpCookieFetcher error: \(error.localizedDescription) \(errorReason)"))
            }
        }

        // Telephony Handler
        self.telephonyHandler = TelephonyHandler(telephonyNetworkInfo: telephonyNetworkInfoHandler,
                                                 notificationCenter: notificationCenter)

        // Device Handler
        self.deviceHandler = DeviceHandler(device: device, screen: screen)

        // User Agent
        self.userAgentHandler = UserAgentHandler(bundle: bundle)

        super.init()

        logTrackingError(ErrorDescription.eventsNotProcessedByRATTracker)

        // Reallocate telephonyNetworkInfo when the app becomes active
        _ = notificationCenter.observe(forName: UIApplication.didBecomeActiveNotification,
                                       object: nil,
                                       queue: nil) { _ in
            self.telephonyHandler.update(telephonyNetworkInfo: CTTelephonyNetworkInfo())
        }
    }
}

// MARK: - Automatic Fields

private extension RAnalyticsRATTracker {
    /// Add the automatic fields to the RAT Payload.
    ///
    /// - Parameters:
    ///     - payload: the Payload to update.
    ///     - state: the State.
    func addAutomaticFields(_ payload: NSMutableDictionary, state: RAnalyticsState) {
        // MARK: acc
        payload[PayloadParameterKeys.acc] =
            (payload[PayloadParameterKeys.acc] as? NSNumber)?.positiveIntegerNumber ?? NSNumber(value: accountIdentifier)
        // MARK: aid
        payload[PayloadParameterKeys.aid] =
            (payload[PayloadParameterKeys.aid] as? NSNumber)?.positiveIntegerNumber ?? NSNumber(value: applicationIdentifier)

        if deviceHandler.batteryState != .unknown {
            // MARK: powerstatus
            payload[PayloadParameterKeys.Device.powerStatus] = NSNumber(value: deviceHandler.batteryState != .unplugged ? 1 : 0)

            // MARK: mbat
            payload[PayloadParameterKeys.Device.mbat] = String(format: "%0.f", deviceHandler.batteryLevel * 100)
        }

        // MARK: dln
        if let languageCode = bundle.languageCode {
            payload[PayloadParameterKeys.Language.dln] = languageCode
        }

        // MARK: loc
        var coordinate = kCLLocationCoordinate2DInvalid

        let location = state.lastKnownLocation

        if let location = location {
            coordinate = location.coordinate
        }

        if CLLocationCoordinate2DIsValid(coordinate),
           let location = location {
            let locationDic = NSMutableDictionary()

            // MARK: loc.accu
            locationDic[PayloadParameterKeys.Location.accu] = NSNumber(value: max(0.0, location.horizontalAccuracy))

            // MARK: loc.altitude
            locationDic[PayloadParameterKeys.Location.altitude] = NSNumber(value: location.altitude)

            // MARK: loc.tms
            locationDic[PayloadParameterKeys.Location.tms] = NSNumber(value: max(0, round(location.timestamp.timeIntervalSince1970 * 1000.0)))

            // MARK: loc.lat
            locationDic[PayloadParameterKeys.Location.lat] = NSNumber(value: min(90.0, max(-90.0, coordinate.latitude)))

            // MARK: loc.long
            locationDic[PayloadParameterKeys.Location.long] = NSNumber(value: min(180.0, max(-180.0, coordinate.longitude)))

            // MARK: loc.speed
            locationDic[PayloadParameterKeys.Location.speed] = NSNumber(value: max(0.0, location.speed))

            payload[PayloadParameterKeys.Location.loc] = locationDic
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

        payload.addEntries(from: CoreHelpers.sharedPayload(for: state))
    }
}

// MARK: - Process an event

extension RAnalyticsRATTracker {
    @discardableResult
    @objc(processEvent:state:) public func process(event: RAnalyticsEvent, state: RAnalyticsState) -> Bool {
        guard let payload = buildPayload(for: event, state: state) else {
            return false
        }

        if let sender = sender {
            sender.send(jsonObject: payload)

            if case .referralApp(let referralAppModel) = state.referralTracking {
                let referralAppAccount = RATAccount(accountId: referralAppModel.accountIdentifier,
                                                    applicationId: referralAppModel.applicationIdentifier,
                                                    disabledEvents: nil)

                let referralPayload = payload.duplicate(for: referralAppAccount)
                referralPayload[PayloadParameterKeys.etype] = RAnalyticsEvent.Name.deeplink

                sender.send(jsonObject: referralPayload)

                duplicateEvent(named: event.name, with: payload, exclude: referralAppAccount, sender: sender)

            } else {
                duplicateEvent(named: event.name, with: payload, sender: sender)
            }

            return true

        } else {
            logTrackingError("The event \(event.name) could not be processed by the RAT Tracker.")
            return false
        }
    }

    private func logTrackingError(_ errorDescription: String) {
        var message = ""

        if dependenciesContainer.databaseConfiguration == nil {
            message += "\(ErrorReason.databaseConnectionIsNil) "
        }

        if bundle.endpointAddress == nil {
            message += "\(ErrorReason.endpointMissing) "
        }

        if !message.isEmpty {
            ErrorRaiser.raise(.detailedError(domain: ErrorDomain.ratTrackerErrorDomain,
                                             code: ErrorCode.eventsNotProcessedByRATracker.rawValue,
                                             description: errorDescription,
                                             reason: message))
        }
    }

    /// Build the RAT payload for a given event and state.
    ///
    /// - Parameters:
    ///     - event: the Event.
    ///     - state: the State.
    ///
    /// - Returns: a mutable payload or nil.
    private func buildPayload(for event: RAnalyticsEvent,
                              state: RAnalyticsState) -> NSMutableDictionary? {
        let payload = NSMutableDictionary()
        let extra = NSMutableDictionary()

        payload[PayloadParameterKeys.etype] = event.name

        if !updatePayload(payload, extra: extra, event: event, state: state) {
            return nil
        }

        if let dict = extra as? [String: Any],
           !dict.isEmpty {
            // If the event already had a 'cp' field, those values take precedence
            if let params = payload[PayloadParameterKeys.cp] as? [AnyHashable: Any] {
                extra.addEntries(from: params)
            }

            payload[PayloadParameterKeys.cp] = extra
        }

        addAutomaticFields(payload, state: state)

        return payload
    }

    /// Update the RAT payload for a given event and state.
    ///
    /// - Parameters:
    ///     - payload: the Payload to update.
    ///     - extra: the Extra Payload to update.
    ///     - event: the Event.
    ///     - state: the State.
    ///
    /// - Returns: `true` if the payload is updated or `false`.
    private func updatePayload(_ payload: NSMutableDictionary,
                               extra: NSMutableDictionary,
                               event: RAnalyticsEvent,
                               state: RAnalyticsState) -> Bool {
        // Core SDK events
        switch event.name {
        // MARK: _rem_init_launch
        case RAnalyticsEvent.Name.initialLaunch: () // Do nothing

        // MARK: _rem_install
        case RAnalyticsEvent.Name.install:
            payload[RAnalyticsConstants.sdkDependenciesKey] = CoreHelpers.sdkDependencies
            extra.addEntries(from: event.installParameters)

        // MARK: _rem_launch
        case RAnalyticsEvent.Name.sessionStart:
            extra.addEntries(from: state.sessionStartParameters)

        // MARK: _rem_end_session
        case RAnalyticsEvent.Name.sessionEnd: () // Do nothing

        // MARK: _rem_update
        case RAnalyticsEvent.Name.applicationUpdate:
            extra.addEntries(from: state.applicationUpdateParameters)

        // MARK: _rem_login
        case RAnalyticsEvent.Name.login:
            extra.addEntries(from: state.loginParameters)

        // MARK: _rem_login_failure
        case RAnalyticsEvent.Name.loginFailure:
            extra.addEntries(from: event.loginFailureParameters)

        // MARK: _rem_logout
        case RAnalyticsEvent.Name.logout:
            extra.addEntries(from: event.logoutParameters)

        // MARK: _rem_visit
        case RAnalyticsEvent.Name.pageVisit:
            // Override etype
            payload[PayloadParameterKeys.etype] = RAnalyticsEvent.Name.pageVisitForRAT

            switch state.referralTracking {
            case .page(let currentPage):
                guard let currentPage = currentPage else {
                    return false
                }
                if !updatePayloadForCurrentPage(for: event,
                                                state: state,
                                                payload: payload,
                                                extra: extra,
                                                currentPage: currentPage) {
                    return false
                }

            case .swiftuiPage(let pageName):
                if !updatePayloadForPageVisit(pageIdentifier: pageName,
                                              state: state,
                                              payload: payload,
                                              extra: extra) {
                    return false
                }

            case .referralApp(let referralAppModel):
                updatePayloadForReferralApp(payload: payload,
                                            extra: extra,
                                            referralApp: referralAppModel)

            case .none:
                return false
            }

        // MARK: _rem_push_notify
        case RAnalyticsEvent.Name.pushNotification:
            guard let pushParameters = event.pushParameters else {
                return false
            }
            extra.addEntries(from: pushParameters)

        // MARK: _rem_push_received
        case RAnalyticsEvent.Name.pushNotificationReceived:
            guard let pushParameters = event.pushParameters else {
                return false
            }
            extra.addEntries(from: pushParameters)

            if !event.pushRequestIdentifier.isEmpty {
                extra[CpParameterKeys.Push.pushRequestIdentifier] = event.pushRequestIdentifier
            }

        // MARK: _rem_push_cv
        case RAnalyticsEvent.Name.pushNotificationConversion:
            guard !event.pushRequestIdentifier.isEmpty
                    && !event.pushConversionAction.isEmpty else {
                return false
            }
            extra[CpParameterKeys.Push.pushRequestIdentifier] = event.pushRequestIdentifier
            extra[CpParameterKeys.Push.pushConversionAction] = event.pushConversionAction

        // MARK: _rem_push_auto_register, _rem_push_auto_unregister
        case RAnalyticsEvent.Name.pushAutoRegistration, RAnalyticsEvent.Name.pushAutoUnregistration:
            guard !event.parameters.isEmpty,
                  let deviceId = event.parameters[CpParameterKeys.PNP.deviceId] as? String,
                  !deviceId.isEmpty,
                  let pnpClientId = event.parameters[CpParameterKeys.PNP.pnpClientId] as? String,
                  !pnpClientId.isEmpty else {
                return false
            }
            extra.addEntries(from: event.parameters)

        // MARK: _rem_discover_＊
        case let value where value.hasPrefix("_rem_discover_"):
            extra.addEntries(from: event.discoverParameters)

        // MARK: _rem_sso_credential_found
        case RAnalyticsEvent.Name.SSOCredentialFound:
            extra.addEntries(from: event.ssoParameters)

        // MARK: _rem_login_credential_found
        case RAnalyticsEvent.Name.loginCredentialFound:
            extra.addEntries(from: event.loginCredentialFoundParameters)

        // MARK: _rem_credential_strategies
        case RAnalyticsEvent.Name.credentialStrategies:
            extra.addEntries(from: event.credentialStrategiesParameters)

        // MARK: _analytics_custom (wrapper for event name and its data)
        case RAnalyticsEvent.Name.custom:
            guard let eventName = event.parameters[RAnalyticsEvent.Parameter.eventName] as? String,
                  !eventName.isEmpty else {
                return false
            }

            payload[PayloadParameterKeys.etype] = eventName

            if let topLevelObject = event.parameters[RAnalyticsEvent.Parameter.topLevelObject] as? [AnyHashable: Any],
               !topLevelObject.isEmpty {
                payload.addEntries(from: topLevelObject)
            }

            if let parameters = event.parameters[RAnalyticsEvent.Parameter.eventData] as? [AnyHashable: Any],
               !parameters.isEmpty {
                extra.addEntries(from: parameters)
            }

            if let customAccNumber = event.parameters[RAnalyticsEvent.Parameter.customAccNumber] as? NSNumber {
                payload[PayloadParameterKeys.acc] = customAccNumber.positiveIntegerNumber
            }

        // MARK: rat.＊
        case let value where value.hasPrefix(Constants.ratEventPrefix):
            if !event.parameters.isEmpty {
                payload.addEntries(from: event.parameters)
            }

            guard let etype = event.eType else {
                return false
            }
            payload[PayloadParameterKeys.etype] = etype

        // MARK: Unsupported events
        default:
            return false
        }

        return true
    }
}

// MARK: - Page Visit Event

private extension RAnalyticsRATTracker {
    /// Update the RAT payload for the Page Visit Event.
    ///
    /// - Parameters:
    ///     - pageVisitEvent: the Page Visit Event.
    ///     - state: the Page Visit State.
    ///     - payload: the Payload to update.
    ///     - extra: the Extra Payload to update.
    ///
    /// - Returns: `true` if the update is complete or `false`.
    func updatePayloadForCurrentPage(for pageVisitEvent: RAnalyticsEvent,
                                     state: RAnalyticsState,
                                     payload: NSMutableDictionary,
                                     extra: NSMutableDictionary,
                                     currentPage: UIViewController) -> Bool {
        var pageIdentifier = pageVisitEvent.parameters[RAnalyticsEvent.Parameter.pageId] as? String
        var pageTitle = currentPage.navigationItem.title ?? currentPage.title
        let pageURL = currentPage.view.getWebViewURL()?.absoluteURL

        pageIdentifier = !pageIdentifier.isEmpty ? pageIdentifier : nil
        pageTitle = !pageTitle.isEmpty ? pageTitle : nil

        if pageIdentifier == nil {
            if let bundleIdentifier = Bundle(for: type(of: currentPage)).bundleIdentifier,
               bundleIdentifier.hasPrefix("com.apple.") && pageURL == nil && pageTitle == nil {
                // Apple class with no title and no URL − should not count as a page visit.
                pageIdentifier = nil

            } else {
                // Custom view controller class with no title.
                pageIdentifier = NSStringFromClass(type(of: currentPage))
            }
        }

        return updatePayloadForPageVisit(pageIdentifier: pageIdentifier,
                                         pageTitle: pageTitle,
                                         pageURL: pageURL,
                                         state: state,
                                         payload: payload,
                                         extra: extra)
    }

    func updatePayloadForPageVisit(pageIdentifier: String?,
                                   pageTitle: String? = nil,
                                   pageURL: URL? = nil,
                                   state: RAnalyticsState,
                                   payload: NSMutableDictionary,
                                   extra: NSMutableDictionary) -> Bool {
        // If no page id was found, simply ignore this view controller.
        guard !pageIdentifier.isEmpty else {
            // If this originated from a push notification or an inbound URL, keep that for next call.
            if state.origin != .internal {
                self.carriedOverOrigin = NSNumber(value: state.origin.rawValue)
            }
            return false
        }

        payload[PayloadParameterKeys.pgn] = pageIdentifier

        let lastVisitedPageIdentifier = self.lastVisitedPageIdentifier
        if !lastVisitedPageIdentifier.isEmpty {
            payload[PayloadParameterKeys.ref] = lastVisitedPageIdentifier
        }
        self.lastVisitedPageIdentifier = pageIdentifier

        // If this transition was internal but a previous (skipped) transition
        // originated from a push notification or an inbound URL, use the correct origin.
        var origin = state.origin
        if origin == .internal,
           let carriedOverOrigin = self.carriedOverOrigin,
           let result = RAnalyticsOrigin(rawValue: carriedOverOrigin.intValue) {
            origin = result
            self.carriedOverOrigin = nil
        }
        extra[CpParameterKeys.Ref.type] = origin.toString

        if let pageTitle = pageTitle {
            extra[CpParameterKeys.Page.title] = pageTitle
        }

        if let pageURL = pageURL {
            extra[CpParameterKeys.Page.url] = pageURL.absoluteString
        }

        return true
    }

    func updatePayloadForReferralApp(payload: NSMutableDictionary,
                                     extra: NSMutableDictionary,
                                     referralApp: ReferralAppModel) {
        payload[PayloadParameterKeys.ref] = referralApp.bundleIdentifier

        extra[CpParameterKeys.Ref.type] = RAnalyticsOrigin.external.toString
        if let link = referralApp.link,
           !link.isEmpty {
            extra[CpParameterKeys.Ref.link] = link
        }
        if let comp = referralApp.component,
           !comp.isEmpty {
            extra[CpParameterKeys.Ref.component] = comp
        }

        referralApp.customParameters?.forEach { extra[$0.key] = $0.value }
    }
}

// MARK: - eType

private extension RAnalyticsEvent {
    var eType: String? {
        var etype = parameters[PayloadParameterKeys.etype] as? String

        if etype.isEmpty && name != RAnalyticsRATTracker.Constants.ratGenericEventName {
            etype = name[RAnalyticsRATTracker.Constants.ratEventPrefix.count..<name.count]
        }

        if etype.isEmpty {
            return nil
        }

        return etype
    }
}

// MARK: - Public API

extension RAnalyticsRATTracker {
    /// Method for configuring the batching delay.
    ///
    /// - Parameters:
    ///     - batchingDelay: Delivery delay in seconds. Value should be >= 0 and <= 60.
    @objc(setBatchingDelay:) public func set(batchingDelay: TimeInterval) {
        sender?.setBatchingDelayBlock(batchingDelay)
    }

    /// Method for configuring the dynamic batching delay.
    ///
    /// - Parameters:
    ///     - batchingDelayBlock: The block returns delivery delay in seconds. Value should be >= 0 and <= 60.
    @objc(setBatchingDelayWithBlock:) public func set(batchingDelayBlock: @escaping BatchingDelayBlock) {
        sender?.setBatchingDelayBlock(batchingDelayBlock())
    }

    /// - Returns: the batching delay.
    @objc public func batchingDelay() -> TimeInterval {
        sender?.batchingDelayBlock()?() ?? 0.0
    }

    /// Create a RAT specific event.
    ///
    /// - Parameters:
    ///     - eventType: the RAT event type.
    ///     - parameters: the Optional RAT parameters.
    ///
    /// - Returns: the RAT event.
    @objc(eventWithEventType:parameters:) public func event(withEventType eventType: String, parameters: [String: Any]? = nil) -> RAnalyticsEvent {
        RAnalyticsEvent(name: "\(Constants.ratEventPrefix)\(eventType)", parameters: parameters)
    }

    /// Add another RAT account to duplicate tracked events to.
    ///
    /// - Parameters:
    ///     - accountId: RAT account ID.
    ///     - applicationId: RAT application ID.
    @objc(addDuplicateAccountWithId:applicationId:) public func addDuplicateAccount(accountId: Int64, applicationId: Int64) {
        duplicateAccounts.insert(RATAccount(accountId: accountId, applicationId: applicationId, disabledEvents: nil))
    }
}
