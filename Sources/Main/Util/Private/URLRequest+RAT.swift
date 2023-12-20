import Foundation

private enum HeaderField: String {
    case contentType = "Content-Type"
    case contentLength = "Content-Length"
    case date = "Date"
}

extension URLRequest {

    /// Build a RAT http request
    ///
    /// - Parameters:
    ///   - url: RAT url endpoint
    ///   - body: body data
    ///   - environmentBundle: type to get bundle data from
    ///   - date: the date set in Date header field.
    ///   Default value: current date and time - https://developer.apple.com/documentation/foundation/date/1780470-init
    ///
    /// - Returns: url request
    init(url: URL,
         body: Data,
         environmentBundle: EnvironmentBundle = Bundle.main,
         at date: Date = Date()) {
        self.init(url: url, cachePolicy: .reloadIgnoringCacheData, timeoutInterval: 30)
        httpShouldHandleCookies = environmentBundle.useDefaultSharedCookieStorage

        /// For historical reasons we don't send the JSON as JSON but as non-urlEncoded x-www-form-urlencoded,
        /// passed as text/plain. The backend also doesn't accept a charset value (but assumes UTF-8).
        setValue("text/plain", forHTTPHeaderField: HeaderField.contentType.rawValue)

        httpBody = body
        httpMethod = "POST"

        /// Set the content length, as the backend needs it.
        let formatted = NSString(format: "%lu", body.count)
        setValue(formatted as String, forHTTPHeaderField: HeaderField.contentLength.rawValue)

        /// Set the date header
        let timestamp = DateFormatter.rfc1123DateFormatter.string(from: date)
        setValue(timestamp, forHTTPHeaderField: HeaderField.date.rawValue)
    }
}
