import Foundation

enum LoginType {
    case userIdentifier(String)
    case easyIdentifier(String)
    case unknown

    static func type(from notificationName: String, with anIdentifier: String?) -> LoginType {
        guard let anIdentifier = anIdentifier else {
            return .unknown
        }

        if notificationName.hasSuffix(RAnalyticsExternalCollector.Constants.idTokenEvent) {
            return .easyIdentifier(anIdentifier)

        } else {
            return .userIdentifier(anIdentifier)
        }
    }
}
