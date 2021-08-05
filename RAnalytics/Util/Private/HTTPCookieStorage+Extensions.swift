import Foundation

protocol HTTPCookieStorable {
    func cookies(for URL: URL) -> [HTTPCookie]?
}

extension HTTPCookieStorage: HTTPCookieStorable {}
