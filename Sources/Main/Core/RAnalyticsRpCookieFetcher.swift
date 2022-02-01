import Foundation
#if canImport(RSDKUtils)
import RSDKUtils
#else // SPM version
import RSDKUtilsMain
#endif

@objc public protocol RAnalyticsRpCookieFetchable {
    var endpointURL: URL? { get set }
    func getRpCookieCompletionHandler(_ completionHandler: @escaping (HTTPCookie?, NSError?) -> Void)
    func getRpCookieFromCookieStorage() -> HTTPCookie?
}

@objc public final class RAnalyticsRpCookieFetcher: NSObject, EndpointSettable {
    /// The endpoint to fetch the Rp Cookie.
    @objc public var endpointURL: URL? {
        get {
            self._endpointURL
        }
        set {
            self._endpointURL = newValue
        }
    }

    @AtomicGetSet private var _endpointURL: URL?
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
        static let failureReason = "Invalid/NoCookie details available"
        static let unknown: NSError = {
            let userInfo = [NSLocalizedDescriptionKey: "Unknown Rp Cookie Error"]
            return NSError(domain: ErrorDomain.rpCookieFetcherErrorDomain, code: NSURLErrorUnknown, userInfo: userInfo)
        }()
        static let endpoint = NSError(domain: ErrorDomain.rpCookieFetcherErrorDomain,
                                      code: 0,
                                      userInfo: [NSLocalizedDescriptionKey: "The Rp Cookie Fetcher endpoint is not set."])
    }

    /// Reachability
    private let reachability: ReachabilityType?

    /// Create a new Rp Cookie Fetcher object.
    ///
    /// - Parameters:
    ///     - cookieStorage: Where the cookie will be set.
    ///
    /// - Returns: A newly-initialized Rp Cookie Fetcher or nil.
    @objc public convenience init?(cookieStorage: HTTPCookieStorage) {
        self.init(cookieStorage: cookieStorage,
                  bundle: Bundle.main,
                  session: URLSession.shared,
                  reachability: Reachability(hostname: ReachabilityConstants.host),
                  maximumTimeOut: Constants.timeOut)
    }

    /// Create a new Rp Cookie Fetcher object.
    ///
    /// - Parameters:
    ///     - cookieStorage: Where the cookie will be set.
    ///     - bundle: The bundle.
    ///     - session: The session.
    ///     - maximumTimeOut: The retry time out.
    ///
    /// - Returns: A newly-initialized Rp Cookie Fetcher or nil.
    init?(cookieStorage: HTTPCookieStorable,
          bundle: EnvironmentBundle,
          session: Sessionable,
          reachability: ReachabilityType?,
          maximumTimeOut: UInt) {
        guard let endpointAddress = bundle.endpointAddress else {
            ErrorRaiser.raise(.detailedError(domain: ErrorDomain.rpCookieFetcherErrorDomain,
                                             code: ErrorCode.rpCookieFetcherCreationFailed.rawValue,
                                             description: ErrorDescription.rpCookieFetcherCreationFailed,
                                             reason: ErrorReason.endpointMissing))
            return nil
        }
        _endpointURL = endpointAddress
        retryInterval = Constants.initialRetryInterval
        rpCookieRequestRetryCount = 0
        rpCookieQueue = DispatchQueue(label: "com.rakuten.tech.analytics.rpcookie")
        self.bundle = bundle
        self.cookieStorage = cookieStorage
        self.session = session
        self.maximumTimeOut = maximumTimeOut
        self.reachability = reachability

        super.init()
    }
}

// MARK: - Public API

extension RAnalyticsRpCookieFetcher: RAnalyticsRpCookieFetchable {
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
            getRpCookieFromRAT { result in
                switch result {
                case .success(let cookie):
                    completionHandler(cookie, nil)

                case .failure(let error):
                    let reason = "\(error.localizedDescription), \(String(describing: (error as NSError).localizedFailureReason))"
                    ErrorRaiser.raise(.detailedError(domain: ErrorDomain.rpCookieFetcherErrorDomain,
                                                     code: ErrorCode.getRpCookieFromRATFailed.rawValue,
                                                     description: ErrorDescription.getRpCookieFromRATFailed,
                                                     reason: reason))
                    completionHandler(nil, error as NSError)
                }
            }
            return
        }
        completionHandler(rpCookie, nil)
    }

    /// - Returns: A cached valid Rp cookie.
    @objc public func getRpCookieFromCookieStorage() -> HTTPCookie? {
        do {
            return try getRpCookie(from: cookieStorage)

        } catch {
            let reason = "\(error.localizedDescription), \(String(describing: (error as NSError).localizedFailureReason))"
            ErrorRaiser.raise(.detailedError(domain: ErrorDomain.rpCookieFetcherErrorDomain,
                                             code: ErrorCode.getRpCookieFromCookieStorageFailed.rawValue,
                                             description: ErrorDescription.rpCookieFetcherError,
                                             reason: reason))
            return nil
        }
    }
}

// MARK: - Get Rp Cookie

