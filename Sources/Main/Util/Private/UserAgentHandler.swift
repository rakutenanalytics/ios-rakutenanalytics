import Foundation
import UIKit

protocol UserAgentHandleable {
    func value(for state: RAnalyticsState?) -> String?
    func enrichedValue(for state: RAnalyticsState?) -> String?
}

protocol DeviceInfoProvidable {
    var systemName: String { get }
    var systemVersion: String { get }
    var modelIdentifier: String { get }
    var userInterfaceIdiom: UIUserInterfaceIdiom { get }
}

protocol LocaleProvidable {
    var preferredLanguages: [String] { get }
}

extension UIDevice: DeviceInfoProvidable {}

struct DefaultLocaleProvider: LocaleProvidable {
    var preferredLanguages: [String] {
        return NSLocale.preferredLanguages
    }
}

private struct UserAgentComponents {
    let appInfo: String
    let osInfo: String
    let deviceInfo: String
    let deviceType: String
    let language: String
    let analyticsInfo: String
}

/// The User Agent Handler handles the creation of the RAT user agent.
final class UserAgentHandler {
    private let bundle: EnvironmentBundle
    private let deviceInfoProvider: DeviceInfoProvidable
    private let localeProvider: LocaleProvidable

    /// Creates a new instance of `UserAgentHandler`.
    ///
    /// - Parameters:
    ///     - bundle: the bundle.
    ///     - deviceInfoProvider: provider for device information (defaults to UIDevice.current)
    ///     - localeProvider: provider for locale information (defaults to DefaultLocaleProvider())
    ///
    /// - Returns: a new instance of `UserAgentHandler`.
    init(bundle: EnvironmentBundle,
         deviceInfoProvider: DeviceInfoProvidable = UIDevice.current,
         localeProvider: LocaleProvidable = DefaultLocaleProvider()) {
        self.bundle = bundle
        self.deviceInfoProvider = deviceInfoProvider
        self.localeProvider = localeProvider
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

    /// The enriched user agent value for RAT.
    ///
    /// - Parameters:
    ///     - state: the state.
    ///
    /// - Returns: a user agent string in the format:
    /// `<application_name>/<application_version> (<operating_system_info>; <device_info>; <device_type>; <language>; Analytics/<sdk_version>)`
    func enrichedValue(for state: RAnalyticsState?) -> String? {
        guard let bundleIdentifier = bundle.bundleIdentifier,
              let currentVersion = state?.currentVersion else {
            return nil
        }

        let components = UserAgentComponents(
            appInfo: "\(bundleIdentifier)/\(currentVersion)",
            osInfo: "\(deviceInfoProvider.systemName) \(deviceInfoProvider.systemVersion)",
            deviceInfo: deviceInfoProvider.modelIdentifier,
            deviceType: getDeviceType(),
            language: getLanguageCode(),
            analyticsInfo: "Analytics/\(CoreHelpers.Constants.sdkVersion)"
        )

        return formatUserAgent(components)
    }
}

// MARK: - Private Methods
private extension UserAgentHandler {
    /// Formats the user agent string from components
    func formatUserAgent(_ components: UserAgentComponents) -> String {
        return "\(components.appInfo) (\(components.osInfo); \(components.deviceInfo); \(components.deviceType); \(components.language); \(components.analyticsInfo))"
    }

    /// Determines the device type based on the user interface idiom and platform.
    func getDeviceType() -> String {
        #if os(watchOS)
        return "watch"
        #else
        switch deviceInfoProvider.userInterfaceIdiom {
        case .pad:
            return "pad"
        case .phone:
            return "phone"
        case .unspecified:
            return "unspecified"
        case .carPlay:
            return "carPlay"
        case .tv:
            return "tv"
        case .mac:
            return "mac"
        case .vision:
            return "vision"
        @unknown default:
            return "phone"
        }
        #endif
    }

    /// Gets the language code using the locale provider.
    func getLanguageCode() -> String {
        if let appLanguage = bundle.preferredLocalization {
            return String(appLanguage.prefix(2))
        } else if let systemLanguage = localeProvider.preferredLanguages.first {
            return systemLanguage
        } else {
            return "ja_JP"
        }
    }
}
