import Foundation

/// The User Agent Handler handles the creation of the RAT user agent.
@objc public final class UserAgentHandler: NSObject {
    private let bundle: EnvironmentBundle

    /// Creates a new instance of `UserAgentHandler`.
    ///
    /// - Parameters:
    ///     - bundle: the bundle.
    ///
    /// - Returns: a new instance of `UserAgentHandler`.
    @objc public init(bundle: EnvironmentBundle) {
        self.bundle = bundle
    }
}

extension UserAgentHandler {
    /// The user agent value for RAT.
    ///
    /// - Parameters:
    ///     - state: the state.
    ///
    /// - Returns: a user agent string of the form AppId/Version.
    @objc public func value(for state: RAnalyticsState?) -> String? {
        if let bundleIdentifier = bundle.bundleIdentifier,
           let currentVersion = state?.currentVersion {
            return "\(bundleIdentifier)/\(currentVersion)"

        } else {
            return nil
        }
    }
}
