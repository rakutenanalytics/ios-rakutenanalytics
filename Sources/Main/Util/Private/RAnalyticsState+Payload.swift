import Foundation

extension RAnalyticsState {
    /// - Returns: the core payload for RAT trackers.
    ///
    /// - Note: this payload contains `app_ver`, `app_name`, `mos`, `ver` and `ts1`.
    var corePayload: [String: Any] {
        var dict = [String: Any]()
        dict[PayloadParameterKeys.Core.appVer] = currentVersion
        dict[PayloadParameterKeys.Core.appName] = CoreHelpers.Constants.applicationName
        dict[PayloadParameterKeys.Core.mos] = CoreHelpers.Constants.osVersion
        dict[PayloadParameterKeys.Core.ver] = CoreHelpers.Constants.sdkVersion
        dict[PayloadParameterKeys.Core.ts1] = Swift.max(0, round(NSDate().timeIntervalSince1970))
        return dict
    }
}
