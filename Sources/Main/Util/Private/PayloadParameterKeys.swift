import Foundation

/// The RAT payload keys.
enum PayloadParameterKeys {
    /// The RAT account identifier.
    static let acc = "acc"

    /// The RAT application identifier.
    static let aid = "aid"

    /// The RAT event type.
    static let etype = "etype"

    /// The RAT extra parameters.
    static let cp = "cp"

    /// The current page name.
    /// - Note: current `UIViewController` Class Name
    static let pgn = "pgn"

    /// The previous page name.
    /// - Note: previous `UIViewController` Class Name
    static let ref = "ref"

    enum Core {
        /// The application version.
        /// - Note: returned by `CFBundleShortVersionString`
        static let appVer = "app_ver"

        /// The application name.
        /// - Note: Returned by `CFBundleIdentifier` key in app's Info.plist (also returned by `Bundle.main.bundleIdentifier`)
        static let appName = "app_name"

        /// The OS version.
        /// - Note: returned by `String(format: "%@ %@", UIDevice.current.systemName, UIDevice.current.systemVersion)`
        static let mos = "mos"

        /// The SDK version.
        static let ver = "ver"

        /// The curent timestamp.
        static let ts1 = "ts1"
    }

    enum Identifier {
        /// The device identifier.
        /// - Note: based on `UIDevice.identifierForVendor.uuidString`
        /// https://developer.apple.com/documentation/uikit/uidevice/1620059-identifierforvendor
        static let ckp = "ckp"

        /// The session identifier.
        /// - Note: returned by `NSUUID().uuidString`
        static let cks = "cks"

        /// The advertising identifier.
        /// - Note: based on `ASIdentifierManager.advertisingIdentifier.uuidString`
        /// https://developer.apple.com/documentation/adsupport/asidentifiermanager/1614151-advertisingidentifier
        static let cka = "cka"

        /// The RAE user identifier.
        static let userid = "userid"

        /// The IDSDK easy identifier.
        static let easyid = "easyid"
    }

    enum Language {
        /// The language code
        /// - Note: returned by `NSLocale.Key.languageCode`
        static let dln = "dln"
    }

    enum Device {
        /// The device battery state.
        /// - Note: returned by `UIDevice.BatteryState`
        /// https://developer.apple.com/documentation/uikit/uidevice/1620051-batterystate
        static let powerStatus = "powerstatus"

        // The device battery level.
        /// - Note: returned by `UIDevice.batteryLevel`
        /// https://developer.apple.com/documentation/uikit/uidevice/1620042-batterylevel
        static let mbat = "mbat"

        /// The model Identifier.
        /// - Note: returned by `UIDevice.current.modelIdentifier`
        static let model = "model"

        /// The screen resolution.
        /// - Note: returned by `UIScreen.main.bounds.size`
        static let res = "res"
    }

    /// Location
    enum Location {
        /// The location dictionary containing `lat`, `long`, `accu`, `tms`, `speed`, `speed_accuracy`, `alt`, `vertical_accuracy`, `bearing`, `bearing_accuracy`, `isaction`, `action_params`
        static let loc = "loc"

        /// Latitude of collected location in degrees
        /// ex: 12.01245 or -39.01245
        /// https://developer.apple.com/documentation/corelocation/cllocationcoordinate2d
        static let lat = "lat"

        /// Longitude of collected location in degrees
        /// ex: 136.02391 or  -130.1245
        /// https://developer.apple.com/documentation/corelocation/cllocationcoordinate2d
        static let long = "long"

        /// Horizontal accuracy of this location
        /// ex: 5.0
        /// https://developer.apple.com/documentation/corelocation/cllocation/1423599-horizontalaccuracy
        static let accu = "accu"

        /// The time at which this location was determined.
        /// Timestamp in ms (Unix epoch time)
        /// ex: 1525648664398
        static let tms = "tms"

        /// Speed at the time of this location
        /// ex: 5.0
        /// https://developer.apple.com/documentation/corelocation/cllocation/1423798-speed
        static let speed = "speed"

        /// The accuracy of the speed value, measured in meters per second.
        /// ex: 9.8
        /// https://developer.apple.com/documentation/corelocation/cllocation/3524340-speedaccuracy
        static let speedAccuracy = "speed_accuracy"

        /// The altitude above mean sea level associated with a location, measured in meters
        /// https://developer.apple.com/documentation/corelocation/cllocation/1423820-altitude
        static let altitude = "altitude"

