import Foundation

// MARK: - Version

extension Bundle {
    /// Retrieve and return the short version string.
    ///
    /// - Returns: The short version string or nil.
    static var shortVersion: String? {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
    }
}

// MARK: - Password Extension

extension Bundle {
    /// Return the availability of password extension
    ///
    /// - Returns: A boolean.
    static var isPasswordExtensionAvailable: Bool {
        guard NSClassFromString("NSExtensionItem") != nil,
              let url = URL(string: "org-appextension-feature-password-management://"),
              let canOpenURL = UIApplication.RAnalyticsSharedApplication?.canOpenURL(url),
              let schemes = Bundle.main.object(forInfoDictionaryKey: "LSApplicationQueriesSchemes") as? [String] else {
            return false
        }
        // There must be only one result for "org-appextension-feature-password-management" scheme
        let result = schemes.first { $0 == "org-appextension-feature-password-management" }
        return result != nil ? canOpenURL : false
    }
}
