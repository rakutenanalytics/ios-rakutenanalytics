import Foundation
import UIKit

// MARK: - Version

extension Bundle {
    /// Retrieve and return the short version string.
    ///
    /// - Returns: The short version string or nil.
    var shortVersion: String? {
        infoDictionary?["CFBundleShortVersionString"] as? String
    }

    /// Retrieve and return the version.
    ///
    /// - Returns: The version or nil.
    var version: String? {
        infoDictionary?["CFBundleVersion"] as? String
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
        if schemes.contains(where: { $0 == "org-appextension-feature-password-management" }) {
            return canOpenURL
        } else {
            return false
        }
    }
}
