import Foundation
import CoreLocation
import UIKit
#if os(iOS)
import AdSupport
import WebKit
import UserNotifications
#endif

// swiftlint:disable type_name
public typealias RAnalyticsShouldTrackEventCompletionBlock = (String) -> Bool
// swiftlint:enable type_name

public typealias WebTrackingCookieDomainBlock = () -> String?

public typealias RAnalyticsErrorBlock = (NSError) -> Void

/// Handler invoked when the SDK needs the host app to collect or reconfirm privacy consent.
public typealias AnalyticsShowConsentCallback = ([DataCollectionType]) -> Void

enum CoreOrigin {
    case analytics
    case geo(LocationModel)
}

/// Serializes app-to-web cookie store refreshes so overlapping triggers (for example
/// `enableAppToWebTracking` and `setWebTrackingCookieMultipleDomains`) cannot race.
/// Each refresh waits for the previously scheduled one to finish before running, so refreshes execute in call order.
private actor CookieStoreRefreshCoordinator {
    private var previousRefresh: Task<[HTTPCookie], Never>?

    func refresh(_ operation: @escaping @Sendable () async -> [HTTPCookie]) async -> [HTTPCookie] {
        let prior = previousRefresh
        let task = Task {
            _ = await prior?.value
            return await operation()
        }
        previousRefresh = task
        return await task.value
    }
}

@objc public enum RAnalyticsLoggingLevel: Int {
    case verbose, debug, info, warning, error, none
}

// MARK: - AnalyticsManageable

@objc public protocol AnalyticsManageable: AnyObject {
    var defaultWebViewUserAgent: String? { get }
    func process(_ event: RAnalyticsEvent) -> Bool
}

// MARK: - ReferralAppTrackable

protocol ReferralAppTrackable: AnyObject {
    func tryToTrackReferralApp(with url: URL?, sourceApplication: String?)
    func tryToTrackReferralApp(with webpageURL: URL?)
    func handleIncomingURLContexts(_ contexts: Set<UIOpenURLContext>)
    func handleIncomingConnectionOptions(_ options: UIScene.ConnectionOptions)
    func handleIncomingUserActivity(_ userActivity: NSUserActivity)
    func handleIncomingColdLaunchFromInjectedValues()
}

// MARK: - AnalyticsManager

/// Main class of the module.
@objc(RAnalyticsManager) public final class AnalyticsManager: NSObject {
    /// - Note:
    ///     - set to true when configure() is called for manual initialization or false otherwise.
    ///     - always set to true for automatic initialization.
    ///     - Stored in `AnalyticsInitState` (same value send gating reads).
    static var isConfigured: Bool {
        get { AnalyticsInitState.isConfigured }
        set { AnalyticsInitState.applyIsConfigured(newValue) }
    }

    private static let singleton: AnalyticsManager = {
        AnalyticsManager(dependenciesContainer: SimpleDependenciesContainer())
    }()

    /// Retrieve the shared instance.
    ///
    /// - Returns: The shared instance.
    @objc(sharedInstance) public static func shared() -> AnalyticsManager {
        if Bundle.main.isManualInitializationEnabled {
            if !isConfigured {
                RLogger.error(message: "Manual initialization is enabled. AnalyticsManager must be configured "
                                + "before accessing shared instance. Call AnalyticsManager.configure() first.")
            }
        } else {
            isConfigured = true
        }
        return singleton
    }

    /// Backing for `shouldTrackLastKnownLocation` so internal reads do not trigger deprecation warnings.
    private var allowsLastKnownLocationWhenPrivacyControlOff: Bool = true

    /// Control whether the SDK should track the device's location or not.
    /// This property is set to `YES` by default, which means @ref RAnalyticsManager will use the device's location.
    ///
    /// When `RATEnablePrivacyControl` is `true`, last-known location collection for analytics follows **only** the
    /// `.location` runtime consent from ``set(dataCollection:enabled:)``. In that mode this property does not gate collection.
    ///
    /// - Warning: If the application has not already requested access to the location information, trying to set this property to `YES` has no effect. Please refer
    /// to the [Location and Maps Programming Guide](https://developer.apple.com/library/ios/documentation/UserExperience/Conceptual/LocationAwarenessPG/)
    /// for more information.
    @available(*, deprecated, message: "Use set(dataCollection: .location, enabled:) when RATEnablePrivacyControl is true. Only applies when privacy control is off.")
    @objc public var shouldTrackLastKnownLocation: Bool {
        get { allowsLastKnownLocationWhenPrivacyControlOff }
        set {
            let oldValue = allowsLastKnownLocationWhenPrivacyControlOff
            allowsLastKnownLocationWhenPrivacyControlOff = newValue
            if oldValue != newValue {
                startStopMonitoringLocationIfNeeded()
            }
        }
    }

