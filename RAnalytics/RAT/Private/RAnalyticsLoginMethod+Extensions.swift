import Foundation

extension RAnalyticsLoginMethod {
    var toString: String {
        switch self {
        case .passwordInput:
            return "password"

        case .oneTapLogin:
            return "one_tap_login"

        case .other:
            return ""
        }
    }
}
