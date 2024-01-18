import WebKit.WKHTTPCookieStore

protocol WKHTTPCookieStorable {
    func allCookies(_ completionHandler: @escaping ([HTTPCookie]) -> Void)
    func set(cookie: HTTPCookie, completionHandler: (() -> Void)?)
    func delete(cookie: HTTPCookie, completionHandler: (() -> Void)?)
}

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
