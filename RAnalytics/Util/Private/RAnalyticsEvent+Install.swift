import Foundation

extension RAnalyticsEvent {
    // MARK: - Install

    var installParameters: [String: Any] {
        var extra = [String: Any]()

        guard let appAndSDKDict = CoreHelpers.applicationInfo else {
            return extra
        }

        if let sdkInfo = appAndSDKDict[RAnalyticsConstants.RAnalyticsSDKInfoKey] as? [String: Any],
           !sdkInfo.isEmpty {
            extra["sdk_info"] = sdkInfo
        }

        if let appInfo = appAndSDKDict[RAnalyticsConstants.RAnalyticsAppInfoKey] as? [String: Any],
           !appInfo.isEmpty,
           let data = try? JSONSerialization.data(withJSONObject: appInfo, options: JSONSerialization.WritingOptions(rawValue: 0)) {
            extra["app_info"] = String(data: data, encoding: .utf8)
        }

        return extra
    }
}
