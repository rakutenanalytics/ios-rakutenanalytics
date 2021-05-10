import Foundation
import RLogger

@objc public final class RAnalyticsRpCookieFetcher: NSObject, EndpointSettable {
    @objc public var endpointURL: URL
    private var retryInterval: TimeInterval
    private var rpCookieRequestRetryCount: UInt
    private let rpCookieQueue: DispatchQueue
    private let cookieStorage: HTTPCookieStorable
    private let session: Sessionable
    private let bundle: EnvironmentBundle
    private enum Constants {
        static let initialRetryInterval: TimeInterval = 10 // 10s as initial timeout request
        static let backOffMultiplier: UInt = 2 // Setting multiplier as 2
        static let maximumTimeOut: UInt = 600 // 10 mins as the time out
        static let rpName = "Rp"
    }
    private enum RpCookieFetcherError {
        static let rpCookie: NSError = {
            let userInfo = [NSLocalizedDescriptionKey: "Cannot get Rp cookie from RAT Server/CookieStorage",
                            NSLocalizedFailureReasonErrorKey: "Invalid/NoCookie details available"]
            return NSError(domain: NSURLErrorDomain, code: NSURLErrorUnknown, userInfo: userInfo)
        }()
    }

    @available(*, unavailable)
    override init() {
        endpointURL = URL(string: "")!
        retryInterval = 0
        rpCookieRequestRetryCount = 0
        rpCookieQueue = DispatchQueue(label: "")
        cookieStorage = HTTPCookieStorage()
        bundle = Bundle.main
        session = URLSession.shared
        super.init()
    }

    /// Create a new RP Cookie Fetcher object.
    ///
    /// - Parameters:
    ///     - cookieStorage: Where the cookie will be set.
    ///
    /// - Returns: A newly-initialized RP Cookie Fetcher or nil.
    @objc public convenience init?(cookieStorage: HTTPCookieStorage) {
        self.init(cookieStorage: cookieStorage, bundle: Bundle.main, session: URLSession.shared)
    }

    /// Create a new RP Cookie Fetcher object.
    ///
    /// - Parameters:
    ///     - cookieStorage: Where the cookie will be set.
    ///     - bundle: The bundle.
    ///     - session: The session.
    ///
    /// - Returns: A newly-initialized RP Cookie Fetcher or nil.
    init?(cookieStorage: HTTPCookieStorable, bundle: EnvironmentBundle, session: Sessionable) {
        guard let endpointAddress = bundle.endpointAddress else {
            return nil
        }
        endpointURL = endpointAddress
        retryInterval = Constants.initialRetryInterval
        rpCookieRequestRetryCount = 0
        rpCookieQueue = DispatchQueue(label: "com.rakuten.tech.analytics.rpcookie")
        self.bundle = bundle
        self.cookieStorage = cookieStorage
        self.session = session
        super.init()
    }
}

// MARK: - Public API

extension RAnalyticsRpCookieFetcher {
    /// Will pass valid Rp cookie to completionHandler as soon as it is available.
    ///
    /// If a valid cookie is cached it will be returned immediately. Otherwise a new cookie will be retrieved
    /// from RAT, which might take time or be delayed depending on network connectivity.
    ///
    /// - Parameters:
    ///     - completionHandler: Returns valid cookie or nil cookie and an error in case of failure
    @objc public func getRpCookieCompletionHandler(_ completionHandler: @escaping (HTTPCookie?, NSError?) -> Void) {
        guard let rpCookie = getRpCookieFromCookieStorage() else {
            getRpCookieFromRATCompletionHandler { cookie in
                completionHandler(cookie, cookie == nil ? RpCookieFetcherError.rpCookie : nil)
            }
            return
        }
        completionHandler(rpCookie, nil)
    }

    /// - Returns: A cached valid RP cookie.
    @objc public func getRpCookieFromCookieStorage() -> HTTPCookie? {
        let cookies = cookieStorage.cookies(for: endpointURL)
        let rpCookie = cookies?.first(where: {
            if let expiresDate = $0.expiresDate,
               $0.name == Constants.rpName && expiresDate.timeIntervalSinceNow > 0 {
                return true
            }
            return false
        })
        return rpCookie
    }
}

// MARK: - Utils

extension RAnalyticsRpCookieFetcher {
    private func getRpCookieFromHttpResponse(_ httpResponse: HTTPURLResponse) -> HTTPCookie? {
        guard let allHeaderFields = httpResponse.allHeaderFields as? [String: String] else {
            return nil
        }
        let cookies = HTTPCookie.cookies(withResponseHeaderFields: allHeaderFields, for: endpointURL)
        return cookies.first { $0.name == Constants.rpName }
    }

    private func getRpCookieFromRATCompletionHandler(_ completionHandler: @escaping (HTTPCookie?) -> Void) {
        var request = URLRequest(url: endpointURL)
        request.httpShouldHandleCookies = bundle.useDefaultSharedCookieStorage

        session.createDataTask(with: request) { _, response, error in
            let httpResponse = response as? HTTPURLResponse
            if error != nil || httpResponse?.statusCode != 200 {
                self.retryFetchingRpCookie()
            }
            self.rpCookieRequestRetryCount = 0

            var cookie: HTTPCookie?
            if request.httpShouldHandleCookies {
                cookie = self.getRpCookieFromCookieStorage()

            } else if let httpResponse = httpResponse {
                cookie = self.getRpCookieFromHttpResponse(httpResponse)
            }
            completionHandler(cookie)

        }.resume()
    }

    private func retryFetchingRpCookie() {
        // If failed retry fetch
        rpCookieRequestRetryCount += 1

        let result = pow(Double(Constants.backOffMultiplier), Double(rpCookieRequestRetryCount))
        retryInterval = min(Double(Constants.maximumTimeOut), result)

        // Retry till the maximumTimeOut
        if UInt(retryInterval) < Constants.maximumTimeOut {
            let deadlineTime = DispatchTime.now() + .seconds(Int(retryInterval))
            rpCookieQueue.asyncAfter(deadline: deadlineTime) {
                self.fetchRATRpCookie()
            }
        }
    }

    private func fetchRATRpCookie() {
        getRpCookieCompletionHandler { _, error in
            if let error = error {
                RLogger.error("%@", arguments: error)
            }
        }
    }
}