    /// Backing for `shouldTrackAdvertisingIdentifier` so internal reads do not trigger deprecation warnings.
    private var allowsAdvertisingIdentifierWhenDeviceInfoAllowed: Bool = true

    /// Control whether the SDK may read the [advertising identifier (IDFA)](https://developer.apple.com/reference/adsupport/asidentifiermanager) when device information collection is allowed.
    ///
    /// When `RATEnablePrivacyControl` is `true`, IDFA is included in payloads only if **both** this flag
    /// and device information consent are enabled.
    ///
    /// - Note: Deprecated in the Mobile Privacy Control specification (same role as Android’s deprecated
    ///   `TrackAdvertisingId` manifest flag). Prefer ``set(dataCollection:enabled:)`` with `.deviceInformation`.
    @available(*, deprecated, message: "Use set(dataCollection: .deviceInformation, enabled:) when RATEnablePrivacyControl is true. IDFA requires this flag and device-information consent.")
    @objc public var shouldTrackAdvertisingIdentifier: Bool {
        get { allowsAdvertisingIdentifierWhenDeviceInfoAllowed }
        set { allowsAdvertisingIdentifierWhenDeviceInfoAllowed = newValue }
    }

    /// Control whether the SDK should inject a tracking cookie into the WKWebView's cookie store.
    /// The cookie enables tracking between mobile app and webviews.
    ///
    /// This feature only works on iOS 11.0 and above.
    ///
    /// This property is set to `NO` by default
    @objc public var enableAppToWebTracking: Bool = false {
        didSet {
            Task { await refreshCookieStore() }
        }
    }

    /// Enable or disable the tracking of an event at runtime.
    ///
    /// For example, to disable `AnalyticsManager.Event.Name.sessionStart`:
    /// `AnalyticsManager.shared().shouldTrackEventHandler = { eventName in eventName != AnalyticsManager.Event.Name.sessionStart }`
    ///
    /// Note that it is also possible to disable events at build time in the `RAnalyticsConfiguration.plist` file:
    /// 1) First create a `RAnalyticsConfiguration.plist` file and add it to your Xcode project.
    /// 2) Then create a key `RATDisabledEventsList` and add the array of disabled events.
    ///
    /// For example, to disable all automatic tracking add the following to your `RAnalyticsConfiguration.plist` file:
    ///
    /// <key>RATDisabledEventsList</key>
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
    @objc public var shouldTrackEventHandler: RAnalyticsShouldTrackEventCompletionBlock? {
        get {
            eventChecker.shouldTrackEventHandler
        }
        set {
            eventChecker.shouldTrackEventHandler = newValue
        }
    }

    /// Handle internal errors that occur in the RAnalytics SDK
    ///
    /// Optional for apps to set, though recommended.
    ///
    /// Usage example:
    /// ```
    /// AnalyticsManager.shared().errorHandler = { error in
    ///     // Report the error to your crash reporting service
    ///     // (e.g., [Crashlytics](https://firebase.google.com/docs/crashlytics/customize-crash-reports?platform=ios#log-excepts)) as a non-fatal error
    /// }
    /// ```
    public var errorHandler: RAnalyticsErrorBlock? {
        get {
            ErrorRaiser.errorHandler
        }
        set {
            ErrorRaiser.errorHandler = newValue
        }
    }

    /// Registers a handler the SDK invokes at launch when privacy control is enabled and one or more
    /// data collection categories have no stored consent.
    ///
    /// Set this as early as possible (for example in `application(_:didFinishLaunchingWithOptions:)`),
    /// before ``shared()`` or ``configure()``, so the host app can present consent UI before automatic
    /// startup events. The handler receives granular categories in ``DataCollectionType/individualTypes``
    /// order whose persisted consent is still `undetermined`.
    ///
    /// When `RATEnablePrivacyControl` is `false`, the handler is never invoked and consent is not persisted.
    /// The handler is delivered at most once per process launch.
    ///
    /// - Parameter callback: Invoked on the main actor with categories that still need consent.
    @MainActor
    public static func showConsentCallback(callback: @escaping AnalyticsShowConsentCallback) {
        PrivacyControlMigrationCoordinator.shared.registerShowConsentCallback(callback)
    }

