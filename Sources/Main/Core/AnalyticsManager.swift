import Foundation
import CoreLocation
import AdSupport
import WebKit

// swiftlint:disable type_name
public typealias RAnalyticsShouldTrackEventCompletionBlock = (String) -> Bool
// swiftlint:enable type_name

public typealias WebTrackingCookieDomainBlock = () -> String?

public typealias RAnalyticsErrorBlock = (NSError) -> Void

enum CoreOrigin {
    case analytics
    case geo(LocationModel)
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
}

// MARK: - AnalyticsManager

/// Main class of the module.
@objc(RAnalyticsManager) public final class AnalyticsManager: NSObject {
    static var isConfigured: Bool = false
    
    private static let singleton: AnalyticsManager = {
        AnalyticsManager(dependenciesContainer: SimpleDependenciesContainer())
    }()

    /// Retrieve the shared instance.
    ///
    /// - Returns: The shared instance.
    @objc(sharedInstance) public static func shared() -> AnalyticsManager {
        if Bundle.main.isManualInitializationEnabled {
            guard isConfigured else {
                RLogger.error(message: "Manual initialization is enabled. AnalyticsManager must be configured before accessing shared instance. Call AnalyticsManager.configure() first.")
                return singleton
            }
            return singleton
        } else {
            isConfigured = true
            return singleton
        }
    }

    /// Control whether the SDK should track the device's location or not.
    /// This property is set to `YES` by default, which means @ref RAnalyticsManager will use the device's location.
    ///
    /// - Warning: If the application has not already requested access to the location information, trying to set this property to `YES` has no effect. Please refer
    /// to the [Location and Maps Programming Guide](https://developer.apple.com/library/ios/documentation/UserExperience/Conceptual/LocationAwarenessPG/)
    /// for more information.
    @objc public var shouldTrackLastKnownLocation: Bool {
        didSet(oldValue) {
            if oldValue != shouldTrackLastKnownLocation {
                startStopMonitoringLocationIfNeeded()
            }
        }
    }

    /// Control whether the SDK should track the [advertising identifier (IDFA)](https://developer.apple.com/reference/adsupport/asidentifiermanager) or not.
    /// This property is set to `YES` by default, which means @ref RAnalyticsManager will use the advertising identifier if it is set to a non-zeroed valid value.
    @objc public var shouldTrackAdvertisingIdentifier: Bool = false

