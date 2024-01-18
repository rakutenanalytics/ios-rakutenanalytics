import Foundation

extension RAnalyticsEvent {

    // MARK: - Login Failure

    var loginFailureParameters: [String: Any] {
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

    // MARK: - Logout

    var logoutParameters: [String: Any] {
        var extra = [String: Any]()

        let logoutMethod = parameters[RAnalyticsEvent.Parameter.logoutMethod] as? String
        let result = logoutMethod?.toLogoutString
        if !result.isEmpty {
            extra[CpParameterKeys.Logout.method] = result
        }

        return extra
    }

    // MARK: - Push

    var pushParameters: [String: Any]? {
        let trackingIdentifier = parameters[RAnalyticsEvent.Parameter.pushTrackingIdentifier] as? String
        guard !trackingIdentifier.isEmpty else {
            return nil
        }

        var extra = [String: Any]()
        extra[CpParameterKeys.Push.pushNotifyValue] = trackingIdentifier
        return extra
    }

    var pushRequestIdentifier: String? {
        parameters[RAnalyticsEvent.Parameter.pushRequestIdentifier] as? String
    }

    var pushConversionAction: String? {
        parameters[RAnalyticsEvent.Parameter.pushConversionAction] as? String
    }

    // MARK: - Discover

    var discoverParameters: [String: Any] {
        var extra = [String: Any]()

        let prApp = parameters["prApp"] as? String
        if !prApp.isEmpty {
            extra["prApp"] = prApp
        }

        let prStoreUrl = parameters["prStoreUrl"] as? String
        if !prStoreUrl.isEmpty {
            extra["prStoreUrl"] = prStoreUrl
        }

        return extra
    }

    // MARK: - SSO

    var ssoParameters: [String: Any] {
        var extra = [String: Any]()

        let source = parameters["source"] as? String
        if !source.isEmpty {
            extra["source"] = source
        }

        return extra
    }

    // MARK: - Login Credential Found

    var loginCredentialFoundParameters: [String: Any] {
        guard let source = parameters["source"] as? String, !source.isEmpty else {
            return [:]
        }
        return ["source": source]
    }

    // MARK: - Credential Strategies

    var credentialStrategiesParameters: [String: Any] {
        guard let strategies = parameters["strategies"] as? String, !strategies.isEmpty else {
            return [:]
        }
        return ["strategies": strategies]
    }
}
