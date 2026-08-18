import Foundation

protocol WKHTTPCookieStorable {
    func allCookies(_ completionHandler: @escaping ([HTTPCookie]) -> Void)
    func set(cookie: HTTPCookie, completionHandler: (() -> Void)?)
    func delete(cookie: HTTPCookie, completionHandler: (() -> Void)?)
}

#if os(iOS)
import WebKit.WKHTTPCookieStore

extension WKHTTPCookieStore: WKHTTPCookieStorable {
    func allCookies(_ completionHandler: @escaping ([HTTPCookie]) -> Void) {
        // Note: getAllCookies crashes on background thread
        DispatchQueue.main.async { self.getAllCookies(completionHandler) }
    }

    func set(cookie: HTTPCookie, completionHandler: (() -> Void)?) {
        setCookie(cookie, completionHandler: completionHandler)
    }

    func delete(cookie: HTTPCookie, completionHandler: (() -> Void)? = nil) {
        delete(cookie, completionHandler: completionHandler)
    }
}
#endif

#if os(tvOS)

/// Stub used on tvOS where WebKit is unavailable.
final class NoOpWKHTTPCookieStore: WKHTTPCookieStorable {
    func allCookies(_ completionHandler: @escaping ([HTTPCookie]) -> Void) {
        completionHandler([])
    }

    func set(cookie: HTTPCookie, completionHandler: (() -> Void)?) {
        completionHandler?()
    }

    func delete(cookie: HTTPCookie, completionHandler: (() -> Void)?) {
        completionHandler?()
    }
}

#endif
