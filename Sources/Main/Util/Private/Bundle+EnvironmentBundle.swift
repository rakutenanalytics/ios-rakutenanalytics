import Foundation
import UIKit

internal enum AppGroupUserDefaultsKeys {
    /// Info.plist key whose value holds the name of the App Group set by the App.
    static let appGroupIdentifierPlistKey = "RPushAppGroupIdentifier"
}

protocol EnvironmentBundle: Bundleable {
    var languageCode: Any? { get }
    var preferredLocalization: String? { get }
    var bundleIdentifier: String? { get }
    var useDefaultSharedCookieStorage: Bool { get }
    var endpointAddress: URL? { get }
    var enableInternalSerialization: Bool { get }
    var disabledEventsAtBuildTime: [String]? { get }
    var duplicateAccounts: [RATAccount]? { get }
    static var assetsBundle: Bundle? { get }
    static var sdkComponentMap: NSDictionary? { get }
    func object(forInfoDictionaryKey key: String) -> Any?
    var appGroupId: String? { get }
    var version: String? { get }
    var applicationSceneManifest: ApplicationSceneManifest? { get }
    var isWebViewAppUserAgentEnabledAtBuildtime: Bool { get }
    var isManualInitializationEnabled: Bool { get }
    var databaseParentDirectory: FileManager.SearchPathDirectory { get }
    var backgroundLocationUpdates: Bool { get }
    var isPrivacyControlEnabled: Bool { get }
}

extension Bundle: EnvironmentBundle {
    private static let jsonDecoder = JSONDecoder()

    private enum Keys {
        static let applicationSceneManifestKey = "UIApplicationSceneManifest"
        static let setWebViewAppUserAgentEnabled = "RATSetWebViewAppUserAgentEnabled"
        static let privacyControlEnabled = "RATEnablePrivacyControl"
    }

    var languageCode: Any? {
        if let preferredLocaleLanguage = NSLocale.preferredLanguages.first {
            let localeLanguageCode = NSLocale(localeIdentifier: preferredLocaleLanguage).object(forKey: NSLocale.Key.languageCode)
            return localeLanguageCode
        }
        return nil
    }

    var preferredLocalization: String? {
        return preferredLocalizations.first
    }

    var useDefaultSharedCookieStorage: Bool {
        guard let result = object(forInfoDictionaryKey: "RATDisableSharedCookieStorage") as? NSNumber else {
            return true
        }
        return !result.boolValue
    }

    var endpointAddress: URL? {
        guard let plistObj = object(forInfoDictionaryKey: "RATEndpoint") as? String,
              !plistObj.isEmpty,
              let userDefinedURL = URL(string: plistObj) else {
            #if PUBLIC_ANALYTICS_IOS_SDK
            #if DEBUG
            assertionFailure(ErrorDescription.endpoint)
            #endif
            return nil
            #else
            return RATConstants.ProductionRat.endpointURL
            #endif
        }
        return userDefinedURL
    }

    var enableInternalSerialization: Bool {
        guard let internalSerializationIsEnabled = object(forInfoDictionaryKey: "RATEnableInternalSerialization") as? Bool else {
            return false
        }
        return internalSerializationIsEnabled
    }

    /// Returns the value of `RATSetWebViewAppUserAgentEnabled` in the app's `Info.plist`.
    ///
    /// `RATSetWebViewAppUserAgentEnabled` allows to append the app user agent to the default WKWebView's user agent.
    ///
    /// - returns: `true` if `RATSetWebViewAppUserAgentEnabled` is set to true or not set, `false` otherwise.
    ///
    /// - Note: If `RATSetWebViewAppUserAgentEnabled` is not set the app's Info.plist, `true` is returned.
    var isWebViewAppUserAgentEnabledAtBuildtime: Bool {
        guard let value = object(forInfoDictionaryKey: Keys.setWebViewAppUserAgentEnabled) as? Bool else {
            return true
        }
        return value
    }

    static let assetsBundle: Bundle? = {
        #if SWIFT_PACKAGE
        return Bundle.module
        #else
        guard let rAnalyticsManagerClass = NSClassFromString("RAnalyticsManager") else {
            return nil
        }
        /// Can't use [NSBundle mainBundle] here, because it returns the path to XCTest.framework
        /// when running unit tests. Also, if the SDK is being bundled as a dynamic framework,
        /// then it comes in its own bundle.
        let classBundle = Bundle(for: rAnalyticsManagerClass.self)
        guard var assetsPath = classBundle.resourcePath else {
            return nil
        }
        /// If RAnalyticsAssets.bundle cannot be found, we revert to using the class bundle
        assetsPath = assetsPath.appendingPathComponent("RAnalyticsAssets.bundle")
        guard let bundle = Bundle(path: assetsPath) else {
            return classBundle
        }
        return bundle
        #endif
    }()

