import Foundation
import RLogger
import CoreTelephony
import CoreLocation
import RDeviceIdentifier

// swiftlint:disable type_name
public typealias RAnalyticsRATShouldDuplicateEventCompletion = (_ eventName: String, _ duplicateAccId: Int) -> Bool

/// Concrete implementation of @ref RAnalyticsTracker that sends events to RAT.
///
/// - Attention: Application developers **MUST** configure the instance by setting
/// the `RATAccountIdentifier` and `RATAppIdentifier` keys in their app's Info.plist.
@objc(RAnalyticsRATTracker) public final class RAnalyticsRATTracker: NSObject, Tracker {
    enum Constants {
        static let RATEventPrefix      = "rat."
        static let RATETypeParameter   = "etype"
        static let RATCPParameter      = "cp"
        static let RATGenericEventName = "rat.generic"
        static let RATPGNParameter     = "pgn"
        static let RATREFParameter     = "ref"
        static let RATReachabilityHost = "8.8.8.8" // Google DNS Server
        static let RATBatchingDelay: TimeInterval = 1.0 // Batching delay is 1 second by default
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
    let accountIdentifier: Int64

    /// The RAT Application Identifier
    let applicationIdentifier: Int64

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
    /// <string>_rem_push_notify</string>
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
        let bundle = dependenciesContainer.bundle
        let httpCookieStore = dependenciesContainer.httpCookieStore
        let notificationCenter = dependenciesContainer.notificationHandler
        let telephonyNetworkInfoHandler = dependenciesContainer.telephonyNetworkInfoHandler
        let device = dependenciesContainer.deviceCapability
        let screen = dependenciesContainer.screenHandler
        let session = dependenciesContainer.session

        // Sender
        if let databaseConfiguration = dependenciesContainer.databaseConfiguration,
           let endpointURL = bundle.endpointAddress {
            self.sender = RAnalyticsSender(endpoint: endpointURL,
                                           database: databaseConfiguration.database,
                                           databaseTable: databaseConfiguration.tableName,
                                           bundle: bundle,
                                           session: session)
            self.sender?.setBatchingDelayBlock(Constants.RATBatchingDelay)

        } else {
            RLogger.error(ErrorMessage.senderCreationFailed)
            self.sender = nil
        }

        self.startTime = NSDate().toString

        // Attempt to read the IDs from the app's plist
        // If not found, use 477/1 as default values for account/application ID.
        self.accountIdentifier = bundle.accountIdentifier
        self.applicationIdentifier = bundle.applicationIdentifier

        // Bundle
        self.bundle = bundle
        self.duplicateAccounts = Set(bundle.duplicateAccounts ?? [])

        // Status Bar Orientation Handler
        let analyticsStatusBarOrientationGetter = dependenciesContainer.analyticsStatusBarOrientationGetter
        statusBarOrientationHandler = RStatusBarOrientationHandler(application: analyticsStatusBarOrientationGetter)

        // Reachability Notifier
        reachabilityNotifier = ReachabilityNotifier(host: Constants.RATReachabilityHost,
                                                    callback: RAnalyticsRATTracker.reachabilityCallback)

        // Rp Cookie Fetcher
        if let httpCookieStore = httpCookieStore as? HTTPCookieStorage,
           let fetcher = RAnalyticsRpCookieFetcher(cookieStorage: httpCookieStore) {
            self.rpCookieFetcher = fetcher
            self.rpCookieFetcher?.getRpCookieCompletionHandler { _, error in
                if let error = error {
                    let errorReason = String(describing: error.localizedFailureReason)
                    let errorMessage = "RAnalyticsRATTracker - RAnalyticsRpCookieFetcher error: \(error.localizedDescription) \(errorReason)"
                    RLogger.error(errorMessage)
                }
            }
        } else {
            RLogger.error(ErrorMessage.rpCookieFetcherCreationFailed)
            self.rpCookieFetcher = nil
        }

        // Telephony Handler
        self.telephonyHandler = TelephonyHandler(telephonyNetworkInfo: telephonyNetworkInfoHandler,
                                                 notificationCenter: notificationCenter)

        // Device Handler
        self.deviceHandler = DeviceHandler(device: device, screen: screen)

        // User Agent
        self.userAgentHandler = UserAgentHandler(bundle: bundle)

        super.init()

