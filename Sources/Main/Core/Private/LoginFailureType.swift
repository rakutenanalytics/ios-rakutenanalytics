import Foundation

enum LoginFailureType {
    case unknown
    case userIdentifier(dictionary: [String: Any])
    case easyIdentifier(error: Error)

    static func type(from notificationName: String, with errorContainer: Any?) -> LoginFailureType {
        guard notificationName.hasPrefix("\(RAnalyticsExternalCollector.Constants.notificationBaseName).login.failure") else {
            return .unknown
        }

        switch notificationName {
        case "\(RAnalyticsExternalCollector.Constants.notificationBaseName).login.failure":
            if let params = errorContainer as? [String: Any] {
                return .userIdentifier(dictionary: params)
            }

        case "\(RAnalyticsExternalCollector.Constants.notificationBaseName).login.failure.\(RAnalyticsExternalCollector.Constants.idTokenEvent)":
            if let error = errorContainer as? Error {
                return .easyIdentifier(error: error)
            }

        default: ()
        }
        return .unknown
    }
}