        /// Vertical accuracy of this location
        /// https://developer.apple.com/documentation/corelocation/cllocation/1423550-verticalaccuracy
        static let verticalAccuracy = "vertical_accuracy"

        /// Bearing at the time of this location Value is between 0.0 and 360.0 inclusive
        /// https://developer.apple.com/documentation/corelocation/cllocation/1423832-course
        static let bearing = "bearing"

        /// Bearing accuracy in degrees of this location
        /// https://developer.apple.com/documentation/corelocation/cllocation/3524338-courseaccuracy
        static let bearingAccuracy = "bearing_accuracy"

        /// isAction = false → The Location collection in regular interval/distance.
        /// isAction = true → The Location Collection is happening on demand(Application Calls Public Method requestLocation)
        /// Default value: `false`
        static let isAction = "isaction"

        /// Optional Values which application can send along with requestLocation() method of public API.
        /// - Note: Present only when `isaction` = true.
        enum ActionParameters {
            /// Type of action performed in requesting location
            static let type = "action_type"

            /// Logs related to performed action
            static let log = "action_log"

            /// Identifier associated with the action
            static let identifier = "action_id"

            /// Duration of action
            static let duration = "action_duration"

            /// Additional Information related to performed action
            static let addLog = "action_add_log"
        }
    }

    enum Orientation {
        /// The interface orientation normally corresponds to the device orientation.
        /// `UIWindowScene.interfaceOrientation`
        /// https://developer.apple.com/documentation/uikit/uiwindowscene/3198088-interfaceorientation
        static let mori = "mori"
    }

    enum Network {
        /// The network connection status.
        static let online = "online"
    }

    enum UserAgent {
        /// The application user agent.
        /// - Note: the format is `bundleIdentifier/currentVersion`
        static let ua = "ua"
    }

    enum Time {
        /// The starts time when the application is launched.
        /// - Note: returned by `NSDate().toString`
        static let ltm = "ltm"
    }

    /// The time zone (current difference in hours between the receiver and Greenwich Mean Time).
    /// - Note: returned by `NSNumber(value: Double(NSTimeZone.local.secondsFromGMT()) / 3600.0)`
    /// https://developer.apple.com/documentation/foundation/nstimezone/1387221-secondsfromgmt
    enum TimeZone {
        static let tzo = "tzo"
    }

    enum Telephony {
        /// The name of the primary carrier
        static let mcn = "mcn"

        /// The name of the secondary carrier
        static let mcnd = "mcnd"

        /// The network status of the primary carrier.
        static let mnetw = "mnetw"

        /// The network status of the secondary carrier.
        static let mnetwd = "mnetwd"

        /// The network carrier name
        static let netopn = "netopn"

        /// The network operator code mcc+mnc
        ///  ex: mcc = 440 and mnc = 11 then netop = 44011
        static let netop = "netop"
    }
}

/// The RAT CP payload keys.
enum CpParameterKeys {
    enum Ref {
        /// The launch origin: internal, external, push.
        static let type = "ref_type"

        /// The source app RAT account identifier.
        static let accountIdentifier = "ref_acc"

        /// The source app RAT application identifier.
        static let applicationIdentifier = "ref_aid"

        /// The deeplink used by the source app.
        static let link = "ref_link"

        /// The source app components.
        static let component = "ref_comp"
    }

    enum SessionStart {
        /// The days passed since the installation launch date.
        static let daysSinceFirstUse = "days_since_first_use"

        /// The days passed since the last launch date.
        static let daysSinceLastUse = "days_since_last_use"
    }

    enum Page {
        /// The page title.
        /// - Note: returned by `UIViewController.title`
        static let title = "title"

        /// The web view absolute url.
        /// - Note: returned by `WKWebView.url.absoluteURL.absoluteString`
        static let url = "url"
    }

    enum Push {
        /// The push notification tracking identifier.
        static let pushNotifyValue = "push_notify_value"

        /// The push notification request identifier.
        static let pushRequestIdentifier = "push_request_id"

        /// The push conversion action.
        static let pushConversionAction = "push_cv_action"
    }

    enum PNP {
        /// The PNP device identifier.
        static let deviceId = "deviceId"

        /// The PNP client identifier.
        static let pnpClientId = "pnpClientId"
    }

    enum Login {
        /// The login method.
        static let method = "login_method"
    }

    enum Logout {
        /// The logout method.
        static let method = "logout_method"
    }
}

enum PayloadConstants {
    /// The RAT payload prefix.
    static let prefix = "cpkg_none="
}