        logTrackingError()

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
        if let acc = (payload["acc"] as? NSNumber)?.positiveIntegerNumber {
            payload["acc"] = acc

        } else {
            payload["acc"] = NSNumber(value: self.accountIdentifier)
        }

        // MARK: aid
        if let aid = (payload["aid"] as? NSNumber)?.positiveIntegerNumber {
            payload["aid"] = aid

        } else {
            payload["aid"] = NSNumber(value: self.applicationIdentifier)
        }

        if deviceHandler.batteryState != .unknown {
            // MARK: powerstatus
            payload["powerstatus"] = NSNumber(value: deviceHandler.batteryState != .unplugged ? 1 : 0)

            // MARK: mbat
            payload["mbat"] = String(format: "%0.f", deviceHandler.batteryLevel * 100)
        }

        // MARK: dln
        if let languageCode = bundle.languageCode {
            payload["dln"] = languageCode
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
            locationDic["accu"] = NSNumber(value: max(0.0, location.horizontalAccuracy))

            // MARK: loc.altitude
            locationDic["altitude"] = NSNumber(value: location.altitude)

            // MARK: loc.tms
            locationDic["tms"] = NSNumber(value: max(0, round(location.timestamp.timeIntervalSince1970 * 1000.0)))

            // MARK: loc.lat
            locationDic["lat"] = NSNumber(value: min(90.0, max(-90.0, coordinate.latitude)))

            // MARK: loc.long
            locationDic["long"] = NSNumber(value: min(180.0, max(-180.0, coordinate.longitude)))

            // MARK: loc.speed
            locationDic["speed"] = NSNumber(value: max(0.0, location.speed))

            payload["loc"] = locationDic
        }

        // MARK: model
        payload["model"] = RDeviceIdentifier.modelIdentifier()

        // Telephony Handler
        telephonyHandler.reachabilityStatus = reachabilityStatus

        // MARK: mcn
        payload["mcn"] = telephonyHandler.mcn

        // MARK: mcnd
        payload["mcnd"] = telephonyHandler.mcnd

        // MARK: mnetw
        payload["mnetw"] = telephonyHandler.mnetw ?? ""

        // MARK: mnetwd
        payload["mnetwd"] = telephonyHandler.mnetwd ?? ""

        // MARK: mori
        payload["mori"] = NSNumber(value: statusBarOrientationHandler.mori.rawValue)

        // MARK: online
        if let reachabilityStatus = reachabilityStatus {
            let isOnline = reachabilityStatus.uintValue != RATReachabilityStatus.offline.rawValue
            payload["online"] = NSNumber(value: isOnline)
        }

        // MARK: ckp
        payload["ckp"] = state.deviceIdentifier

        // MARK: ua
        payload["ua"] = userAgentHandler.value(for: state)

        // MARK: res
        payload["res"] = deviceHandler.screenResolution

        // MARK: ltm
        payload["ltm"] = startTime

        // MARK: cks
        payload["cks"] = state.sessionIdentifier

        // MARK: tzo
        payload["tzo"] = NSNumber(value: Double(NSTimeZone.local.secondsFromGMT()) / 3600.0)

        // MARK: cka
        if !state.advertisingIdentifier.isEmpty {
            payload["cka"] = state.advertisingIdentifier
        }

        // MARK: userid
        if !state.userIdentifier.isEmpty && (payload["userid"] as? String).isEmpty {
            payload["userid"] = state.userIdentifier
        }

        // MARK: easyid
        if !state.easyIdentifier.isEmpty && (payload["easyid"] as? String).isEmpty {
            payload["easyid"] = state.easyIdentifier
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
            duplicateEvent(named: event.name, with: payload, sender: sender)
            return true

        } else {
            RLogger.error("The event \(event.name) could not be processed by the RAT Tracker.")
            logTrackingError()
            return false
        }
    }

