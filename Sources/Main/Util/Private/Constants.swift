import Foundation

enum RATConstants {
    /// Mobile Privacy Control migration and payload helpers.
    enum PrivacyControl {
        /// Current privacy-control feature version persisted under ``privacyVersionKey``.
        static let currentPrivacyVersion = 1

        /// UserDefaults key for the stored privacy-control feature version (`privacy_version` in the migration spec).
        static let privacyVersionKey = "RATDataCollection_privacy_version"
    }

    /// Root JSON `privacy_mode` field (Mobile Privacy Control spec).
    enum PrivacyMode {
        /// Value when `RATEnablePrivacyControl` is off: all categories treated as allowed (default full collection).
        static let defaultFullCollection = "1111"
    }

    enum RpCookie {
        /// Cookie name used by RAT backend for user identification.
        static let cookieName = "Rp"
    }

    /// Default RAT collection origin when the app does not define `RATEndpoint` (internal builds).
    /// Host apps customize via `RATEndpoint` in Info.plist or ``AnalyticsManager/set(endpointURL:)``;
    /// this constant is the SDK-internal fallback only (see ``Bundle/endpointAddress``).
    enum ProductionRat {
        static let endpointURL = URL(string: "https://rat.rakuten.co.jp/")! // NOSONAR (swift:S1075)
    }
}
