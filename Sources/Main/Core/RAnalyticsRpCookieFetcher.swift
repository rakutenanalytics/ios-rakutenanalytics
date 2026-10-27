import Foundation
#if canImport(UIKit)
import UIKit
#endif

public protocol RAnalyticsRpCookieFetchable: AnyObject {
    var endpointURL: URL? { get set }
    func fetchRpCookie() async throws -> HTTPCookie
    func getRpCookieFromCookieStorage() -> HTTPCookie?
}

@objc public final class RAnalyticsRpCookieFetcher: NSObject, EndpointSettable {
    /// The endpoint to fetch the Rp Cookie.
    @objc public var endpointURL: URL? {
        get {
            self.safeEndpointURL
        }
        set {
            self.safeEndpointURL = newValue
        }
    }

    @AtomicGetSet private var safeEndpointURL: URL?
    /// Retry/backoff state is `@AtomicGetSet` so recursive async retry is safe across task hops.
    @AtomicGetSet private var retryInterval: TimeInterval
    @AtomicGetSet private var rpCookieRequestRetryCount: UInt
    private let cookieStorage: HTTPCookieStorable
    private let session: Sessionable
    private let bundle: EnvironmentBundle
    private let maximumTimeOut: UInt
    private let consentStore: DataCollectionConsentReadable
    private enum Constants {
        static let initialRetryInterval: TimeInterval = 10 // 10s as initial timeout request
        static let backOffMultiplier: UInt = 2 // Setting multiplier as 2
        static let timeOut: UInt = 600 // 10 mins as the time out
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
        static let consentDisabled = NSError(domain: ErrorDomain.rpCookieFetcherErrorDomain,
                                             code: ErrorCode.getRpCookieFromRATFailed.rawValue,
                                             userInfo: [NSLocalizedDescriptionKey: "User information data collection is disabled."])
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
                  reachability: Reachability(),
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
          maximumTimeOut: UInt,
          consentStore: DataCollectionConsentReadable = DataCollectionConsentStore.shared) {
        guard let endpointAddress = bundle.endpointAddress else {
            ErrorRaiser.raise(.detailedError(domain: ErrorDomain.rpCookieFetcherErrorDomain,
                                             code: ErrorCode.rpCookieFetcherCreationFailed.rawValue,
                                             description: ErrorDescription.rpCookieFetcherCreationFailed,
                                             reason: ErrorReason.endpointMissing))
            return nil
        }
        safeEndpointURL = endpointAddress
        retryInterval = Constants.initialRetryInterval
        rpCookieRequestRetryCount = 0
        self.bundle = bundle
        self.cookieStorage = cookieStorage
        self.session = session
        self.maximumTimeOut = maximumTimeOut
        self.reachability = reachability
        self.consentStore = consentStore

        super.init()
    }
}

// MARK: - Public API

extension RAnalyticsRpCookieFetcher: RAnalyticsRpCookieFetchable {
    /// Returns a valid Rp cookie as soon as it is available.
    ///
    /// If a valid cookie is cached it will be returned immediately. Otherwise a new cookie will be retrieved
    /// from RAT, which might take time or be delayed depending on network connectivity.
    public func fetchRpCookie() async throws -> HTTPCookie {
        guard consentStore.isEnabled(.userInformation) else {
            throw RpCookieFetcherError.consentDisabled
        }

        if let rpCookie = getRpCookieFromCookieStorage() {
            return rpCookie
        }

        do {
            return try await getRpCookieFromRAT()
        } catch {
            let reason = "\(error.localizedDescription), \(String(describing: (error as NSError).localizedFailureReason))"
            ErrorRaiser.raise(.detailedError(domain: ErrorDomain.rpCookieFetcherErrorDomain,
                                             code: ErrorCode.getRpCookieFromRATFailed.rawValue,
                                             description: ErrorDescription.getRpCookieFromRATFailed,
                                             reason: reason))
            throw error
        }
    }

