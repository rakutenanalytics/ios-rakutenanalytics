import Foundation

extension String {
    var toLogoutString: String? {
        switch self {
        case RAnalyticsEvent.LogoutMethod.local:
            return "single"

        case RAnalyticsEvent.LogoutMethod.global:
            return "all"

        default:
            return nil
        }
    }
}
