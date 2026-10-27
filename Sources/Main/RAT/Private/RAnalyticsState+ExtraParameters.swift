import Foundation

extension RAnalyticsState {

    // MARK: - Session Start

    var sessionStartParameters: [String: Any] {
        var extra = [String: Any]()

        extra[PayloadParameterKeys.Cp.daysSinceFirstUse] = NSNumber(value: NSDate.daysPassedSinceDate(installLaunchDate))
        extra[PayloadParameterKeys.Cp.daysSinceLastUse] = NSNumber(value: NSDate.daysPassedSinceDate(lastLaunchDate))

        return extra
    }

    // MARK: - Application Update

    func applicationUpdateParameters(with appInfo: String?) -> [String: Any] {
        var extra = [String: Any]()

        if let appInfoNotOptional = appInfo {
            extra[RAnalyticsConstants.appInfoKey] = appInfoNotOptional
        }
        if !lastVersion.isEmpty {
            extra[PayloadParameterKeys.Cp.previousVersion] = lastVersion
        }
        extra[PayloadParameterKeys.Cp.launchesSinceLastUpgrade] = NSNumber(value: lastVersionLaunches)
        extra[PayloadParameterKeys.Cp.daysSinceLastUpgrade] = NSNumber(value: NSDate.daysPassedSinceDate(lastUpdateDate))

        return extra
    }

    // MARK: - Login

    var loginParameters: [String: Any] {
        var extra = [String: Any]()

        let loginMethodString = loginMethod.toString
        if !loginMethodString.isEmpty {
            extra[PayloadParameterKeys.Cp.loginMethod] = loginMethodString
        }

        return extra
    }
}