    /// - Returns: A cached valid Rp cookie.
    @objc public func getRpCookieFromCookieStorage() -> HTTPCookie? {
        guard consentStore.isEnabled(.userInformation) else {
            return nil
        }
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
        let result = cookies.first { $0.name == RATConstants.RpCookie.cookieName }

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
               $0.name == RATConstants.RpCookie.cookieName && expiresDate.timeIntervalSinceNow > 0 {
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
    private func getRpCookieFromRAT() async throws -> HTTPCookie {
        try await waitForAvailableConnection()

        guard let endpointURL = endpointURL else {
            throw RpCookieFetcherError.endpoint
        }

        var request = URLRequest(url: endpointURL)
        request.httpShouldHandleCookies = bundle.useDefaultSharedCookieStorage

        let response: URLResponse?
        let fetchError: Error?
        do {
            let (_, sessionResponse) = try await self.session.data(for: request)
            response = sessionResponse
            fetchError = nil
        } catch {
            response = nil
            fetchError = error
        }
        return try await handleResponse(request: request, response: response, error: fetchError)
    }

    private func handleResponse(request: URLRequest, response: URLResponse?, error: Error?) async throws -> HTTPCookie {
        let httpResponse = response as? HTTPURLResponse

        if let error = error {
            return try await handleError(error: error, httpResponse: httpResponse)
        } else if httpResponse?.statusCode != 200 {
            return try await handleNon200Response(httpResponse: httpResponse)
        } else {
            return try handleSuccess(request: request, httpResponse: httpResponse)
        }
    }

    private func handleError(error: Error, httpResponse _: HTTPURLResponse?) async throws -> HTTPCookie {
        let shouldRetry = await retryFetchingRpCookie()
        guard shouldRetry else {
            self.rpCookieRequestRetryCount = 0
            throw error
        }
        return try await getRpCookieFromRAT()
    }

    private func handleNon200Response(httpResponse: HTTPURLResponse?) async throws -> HTTPCookie {
        let shouldRetry = await retryFetchingRpCookie()
        guard shouldRetry else {
            self.rpCookieRequestRetryCount = 0
            if let statusCode = httpResponse?.statusCode {
                let errorDescription = "The Rp Cookie request response status code is \(statusCode) - \(self.endpointURL?.absoluteString ?? "")"
                let userInfo = [NSLocalizedDescriptionKey: errorDescription]
                let statusCodeError = NSError(domain: ErrorDomain.rpCookieFetcherErrorDomain, code: statusCode, userInfo: userInfo)
                throw statusCodeError
            } else {
                throw RpCookieFetcherError.unknown
            }
        }
        return try await getRpCookieFromRAT()
    }

    private func handleSuccess(request: URLRequest, httpResponse: HTTPURLResponse?) throws -> HTTPCookie {
        self.rpCookieRequestRetryCount = 0

        if request.httpShouldHandleCookies {
            return try self.getRpCookie(from: self.cookieStorage)
        } else if let httpResponse = httpResponse {
            return try self.getRpCookie(from: httpResponse)
        } else {
            throw NSError(domain: ErrorDomain.rpCookieFetcherErrorDomain, code: 0, userInfo: [
                NSLocalizedDescriptionKey: "Cannot get Rp cookie from the RAT server and from the Cookie Storage - \(endpointURL?.absoluteString ?? "")",
                NSLocalizedFailureReasonErrorKey: "httpShouldHandleCookies is false and httpResponse is nil."
            ])
        }
    }
}

// MARK: - Reachability & lifecycle

extension RAnalyticsRpCookieFetcher {
    /// Waits until connectivity is available, re-checking on foreground resume, or times out.
    private func waitForAvailableConnection() async throws {
        guard let reachability else { return }
        if reachability.connection.isAvailable { return }

        let offlineError = ErrorConstants.rpCookieCantBeFetchedError(reason: ErrorReason.connectionIsOffline)
        try await Self.waitUntilFirstThrowing(
            timeoutNanoseconds: UInt64(maximumTimeOut) * 1_000_000_000,
            timeoutError: offlineError
        ) {
            for await connection in reachability.connectionUpdates where connection.isAvailable {
                return
            }
            throw offlineError
        } onForeground: {
            reachability.connection.isAvailable
        }
    }

    /// Returns when the first wait condition completes; cancels the rest.
    private static func waitUntilFirstThrowing(
        timeoutNanoseconds: UInt64,
        timeoutError: Error,
        connectivity waitForConnectivity: @escaping @Sendable () async throws -> Void,
        onForeground isReadyAfterForeground: @escaping @Sendable () -> Bool
    ) async throws {
        try await withThrowingTaskGroup(of: Void.self) { group in
            group.addTask { try await waitForConnectivity() }
            group.addTask {
                for await _ in didBecomeActiveNotificationStream() where isReadyAfterForeground() {
                    return
                }
            }
            group.addTask {
                try await Task.sleep(nanoseconds: timeoutNanoseconds)
                throw timeoutError
            }
            try await group.next()
            group.cancelAll()
        }
    }

    /// Returns the result of the first wait condition; cancels the rest.
    private static func waitUntilFirstBool(
        interval waitForInterval: @escaping @Sendable () async -> Bool,
        onForeground resumeOnForeground: @escaping @Sendable () -> Bool
    ) async -> Bool {
        await withTaskGroup(of: Bool.self) { group in
            group.addTask { await waitForInterval() }
            group.addTask {
                for await _ in didBecomeActiveNotificationStream() {
                    return resumeOnForeground()
                }
                return false
            }
            let result = await group.next() ?? false
            group.cancelAll()
            return result
        }
    }

    /// Yields whenever the app becomes active so fetches can resume after background suspension.
    private static func didBecomeActiveNotificationStream() -> AsyncStream<Void> {
        AsyncStream { continuation in
            #if canImport(UIKit)
            let observer = NotificationCenter.default.addObserver(
                forName: UIApplication.didBecomeActiveNotification,
                object: nil,
                queue: nil
            ) { _ in
                continuation.yield(())
            }
            continuation.onTermination = { _ in
                NotificationCenter.default.removeObserver(observer)
            }
            #else
            continuation.finish()
            #endif
        }
    }
}

// MARK: - Retry

extension RAnalyticsRpCookieFetcher {
    /// This method is used to retry getting the Rp Cookie until a given `maximumTimeOut`.
    private func retryFetchingRpCookie() async -> Bool {
        var retryCount: UInt = 0
        _rpCookieRequestRetryCount.mutate { count in
            count += 1
            retryCount = count
        }

        let result = pow(Double(Constants.backOffMultiplier), Double(retryCount))
        retryInterval = min(Double(maximumTimeOut), result)

        if UInt(retryInterval) < maximumTimeOut {
            let shouldContinue = await waitBeforeRetry(interval: retryInterval)
            guard shouldContinue else { return false }
            return true
        }

        return false
    }

    /// Sleeps for the retry interval but also resumes early when the app returns to foreground.
    private func waitBeforeRetry(interval: TimeInterval) async -> Bool {
        await Self.waitUntilFirstBool {
            do {
                try await Task.sleep(nanoseconds: UInt64(interval) * 1_000_000_000)
                return true
            } catch {
                return false
            }
        } onForeground: {
            true
        }
    }
}

// MARK: - Internal API

extension RAnalyticsRpCookieFetcher {
    convenience init?(cookieStorage: HTTPCookieStorable) {
        self.init(cookieStorage: cookieStorage,
                  bundle: Bundle.main,
                  session: URLSession.shared,
                  reachability: Reachability(),
                  maximumTimeOut: Constants.timeOut)
    }
}