    /// Enable or disable the tracking of an event from an iOS Extension.
    @objc public var enableExtensionEventTracking: Bool = false {
        didSet {
            if enableExtensionEventTracking {
                eventObserver.startObservation(delegate: self)

                // Track cached events if there are some
                eventObserver.trackCachedEvents()

            } else {
                eventObserver.stopObservation()
            }
        }
    }

    /// The device identifier used to set `ckp` in the RAT payload.
    public var deviceIdentifier: String {
        deviceIdentifierHandler.ckp()
    }

    private let locationManager: LocationManageable
    private(set) var locationManagerIsUpdating: Bool = false

    /// Session cookie. We use an UUID automatically created at startup and
    /// regenerated when the app comes back from background, as per the specifications.
    private var sessionCookie: String?
    private var sessionStartDate: Date?
    private var cookieDomainBlock: WebTrackingCookieDomainBlock?
    private var cookieDomains: [String]?
    /// `true` when `setWebTrackingCookieDomain(block:)` was called after `setWebTrackingCookieMultipleDomains(array:)`.
    /// Decides which of `cookieDomainBlock` / `cookieDomains` is used when the cookie store is refreshed
    /// (toggle of `enableAppToWebTracking`, consent change); the other one is only a fallback.
    private var isCookieDomainBlockLastConfigured = false
    private let cookieStoreRefreshCoordinator = CookieStoreRefreshCoordinator()

    /// Trackers Set
    /// - Note: The 'Tracker' type has to conform to protocol `Hashable` in order to use `Set` instead of `NSMutableSet`
    private(set) var trackers: NSMutableSet
    private(set) var trackersLockableObject: LockableObject<NSMutableSet>

    /// Dependencies
    private let advertisingIdentifierHandler: RAdvertisingIdentifierHandler
    private let analyticsCookieInjector: RAnalyticsCookieInjector
    private let userIdentifierSelector: UserIdentifierSelector
    private let externalCollector: RAnalyticsExternalCollector
    private let eventChecker: EventChecker
    private let eventObserver: AnalyticsEventObserver
    private let deviceIdentifierHandler: DeviceIdentifierHandler
    private let bundle: EnvironmentBundle
    private let dataCollectionConsent: DataCollectionConsentReadable
    private let userStorageHandler: UserStorageHandleable

    private lazy var dataEraserCoordinator: DataEraserCoordinator = {
        DataEraserCoordinator(erasables: [
            launchCollector,
            externalCollector,
            RAnalyticsRATTracker.shared(),
            GeoManager.shared,
            AnalyticsManagerSessionEraser(delegate: self),
            analyticsCookieInjector
        ])
    }()

    /// The default `WKWebView` user agent
    public private(set) var defaultWebViewUserAgent: String?

    /// Returns the value of `RATSetWebViewAppUserAgentEnabled` in the app's `Info.plist`.
    ///
    /// `RATSetWebViewAppUserAgentEnabled` allows to append the app user agent to the default WKWebView's user agent.
    ///
    /// - returns: `true` if `RATSetWebViewAppUserAgentEnabled` is set to true or not set, `false` otherwise.
    ///
    /// - Note: If `RATSetWebViewAppUserAgentEnabled` is not set the app's Info.plist, `true` is returned.
    public var isWebViewAppUserAgentEnabledAtBuildtime: Bool {
        bundle.isWebViewAppUserAgentEnabledAtBuildtime
    }

    let launchCollector: RAnalyticsLaunchCollector

    var isTrackingGeoLocation: Bool {
        userStorageHandler.bool(forKey: UserDefaultsKeys.locationCollectionKey)
    }

    var shouldContinueGeoBackgroundTimer: Bool {
        userStorageHandler.shouldContinueGeoBackgroundTimer
    }

    var easyIdentifier: String? {
        externalCollector.easyIdentifier
    }

    private var allowsDeviceInformationOnRatPayload: Bool {
        PrivacyControlPayload.allowsDeviceInformationOnRatPayload(bundle: bundle, consentStore: dataCollectionConsent)
    }