    static let sdkComponentMap: NSDictionary? = {
        guard let bundle = assetsBundle,
              let filePath = bundle.path(forResource: "RModulesList", ofType: "plist") else {
            return nil
        }
        return NSDictionary(contentsOfFile: filePath)
    }()

    var disabledEventsAtBuildTime: [String]? {
        configuration?.disabledEvents
    }

    var duplicateAccounts: [RATAccount]? {
        configuration?.duplicateAccounts
    }

    private static var _configuration: RAnalyticsConfiguration?
    private var configuration: RAnalyticsConfiguration? {
        guard Self._configuration == nil else {
            return Self._configuration
        }
        do {
            guard let ratConfigPlistURL = url(forResource: "RAnalyticsConfiguration", withExtension: "plist") else {
                return nil
            }
            let data = try Data(contentsOf: ratConfigPlistURL)
            let decoder = PropertyListDecoder()
            Self._configuration = try decoder.decode(RAnalyticsConfiguration.self, from: data)
        } catch {
            #if DEBUG
            assertionFailure("Your application's RAnalyticsConfiguration.plist is malformed: \(error)")
            #endif
        }
        return Self._configuration
    }

    /// - Returns `.applicationSupportDirectory` or `.documentDirectory` regarding the value of `RATStoreDatabaseInApplicationSupportDirectory` in the app's `Info.plist`, `.documentDirectory` otherwise.
    ///
    /// - Enable `.documentDirectory` storage:
    /// <key>RATStoreDatabaseInApplicationSupportDirectory</key>
    /// <false/>
    ///
    /// - Enable `.applicationSupportDirectory` storage:
    /// <key>RATStoreDatabaseInApplicationSupportDirectory</key>
    /// <true/>
    var databaseParentDirectory: FileManager.SearchPathDirectory {
        guard let result = object(forInfoDictionaryKey: "RATStoreDatabaseInApplicationSupportDirectory") as? Bool else {
            return .documentDirectory
        }
        return result ? .applicationSupportDirectory : .documentDirectory
    }

    var appGroupId: String? {
        object(forInfoDictionaryKey: AppGroupUserDefaultsKeys.appGroupIdentifierPlistKey) as? String
    }

    var applicationSceneManifest: ApplicationSceneManifest? {
        guard let dict = object(forInfoDictionaryKey: Keys.applicationSceneManifestKey) as? [String: Any],
              let data = try? JSONSerialization.data(withJSONObject: dict, options: []) else {
            return nil
        }
        return try? Bundle.jsonDecoder.decode(ApplicationSceneManifest.self, from: data)
    }

    var backgroundLocationUpdates: Bool {
        guard let backgroundModes = object(forInfoDictionaryKey: "UIBackgroundModes") as? [String],
              backgroundModes.contains("location") else {
            return false
        }
        return true
    }

    /// Build-time privacy control flag (`RATEnablePrivacyControl` in the app Info.plist; default `false`).
    ///
    /// Behavior matches the Analytics SDK Mobile Privacy Control specification:
    /// - **`false` (default):** Ignore ``AnalyticsManager/set(dataCollection:enabled:)`` (and related runtime consent).
    ///   All categories are collected; the Data Collection API has no effect.
    /// - **`true`:** Granular APIs are active. Initial consent state is per product/legal (stored consent;
    ///   unset is treated as not granted until the app grants categories via the runtime API).
    ///   **Semantics:** consent gates **per-category collection and inclusion in RAT payloads** (and related
    ///   behavior such as cookies/Geo). The SDK does **not** stop all events or block transport until the
    ///   runtime API runs; core/minimal parameters may still be sent even before any `set(dataCollection:)` call.
    ///
    /// - Note: Set `RATEnablePrivacyControl` to `true` in Info.plist to enable granular control.
    var isPrivacyControlEnabled: Bool {
        guard let value = object(forInfoDictionaryKey: Keys.privacyControlEnabled) as? Bool else {
            return false
        }
        return value
    }
}

private extension String {
    func appendingPathComponent(_ string: String) -> String {
        return URL(fileURLWithPath: self).appendingPathComponent(string).path
    }
}
