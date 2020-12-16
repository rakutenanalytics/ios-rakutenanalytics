@objc public extension NSURLRequest {

    /// Build a RAT http request
    /// - Parameters:
    ///   - url: RAT url endpoint
    ///   - body: body data
    /// - Returns: url request
    class func ratRequest(url: URL, body: Data) -> NSURLRequest {
        return URLRequest(url: url, body: body) as NSURLRequest
    }
}

fileprivate extension URLRequest {
    init(url: URL, body: Data) {
        self.init(url: url, cachePolicy: .reloadIgnoringCacheData, timeoutInterval: 30)
        httpShouldHandleCookies = Bundle.useDefaultSharedCookieStorage

        /// For historical reasons we don't send the JSON as JSON but as non-urlEncoded x-www-form-urlencoded,
        /// passed as text/plain. The backend also doesn't accept a charset value (but assumes UTF-8).
        setValue("text/plain", forHTTPHeaderField: "Content-Type")

        httpBody = body
        httpMethod = "POST"

        /// Set the content length, as the backend needs it.
        let formatted = NSString(format: "%lu", body.count)
        setValue(formatted as String, forHTTPHeaderField: "Content-Length")
    }
}
