import Foundation
import UIKit.UIViewController
import CoreLocation.CLLocation
#if canImport(RSDKUtils)
import RSDKUtils
#else // SPM version
import RSDKUtilsMain
#endif

/// Known login methods.
///
/// @see RAnalyticsState.loginMethod
/// @enum RAnalyticsLoginMethod
/// @ingroup AnalyticsConstants
@objc public enum RAnalyticsLoginMethod: UInt {
    /// Login with other method except input password and one tap.
    /// @par Swift
    /// This value is exposed as **AnalyticsManager.State.LoginMethod.other**.
    @objc(RAnalyticsOtherLoginMethod) case other = 0

    /// Password Input Login.
    /// The user had to manually input their credentials in order to login.
    @objc(RAnalyticsPasswordInputLoginMethod) case passwordInput

    /// One Tap Login.
    /// The user logged in by just tapping a button, as allowed by Single Sign-On.
    @objc(RAnalyticsOneTapLoginLoginMethod) case oneTapLogin
}

/// Known launch origins.
///
/// @see RAnalyticsState.origin
/// @enum Origin
/// @ingroup AnalyticsConstants
@objc public enum RAnalyticsOrigin: Int {
    /// The visit originates from within the app itself.
    @objc(RAnalyticsInternalOrigin) case `internal` = 0

    /// The visit originates from another app (i.e. deep-linking).
    @objc(RAnalyticsExternalOrigin) case external

    /// The visit originates from a push notification.
    @objc(RAnalyticsPushOrigin) case push
}

/// Composite state created every time an event is processed,
/// and passed to each tracker's [processEvent(event, state)](protocol_r_s_d_k_analytics_tracker_01-p.html#abd4a093a74d3445fe72916f16685f5a3) method.
///
/// @class RAnalyticsState
/// @ingroup AnalyticsCore
@objc public class RAnalyticsState: NSObject {
    /// Note: The LoginMethod type is declared in State in order to keep the compatibility with apps using previous versions of RAnalytics version <= 7.x
    public typealias LoginMethod = RAnalyticsLoginMethod

    /// Note: The Origin type is declared in State in order to keep the compatibility with apps using previous versions of RAnalytics version <= 7.x
    public typealias Origin = RAnalyticsOrigin

    /// Globally-unique string updated every time a new session starts.
    @objc public let sessionIdentifier: String

    /// Globally-unique string identifying the current device across all Rakuten applications.
    @objc public let deviceIdentifier: String

    /// Current app version.
    @objc public let currentVersion: String

    /// `CLLocation` object representing the last known location of the device.
    /// Only set if that information is available and AnalyticsManager.shouldTrackLastKnownLocation is `true`.
    @objc public internal(set) var lastKnownLocation: CLLocation?

    /// IDFA.
    /// Only set if AnalyticsManager.shouldTrackAdvertisingId is `true`.
    @objc public internal(set) var advertisingIdentifier: String?

    /// This property stores the date when a new session is started.
    @objc public internal(set) var sessionStartDate: Date?

    /// `true` if there's a user currently logged in, `false` otherwise.
    @objc public internal(set) var loggedIn: Bool = false
    @objc public var isLoggedIn: Bool { loggedIn }

    /// String uniquely identifying the last logged-in user, if any.
    /// If `loggedIn` is `true`, then trackers can assume that user is
    /// currently logged in.
    ///
    /// Note: for users logged in with RAE, this is the "encrypted easy id"
    /// as returned by the `IdInformation/GetEncryptedEasyId/20140617` API.
    @objc public internal(set) var userIdentifier: String?

    /// The logged in user's easyid (unique member identifier).
    @objc public internal(set) var easyIdentifier: String?

    /// The login method for the last logged-in user.
    @objc public internal(set) var loginMethod: RAnalyticsLoginMethod = .other

    /// String identifying the origin of the launch or visit, if it can be determined.
    @objc public internal(set) var origin: RAnalyticsOrigin = .internal

    /// Version of the app when it was last run.
    @objc public internal(set) var lastVersion: String?

    /// Number of times the last-run version was launched.
    @objc public internal(set) var lastVersionLaunches: UInt = 0

    /// Date the application was launched for the first time.
    /// This is nil on the first launch.
    @objc public internal(set) var initialLaunchDate: Date?

    /// Date the application was installed.
    @objc public internal(set) var installLaunchDate: Date?

    /// Date the application was last launched (prior to this run).
    @objc public internal(set) var lastLaunchDate: Date?

    /// Date the last-run version was launched for the first time.
    @objc public internal(set) var lastUpdateDate: Date?

    /// Referral tracking type
    internal var referralTracking: ReferralTrackingType

    private let bundle: EnvironmentBundle

    @available(*, unavailable)
    override init() {
        sessionIdentifier = ""
        deviceIdentifier = ""
        currentVersion = ""
        referralTracking = .none
        bundle = Bundle(for: RAnalyticsState.self)
        super.init()
    }

