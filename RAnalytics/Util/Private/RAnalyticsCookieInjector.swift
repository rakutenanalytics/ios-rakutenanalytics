import Foundation
import RLogger

/// A class that injects a cookie in the HTTP Cookie Store
/// @warning RAnalyticsCookieInjector is declared as public to be accessible from Objective-C
/// @warning RAnalyticsCookieInjector will have to be private when the callers are migrated to Swift
@objc public final class RAnalyticsCookieInjector: NSObject {
    private enum TrackingCookieConstants {
        static let name = "ra_uid"
        static let defaultDomain = ".rakuten.co.jp"
    }
    private let cookiesDeletionQueue = DispatchQueue(label: "com.analytics.cookies.deletion.queue", qos: .default)
    private let httpCookieStore: WKHTTPCookieStorable
    private let adIdentifierManager: AdvertisementIdentifiable

    /// Initialize RAnalyticsCookieInjector with a dependenciesFactory
    @objc public init(dependenciesContainer: SimpleDependenciesContainable) {
        self.httpCookieStore = dependenciesContainer.httpCookieStore
        self.adIdentifierManager = dependenciesContainer.adIdentifierManager
        super.init()
    }
}

// MARK: - Cookie Injection

extension RAnalyticsCookieInjector {
    /// Inject app-to-web tracking cookie
    ///
    /// @param domain  Domain to set on cookie, if nil default domain will be used
    /// @param deviceIdentifier Device identifier string
    ///
    /// completionHandler:  Injected cookie or nil if cookie cannot be created or injected
    @objc public func injectAppToWebTrackingCookie(domain: String?,
                                                   deviceIdentifier: String,
                                                   completionHandler: ((HTTPCookie?) -> Void)?) {
        guard !deviceIdentifier.isEmpty,
              let trackingCookieValue = trackingCookieValue(deviceIdentifier: deviceIdentifier),
              let trackingCookie = trackingCookie(domain: domain, value: trackingCookieValue) else {
            completionHandler?(nil)
            return
        }
        httpCookieStore.allCookies { (cookies) in
            self.deleteCookies(cookies, for: TrackingCookieConstants.name) {
                self.storeCookie(cookieToStore: trackingCookie) {
                    completionHandler?(trackingCookie)
                }
            }
        }
    }
}

// MARK: - Utils

private extension CharacterSet {
    static let allowedCookieCharacters: CharacterSet = {
        var allowedCharacters = CharacterSet.alphanumerics
        allowedCharacters.insert(charactersIn: "-._~/?")
        return allowedCharacters
    }()
}

extension RAnalyticsCookieInjector {
    private func trackingCookieValue(deviceIdentifier: String) -> String? {
        return String(format: "rat_uid=%@;a_uid=%@", deviceIdentifier, adIdentifierManager.advertisingIdentifierUUIDString)
            .addingPercentEncoding(withAllowedCharacters: CharacterSet.allowedCookieCharacters)
    }

    private func trackingCookie(domain: String?, value: String) -> HTTPCookie? {
        let domainNotOptional = domain ?? ""
        return HTTPCookie(properties: [.name: TrackingCookieConstants.name,
                                       .domain: domainNotOptional.isEmpty ? TrackingCookieConstants.defaultDomain : domainNotOptional,
                                       .value: value,
                                       .path: "/",
                                       .secure: true])
    }

    private func deleteCookies(_ cookies: [HTTPCookie], for name: String, completionHandler:@escaping () -> Void) {
        let cookiesToDelete = cookies.filter { $0.name == TrackingCookieConstants.name }
        guard !cookiesToDelete.isEmpty else {
            completionHandler()
            return
        }
        let group = DispatchGroup()
        cookiesToDelete.forEach { (cookie) in
            group.enter()
            httpCookieStore.delete(cookie: cookie) {
                RLogger.verbose("Delete cookie %@ on webview", arguments: cookie)
                group.leave()
            }
        }
        group.notify(queue: cookiesDeletionQueue) {
            DispatchQueue.main.async {
                completionHandler()
            }
        }
    }

    private func storeCookie(cookieToStore: HTTPCookie, completionHandler:@escaping () -> Void) {
        httpCookieStore.set(cookie: cookieToStore) {
            RLogger.verbose("Set cookie %@ on webview", arguments: cookieToStore)
            completionHandler()
        }
    }
}