    /// Control whether the SDK should inject a tracking cookie into the WKWebView's cookie store.
    /// The cookie enables tracking between mobile app and webviews.
    ///
    /// This feature only works on iOS 11.0 and above.
    ///
    /// This property is set to `NO` by default
    @objc public var enableAppToWebTracking: Bool = false {
        didSet {
            refreshCookieStore()
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
    private var authorizationStatusLockableObject: LockableObject<CLAuthorizationStatus>
    private(set) var locationManagerIsUpdating: Bool = false

    /// Session cookie. We use an UUID automatically created at startup and
    /// regenerated when the app comes back from background, as per the specifications.
    private var sessionCookie: String?
    private var sessionStartDate: Date?
    private var cookieDomainBlock: WebTrackingCookieDomainBlock?
    private var cookieDomains: [String]?

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
    private let userStorageHandler: UserStorageHandleable

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

    init(dependenciesContainer: SimpleDependenciesContainable) {
        externalCollector = RAnalyticsExternalCollector(dependenciesContainer: dependenciesContainer)
        launchCollector = RAnalyticsLaunchCollector(dependenciesContainer: dependenciesContainer)
        self.locationManager = dependenciesContainer.locationManager

        bundle = dependenciesContainer.bundle
        eventChecker = EventChecker(disabledEventsAtBuildTime: bundle.disabledEventsAtBuildTime)

        userStorageHandler = dependenciesContainer.userStorageHandler

        eventObserver = AnalyticsEventObserver(pushEventHandler: dependenciesContainer.pushEventHandler)

        shouldTrackLastKnownLocation = true
        shouldTrackAdvertisingIdentifier = true

        // Inject the Dependencies Container
        advertisingIdentifierHandler = RAdvertisingIdentifierHandler(dependenciesContainer: dependenciesContainer)
        analyticsCookieInjector = RAnalyticsCookieInjector(dependenciesContainer: dependenciesContainer)

        userIdentifierSelector = UserIdentifierSelector(userIdentifiable: externalCollector)

        trackers = NSMutableSet()
        trackersLockableObject = LockableObject(trackers)

        authorizationStatusLockableObject = LockableObject(type(of: locationManager).authorizationStatus())

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
    }

    deinit {
        stopMonitoringLocation()
    }
}

// MARK: - Configuration

extension AnalyticsManager {
    /// Set the WKWebView's user agent value at buildtime only if Bundle's `isWebViewAppUserAgentEnabledAtBuildtime` is set to true.
    ///
    /// - Warning: If the `AnalyticsManager` is not launched from the main thread, then the `WKWebView` user agent will be set only in the next loop of the main Thread.
    private func configureWebViewUserAgent() {
        guard bundle.isWebViewAppUserAgentEnabledAtBuildtime else {
            // WKWebView can only be instantiated on the main thread.
            MainThreadExecutor.run {
                self.defaultWebViewUserAgent = WKWebView().rCurrentUserAgent
            }
            return
        }

        // WKWebView can only be instantiated on the main thread.
        MainThreadExecutor.run {
            let webView = WKWebView()
            self.defaultWebViewUserAgent = webView.rCurrentUserAgent

            if let userAgent = self.defaultWebViewUserAgent,
               let customUserAgent = webView.webViewUserAgent(defaultWebViewUserAgent: userAgent,
                                                              for: self.bundle) {
                self.userStorageHandler.register(defaults: [UserDefaultsKeys.userAgentKey: customUserAgent])
            }
        }
    }

    private func configure() {
        configureWebViewUserAgent()

        // Due to https://github.com/CocoaPods/CocoaPods/issues/2774 we can't
        // always rely solely on header availability so we also do a runtime check
        if let ratTracker = NSObject.ratTracker {
            add(ratTracker)
        }

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
    
    private func refreshCookieStore(with targetDomains: [String]? = nil, completion: (([HTTPCookie]) -> Void)? = nil) {
        guard enableAppToWebTracking else {
            analyticsCookieInjector.clearCookies { }
            return
        }
        
        // If targetDomains is not nil and not empty, proceed with the following logic
        guard let targetDomains = targetDomains, !targetDomains.isEmpty else {
            injectAppToWebTrackingCookie(domain: nil) { trackingCookie in
                if let trackingCookie = trackingCookie {
                    completion?([trackingCookie])
                } else {
                    // No tracking cookie found, return an empty array
                    completion?([])
                }
            }
            return
        }

        var trackingCookies: [HTTPCookie] = []
        let group = DispatchGroup()
        
        for domain in targetDomains {
            group.enter()
            injectAppToWebTrackingCookie(domain: domain) { trackingCookie in
                if let trackingCookie = trackingCookie {
                    trackingCookies.append(trackingCookie)
                }
                group.leave()
            }
        }
        
        group.notify(queue: .main) {
            completion?(trackingCookies)
        }
    }

    private func injectAppToWebTrackingCookie(domain: String?, completion: ((HTTPCookie?) -> Void)? = nil) {
        analyticsCookieInjector.injectAppToWebTrackingCookie(domain: domain, deviceIdentifier: deviceIdentifierHandler.ckp()) { trackingCookie in
            completion?(trackingCookie)
        }
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
    private func startStopMonitoringLocationIfNeeded() {
        let status: CLAuthorizationStatus = type(of: locationManager).authorizationStatus()

        #if DEBUG
        var lastStatus: CLAuthorizationStatus?
        Synchronizable.withSynchronized([authorizationStatusLockableObject]) {
            let hasUpdated = status != lastStatus
            if hasUpdated {
                lastStatus = status

                var statusString = ""
                switch status {
                case .notDetermined:       statusString = "Not Determined"
                case .restricted:          statusString = "Restricted"
                case .denied:              statusString = "Denied"
                case .authorizedAlways:    statusString = "Authorized Always"
                case .authorizedWhenInUse: statusString = "Authorized When In Use"
                default: statusString = "Value (\(String(describing: status)))"
                }
                RLogger.debug(message: "Location services' authorization status changed to [\(statusString)].")
            }
        }
        #endif

        if shouldTrackLastKnownLocation &&
            (status == .authorizedAlways
                || (status == .authorizedWhenInUse && UIApplication.RAnalyticsSharedApplication?.applicationState == .active)) {
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

        if shouldTrackAdvertisingIdentifier, let advertisingIdentifier = advertisingIdentifierHandler.idfa {
            // User has not disabled tracking
            state.advertisingIdentifier = advertisingIdentifier
        }

        switch coreOrigin {
        case .analytics:
            if shouldTrackLastKnownLocation,
                let location = locationManager.location {
                state.lastKnownLocation = LocationModel(location: location)

            } else {
                state.lastKnownLocation = nil
            }

        case .geo(let locationModel):
            state.lastKnownLocation = locationModel
        }

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
    /// This method sets up automatic tracking for various components of the app, such as the application lifecycle,
    /// user notifications, view controllers, and window scenes (if available).
    ///
    /// - Note: For iOS 13.0 and above, it also installs auto-tracking hooks for `UIWindowScene`.
    public static func configure() {
        UIApplication.installAutoTrackingHooks()
        UNUserNotificationCenter.installAutoTrackingHooks()
        UIViewController.installAutoTrackingHooks()
        if #available(iOSApplicationExtension 13.0, *) {
            UIWindowScene.installAutoTrackingHooks()
        }
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

    /// Set the user identifier of the logged in user.
    ///
    /// - Parameters:
    ///     - userID:  The user identifier. This can be the encrypted internal tracking ID.
    @objc public func setUserIdentifier(_ userID: String?) {
        externalCollector.userIdentifier = userID
    }

    /// Block to allow the app to set a custom domain on the app-to-web tracking cookie.
    ///
    /// - Parameters:
    ///     - cookieDomainBlock: The block returns the domain string to set on the cookie.
    ///     - completion: An optional completion handler that returns the tracking cookies.
    @objc(setWebTrackingCookieDomainWithBlock:completion:) public func setWebTrackingCookieDomain(block cookieDomainBlock: @escaping WebTrackingCookieDomainBlock, completion: (([HTTPCookie]) -> Void)? = nil) {
        self.cookieDomainBlock = cookieDomainBlock
        guard let domain = self.cookieDomainBlock?() else {
            refreshCookieStore(completion: completion)
            return
        }
        refreshCookieStore(with: [domain], completion: completion)
    }
    
    /// Method to allow the app to set multiple custom domains for app-to-web tracking cookies.
    ///
    /// - Parameters:
    ///     - cookieDomains: An array of domain strings to set on the cookie.
    ///     - completion: An optional completion handler that returns the tracking cookies.
    @objc(setWebTrackingCookieMultipleDomainsWithArray:completion:) public func setWebTrackingCookieMultipleDomains(array cookieDomains: [String]?, completion: (([HTTPCookie]) -> Void)? = nil) {
        self.cookieDomains = cookieDomains
        refreshCookieStore(with: cookieDomains, completion: completion)
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
