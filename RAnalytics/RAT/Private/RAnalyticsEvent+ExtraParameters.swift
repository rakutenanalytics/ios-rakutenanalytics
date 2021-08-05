import Foundation

extension RAnalyticsEvent {

    // MARK: - Install

    var installParameters: [String: Any] {
        var extra = [String: Any]()

        guard let appAndSDKDict = CoreHelpers.applicationInfo,
              let appInfo = appAndSDKDict[RAnalyticsConstants.RAnalyticsAppInfoKey] as? [String: Any],
              let sdkInfo = appAndSDKDict[RAnalyticsConstants.RAnalyticsSDKInfoKey] as? [String: Any] else {
            return extra
        }

        let sdkComponents = sdkInfo.compactMap { "\($0.key)/\($0.value)" }

        if !sdkComponents.isEmpty {
            extra["sdk_info"] = sdkComponents.joined(separator: "; ")
        }

        if !appInfo.isEmpty,
           let data = try? JSONSerialization.data(withJSONObject: appInfo, options: JSONSerialization.WritingOptions(rawValue: 0)) {
            extra["app_info"] = String(data: data, encoding: .utf8)
        }

        return extra
    }

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
            extra["logout_method"] = result
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
        extra["push_notify_value"] = trackingIdentifier
        return extra
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
        var extra = [String: Any]()

        let source = parameters["source"] as? String
        if !source.isEmpty {
            extra["source"] = source
        }

        return extra
    }

    // MARK: - Credential Strategies

    var credentialStrategiesParameters: [String: Any] {
        var extra = [String: Any]()

        if let strategies = parameters["strategies"] as? [String: Any],
           !strategies.isEmpty {
            extra["strategies"] = strategies
        }

        return extra
    }
}
