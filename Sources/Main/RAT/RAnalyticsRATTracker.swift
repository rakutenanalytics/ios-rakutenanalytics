import Foundation
import UIKit

// swiftlint:disable type_name
public typealias RAnalyticsRATShouldDuplicateEventCompletion = (_ eventName: String, _ duplicateAccId: Int64) -> Bool
// swiftlint:enable type_name

/// Concrete implementation of @ref RAnalyticsTracker that sends events to RAT.
///
/// - Attention: Application developers **MUST** configure the instance by setting
/// the `RATAccountIdentifier` and `RATAppIdentifier` keys in their app's Info.plist.
///
/// - Warning: The app **CRASHES** in DEBUG mode when `RATAccountIdentifier`key is not set in their app's Info.plist.
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

    private let coreInfosCollector: CoreInfosCollectable

    /// Bundle
    private let bundle: EnvironmentBundle

    /// RPCookie fetcher is used to retrieve the cookie details on initialize
    /// - Note: marked as `@objc` for `RAnalyticsRATTrackerInitSpec`.
    @objc private let rpCookieFetcher: RAnalyticsRpCookieFetchable?

    /// Sender
    /// - Note: marked as `@objc` for this deprecated method:
    /// `@objc public static func endpointAddress() -> URL?`
    @objc private let sender: AnalyticsSendable?

    /// The RAT Automatic Fields Setter
    private let automaticFieldsBuilder: AutomaticFieldsBuildable

    /// The RAT Account Identifier
    ///
    /// - Note: This identifier is configured in the app's `Info.plist` for the key `RATAccountIdentifier`.
    ///
    /// - Warning: If this identifier is not configured in the app's `Info.plist`:
    ///
    ///     - The RAnalytics framework crashes in Debug mode.
    ///     - The RAT tracking is disabled in Release mode.
    ///
    /// - Warning: The type of this identifier must be `Number` in the app's `Info.plist`.
    public let accountIdentifier: Int64

    /// The RAT Application Identifier
    ///
    /// - Note: This identifier is configured in the app's `Info.plist` for the key `RATAppIdentifier`.
    ///
    /// - Warning: If this identifier is not configured in the app's `Info.plist`:
    ///
    ///     - The RAT tracking is disabled in Release mode.
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
    /// <string>_rem_applink</string>
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
        if Bundle.main.isManualInitializationEnabled {
            guard AnalyticsManager.isConfigured else {
                RLogger.error(message: "Manual initialization is enabled. AnalyticsManager must be configured before accessing shared instance of RAnalyticsRATTracker. Call AnalyticsManager.configure() first.")
                return singleton
            }
            return singleton
        } else {
            return singleton
        }
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

        // Sender
        self.sender = RAnalyticsSender(databaseConfiguration: dependenciesContainer.databaseConfiguration,
                                       bundle: bundleContainer,
                                       session: dependenciesContainer.session,
                                       userStorageHandler: dependenciesContainer.userStorageHandler)
        self.sender?.setBatchingDelayBlock(Constants.ratBatchingDelay)

        // Attempt to read the IDs from the app's plist
        // If not found, use 477/1 as default values for account/application ID.
        self.accountIdentifier = bundleContainer.accountIdentifier
        self.applicationIdentifier = bundleContainer.applicationIdentifier

        // Bundle
        self.bundle = bundleContainer
        self.duplicateAccounts = Set(bundle.duplicateAccounts ?? [])

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

        self.coreInfosCollector = dependenciesContainer.coreInfosCollector

        self.automaticFieldsBuilder = dependenciesContainer.automaticFieldsBuilder

        super.init()

        logTrackingError(ErrorDescription.eventsNotProcessedByRATTracker)

        // 1) Debug
        // DEBUG should not be mandatory as `assertionFailure` crashes only in DEBUG mode.
        // But application developers could configure their apps build with DEBUG optimization by mistake, therefore their apps could crash in Production.
        // This condition is made only to avoid crashes in Production because of unexpected build configuration.
        //
        // 2) Call
        // This check is called here in order to avoid this error before the `super.init()` call:
        // `super.init isn't called on all paths before returning from initializer`
        guard bundleContainer.accountIdentifier != 0 else {
            #if DEBUG
            // Crash only when the target is not the Tests Target
            if NSClassFromString("XCTest") == nil {
                assertionFailure(ErrorReason.ratIdentifiersAreNotSet)
            } else {
                RLogger.error(message: ErrorReason.ratIdentifiersAreNotSet)
            }
            #else
            RLogger.error(message: ErrorReason.ratIdentifiersAreNotSet)
            #endif
            return
        }
    }
}

// MARK: - Process an event

