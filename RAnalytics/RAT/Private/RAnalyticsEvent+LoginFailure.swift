import Foundation

extension RAnalyticsEvent {
    @objc public var loginFailureParameters: [String: Any] {
        var extra = [String: Any]()

        if let loginFailureType = parameters[LoginFailureKey.type] as? String,
           !loginFailureType.isEmpty {
            extra[LoginFailureKey.type] = loginFailureType
        }

        if let loginError = parameters[LoginFailureKey.raeError] as? String,
           !loginError.isEmpty {
            extra[LoginFailureKey.raeError] = loginError
        }

        if let loginFailureReason = parameters[LoginFailureKey.raeErrorMessage] as? String,
           !loginFailureReason.isEmpty {
            extra[LoginFailureKey.raeErrorMessage] = loginFailureReason
        }

        if let idsdkLoginError = parameters[LoginFailureKey.idsdkError] as? String,
           !idsdkLoginError.isEmpty {
            extra[LoginFailureKey.idsdkError] = idsdkLoginError
        }

        if let idsdkLoginFailureReason = parameters[LoginFailureKey.idsdkErrorMessage] as? String,
           !idsdkLoginFailureReason.isEmpty {
            extra[LoginFailureKey.idsdkErrorMessage] = idsdkLoginFailureReason
        }

        return extra
    }
}