    init(dependenciesContainer: SimpleDependenciesContainable) {
        externalCollector = RAnalyticsExternalCollector(dependenciesContainer: dependenciesContainer)
        launchCollector = RAnalyticsLaunchCollector(dependenciesContainer: dependenciesContainer)
        self.locationManager = dependenciesContainer.locationManager

        bundle = dependenciesContainer.bundle
        dataCollectionConsent = dependenciesContainer.dataCollectionConsent
        eventChecker = EventChecker(disabledEventsAtBuildTime: bundle.disabledEventsAtBuildTime)

        userStorageHandler = dependenciesContainer.userStorageHandler

        eventObserver = AnalyticsEventObserver(pushEventHandler: dependenciesContainer.pushEventHandler)

        allowsLastKnownLocationWhenPrivacyControlOff = true
        allowsAdvertisingIdentifierWhenDeviceInfoAllowed = true
        #if os(tvOS)
        allowsLastKnownLocationWhenPrivacyControlOff = false
        allowsAdvertisingIdentifierWhenDeviceInfoAllowed = false
        #endif

        // Inject the Dependencies Container
        advertisingIdentifierHandler = RAdvertisingIdentifierHandler(dependenciesContainer: dependenciesContainer)
        analyticsCookieInjector = RAnalyticsCookieInjector(dependenciesContainer: dependenciesContainer)

        userIdentifierSelector = UserIdentifierSelector(userIdentifiable: externalCollector)

        trackers = NSMutableSet()
        trackersLockableObject = LockableObject(trackers)

        deviceIdentifierHandler = DeviceIdentifierHandler(device: dependenciesContainer.deviceCapability,
                                                          hasher: SecureHasher())

        super.init()

        externalCollector.trackerDelegate = self
        launchCollector.trackerDelegate = self

        configure()

        #if SWIFT_PACKAGE
        RLogger.debug(message: "RAnalytics Swift Package is running.")
        #else
        RLogger.debug(message: "RAnalytics Pod is running.")
        #endif

        Task { @MainActor in
            PrivacyConsentReactor.shared.register(analytics: self)
        }
        if let consentStore = dependenciesContainer.migrationConsentStore {
            Task { @MainActor in
                PrivacyControlMigrationCoordinator.shared.runStartupMigrationIfNeeded(consentStore: consentStore)
            }
        }
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
        stopMonitoringLocation()
    }

    /// Set carrier names for analytics tracking
    /// - Parameters:
    ///   - primary: Primary carrier name (mcn)
    ///   - secondary: Secondary carrier name (mcnd), optional for single SIM devices
    @objc public func setCarrierNames(primary: String?, secondary: String? = nil) {
        RAnalyticsRATTracker.shared().updateCarrierNames(mcn: primary, mcnd: secondary)
    }

    /// Clear all carrier information
    @objc public func clearCarrierNames() {
        setCarrierNames(primary: nil, secondary: nil)
    }

    /// Get current carrier names
    /// - Returns: Tuple containing primary and secondary carrier names
    public func getCarrierNames() -> (primary: String?, secondary: String?) {
        return RAnalyticsRATTracker.shared().getCarrierNames()
    }

    /// Apply a runtime data collection / privacy setting when `RATEnablePrivacyControl` is enabled.
    ///
    /// When `RATEnablePrivacyControl` is `false` (default), this is ignored and all categories are collected.
    /// When `true`, granular consent applies; each category must be explicitly granted to be collected,
    /// and unset stored consent is treated as not granted. This gates **what** is collected and sent per
    /// category, not whether the SDK sends events altogether (core/minimal payloads may still flow).
    ///
    /// - Parameters:
    ///   - type: Which category (or all categories) to update.
    ///   - enabled: Whether collection for that category is allowed.
    public func set(dataCollection type: DataCollectionType, enabled: Bool) async {
        await dataCollectionConsent.setEnabled(enabled, for: type)
    }

    /// Returns whether data collection is currently enabled for `type`.
    ///
    /// When `RATEnablePrivacyControl` is `false` (default), this always returns `true` for every type (legacy full collection).
    /// When `true`, this reflects persisted runtime consent; unset storage is treated as not granted.
    ///
    /// For ``DataCollectionType/all``, this returns `true` only when every granular category is enabled.
    /// Prefer checking the four concrete types if you need per-category state.
    ///
    /// - Parameter type: The data collection category to query.
    /// - Returns: Whether that category is allowed for collection and payloads, subject to OS permissions and other legacy rules.
    public func isDataCollectionEnabled(dataCollection type: DataCollectionType) -> Bool {
        dataCollectionConsent.isEnabled(type)
    }

    /// Erases locally stored analytics data (GDPR / opt-out).
    ///
    /// Clears SDK-owned UserDefaults, Keychain items, SQLite queues, cookies, and in-memory state.
    /// Does not send analytics events or remove registered trackers.
    ///
    /// - Throws: ``ClearDataError/alreadyRunning`` when another `clearData()` call is already in progress.
    public func clearData() async throws {
        try await dataEraserCoordinator.clearData()
    }
}

extension AnalyticsManager: SessionDataDelegating {
    func clearSessionData() {
        sessionCookie = nil
        sessionStartDate = nil
        userStorageHandler.removeObject(forKey: UserDefaultsKeys.userAgentKey)
        clearCarrierNames()
        stopMonitoringLocation()
        startNewSession()
    }
}

