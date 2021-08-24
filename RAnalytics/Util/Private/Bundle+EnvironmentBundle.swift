import Foundation
import UIKit

protocol EnvironmentBundle {
    var languageCode: Any? { get }
    var bundleIdentifier: String? { get }
    var useDefaultSharedCookieStorage: Bool { get }
    var accountIdentifier: Int64 { get }
    var applicationIdentifier: Int64 { get }
    var endpointAddress: URL? { get }
    var enableInternalSerialization: Bool { get }
    var disabledEventsAtBuildTime: [String]? { get }
    var duplicateAccounts: [RATAccount]? { get }
    static var assetsBundle: Bundle? { get }
    static var sdkComponentMap: NSDictionary? { get }
    func object(forInfoDictionaryKey key: String) -> Any?
}

extension Bundle: EnvironmentBundle {
    private enum Constants {
        static let defaultAccountIdentifier: Int64 = 477
        static let defaultApplicationIdentifier: Int64 = 1
    }

    var languageCode: Any? {
        if let preferredLocaleLanguage = NSLocale.preferredLanguages.first,
           let preferredLocalizationLanguage = preferredLocalizations.first {
            let localeLanguageCode = NSLocale(localeIdentifier: preferredLocaleLanguage).object(forKey: NSLocale.Key.languageCode)
            let bundleLanguageCode = NSLocale(localeIdentifier: preferredLocalizationLanguage).object(forKey: NSLocale.Key.languageCode)
            return bundleLanguageCode ?? localeLanguageCode
        }
        return nil
    }

    var useDefaultSharedCookieStorage: Bool {
        guard let result = object(forInfoDictionaryKey: "RATDisableSharedCookieStorage") as? NSNumber else {
            return true
        }
        return !result.boolValue
    }

    var accountIdentifier: Int64 {
        guard let plistObj = object(forInfoDictionaryKey: "RATAccountIdentifier") as? NSNumber else {
            return Constants.defaultAccountIdentifier
        }
        return plistObj.int64Value
    }

    var applicationIdentifier: Int64 {
        guard let plistObj = object(forInfoDictionaryKey: "RATAppIdentifier") as? NSNumber else {
            return Constants.defaultApplicationIdentifier
        }
        return plistObj.int64Value
    }

    var endpointAddress: URL? {
        guard let plistObj = object(forInfoDictionaryKey: "RATEndpoint") as? String,
              !plistObj.isEmpty,
              let userDefinedURL = URL(string: plistObj) else {
            #if PUBLIC_ANALYTICS_IOS_SDK
            #if DEBUG
            assertionFailure(ErrorMessage.endpoint)
            #endif
            return nil
            #else
            let prodURL = URL(string: "https://rat.rakuten.co.jp/")
            return prodURL
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

    static let assetsBundle: Bundle? = {
        guard let RAnalyticsManagerClass = NSClassFromString("RAnalyticsManager") else {
            return nil
        }
        /// Can't use [NSBundle mainBundle] here, because it returns the path to XCTest.framework
        /// when running unit tests. Also, if the SDK is being bundled as a dynamic framework,
        /// then it comes in its own bundle.
        let classBundle = Bundle(for: RAnalyticsManagerClass.self)
        guard var assetsPath = classBundle.resourcePath else {
            return nil
        }
        /// If RAnalyticsAssets.bundle cannot be found, we revert to using the class bundle
        assetsPath = assetsPath.appendingPathComponent("RAnalyticsAssets.bundle")
        guard let bundle = Bundle(path: assetsPath) else {
            return classBundle
        }
        return bundle
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
}

private extension String {
    func appendingPathComponent(_ string: String) -> String {
        return URL(fileURLWithPath: self).appendingPathComponent(string).path
    }
}
