import Foundation

extension RAnalyticsEvent {
    // MARK: - Install

    func installParameters(with appInfo: String?) -> [String: Any] {
        var extra = [String: Any]()
        if let appInfoNotOptional = appInfo {
            extra[RAnalyticsConstants.appInfoKey] = appInfoNotOptional
        }
        return extra
    }
}