// MARK: - Configuration

extension AnalyticsManager {
    /// Set the WKWebView's user agent value at buildtime only if Bundle's `isWebViewAppUserAgentEnabledAtBuildtime` is set to true.
    ///
    /// - Warning: If the `AnalyticsManager` is not launched from the main thread, then the `WKWebView` user agent will be set only in the next loop of the main Thread.
    private func configureWebViewUserAgent() {
        #if os(iOS)
        MainThreadExecutor.run {
            self.applyWebViewUserAgentForCurrentPrivacyState()
        }
        #endif
    }

    /// Applies WebView UA: custom analytics UA only when device-information collection is allowed (or privacy control is off).
    /// Mobile Privacy Control spec: when `DEVICE_INFORMATION` is disabled, use the default system WebView user agent without SDK modification.
    private func applyWebViewUserAgentForCurrentPrivacyState() {
        #if os(iOS)
        guard bundle.isWebViewAppUserAgentEnabledAtBuildtime else {
            defaultWebViewUserAgent = WKWebView().rCurrentUserAgent
            return
        }

        let webView = WKWebView()
        defaultWebViewUserAgent = webView.rCurrentUserAgent

        let allowAnalyticsUserAgentCustomization = !bundle.isPrivacyControlEnabled
            || dataCollectionConsent.isEnabled(.deviceInformation)
        if allowAnalyticsUserAgentCustomization,
           let userAgent = defaultWebViewUserAgent,
           let customUserAgent = webView.webViewUserAgent(defaultWebViewUserAgent: userAgent,
                                                          for: bundle) {
            userStorageHandler.register(defaults: [UserDefaultsKeys.userAgentKey: customUserAgent])
        } else {
            userStorageHandler.removeObject(forKey: UserDefaultsKeys.userAgentKey)
        }
        #endif
    }

    private func configure() {
        configureWebViewUserAgent()

        addAndConfigureIfNeeded(RAnalyticsRATTracker.shared())

        // Set up the location manager
        locationManager.desiredAccuracy = kCLLocationAccuracyKilometer
        locationManager.delegate = self

        // Start a new session, and renew it every time the application goes back to the foreground.
        startNewSession()

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(startNewSession),
                                               name: UIApplication.didBecomeActiveNotification,
                                               object: nil)

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(stopMonitoringLocationUnlessAlways),
                                               name: UIApplication.willResignActiveNotification,
                                               object: nil)
    }

    private func refreshCookieStore() async -> [HTTPCookie] {
        await cookieStoreRefreshCoordinator.refresh { [weak self] in
            guard let self else {
                return []
            }
            return await self.performRefreshCookieStore()
        }
    }

    private func performRefreshCookieStore() async -> [HTTPCookie] {
        await analyticsCookieInjector.clearCookies()
        guard enableAppToWebTracking else { return [] }

        // ra_uid (app-to-web) is built from device identifiers (ckp / advertising id); gated by DEVICE_INFORMATION only.
        // Rp cookie and shared cookie handling on RAT POSTs remain gated by USER_INFORMATION elsewhere.
        guard dataCollectionConsent.isEnabled(.deviceInformation) else { return [] }

        var trackingCookies: [HTTPCookie] = []
        for domain in configuredWebTrackingCookieDomains() {
            if let trackingCookie = await injectAppToWebTrackingCookie(domain: domain) {
                trackingCookies.append(trackingCookie)
            }
        }
        return trackingCookies
    }

    /// The last configured domain setting wins; the other one is the fallback, then the default domain (`nil`).
    private func configuredWebTrackingCookieDomains() -> [String?] {
        let multipleDomains = cookieDomains?.isEmpty == false ? cookieDomains : nil
        let blockDomains = cookieDomainBlock?().map { [$0] }
        let domains = isCookieDomainBlockLastConfigured ? blockDomains ?? multipleDomains : multipleDomains ?? blockDomains
        guard let domains else { return [nil] }
        return domains
    }

    private func injectAppToWebTrackingCookie(domain: String?) async -> HTTPCookie? {
        await analyticsCookieInjector.injectAppToWebTrackingCookie(
            domain: domain,
            deviceIdentifier: deviceIdentifierHandler.ckp()
        )
    }

}

// MARK: - UIApplication Notifications

extension AnalyticsManager {
    @objc private func startNewSession() {
        sessionCookie = Session.cks()
        sessionStartDate = Date()

        // Resume location updates if needed.
        startStopMonitoringLocationIfNeeded()
    }

