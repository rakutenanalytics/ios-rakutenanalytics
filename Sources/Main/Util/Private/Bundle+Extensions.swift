import Foundation
import UIKit

// MARK: - Version

extension Bundle {
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

// MARK: - Manual Initialization

extension Bundle {
    
    private enum Keys {
        static let manualInitializationEnabledKey = "RATEnableManualInitialization"
    }
    
    /// Indicates whether manual initialization is enabled.
    ///
    /// This property retrieves its value from the app's Info.plist using the key `manualInitializationEnabled`.
    /// If the key is not present or its value is not a boolean, the property returns `false`.
    ///
    /// - Returns: A boolean value indicating if manual initialization is enabled.
    var isManualInitializationEnabled: Bool {
        guard let value = object(forInfoDictionaryKey: Keys.manualInitializationEnabledKey) as? Bool else {
            return false
        }
        return value
    }
    
}
