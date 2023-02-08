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

final class CoreHelpers {
    enum Constants {
        static let osVersion = String(format: "%@ %@", UIDevice.current.systemName, UIDevice.current.systemVersion)
        static let applicationName = Bundle.main.bundleIdentifier
        /// Current RAT SDK version
        static let sdkVersion = "9.9.0-snapshot"
    }

    static func getCollectedInfos(sdkComponentMap: NSDictionary? = Bundle.sdkComponentMap) -> [String: Any]? {
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
        Bundle.allFrameworks.forEach {
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

    static var appInfo: String? {
        guard let collectedInfos = CoreHelpers.getCollectedInfos(),
              let appInfo = collectedInfos[RAnalyticsConstants.rAnalyticsAppInfoKey] as? [String: Any],
              !appInfo.isEmpty,
              let data = try? JSONSerialization.data(withJSONObject: appInfo, options: JSONSerialization.WritingOptions(rawValue: 0)) else {
            return nil
        }
        return String(data: data, encoding: .utf8)
    }

    static var sdkDependencies: [String: Any]? {
        guard let collectedInfos = CoreHelpers.getCollectedInfos(),
              let sdkInfo = collectedInfos[RAnalyticsConstants.rAnalyticsSDKInfoKey] as? [String: Any],
              !sdkInfo.isEmpty else {
            return nil
        }
        return sdkInfo
    }
}
