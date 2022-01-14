import Foundation

protocol HTTPCookieStorable {
    func cookies(for url: URL) -> [HTTPCookie]?
}

extension HTTPCookieStorage: HTTPCookieStorable {}