extension RAnalyticsRATTracker {
    /// Process an event and send it to the RAT Backend.
    ///
    /// - Parameters:
    ///    - event: the event to process
    ///    - state: the state associated to the event
    ///
    /// - Returns:
    ///    - `false` when `RATAccountIdentifier` or `RATApplicationIdentifier` is not set in the app's Info.plist
    ///    - `false` when the payload build fails
    ///    - `false` when the sender is nil (`RATEndpoint` is not set in the app's Info.plist)
    ///    - `true` otherwise
    @discardableResult
    @objc(processEvent:state:) public func process(event: RAnalyticsEvent, state: RAnalyticsState) -> Bool {
        guard accountIdentifier != 0 && applicationIdentifier != 0 else {
            RLogger.error(message: ErrorReason.ratIdentifiersAreNotSet)

            ErrorRaiser.raise(AnalyticsError.detailedError(domain: ErrorDomain.ratTrackerErrorDomain,
                                                           code: ErrorCode.eventsNotProcessedByRATracker.rawValue,
                                                           description: ErrorDescription.eventsNotProcessedByRATTracker,
                                                           reason: ErrorReason.ratIdentifiersAreNotSet))
            return false
        }

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

        automaticFieldsBuilder.addCommonParameters(payload, state: state)
        automaticFieldsBuilder.addLocation(payload,
                                           state: state,
                                           addActionParameters: false)

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
            if let sdkDependencies = coreInfosCollector.sdkDependencies {
                payload[PayloadParameterKeys.cp] = sdkDependencies
            }
            extra.addEntries(from: event.installParameters(with: coreInfosCollector.appInfo))

        // MARK: _rem_launch
        case RAnalyticsEvent.Name.sessionStart:
            extra.addEntries(from: state.sessionStartParameters)

        // MARK: _rem_end_session
        case RAnalyticsEvent.Name.sessionEnd: () // Do nothing

        // MARK: _rem_update
        case RAnalyticsEvent.Name.applicationUpdate:
            if let sdkDependencies = coreInfosCollector.sdkDependencies {
                payload[PayloadParameterKeys.cp] = sdkDependencies
            }
            extra.addEntries(from: state.applicationUpdateParameters(with: coreInfosCollector.appInfo))

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

            default:
                return false
            }

        // MARK: _rem_applink
        case RAnalyticsEvent.Name.applink:
            // Override etype
            payload[PayloadParameterKeys.etype] = RAnalyticsEvent.Name.pageVisitForRAT
            if case .referralApp(let referralAppModel) = state.referralTracking {
                updatePayloadForReferralApp(payload: payload, extra: extra, referralApp: referralAppModel)
            } else {
                return false
            }

        // MARK: _rem_push_notify_external, _rem_push_received_external
        // MARK: _rem_push_auto_register_external, _rem_push_auto_unregister_external
        case RAnalyticsEvent.Name.pushNotificationExternal,
            RAnalyticsEvent.Name.pushNotificationReceivedExternal,
            RAnalyticsEvent.Name.pushAutoRegistrationExternal,
            RAnalyticsEvent.Name.pushAutoUnregistrationExternal:
            if let etype = payload[PayloadParameterKeys.etype] as? String {
                payload[PayloadParameterKeys.etype] = etype.remove(suffix: "_external")
            }
            extra.addEntries(from: event.parameters)

        // MARK: _rem_push_cv
        case RAnalyticsEvent.Name.pushNotificationConversion:
            extra.addEntries(from: event.parameters)

        // MARK: _rem_discover_＊
        case let value where value.hasPrefix("_rem_discover_"):
            extra.addEntries(from: event.discoverParameters)

        // MARK: _rem_sso_credential_found
        case RAnalyticsEvent.Name.ssoCredentialFound:
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
        
        if let pgidValue = event.parameters["pgid"] as? String {
            if validatePgidFormat(pgidValue, deviceIdentifier: state.deviceIdentifier) {
                payload["pgid"] = pgidValue
            } else {
                payload.removeObject(forKey: "pgid")
            }
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
        let pageURL = currentPage.view?.getWebViewURL()?.absoluteURL

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
            if state.origin != .inner {
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
        if origin == .inner,
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
    ///
    /// For example, to create and track a RAT event `click` with `acc` and `aid`:
    /// Note: `acc` and `aid` must be integers.
    ///
    /// RAnalyticsRATTracker.shared().event(eventType: "click", parameters:["acc": 123, "aid": 456]).track()
    @objc(eventWithEventType:parameters:) public func event(withEventType eventType: String, parameters: [String: Any]? = nil) -> RAnalyticsEvent {
        RAnalyticsEvent(name: "\(Constants.ratEventPrefix)\(eventType)", parameters: parameters)
    }

    /// Add another RAT account to duplicate tracked events to.
    ///
    /// - Parameters:
    ///     - accountId: RAT account ID.
    ///     - applicationId: RAT application ID.
    ///
    /// - Returns: Whether or not the duplicate account was added.
    ///
    /// Note: Negative and zero values are not accepted. Both `accountId` and `applicationId` must be > 0.
    @discardableResult
    @objc(addDuplicateAccountWithId:applicationId:) public func addDuplicateAccount(accountId: Int64, applicationId: Int64) -> Bool {
        guard (accountId > 0) && (applicationId > 0) else {
            return false
        }
        let (wasAdded, _) = duplicateAccounts.insert(RATAccount(accountId: accountId, applicationId: applicationId, disabledEvents: nil))
        return wasAdded
    }
    
    /// Validates the format of a pgid parameter.
    ///
    /// - Parameters:
    ///   - pgid: The pgid value to validate
    ///   - deviceIdentifier: The current device identifier (ckp) for comparison
    /// - Returns: `true` if the pgid format is valid, `false` otherwise
    private func validatePgidFormat(_ pgid: String, deviceIdentifier: String) -> Bool {
        let components = pgid.components(separatedBy: "_")
        
        guard components.count == 2, components[0] == deviceIdentifier, TimeInterval(components[1]) != nil else {
            return false
        }
        
        return true
    }
}
