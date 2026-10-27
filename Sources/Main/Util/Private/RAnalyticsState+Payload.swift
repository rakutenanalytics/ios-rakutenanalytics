import Foundation

extension RAnalyticsState {
    /// Fields collected regardless of device-information consent (app version, name, SDK version, ordering timestamp).
    var alwaysCollectedCorePayload: [String: Any] {
        var dict = [String: Any]()
        dict[PayloadParameterKeys.appVer] = currentVersion
        dict[PayloadParameterKeys.appName] = CoreHelpers.Constants.applicationName
        dict[PayloadParameterKeys.ver] = CoreHelpers.Constants.sdkVersion
        dict[PayloadParameterKeys.ts1] = Swift.max(0, round(NSDate().timeIntervalSince1970))
        return dict
    }

    /// OS version (`mos`), included only when device-information collection is allowed.
    var deviceInformationMosPayload: [String: Any] {
        [PayloadParameterKeys.mos: CoreHelpers.Constants.osVersion]
    }
}
