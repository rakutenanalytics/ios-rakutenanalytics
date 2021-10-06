import Foundation

// MARK: - Bundleable

enum RATConstants {
    static let defaultAccountIdentifier: Int64 = 477
    static let defaultApplicationIdentifier: Int64 = 1
}

public protocol Bundleable {
    var bundleIdentifier: String? { get }
    var accountIdentifier: Int64 { get }
    var applicationIdentifier: Int64 { get }
}

extension Bundle: Bundleable {
    public var accountIdentifier: Int64 {
        guard let plistObj = object(forInfoDictionaryKey: "RATAccountIdentifier") as? NSNumber else {
            return RATConstants.defaultAccountIdentifier
        }
        return plistObj.int64Value
    }

    public var applicationIdentifier: Int64 {
        guard let plistObj = object(forInfoDictionaryKey: "RATAppIdentifier") as? NSNumber else {
            return RATConstants.defaultApplicationIdentifier
        }
        return plistObj.int64Value
    }
}

// MARK: - ReferralAppModel

/// This is the App-to-App Referral Tracking Model.
public struct ReferralAppModel: Hashable {
    /// The referral app's bundle identifier
    public let bundleIdentifier: String

    /// The referral app's RAT account identifier
    public let accountIdentifier: Int64

    /// The referral app's RAT application identifier
    public let applicationIdentifier: Int64

    /// The referral app's link
    public let link: String?

    /// The referral app's component
    public let component: String?

    /// The referral app's custom parameters
    public var customParameters: [String: String]?

    /// Create a new App-to-App Referral Tracking Model.
    ///
    /// - Parameters:
    ///     - link: the referral app's link.
    ///     - component: the referral app's component.
    ///     - customParameters: the referral app's custom parameters.
    ///     - bundle: the bundle used to retrieve the referral app's `bundle identifier`, the `RATAccountIdentifier` and the `RATAppIdentifier`.
    ///
    /// - Returns: A newly-initialized App-to-App Referral Tracking Model, `nil` otherwise if the bundle identifier is nil.
    ///
    /// - Example:
    ///
    /// 1) URL Scheme
    ///
    /// guard let  url = ReferralAppModel().urlScheme(appScheme: "app"), UIApplication.shared.canOpenURL(url) else {
    ///     return
    /// }
    /// UIApplication.shared.open(url, options: [:])
    ///
    /// 2) Universal Link
    ///
    /// guard let  url = ReferralAppModel().universalLink(domain: "domain.com"), UIApplication.shared.canOpenURL(url) else {
    ///     return
    /// }
    /// UIApplication.shared.open(url, options: [:])
    public init?(link: String? = nil,
                 component: String? = nil,
                 customParameters: [String: String]? = nil,
                 bundle: Bundleable = Bundle.main) {
        self.init(accountIdentifier: bundle.accountIdentifier,
                  applicationIdentifier: bundle.applicationIdentifier,
                  link: link,
                  component: component,
                  customParameters: customParameters,
                  bundle: bundle)
    }

    /// Create a new App-to-App Referral Tracking Model.
    ///
    /// - Parameters:
    ///     - accountIdentifier: the referral app's RAT account identifier.
    ///     - applicationIdentifier: the referral app's RAT account identifier.
    ///     - link: the referral app's link.
    ///     - component: the referral app's component.
    ///     - customParameters: the referral app's custom parameters.
    ///     - bundle: the bundle used to retrieve the referral app's `bundle identifier`, the `RATAccountIdentifier` and the `RATAppIdentifier`.
    ///
    /// - Returns: A newly-initialized App-to-App Referral Tracking Model, `nil` otherwise if the bundle identifier is nil.
    ///
    /// - Example:
    ///
    /// 1) URL Scheme
    ///
    /// guard let  url = ReferralAppModel(accountIdentifier: 1, applicationIdentifier: 2).urlScheme(appScheme: "app"), UIApplication.shared.canOpenURL(url) else {
    ///     return
    /// }
    /// UIApplication.shared.open(url, options: [:])
    ///
    /// 2) Universal Link
    ///
    /// guard let  url = ReferralAppModel(accountIdentifier: 1, applicationIdentifier: 2).universalLink(domain: "domain.com"), UIApplication.shared.canOpenURL(url) else {
    ///     return
    /// }
    /// UIApplication.shared.open(url, options: [:])
    public init?(accountIdentifier: Int64,
                 applicationIdentifier: Int64,
                 link: String? = nil,
                 component: String? = nil,
                 customParameters: [String: String]? = nil,
                 bundle: Bundleable = Bundle.main) {
        guard let bundleIdentifier = bundle.bundleIdentifier else {
            return nil
        }
        self.init(bundleIdentifier: bundleIdentifier,
                  accountIdentifier: accountIdentifier,
                  applicationIdentifier: applicationIdentifier,
                  link: link,
                  component: component,
                  customParameters: customParameters)
    }

    /// Create a new App-to-App Referral Tracking Model.
    ///
    /// - Parameters:
    ///     - bundleIdentifier: the referral app's bundle identifier.
    ///     - accountIdentifier: the referral app's RAT account identifier.
    ///     - applicationIdentifier: the referral app's RAT account identifier.
    ///     - link: the referral app's link.
    ///     - component: the referral app's component.
    ///     - customParameters: the referral app's custom parameters.
    ///
    /// - Returns: A newly-initialized App-to-App Referral Tracking Model.
    init(bundleIdentifier: String,
         accountIdentifier: Int64,
         applicationIdentifier: Int64,
         link: String?,
         component: String?,
         customParameters: [String: String]?) {
        self.bundleIdentifier = bundleIdentifier
        self.accountIdentifier = accountIdentifier
        self.applicationIdentifier = applicationIdentifier
        self.link = link
        self.component = component
        self.customParameters = customParameters
    }

    /// - Parameters:
    ///     - appScheme: the app scheme name defined in `CFBundleURLSchemes` in the app's `Info.plist`.
    ///
    /// - Returns the URL Scheme for the app-to-app referral tracking, `nil` otherwise.
    public func urlScheme(appScheme: String) -> URL? {
        guard !appScheme.isEmpty else {
            return nil
        }
        return URL(string: "\(appScheme)://?\(query)")
    }

    /// - Parameters:
    ///     - domain: the associated domain for the Universal Link. Example: `rakuten.co.jp`.
    ///
    /// - Returns the Universal Link for the app-to-app referral tracking, `nil` otherwise.
    public func universalLink(domain: String) -> URL? {
        guard !domain.isEmpty else {
            return nil
        }
        return URL(string: "https://\(domain)?ref=\(bundleIdentifier)&\(query)")
    }
}