    @objc private func stopMonitoringLocationUnlessAlways() {
        if CLLocationManager().authorizationStatus != .authorizedAlways {
            stopMonitoringLocation()
        }
    }
}

// MARK: - Location

extension AnalyticsManager {
    /// Last-known location for automatic events: legacy `shouldTrackLastKnownLocation` when privacy control is off;
    /// location consent only when privacy control is on.
    private var isLastKnownLocationCollectionAllowed: Bool {
        if bundle.isPrivacyControlEnabled {
            return dataCollectionConsent.isEnabled(.location)
        }
        return allowsLastKnownLocationWhenPrivacyControlOff
    }

    /// Sets ``RAnalyticsState/lastKnownLocation`` only when the LOCATION category may be used for analytics on this path.
    ///
    /// **Mobile Privacy Control — “clear location” for RAT:** the SDK does not persist a separate lat/long cache for
    /// automatic events. Keeping ``lastKnownLocation`` `nil` here (when consent is off or location is unavailable)
    /// is how we **omit `loc` from payloads**—there is nothing else to “clear” for outbound analytics on the main path.
    /// ``AutomaticFieldsBuilder/addLocation`` also gates on location consent before attaching `loc`.
    private func applyLastKnownLocationForPrivacyPolicy(to state: RAnalyticsState, coreOrigin: CoreOrigin) {
        if case .analytics = coreOrigin {
            if isLastKnownLocationCollectionAllowed,
               let location = locationManager.location {
                state.lastKnownLocation = LocationModel(location: location)
            } else {
                state.lastKnownLocation = nil
            }
        } else if case .geo(let locationModel) = coreOrigin {
            if dataCollectionConsent.isEnabled(.location) {
                state.lastKnownLocation = locationModel
            } else {
                state.lastKnownLocation = nil
            }
        }
    }

    private func startStopMonitoringLocationIfNeeded() {
        let status: CLAuthorizationStatus = type(of: locationManager).authorizationStatus()

        if isLastKnownLocationCollectionAllowed,
           status == .authorizedAlways
            || status == .authorizedWhenInUse && UIApplication.RAnalyticsSharedApplication?.applicationState == .active {
            startMonitoringLocation()

        } else {
            stopMonitoringLocation()
        }
    }

    private func startMonitoringLocation() {
        guard !locationManagerIsUpdating else {
            return
        }
        RLogger.verbose(message: "Start monitoring location")
        locationManager.startUpdatingLocation()
        locationManagerIsUpdating = true
    }

    private func stopMonitoringLocation() {
        guard locationManagerIsUpdating else {
            return
        }
        RLogger.verbose(message: "Stop monitoring location")
        locationManager.stopUpdatingLocation()
        locationManagerIsUpdating = false
    }
}

// MARK: - CLLocationManagerDelegate

extension AnalyticsManager: CLLocationManagerDelegate {
    // Only for iOS version <= 13.x
    public func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        startStopMonitoringLocationIfNeeded()
    }

    // Only for iOS version >= 14.0
    public func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        startStopMonitoringLocationIfNeeded()
    }

    #if os(iOS)
    public func locationManagerDidPauseLocationUpdates(_ manager: CLLocationManager) {
        RLogger.verbose(message: "Location updates paused.")
    }

    public func locationManagerDidResumeLocationUpdates(_ manager: CLLocationManager) {
        RLogger.verbose(message: "Location updates resumed.")
    }

    public func locationManager(_ manager: CLLocationManager, didFinishDeferredUpdatesWithError error: Error?) {
        ErrorRaiser.raise(.detailedError(domain: ErrorDomain.analyticsManagerErrorDomain,
                                         code: ErrorCode.locationHasFailed.rawValue,
                                         description: ErrorDescription.locationHasFailed,
                                         reason: "\(error?.localizedDescription ?? "")"))
    }
    #endif
}

// MARK: - Public API

extension AnalyticsManager: AnalyticsManageable {
    /// Process an event. The manager passes the event to each registered tracker, in turn.
    ///
    /// - Parameters:
    ///     - event:  Event to track.
    ///
    /// - Returns: A boolean value indicating if the event has been processed.
    @discardableResult
    @objc dynamic public func process(_ event: RAnalyticsEvent) -> Bool {
        guard AnalyticsManager.isConfigured else {
            return false
        }

        return process(event, coreOrigin: .analytics)
    }

