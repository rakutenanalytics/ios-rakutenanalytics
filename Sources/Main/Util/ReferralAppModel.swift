import Foundation

// MARK: - Bundleable

public protocol Bundleable {
    var bundleIdentifier: String? { get }
    var shortVersion: String? { get }
    var accountIdentifier: Int64 { get }
    var applicationIdentifier: Int64 { get }
}

private struct IdentifierModel {
    let key: String
    let defaultValue: Int64
    let configWarning: String
    let typeWarning: String
}

private enum IdentifierResult {
    case warning(result: Int64, warning: String)
    case success(result: Int64)

    func toInt64() -> Int64 {
        switch self {
        case .warning(let result, let warning):
            RLogger.warning(message: warning)
            return result

        case .success(let result):
            return result
        }
    }
}

extension Bundle: Bundleable {
    /// Retrieve and return the short version string.
    ///
    /// - Returns: The short version string or nil.
    public var shortVersion: String? {
        infoDictionary?["CFBundleShortVersionString"] as? String
    }

    private func identifier(from model: IdentifierModel) -> IdentifierResult {
        guard let idNoType = object(forInfoDictionaryKey: model.key) else {
            return .warning(result: model.defaultValue, warning: model.configWarning)
        }

        switch idNoType {
        case let aValue as NSNumber:
            if CFGetTypeID(aValue) == CFBooleanGetTypeID() {
                return .warning(result: model.defaultValue, warning: model.typeWarning)
            }
            guard aValue.int64Value > 0 else {
                return .success(result: 0)
            }
            return .success(result: aValue.int64Value)

        case let aValue as String:
            guard let result = Int64(aValue) else {
                return .warning(result: model.defaultValue, warning: model.configWarning)
            }
            guard result > 0 else {
                return .success(result: 0)
            }
            return .warning(result: result, warning: model.typeWarning)

        default:
            return .warning(result: model.defaultValue, warning: model.typeWarning)
        }
    }

    public var accountIdentifier: Int64 {
        identifier(from: IdentifierModel(key: RATAccount.CodingKeys.accountId.rawValue,
                                         defaultValue: 0,
                                         configWarning: LogMessage.accountIdentifierConfigWarning,
                                         typeWarning: LogMessage.accountIdentifierTypeWarning)).toInt64()
    }

    public var applicationIdentifier: Int64 {
        identifier(from: IdentifierModel(key: RATAccount.CodingKeys.applicationId.rawValue,
                                         defaultValue: 1,
                                         configWarning: LogMessage.applicationIdentifierConfigWarning,
                                         typeWarning: LogMessage.applicationIdentifierTypeWarning)).toInt64()

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
    
    /// Constructs a URL Scheme for app-to-app referral tracking.
    ///
    /// - Parameters:
    ///   - appScheme: The app scheme name defined in `CFBundleURLSchemes` in the app's `Info.plist`.
    ///   - pathComponent: An optional path component to be appended to the app scheme. This can be used to specify a particular resource or endpoint within the domain. Example: `path/to/resource`.
    ///     If this parameter is `nil` or an empty string, no path component will be added to the URL.
    ///   - ref: The referral identifier to be included in the URL. If this parameter is `nil` or an empty string, the application bundle identifier will be added.
    ///
    /// - Returns: The URL Scheme for the app-to-app referral tracking, `nil` otherwise.
    public func urlScheme(appScheme: String, pathComponent: String? = nil, ref: String? = nil) -> URL? {
        guard !appScheme.isEmpty else {
            return nil
        }
        
        var components = URLComponents()
        components.scheme = appScheme
        components.host = ""
        
        return buildURLWithComponents(components: components, pathComponent: pathComponent, ref: ref)
    }
    
    /// Constructs a universal link for app-to-app referral tracking.
    ///
    /// - Parameters:
    ///   - domain: The domain name for the universal link.
    ///   - pathComponent: An optional path component to be appended to the domain. This can be used to specify a particular resource or endpoint within the domain. Example: `path/to/resource`.
    ///     If this parameter is `nil` or an empty string, no path component will be added to the URL.
    ///   - ref: The referral identifier to be included in the URL. If this parameter is `nil` or an empty string, the application bundle identifier will be added.
    ///
    /// - Returns: The universal link for the app-to-app referral tracking, `nil` otherwise.
    public func universalLink(domain: String, pathComponent: String? = nil, ref: String? = nil) -> URL? {
        guard !domain.isEmpty else {
            return nil
        }
        
        var components = URLComponents()
        components.scheme = "https"
        components.host = domain
        
        return buildURLWithComponents(components: components, pathComponent: pathComponent, ref: ref)
    }
}

extension ReferralAppModel {
    
    /// Constructs a URL from the given URL components, optional path component, and reference.
    /// - Parameters:
    ///   - urlComponents: The base URL components to configure.
    ///   - pathComponent: An optional path component to append to the URL.
    ///   - ref: An optional reference to include as a query item. If not provided, the bundle identifier will be used.
    /// - Returns: A configured URL or nil if the URL could not be constructed.
    private func buildURLWithComponents(components: URLComponents, pathComponent: String? = nil, ref: String? = nil) -> URL? {
        var configuredComponents = components
        
        if let pathComponent = pathComponent, !pathComponent.isEmpty {
            configuredComponents.path = "/\(pathComponent)"
        }
        
        var queryItems = [URLQueryItem]()
        
        if let ref = ref, !ref.isEmpty {
            queryItems.append(URLQueryItem(name: "ref", value: ref))
        } else {
            if let bundleIdentifier = Bundle.main.bundleIdentifier {
                queryItems.append(URLQueryItem(name: "ref", value: bundleIdentifier))
            }
        }
        
        let queryString = self.query
        if !queryString.isEmpty {
            let queryComponents = queryString.split(separator: "&")
            for queryComponent in queryComponents {
                let keyValue = queryComponent.split(separator: "=")
                if keyValue.count == 2 {
                    let name = String(keyValue[0])
                    let value = String(keyValue[1])
                    queryItems.append(URLQueryItem(name: name, value: value))
                }
            }
        }
        
        configuredComponents.queryItems = queryItems.isEmpty ? nil : queryItems
        
        return configuredComponents.url
    }
    
}
