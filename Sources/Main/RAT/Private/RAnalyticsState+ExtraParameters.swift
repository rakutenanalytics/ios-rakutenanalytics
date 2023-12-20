import Foundation

extension RAnalyticsState {

    // MARK: - Session Start

    var sessionStartParameters: [String: Any] {
        var extra = [String: Any]()

        extra[CpParameterKeys.SessionStart.daysSinceFirstUse] = NSNumber(value: NSDate.daysPassedSinceDate(installLaunchDate))
        extra[CpParameterKeys.SessionStart.daysSinceLastUse] = NSNumber(value: NSDate.daysPassedSinceDate(lastLaunchDate))

        return extra
    }

    // MARK: - Application Update

    func applicationUpdateParameters(with appInfo: String?) -> [String: Any] {
        var extra = [String: Any]()

        if let appInfoNotOptional = appInfo {
            extra[RAnalyticsConstants.appInfoKey] = appInfoNotOptional
        }
        if !lastVersion.isEmpty {
            extra["previous_version"] = lastVersion
        }
        extra["launches_since_last_upgrade"] = NSNumber(value: lastVersionLaunches)
        extra["days_since_last_upgrade"] = NSNumber(value: NSDate.daysPassedSinceDate(lastUpdateDate))

        return extra
    }

    // MARK: - Login

    var loginParameters: [String: Any] {
        var extra = [String: Any]()

        let loginMethodString = loginMethod.toString
        if !loginMethodString.isEmpty {
            extra[CpParameterKeys.Login.method] = loginMethodString
        }

        return extra
    }
}
