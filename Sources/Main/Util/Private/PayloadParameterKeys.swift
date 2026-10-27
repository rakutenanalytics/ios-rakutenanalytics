// Generated from rakuten-analytics-json-schema latest, schemas/base-non-strict.json. Do not edit manually.
import Foundation

/// RAT payload keys whose `x-definitionLevel` explicitly includes `iOS` and whose `x-layerLevel` is `SDK`.
enum PayloadParameterKeys {
    /// Each account ID corresponds to a group of services
    static let acc = "acc"

    /// The service ID is assigned individually for each service. Multiple services can have same ID if their account ID differs. This is an optional parameter.
    static let aid = "aid"

    /// App name
    static let appName = "app_name"

    /// App version
    static let appVer = "app_ver"

    /// IDFA/ADID
    static let cka = "cka"

    /// Value is set indirectly by specifying the corresponding cookie name
    static let ckp = "ckp"

    /// Session Cookie with a unique value for each user, regardless of their membership. This value will match the Rp Cookie, and it will only be set on the rakuten.co.jp domain or on third party domains which have been allowed access to the Rp Cookie. On other third party domains this property will not be present.
    static let cks = "cks"

    /// The device permissions collected from the device.
    static let devicePer = "device_per"

    /// Device language
    static let dln = "dln"

    /// In principle this should be in cp group since it applies to Ichiba only
    static let easyid = "easyid"

    /// Event type
    static let etype = "etype"

    /// To indiacate location collection is user action or interval/distance based location collection, not sent when geotracker is disabled
    static let isaction = "isaction"

    /// Script start time
    static let ltm = "ltm"

    /// Battery usage
    static let mbat = "mbat"

    /// Mobile carrier name
    static let mcn = "mcn"

    /// Mobile carrier name for dual SIM functionality
    static let mcnd = "mcnd"

    /// Mobile network type (-1-Unknown, 1-Wifi, 2-GPRS/2G, 3-3G, 4-4G/LTE, 5-5G, 6-Android専用Ethernet)
    static let mnetw = "mnetw"

    /// Mobile network type (-1-Unknown, 1-Wifi, 2-GPRS/2G, 3-3G, 4-4G/LTE, 5-5G) for dual SIM functionality
    static let mnetwd = "mnetwd"

    /// Mobile device brand model
    static let model = "model"

    /// Mobile orientation (0: unknown, 1: portrait, 2: landscape)
    static let mori = "mori"

    /// Mobile OS
    static let mos = "mos"

    /// Online status when creating the event client side
    static let online = "online"

    /// Page id
    static let pgid = "pgid"

    /// Page name
    static let pgn = "pgn"

    /// Page Section
    static let pgs = "pgs"

    /// Battery charging status (0-Not charging, 1-Charging)
    static let powerstatus = "powerstatus"

    /// 4 digit representation of the current data collection type consent status (1: enabled, 0: disabled). Order: location, mobile network, device information, user information.
    static let privacyMode = "privacy_mode"

    /// Referrer URL
    static let ref = "ref"

    /// Device screen resolution
    static let res = "res"

    /// SDK source which was used for sending an event.
    static let sdkSource = "sdk_source"

    /// For redirect and native app purposes only. Format: seconds since epoch time
    static let ts1 = "ts1"

    /// Timezone expressed in hour offset from GMT
    static let tzo = "tzo"

    /// User agent
    static let ua = "ua"

    /// Enriched user agent string to capture device and OS details.
    static let uaEnriched = "ua_enriched"

    /// Defined for applications to pass users encrypted member id
    static let userid = "userid"

    /// Client SDK or Library version
    static let ver = "ver"

    /// Array of qualified viewable impression items from a single refreshState evaluation.
    static let viewableData = "viewable_data"

    /// Optional action parameters for requestion a location for an event of type `loc`, sent only when atleast one of them is present
    enum ActionParams {
        /// Optional action parameters for requestion a location for an event of type `loc`, sent only when atleast one of them is present
        static let actionParams = "action_params"

        /// Type of action user performed when requesting location, sent only when application provides the details
        static let type = "type"

        /// Action Log when requesting location, sent only when application provides the details
        static let log = "log"

        /// Action ID when requesting location, sent only when application provides the details
        static let id = "id"

        /// Action duration when requesting location, sent only when application provides the details
        static let duration = "duration"

        /// Addtional action Log when requesting location, sent only when application provides the details
        static let addLog = "add_log"
    }

    /// Custom parameter group: contain fields which are specific to certain services but do not apply in general to all services
    enum Cp {
        /// Custom parameter group: contain fields which are specific to certain services but do not apply in general to all services
        static let cp = "cp"

        /// Page transition type
        static let refType = "ref_type"

        /// The deeplink used by the source app.
        static let refLink = "ref_link"

        /// The source app components.
        static let refComp = "ref_comp"

        /// The days passed since the installation launch date.
        static let daysSinceFirstUse = "days_since_first_use"

        /// The days passed since the last launch date.
        static let daysSinceLastUse = "days_since_last_use"

        /// The days passed since the last upgrade.
        static let daysSinceLastUpgrade = "days_since_last_upgrade"

        /// The number of launches since the last upgrade.
        static let launchesSinceLastUpgrade = "launches_since_last_upgrade"

        /// The previous installed version number.
        static let previousVersion = "previous_version"

        /// The application information.
        static let appInfo = "app_info"

        /// The login method. Possible values are password, one_tap_login or empty string if not available.
        static let loginMethod = "login_method"

        /// The logout method. Possible values are single, all or nil if not available
        static let logoutMethod = "logout_method"

        /// Displayed page title
        static let title = "title"

        /// Page url
        static let url = "url"
    }

    /// Geolocation coordinates (ref: https://dev.w3.org/geo/api/spec-source.html#navi-geo)
    enum Loc {
        /// Geolocation coordinates (ref: https://dev.w3.org/geo/api/spec-source.html#navi-geo)
        static let loc = "loc"

        /// Accuracy level of the latitude and longitude coordinates, specified in meters
        static let accu = "accu"

        /// Height of the position, specified in meters
        static let altitude = "altitude"

        /// Latitude coordinate in decimal degrees
        static let lat = "lat"

        /// Longitude coordinate in decimal degrees
        static let long = "long"

        /// Horizontal component of the device's velocity, in meters per second
        static let speed = "speed"

        /// Represent the time when the location was acquired, in milliseconds since epoch time
        static let tms = "tms"

        /// The instantaneous speed of the device, measured in meters per second, not sent when the value cannot be detemined
        static let speedAccuracy = "speed_accuracy"

        /// The validity of the altitude values, and their estimated uncertainty, measured in meters, not sent when the value cannot be detemined
        static let verticalAccuracy = "vertical_accuracy"

        /// The direction in which the device is traveling, measured in degrees and relative to due north, not sent when the value cannot be detemined
        static let bearing = "bearing"

        /// The accuracy of the course value, measured in degrees, not sent when the value cannot be detemined
        static let bearingAccuracy = "bearing_accuracy"
    }

}

enum PayloadConstants {
    /// The RAT payload prefix.
    static let prefix = "cpkg_none="
}