extension RAnalyticsRpCookieFetcher {
    /// Get the Rp Cookie from the HTTP URL response.
    ///
    /// - Parameter httpResponse: the HTTP URL response.
    ///
    /// - Returns: the HTTP Cookie
    ///
    /// - Throws: an error if the HTTP Cookie can't be retrieved in the HTTP URL response.
    private func getRpCookie(from httpResponse: HTTPURLResponse) throws -> HTTPCookie {
        guard let endpointURL = endpointURL else {
            throw RpCookieFetcherError.endpoint
        }
        let errorDescription = "Cannot get Rp cookie from the RAT Server HTTP Response - \(endpointURL.absoluteString)"

        guard let allHeaderFields = httpResponse.allHeaderFields as? [String: String],
              !allHeaderFields.isEmpty else {
            let userInfo = [NSLocalizedDescriptionKey: errorDescription,
                            NSLocalizedFailureReasonErrorKey: "The header fields are empty."]
            throw NSError(domain: ErrorDomain.rpCookieFetcherErrorDomain, code: 0, userInfo: userInfo)
        }

        let cookies = HTTPCookie.cookies(withResponseHeaderFields: allHeaderFields, for: endpointURL)
        let result = cookies.first { $0.name == Constants.rpName }

        guard let cookie = result else {
            let userInfo = [NSLocalizedDescriptionKey: errorDescription,
                            NSLocalizedFailureReasonErrorKey: "The Rp Cookie is not in the http response header fields."]
            throw NSError(domain: ErrorDomain.rpCookieFetcherErrorDomain, code: 0, userInfo: userInfo)
        }
        return cookie
    }

    /// Get the Rp Cookie from the cookie storage.
    ///
    /// - Parameter cookieStorage: the cookie storage.
    ///
    /// - Returns: the HTTP Cookie
    ///
    /// - Throws: an error if the HTTP Cookie can't be retrieved in the cookie storage.
    private func getRpCookie(from cookieStorage: HTTPCookieStorable) throws -> HTTPCookie {
        guard let endpointURL = endpointURL else {
            throw RpCookieFetcherError.endpoint
        }
        let cookies = cookieStorage.cookies(for: endpointURL)
        let rpCookie = cookies?.first(where: {
            if let expiresDate = $0.expiresDate,
               $0.name == Constants.rpName && expiresDate.timeIntervalSinceNow > 0 {
                return true
            }
            return false
        })
        guard let result = rpCookie else {
            let errorDescription = "Cannot get Rp cookie from the Cookie Storage - \(endpointURL.absoluteString)"
            let userInfo = [NSLocalizedDescriptionKey: errorDescription,
                            NSLocalizedFailureReasonErrorKey: RpCookieFetcherError.failureReason]
            throw NSError(domain: ErrorDomain.rpCookieFetcherErrorDomain, code: 0, userInfo: userInfo)
        }
        return result
    }
}

// MARK: - Request

extension RAnalyticsRpCookieFetcher {
    /// Get the Rp Cookie from the `endpointURL`.
    ///
    /// - Parameter completionHandler: the completion handler.
    private func getRpCookieFromRAT(_ completionHandler: @escaping (Result<HTTPCookie, Error>) -> Void) {
        guard self.reachability?.connection != .unavailable else {
            completionHandler(.failure(ErrorConstants.rpCookieCantBeFetchedError(reason: ErrorReason.connectionIsOffline)))
            return
        }

        guard let endpointURL = endpointURL else {
            completionHandler(.failure(RpCookieFetcherError.endpoint))
            return
        }
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
                            let errorDescription = "The Rp Cookie request response status code is \(statusCode) - \(endpointURL.absoluteString)"
                            let userInfo = [NSLocalizedDescriptionKey: errorDescription]
                            let statusCodeError = NSError(domain: ErrorDomain.rpCookieFetcherErrorDomain,
                                                          code: statusCode,
                                                          userInfo: userInfo)
                            completionHandler(.failure(statusCodeError))

                        } else {
                            completionHandler(.failure(RpCookieFetcherError.unknown))
                        }
                        return
                    }
                    self.getRpCookieFromRAT(completionHandler)
                }

            } else {
                self.rpCookieRequestRetryCount = 0

                if request.httpShouldHandleCookies {
                    do {
                        let retrievedCookie = try self.getRpCookie(from: self.cookieStorage)
                        completionHandler(.success(retrievedCookie))

                    } catch {
                        completionHandler(.failure(error))
                    }

                } else if let httpResponse = httpResponse {
                    do {
                        let retrievedCookie = try self.getRpCookie(from: httpResponse)
                        completionHandler(.success(retrievedCookie))

                    } catch {
                        completionHandler(.failure(error))
                    }

                } else {
                    let errorDescription = "Cannot get Rp cookie from the RAT server and from the Cookie Storage - \(endpointURL.absoluteString)"
                    let userInfo = [NSLocalizedDescriptionKey: errorDescription,
                                    NSLocalizedFailureReasonErrorKey: "httpShouldHandleCookies is false and httpResponse is nil."]
                    completionHandler(.failure(NSError(domain: ErrorDomain.rpCookieFetcherErrorDomain, code: 0, userInfo: userInfo)))
                }
            }

        }.resume()
    }
}

// MARK: - Retry

extension RAnalyticsRpCookieFetcher {
    /// This method is used to retry getting the Rp Cookie until a given `maximumTimeOut`.
    ///
    /// - Parameter completionHandler: the completion handler.
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

// MARK: - Internal API

extension RAnalyticsRpCookieFetcher {
    convenience init?(cookieStorage: HTTPCookieStorable) {
        self.init(cookieStorage: cookieStorage,
                  bundle: Bundle.main,
                  session: URLSession.shared,
                  reachability: Reachability(hostname: ReachabilityConstants.host),
                  maximumTimeOut: Constants.timeOut)
    }
}
