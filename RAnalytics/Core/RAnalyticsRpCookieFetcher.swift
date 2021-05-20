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
    private let maximumTimeOut: UInt
    private enum Constants {
        static let initialRetryInterval: TimeInterval = 10 // 10s as initial timeout request
        static let backOffMultiplier: UInt = 2 // Setting multiplier as 2
        static let timeOut: UInt = 600 // 10 mins as the time out
        static let rpName = "Rp"
    }
    private enum RpCookieFetcherError {
        static let domain = "com.rakuten.esd.sdk.analytics.error.rpcookie"
        static let unknown: NSError = {
            let userInfo = [NSLocalizedDescriptionKey: "Unknown RP Cookie Error"]
            return NSError(domain: domain, code: NSURLErrorUnknown, userInfo: userInfo)
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
        maximumTimeOut = 0
        super.init()
    }

    /// Create a new RP Cookie Fetcher object.
    ///
    /// - Parameters:
    ///     - cookieStorage: Where the cookie will be set.
    ///
    /// - Returns: A newly-initialized RP Cookie Fetcher or nil.
    @objc public convenience init?(cookieStorage: HTTPCookieStorage) {
        self.init(cookieStorage: cookieStorage,
                  bundle: Bundle.main,
                  session: URLSession.shared,
                  maximumTimeOut: Constants.timeOut)
    }

    /// Create a new RP Cookie Fetcher object.
    ///
    /// - Parameters:
    ///     - cookieStorage: Where the cookie will be set.
    ///     - bundle: The bundle.
    ///     - session: The session.
    ///     - maximumTimeOut: The retry time out.
    ///
    /// - Returns: A newly-initialized RP Cookie Fetcher or nil.
    init?(cookieStorage: HTTPCookieStorable,
          bundle: EnvironmentBundle,
          session: Sessionable,
          maximumTimeOut: UInt) {
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
        self.maximumTimeOut = maximumTimeOut
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
    ///     - completionHandler: Returns valid cookie or nil cookie and an error in case of failure.
    ///     `completionHandler` may be called on a background queue.
    @objc public func getRpCookieCompletionHandler(_ completionHandler: @escaping (HTTPCookie?, NSError?) -> Void) {
        guard let rpCookie = getRpCookieFromCookieStorage() else {
            getRpCookieFromRATCompletionHandler { result in
                switch result {
                case .success(let cookie):
                    completionHandler(cookie, nil)

                case .failure(let error):
                    completionHandler(nil, error as NSError)
                }
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

    private func getRpCookieFromRATCompletionHandler(_ completionHandler: @escaping (Result<HTTPCookie, Error>) -> Void) {
        var request = URLRequest(url: endpointURL)
        request.httpShouldHandleCookies = bundle.useDefaultSharedCookieStorage

        session.createDataTask(with: request) { _, response, error in
            let httpResponse = response as? HTTPURLResponse

            if error != nil || httpResponse?.statusCode != 200 {
                self.retryFetchingRpCookie { retry in
                    guard retry else {
                        self.rpCookieRequestRetryCount = 0

                        if let error = error {
                            completionHandler(.failure(error))

                        } else if let statusCode = httpResponse?.statusCode {
                            let userInfo = [NSLocalizedDescriptionKey: "The RP Cookie request response status code is \(statusCode)"]
                            let statusCodeError = NSError(domain: RpCookieFetcherError.domain,
                                                          code: statusCode,
                                                          userInfo: userInfo)
                            completionHandler(.failure(statusCodeError))

                        } else {
                            completionHandler(.failure(RpCookieFetcherError.unknown))
                        }
                        return
                    }
                    self.getRpCookieFromRATCompletionHandler(completionHandler)
                }

            } else {
                self.rpCookieRequestRetryCount = 0

                var userInfo: [String: String]?

                var retrievedCookie: HTTPCookie?
                if request.httpShouldHandleCookies {
                    retrievedCookie = self.getRpCookieFromCookieStorage()

                    if retrievedCookie == nil {
                        let errorDescription = "Cannot get Rp cookie from the Cookie Storage - \(self.endpointURL.absoluteString)"
                        userInfo = [NSLocalizedDescriptionKey: errorDescription,
                                    NSLocalizedFailureReasonErrorKey: "Invalid/NoCookie details available"]
                    }

                } else if let httpResponse = httpResponse {
                    retrievedCookie = self.getRpCookieFromHttpResponse(httpResponse)

                    if retrievedCookie == nil {
                        let errorDescription = "Cannot get Rp cookie from the RAT Server HTTP Response - \(self.endpointURL.absoluteString)"
                        userInfo = [NSLocalizedDescriptionKey: errorDescription,
                                    NSLocalizedFailureReasonErrorKey: "Invalid/NoCookie details available"]
                    }
                }

                guard let cookie = retrievedCookie else {
                    let rpCookieError = NSError(domain: RpCookieFetcherError.domain, code: 0, userInfo: userInfo)
                    completionHandler(.failure(rpCookieError))
                    return
                }
                completionHandler(.success(cookie))
            }

        }.resume()
    }

    private func retryFetchingRpCookie(_ completionHandler: @escaping (Bool) -> Void) {
        // If failed retry fetch
        rpCookieRequestRetryCount += 1

        let result = pow(Double(Constants.backOffMultiplier), Double(rpCookieRequestRetryCount))
        retryInterval = min(Double(maximumTimeOut), result)

        // Retry till the maximumTimeOut
        if UInt(retryInterval) < maximumTimeOut {
            let deadlineTime = DispatchTime.now() + .seconds(Int(retryInterval))
            rpCookieQueue.asyncAfter(deadline: deadlineTime) {
                completionHandler(true)
            }

        } else {
            completionHandler(false)
        }
    }
}
