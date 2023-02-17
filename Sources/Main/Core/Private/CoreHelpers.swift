import Foundation
import UIKit

enum RAnalyticsConstants {
    static let rAnalyticsAppInfoKey = "_RAnalyticsAppInfoKey"
    static let rAnalyticsSDKInfoKey = "_RAnalyticsSDKInfoKey"
    static let appInfoKey = "app_info"
    static let sdkDependenciesPrefixKey = "rsdks"
}

enum RAnalyticsFrameworkIdentifiers {
    static let appleIdentifier = "com.apple"
    static let analyticsIdentifier = "org.cocoapods.RAnalytics"
    static let analyticsPublicFrameworkIdentifier = "com.rakuten.RAnalytics"
    static let sdkUtilsIdentifier = "org.cocoapods.RSDKUtils"
}

enum RModulesListKeys {
    static let analyticsValue = "analytics"
}

/// - Note: `sdkVersion`'s value is updated by `bundle exec fastlane ios commit_sdk_ver_bump version:...`
final class CoreHelpers {
    enum Constants {
        static let osVersion = String(format: "%@ %@", UIDevice.current.systemName, UIDevice.current.systemVersion)
        static let applicationName = Bundle.main.bundleIdentifier
        /// Current RAT SDK version
        static let sdkVersion = "9.9.0-snapshot"
    }
}

protocol CoreInfosCollectable {
    func getCollectedInfos(sdkComponentMap: NSDictionary?, allFrameworks: [EnvironmentBundle]) -> [String: Any]?
    var appInfo: String? { get }
    var sdkDependencies: [String: Any]? { get }
}

struct CoreInfosCollector: CoreInfosCollectable {
    /// Collects application and SDKs information.
    ///
    /// - Parameters:
    ///    - sdkComponentMap: a dictionary of SDKs (defined in `RModulesList.plist`).
    ///    Example:
    ///    ["org.cocoapods.RInAppMessaging": "inappmessaging", "org.cocoapods.RPushPNP": "pushpnp"]
    ///
    ///    - allFrameworks: an array of `Bundle` where each instance defines a framework.
    ///
    /// - returns: a dictionary of collected informations containing:
    ///     - a dictionary of app informations entries (`xcode`, `sdk`, `frameworks`, `deployment_target`) set for the key `_RAnalyticsAppInfoKey`
    ///     - a dictionary of loaded frameworks defined in `RModulesList.plist` set for the key `_RAnalyticsSDKInfoKey`
    func getCollectedInfos(sdkComponentMap: NSDictionary? = Bundle.sdkComponentMap,
                           allFrameworks: [EnvironmentBundle] = Bundle.allFrameworks) -> [String: Any]? {
        var dict = [String: Any]()

        // Collect build environment (Xcode version and build SDK)
        let info = Bundle.main.infoDictionary
        var xcodeVersion = info?["DTXcode"] as? String

        if let xcodeBuild = info?["DTXcodeBuild"] as? String {
            // The legacy code doesn't check if xcodeVersion is nil. To be fixed?
            xcodeVersion = "\(xcodeVersion ?? "").\(xcodeBuild)"
        }

        var buildSDK = info?["DTSDKName"] as? String
        if buildSDK == nil {
            buildSDK = info?["DTPlatformName"] as? String
            if let version = info?["DTPlatformVersion"] as? String {
                buildSDK = "\(buildSDK ?? "")\(version)"
            }
        }

        // Collect information on frameworks shipping with the app
        var sdkInfo = [String: Any]()
        var otherFrameworks = [String: Any]()
        allFrameworks.forEach {
            guard let identifier = $0.bundleIdentifier,
                  !identifier.hasPrefix(RAnalyticsFrameworkIdentifiers.appleIdentifier),
                  !identifier.hasSuffix(RAnalyticsFrameworkIdentifiers.analyticsIdentifier),
                  !identifier.hasSuffix(RAnalyticsFrameworkIdentifiers.analyticsPublicFrameworkIdentifier),
                  !identifier.hasSuffix(RAnalyticsFrameworkIdentifiers.sdkUtilsIdentifier) else {
                return
            }
            let version = $0.object(forInfoDictionaryKey: "CFBundleShortVersionString")
            if let sdkComponentMapIdentifier = sdkComponentMap?.object(forKey: identifier) as? String {
                let sdkDependencyComponentIdentifier = "\(RAnalyticsConstants.sdkDependenciesPrefixKey)_\(sdkComponentMapIdentifier)"
                sdkInfo[sdkDependencyComponentIdentifier] = version
            } else {
                otherFrameworks[identifier] = version
            }
        }

        // App Info
        var appInfo = [String: Any]()
        if let xcodeVersion = xcodeVersion, !xcodeVersion.isEmpty {
            appInfo["xcode"] = xcodeVersion
        }
        if let buildSDK = buildSDK, !buildSDK.isEmpty {
            appInfo["sdk"] = buildSDK
        }
        if !otherFrameworks.isEmpty {
            appInfo["frameworks"] = otherFrameworks
        }
        if let minimumOSVersion = info?["MinimumOSVersion"] {
            appInfo["deployment_target"] = minimumOSVersion
        }

        dict[RAnalyticsConstants.rAnalyticsAppInfoKey] = appInfo
        dict[RAnalyticsConstants.rAnalyticsSDKInfoKey] = sdkInfo

        return dict
    }

    var appInfo: String? {
        guard let collectedInfos = getCollectedInfos(),
              let appInfo = collectedInfos[RAnalyticsConstants.rAnalyticsAppInfoKey] as? [String: Any],
              !appInfo.isEmpty,
              let data = try? JSONSerialization.data(withJSONObject: appInfo, options: JSONSerialization.WritingOptions(rawValue: 0)) else {
            return nil
        }
        return String(data: data, encoding: .utf8)
    }

    var sdkDependencies: [String: Any]? {
        guard let collectedInfos = getCollectedInfos(),
              let sdkInfo = collectedInfos[RAnalyticsConstants.rAnalyticsSDKInfoKey] as? [String: Any],
              !sdkInfo.isEmpty else {
            return nil
        }
        return sdkInfo
    }
}