    @discardableResult
    func process(_ event: RAnalyticsEvent, coreOrigin: CoreOrigin) -> Bool {
        guard eventChecker.shouldProcess(event.name),
              let sessionIdentifier = sessionCookie else {
            return false
        }

        let state = RAnalyticsState(sessionIdentifier: sessionIdentifier,
                                    deviceIdentifier: deviceIdentifierHandler.ckp())

        if allowsAdvertisingIdentifierWhenDeviceInfoAllowed,
           dataCollectionConsent.isEnabled(.deviceInformation),
           let advertisingIdentifier = advertisingIdentifierHandler.idfa {
            state.advertisingIdentifier = advertisingIdentifier
        }

        applyLastKnownLocationForPrivacyPolicy(to: state, coreOrigin: coreOrigin)
        state.sessionStartDate = sessionStartDate ?? nil

        // Update state with data from external collector
        state.userIdentifier = userIdentifierSelector.selectedTrackingIdentifier
        state.easyIdentifier = externalCollector.easyIdentifier
        state.loginMethod = externalCollector.loginMethod
        state.loggedIn = externalCollector.isLoggedIn

        // Update state with data from launch collector
        state.initialLaunchDate = launchCollector.initialLaunchDate
        state.installLaunchDate = launchCollector.installLaunchDate
        state.lastUpdateDate = launchCollector.lastUpdateDate
        state.lastLaunchDate = launchCollector.lastLaunchDate
        state.lastVersion = launchCollector.lastVersion
        state.lastVersionLaunches = launchCollector.lastVersionLaunches
        state.referralTracking = launchCollector.referralTracking
        state.origin = launchCollector.origin

        var processed = false
        trackersLockableObject.get().forEach { tracker in
            RLogger.debug(message: "Using tracker \(tracker)")

            if let tracker = tracker as? Tracker {
                processed = tracker.process(event: event, state: state) || processed
            }
        }
        if !processed {
            RLogger.debug(message: "No tracker processed event \(event.name)")
        }
        return processed
    }

    /// Initializes the SDK and installs auto-tracking hooks.
    ///
    /// This method sets up automatic tracking for user notifications, view controllers, and window scenes.
    /// Host apps must adopt the UIKit scene-based lifecycle with a `UISceneDelegate`.
    public static func configure() {
        #if os(iOS)
        UNUserNotificationCenter.installAutoTrackingHooks()
        #endif
        UIViewController.installAutoTrackingHooks()
        UIWindowScene.installAutoTrackingHooks()
        SceneDelegateHelper.autoTrack()
        GeoLaunchConfigurator.configureIfNeeded()
        isConfigured = true
    }
}

extension AnalyticsManager {
    /// Set logging level
    ///
    /// - Parameters:
    ///     - loggingLevel:  The logging level type.
    @objc(setLoggingLevel:) public func set(loggingLevel: RAnalyticsLoggingLevel) {
        switch loggingLevel {
        case .verbose:
            RLogger.loggingLevel = .verbose
        case .debug:
            RLogger.loggingLevel = .debug
        case .info:
            RLogger.loggingLevel = .info
        case .warning:
            RLogger.loggingLevel = .warning
        case .error:
            RLogger.loggingLevel = .error
        case .none:
            RLogger.loggingLevel = .none
        }
    }

    /// Add a tracker to tracker list.
    ///
    /// - Parameter tracker: Any object that comforms to the RAnalyticsTracker protocol.
    @objc(addTracker:) public func add(_ tracker: Tracker) {
        trackersLockableObject.lock()
        let trackers = trackersLockableObject.get()
        if !trackers.contains(tracker) {
            trackers.add(tracker)
            RLogger.debug(message: "Added tracker \(tracker)")
        }
        trackersLockableObject.unlock()
    }

    /// Adds the tracker and marks it as configured if it conforms to `RATConfigurable`.
    private func addAndConfigureIfNeeded(_ tracker: Tracker) {
        add(tracker)
        (tracker as? RATConfigurable)?.markAsConfigured()
    }

    /// Remove a tracker from tracker list.
    ///
    /// - Parameter tracker: Any object that comforms to the RAnalyticsTracker protocol.
    func remove(_ tracker: Tracker) {
        trackersLockableObject.lock()
        let trackers = trackersLockableObject.get()
        if trackers.contains(tracker) {
            trackers.remove(tracker)
            RLogger.debug(message: "Deleted tracker \(tracker)")
        }
        trackersLockableObject.unlock()
    }

