import Foundation
import UIKit

@objc public class RAnalyticsConstants: NSObject {
    @objc public static let RAnalyticsAppInfoKey = "_RAnalyticsAppInfoKey"
    @objc public static let RAnalyticsSDKInfoKey = "_RAnalyticsSDKInfoKey"
}

@objc public class CoreHelpers: NSObject {
    private enum Constants {
        static let osVersion = String(format: "%@ %@", UIDevice.current.systemName, UIDevice.current.systemVersion)
        static let applicationName = Bundle.main.bundleIdentifier
    }

    @objc public static func sharedPayload(for state: AnalyticsManager.State?) -> [String: Any] {
        var dict = [String: Any]()
        if let state = state {
            dict["app_ver"] = state.currentVersion
        }
        dict["app_name"] = Constants.applicationName
        dict["mos"] = Constants.osVersion
        dict["ver"] = RAnalyticsVersion
        dict["ts1"] = Swift.max(0, round(NSDate().timeIntervalSince1970))
        return dict
    }

    @objc public static let applicationInfo: [String: Any]? = {
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
                  !identifier.hasPrefix("com.apple.") else {
                return
            }
            let version = $0.object(forInfoDictionaryKey: "CFBundleShortVersionString")
            if let sdkComponentMapIdentifier = Bundle.sdkComponentMap?.object(forKey: identifier) as? String {
                sdkInfo[sdkComponentMapIdentifier] = version
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

        dict[RAnalyticsConstants.RAnalyticsAppInfoKey] = appInfo
        dict[RAnalyticsConstants.RAnalyticsSDKInfoKey] = sdkInfo

        return dict
    }()
}
