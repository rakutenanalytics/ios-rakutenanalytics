import WebKit.WKHTTPCookieStore

@objc public protocol WKHTTPCookieStorable {
    func allCookies(_ completionHandler: @escaping ([HTTPCookie]) -> Void)
    func set(cookie: HTTPCookie, completionHandler: (() -> Void)?)
    func delete(cookie: HTTPCookie, completionHandler: (() -> Void)?)
}

@objc extension WKHTTPCookieStore: WKHTTPCookieStorable {
    public func allCookies(_ completionHandler: @escaping ([HTTPCookie]) -> Void) {
        getAllCookies(completionHandler)
    }
    public func set(cookie: HTTPCookie, completionHandler: (() -> Void)?) {
        setCookie(cookie, completionHandler: completionHandler)
    }
    public func delete(cookie: HTTPCookie, completionHandler: (() -> Void)? = nil) {
        delete(cookie, completionHandler: completionHandler)
    }
}