    /// Generates a new unique page identifier for optional `pgid` on RAT events.
    ///
    /// Embeds `deviceIdentifierHandler.ckp()` when device-information may appear on RAT; otherwise `ckp` is
    /// treated as empty, producing `"_<timestamp>"` (same validation shape without embedding the id).
    ///
    /// - Returns: `"<ckp>_<timestamp>"` or `"_<timestamp>"`.
    @objc public func generatePageId() -> String {
        let timestamp = Int(Date().toRatTimestamp)
        let ckp = allowsDeviceInformationOnRatPayload ? deviceIdentifierHandler.ckp() : ""
        return "\(ckp)_\(timestamp)"
    }

    /// Block to allow the app to set a custom domain on the app-to-web tracking cookie.
    ///
    /// - Parameters:
    ///     - cookieDomainBlock: The block returns the domain string to set on the cookie.
    ///
    /// - Returns: The tracking cookies injected into the web view cookie store.
    ///
    /// - Note: Takes precedence over domains set by `setWebTrackingCookieMultipleDomains(array:)` until that method is called again.
    public func setWebTrackingCookieDomain(block cookieDomainBlock: @escaping WebTrackingCookieDomainBlock) async -> [HTTPCookie] {
        self.cookieDomainBlock = cookieDomainBlock
        isCookieDomainBlockLastConfigured = true
        return await refreshCookieStore()
    }

    /// Method to allow the app to set multiple custom domains for app-to-web tracking cookies.
    ///
    /// - Parameters:
    ///     - cookieDomains: An array of domain strings to set on the cookie.
    ///
    /// - Returns: The tracking cookies injected into the web view cookie store.
    ///
    /// - Note: Takes precedence over the domain set by `setWebTrackingCookieDomain(block:)` until that method is called again.
    public func setWebTrackingCookieMultipleDomains(array cookieDomains: [String]?) async -> [HTTPCookie] {
        self.cookieDomains = cookieDomains
        isCookieDomainBlockLastConfigured = false
        return await refreshCookieStore()
    }

    /// Returns the web tracking cookie domain set by `setWebTrackingCookieDomain(block:)`
    @objc public func webTrackingCookieDomain() -> String? {
        cookieDomainBlock?()
    }

    /// Returns the latest web tracking cookie domains set by `setWebTrackingCookieMultipleDomains(array:)`
    @objc public func webTrackingCookieMultipleDomains() -> [String]? {
        cookieDomains
    }

    /// Set the endpoint URL for all the trackers at runtime.
    /// - Warning: If endpointURL is not nil, RATEndpoint defined in app's info.plist is ignored.
    /// - Warning: If endpointURL is nil, RATEndpoint defined in app's info.plist is set.
    @objc(setEndpointURL:) public func set(endpointURL: URL?) {
        trackersLockableObject
            .get()
            .compactMap { $0 as? EndpointSettable }
            .forEach { tracker in
                if tracker.responds(to: #selector(set(endpointURL:))),
                   let endpointURL = endpointURL ?? Bundle.main.endpointAddress {
                    tracker.endpointURL = endpointURL
                }
            }
    }
}

// MARK: - Member Identifier

extension AnalyticsManager {
    /// Set the member identifier
    ///
    /// - Parameter memberIdentifier: The logged-in ID SDK member's tracking identfier - normally the Easy ID.
    ///
    /// - Note: memberIdentifier can be obtained by calling `idToken[StandardClaims.subject]` from `IDSDK`.
    ///
    /// - Note: By setting the member identifier, `_rem_login` is automatically tracked.
    public func setMemberIdentifier(_ memberIdentifier: String) {
        if externalCollector.userIdentifier != nil {
            externalCollector.userIdentifier = nil
        }
        externalCollector.trackLogin(.easyIdentifier(memberIdentifier))
    }

    /// Raise a member identifier login failure error
    ///
    /// - Parameter error: the login failure Error
    ///
    /// - Note: By setting a member error, `_rem_login_failure` is automatically tracked.
    public func setMemberError(_ error: Error) {
        externalCollector.trackLoginFailure(.easyIdentifier(error: error))
    }

    /// Remove the member identifier
    ///
    /// - Note: By removing the member identifier, `_rem_logout` is automatically tracked.
    public func removeMemberIdentifier() {
        externalCollector.trackLogout()
    }
}

// MARK: - Privacy consent reconciliation

extension AnalyticsManager: AnalyticsPrivacyConsentReconciling {
    func reconcileLastKnownLocationMonitoringAfterConsentChange() {
        startStopMonitoringLocationIfNeeded()
    }

    func refreshAppToWebCookiesAfterConsentChange() async {
        _ = await refreshCookieStore()
    }

    func applyWebViewUserAgentAfterConsentChange() {
        applyWebViewUserAgentForCurrentPrivacyState()
    }
}
