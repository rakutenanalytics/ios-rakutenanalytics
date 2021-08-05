import Foundation

extension RAnalyticsState {

    // MARK: - Session Start

    var sessionStartParameters: [String: Any] {
        var extra = [String: Any]()

        extra["days_since_first_use"] = NSNumber(value: NSDate.daysPassedSinceDate(installLaunchDate))
        extra["days_since_last_use"] = NSNumber(value: NSDate.daysPassedSinceDate(lastLaunchDate))

        return extra
    }

    // MARK: - Application Update

    var applicationUpdateParameters: [String: Any] {
        var extra = [String: Any]()

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
            extra["login_method"] = loginMethodString
        }

        return extra
    }
}