    private func logTrackingError() {
        var message = ""

        if dependenciesContainer.databaseConfiguration == nil {
            message += "\(ErrorMessage.databaseConnectionIsNil) "
        }

        if bundle.endpointAddress == nil {
            message += "\(ErrorMessage.endpointMissing) "
        }

        if !message.isEmpty {
            RLogger.error("\(message)\(ErrorMessage.eventsNotProcessedByRATTracker)")
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

        payload[Constants.RATETypeParameter] = event.name

        if !updatePayload(payload, extra: extra, event: event, state: state) {
            return nil
        }

        if let dict = extra as? [String: Any],
           !dict.isEmpty {
            // If the event already had a 'cp' field, those values take precedence
            if let params = payload[Constants.RATCPParameter] as? [AnyHashable: Any] {
                extra.addEntries(from: params)
            }

            payload[Constants.RATCPParameter] = extra
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
        case RAnalyticsEvent.Name.pageVisit where AnalyticsManager.shared().shouldTrackPageView == true:
            // Override etype
            payload[Constants.RATETypeParameter] = "pv"

            if !updatePageVisitPayload(for: event, state: state, payload: payload, extra: extra) {
                return false
            }

        // MARK: _rem_push_notify
        case RAnalyticsEvent.Name.pushNotification:
            guard let pushParameters = event.pushParameters else {
                return false
            }
            extra.addEntries(from: pushParameters)

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
            guard let eventName = event.parameters[RAnalyticsCustomEventNameParameter] as? String,
                  !eventName.isEmpty else {
                return false
            }

            payload[Constants.RATETypeParameter] = eventName

            if let topLevelObject = event.parameters[RAnalyticsCustomEventTopLevelObjectParameter] as? [AnyHashable: Any],
               !topLevelObject.isEmpty {
                payload.addEntries(from: topLevelObject)
            }

            if let parameters = event.parameters[RAnalyticsCustomEventDataParameter] as? [AnyHashable: Any],
               !parameters.isEmpty {
                extra.addEntries(from: parameters)
            }

        // MARK: rat.＊
        case let value where value.hasPrefix(Constants.RATEventPrefix):
            if !event.parameters.isEmpty {
                payload.addEntries(from: event.parameters)
            }

            guard let etype = event.eType else {
                return false
            }
            payload[Constants.RATETypeParameter] = etype

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
    func updatePageVisitPayload(for pageVisitEvent: RAnalyticsEvent,
                                state: RAnalyticsState,
                                payload: NSMutableDictionary,
                                extra: NSMutableDictionary) -> Bool {
        guard let currentPage = state.currentPage else {
            return false
        }

        var pageIdentifier = pageVisitEvent.parameters["page_id"] as? String
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

        // If no page id was found, simply ignore this view controller.
        guard !pageIdentifier.isEmpty else {
            // If this originated from a push notification or an inbound URL, keep that for next call.
            if state.origin != .internal {
                self.carriedOverOrigin = NSNumber(value: state.origin.rawValue)
            }
            return false
        }

        payload[Constants.RATPGNParameter] = pageIdentifier

        let lastVisitedPageIdentifier = self.lastVisitedPageIdentifier
        if !lastVisitedPageIdentifier.isEmpty {
            payload[Constants.RATREFParameter] = lastVisitedPageIdentifier
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
        extra["ref_type"] = origin.toString

        if let pageTitle = pageTitle {
            extra["title"] = pageTitle
        }

        if let pageURL = pageURL {
            extra["url"] = pageURL.absoluteString
        }

        return true
    }
}

// MARK: - eType

private extension RAnalyticsEvent {
    var eType: String? {
        var etype = parameters[RAnalyticsRATTracker.Constants.RATETypeParameter] as? String

        if etype.isEmpty && name != RAnalyticsRATTracker.Constants.RATGenericEventName {
            etype = name[RAnalyticsRATTracker.Constants.RATEventPrefix.count..<name.count]
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
        RAnalyticsEvent(name: "\(Constants.RATEventPrefix)\(eventType)", parameters: parameters)
    }

    /// Add another RAT account to duplicate tracked events to.
    ///
    /// - Parameters:
    ///     - accountId: RAT account ID.
    ///     - applicationId: RAT application ID.
    @objc(addDuplicateAccountWithId:applicationId:) public func addDuplicateAccount(accountId: Int, applicationId: Int) {
        duplicateAccounts.insert(RATAccount(accountId: accountId, applicationId: applicationId, disabledEvents: nil))
    }
}

// MARK: - Deprecated Public API

extension RAnalyticsRATTracker {
    /// - Returns: the RAT Endpoint URL.
    @available(*, deprecated, message: "RAnalyticsRATTracker#endpointURL should be used instead.")
    @objc public static func endpointAddress() -> URL? {
        let selector = #selector(getter: self.sender)
        guard let sender = RAnalyticsRATTracker.shared().perform(selector)?.takeUnretainedValue() as? RAnalyticsSender else {
            return nil
        }
        return sender.endpointURL
    }
}
