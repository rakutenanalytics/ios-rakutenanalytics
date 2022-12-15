import WebKit

private enum WKWebViewKeys {
    static let userAgentKey = "userAgent"
}

extension WKWebView {
    /// - Returns: the current user agent of the `WKWebView` instance.
    public var rCurrentUserAgent: String? {
        value(forKey: WKWebViewKeys.userAgentKey) as? String
    }

    /// Generate an app user agent based on the bundle identifier and the bundle short version (`CFBundleShortVersionString`)
    /// - Parameters:
    ///     - bundle: the `Bundle` instance
    ///
    /// - Returns: the app user agent.
    func appUserAgent(for bundle: Bundleable) -> String? {
        guard let bundleIdentifier = bundle.bundleIdentifier,
            let version = bundle.shortVersion else {
            return nil
        }

        return "\(bundleIdentifier)/\(version)"
    }

    /// Add the app user agent suffix to the Web View's User Agent
    /// - Parameters:
    ///    - defaultWebViewUserAgent: the default `WKWebView` user agent.
    ///    - bundle: the `Bundle` instance
    ///
    /// - Returns: the Web View's User Agent by appending the app user agent suffix.
    func webViewUserAgent(defaultWebViewUserAgent: String,
                          for bundle: Bundleable) -> String? {
        guard let appUserAgent = appUserAgent(for: bundle) else {
            return nil
        }

        return "\(defaultWebViewUserAgent) \(appUserAgent)"
    }

    /// Enable or disable the app user agent setting in `WKWebView`.
    ///
    /// - Note: When enabled, the app user agent is appended to the default WKWebView's user agent.
    ///
    /// - Parameters:
    ///    - enabled: the app user agent is appended if enabled is `true`.
    ///    - customAppUserAgent: `customAppUserAgent` replaces the default app user agent if enabled is `true`.
    public func enableAppUserAgent(_ enabled: Bool,
                                   with customAppUserAgent: String? = nil,
                                   bundle: Bundleable = Bundle.main,
                                   manager: AnalyticsManageable = AnalyticsManager.shared()) {
        guard let defaultWebViewUserAgent = manager.defaultWebViewUserAgent else {
            customUserAgent = nil
            return
        }

        guard enabled else {
            customUserAgent = manager.defaultWebViewUserAgent
            return
        }

        guard let customAppUserAgent = customAppUserAgent else {
            customUserAgent = webViewUserAgent(defaultWebViewUserAgent: defaultWebViewUserAgent,
                                               for: bundle)
            return
        }
        customUserAgent = "\(defaultWebViewUserAgent) \(customAppUserAgent)"
    }
}
