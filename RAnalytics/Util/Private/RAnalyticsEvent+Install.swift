import Foundation

extension RAnalyticsEvent {
    // MARK: - Install

    var installParameters: [String: Any] {
        var extra = [String: Any]()
        if let appInfo = CoreHelpers.appInfo {
            extra[RAnalyticsConstants.appInfoKey] = appInfo
        }
        return extra
    }
}