    /// Creates a new state
    ///
    /// - Parameters:
    ///   - sessionIdentifier: The session identifier. Globally-unique string updated every time a new session starts.
    ///   - deviceIdentifier: The device identifier. Vendor-unique string identifying the current device across all Rakuten applications.
    ///   - bundle: The bundle. It is used to retrieve the version set in the info.plist file.
    ///
    /// - Returns: A new instance of State.
    @objc public convenience init(sessionIdentifier: String,
                                  deviceIdentifier: String,
                                  bundle: Bundle) {
        self.init(sessionIdentifier: sessionIdentifier,
                  deviceIdentifier: deviceIdentifier,
                  for: bundle)
    }

    /// Creates a new state
    ///
    /// - Parameters:
    ///   - sessionIdentifier: The session identifier. Globally-unique string updated every time a new session starts.
    ///   - deviceIdentifier: The device identifier. Vendor-unique string identifying the current device across all Rakuten applications.
    ///
    /// - Returns: A new instance of State.
    ///
    /// Note: it initializes the state with Bundle.main.
    @objc public convenience init(sessionIdentifier: String, deviceIdentifier: String) {
        self.init(sessionIdentifier: sessionIdentifier,
                  deviceIdentifier: deviceIdentifier,
                  bundle: Bundle.main)
    }

    init(sessionIdentifier: String,
         deviceIdentifier: String,
         for bundle: EnvironmentBundle) {
        self.sessionIdentifier = sessionIdentifier
        self.deviceIdentifier = deviceIdentifier
        referralTracking = .none
        self.bundle = bundle
        currentVersion = bundle.shortVersion ?? bundle.version ?? ""
        super.init()
    }

    @objc public override var hash: Int {
        sessionIdentifier.hashValue
            ^ deviceIdentifier.hashValue
            ^ currentVersion.hashValue
            ^ advertisingIdentifier.safeHashValue
            // CLLocation's hash method gives different hash values for objects with identical properties so use a
            // hash of its string description instead
            ^ lastKnownLocation.safeHashValue
            ^ sessionStartDate.hashValue
            ^ isLoggedIn.hashValue
            ^ userIdentifier.safeHashValue
            ^ easyIdentifier.safeHashValue
            ^ loginMethod.hashValue
            ^ origin.hashValue
            ^ lastVersion.hashValue
            ^ lastVersionLaunches.hashValue
            ^ initialLaunchDate.hashValue
            ^ installLaunchDate.hashValue
            ^ lastLaunchDate.hashValue
            ^ lastUpdateDate.hashValue
            ^ referralTracking.hashValue
    }

    @objc public override func isEqual(_ object: Any?) -> Bool {
        guard let object = object as? RAnalyticsState else {
            return false
        }
        return advertisingIdentifier == object.advertisingIdentifier
            && sessionIdentifier == object.sessionIdentifier
            && deviceIdentifier == object.deviceIdentifier
            && currentVersion == object.currentVersion
            && CLLocation.equalLocation(lhs: lastKnownLocation, rhs: object.lastKnownLocation)
            && sessionStartDate == object.sessionStartDate
            && isLoggedIn == object.isLoggedIn
            && userIdentifier == object.userIdentifier
            && easyIdentifier == object.easyIdentifier
            && loginMethod == object.loginMethod
            && origin == object.origin
            && lastVersion == object.lastVersion
            && lastVersionLaunches == object.lastVersionLaunches
            && initialLaunchDate == object.initialLaunchDate
            && installLaunchDate == object.installLaunchDate
            && lastLaunchDate == object.lastLaunchDate
            && lastUpdateDate == object.lastUpdateDate
            && referralTracking == object.referralTracking
    }
}

extension RAnalyticsState: NSCopying {
    @objc public func copy(with zone: NSZone? = nil) -> Any {
        let state = RAnalyticsState(sessionIdentifier: sessionIdentifier,
                                    deviceIdentifier: deviceIdentifier,
                                    for: bundle)
        state.lastKnownLocation = lastKnownLocation
        state.advertisingIdentifier = advertisingIdentifier
        state.sessionStartDate = sessionStartDate
        state.loggedIn = loggedIn
        state.userIdentifier = userIdentifier
        state.easyIdentifier = easyIdentifier
        state.loginMethod = loginMethod
        state.origin = origin
        state.lastVersion = lastVersion
        state.lastVersionLaunches = lastVersionLaunches
        state.initialLaunchDate = initialLaunchDate
        state.installLaunchDate = installLaunchDate
        state.lastLaunchDate = lastLaunchDate
        state.lastUpdateDate = lastUpdateDate
        state.referralTracking = referralTracking
        return state
    }
}

/// Note: The State class is created in AnalyticsManager in order to keep the compatibility with apps using previous versions of RAnalytics version <= 7.x
public extension AnalyticsManager {
    typealias State = RAnalyticsState
}
