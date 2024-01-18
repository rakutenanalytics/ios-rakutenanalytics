import Foundation

extension RAnalyticsLoginMethod {
    static func type(from loginMethod: String) -> RAnalyticsLoginMethod {
        let base = "\(RAnalyticsExternalCollector.Constants.notificationBaseName).login."
        switch loginMethod {
        case "\(base)password":
            return .passwordInput
        case "\(base)one_tap":
            return .oneTapLogin
        default:
            return .other
        }
    }
}
