import Foundation

@objc protocol HTTPCookieStorable {
    @objc(cookiesForURL:) func cookies(for URL: URL) -> [HTTPCookie]?
}

extension HTTPCookieStorage: HTTPCookieStorable {}
