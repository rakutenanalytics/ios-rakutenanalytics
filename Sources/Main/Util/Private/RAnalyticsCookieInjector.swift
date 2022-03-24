import Foundation
#if canImport(RSDKUtils)
import struct RSDKUtils.RLogger
#else // SPM version
import RLogger
#endif

/// A class that injects a cookie in the HTTP Cookie Store
final class RAnalyticsCookieInjector {
    private enum TrackingCookieConstants {
        static let name = "ra_uid"
        static let defaultDomain = ".rakuten.co.jp"
    }
    private let cookiesDeletionQueue = DispatchQueue(label: "com.analytics.cookies.deletion.queue", qos: .default)
    private let httpCookieStore: WKHTTPCookieStorable
    private let adIdentifierManager: AdvertisementIdentifiable

    /// Initialize RAnalyticsCookieInjector with a dependenciesFactory
    init(dependenciesContainer: SimpleDependenciesContainable) {
        self.httpCookieStore = dependenciesContainer.wkHttpCookieStore
        self.adIdentifierManager = dependenciesContainer.adIdentifierManager
    }
}

// MARK: - Cookie Injection

extension RAnalyticsCookieInjector {
    /// Inject app-to-web tracking cookie
    ///
    /// - Parameters:
    ///     - domain:  Domain to set on cookie, if nil default domain will be used
    ///     - deviceIdentifier: Device identifier string
    ///     - completionHandler: Injected cookie or nil if cookie cannot be created or injected
    func injectAppToWebTrackingCookie(domain: String?,
                                      deviceIdentifier: String,
                                      completionHandler: ((HTTPCookie?) -> Void)?) {
        guard !deviceIdentifier.isEmpty,
              let trackingCookieValue = trackingCookieValue(deviceIdentifier: deviceIdentifier),
              let trackingCookie = trackingCookie(domain: domain, value: trackingCookieValue) else {
            completionHandler?(nil)
            return
        }
        clearCookies {
            self.storeCookie(cookieToStore: trackingCookie) {
                completionHandler?(trackingCookie)
            }
        }
    }

    /// Delete all cookies in WKWebsiteDataStore
    func clearCookies(completion: @escaping () -> Void) {
        httpCookieStore.allCookies { self.deleteCookies($0, completionHandler: completion)}
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

    private func deleteCookies(_ cookies: [HTTPCookie], completionHandler:@escaping () -> Void) {
        let cookiesToDelete = cookies.filter { $0.name == TrackingCookieConstants.name }
        guard !cookiesToDelete.isEmpty else {
            completionHandler()
            return
        }
        let group = DispatchGroup()
        cookiesToDelete.forEach { (cookie) in
            group.enter()
            httpCookieStore.delete(cookie: cookie) {
                RLogger.verbose(message: "Delete cookie \(cookie) on webview")
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
            RLogger.verbose(message: "Set cookie \(cookieToStore) on webview")
            completionHandler()
        }
    }
}
