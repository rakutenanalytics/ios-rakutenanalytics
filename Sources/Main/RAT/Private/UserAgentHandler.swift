import Foundation

protocol UserAgentHandleable {
    func value(for state: RAnalyticsState?) -> String?
}

/// The User Agent Handler handles the creation of the RAT user agent.
final class UserAgentHandler {
    private let bundle: EnvironmentBundle

    /// Creates a new instance of `UserAgentHandler`.
    ///
    /// - Parameters:
    ///     - bundle: the bundle.
    ///
    /// - Returns: a new instance of `UserAgentHandler`.
    init(bundle: EnvironmentBundle) {
        self.bundle = bundle
    }
}

extension UserAgentHandler: UserAgentHandleable {
    /// The user agent value for RAT.
    ///
    /// - Parameters:
    ///     - state: the state.
    ///
    /// - Returns: a user agent string of the form AppId/Version.
    func value(for state: RAnalyticsState?) -> String? {
        if let bundleIdentifier = bundle.bundleIdentifier,
           let currentVersion = state?.currentVersion {
            return "\(bundleIdentifier)/\(currentVersion)"

        } else {
            return nil
        }
    }
}
