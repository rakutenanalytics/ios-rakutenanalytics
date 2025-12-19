import Foundation
@testable import RakutenAnalytics

public final class URLSessionMock: URLSession, @unchecked Sendable {

    public typealias SessionTaskCompletion = (Data?, URLResponse?, Error?) -> Void

    private static var swizzledMethods: (Method, Method)?
    private static var swizzleRefCount: Int = 0
    private static let swizzleLock = DispatchQueue(label: "com.rakuten.analytics.URLSessionMock.swizzleLock")
    /// Global exclusive gate while the URLSession swizzle is active.
    /// Swizzling affects the entire process; without serialization, parallel tests can interfere by
    /// reconfiguring the shared mock (or toggling swizzling) while other tests are running.
    private static let mockingExclusiveSemaphore = DispatchSemaphore(value: 1)
    private static var mockSessionLinks = [URLSession: WeakWrapper<URLSessionMock>]()

    private let originalInstance: URLSession?

    @objc public var sentRequest: URLRequest?
    public var httpResponse: HTTPURLResponse?
    public var responseData: Data?
    public var responseError: Error?
    public var onCompletedTask: (() -> Void)?

    public static func mock(originalInstance: URLSession) -> URLSessionMock {
        if let existingMock = URLSessionMock.mockSessionLinks[originalInstance]?.value {
            return existingMock
        } else {
            let newMock = URLSessionMock(originalInstance: originalInstance)
            URLSessionMock.mockSessionLinks[originalInstance] = WeakWrapper(value: newMock)
            return newMock
        }
    }

    private init(originalInstance: URLSession) {
        self.originalInstance = originalInstance
        super.init()
    }

    public static func startMockingURLSession() {
        swizzleLock.sync {
            if swizzleRefCount == 0 {
                // Block other tests from entering a swizzled environment concurrently.
                mockingExclusiveSemaphore.wait()

                let originalMethod = class_getInstanceMethod(
                    URLSession.self,
                    #selector(URLSession(configuration: .default).dataTask(with:completionHandler:)
                        as (URLRequest, @escaping SessionTaskCompletion) -> URLSessionDataTask))!

                let dummyObject = URLSessionMock(originalInstance: URLSession(configuration: .default))
                let swizzledMethod = class_getInstanceMethod(
                    URLSessionMock.self,
                    #selector(dummyObject.dataTask(with:completionHandler:)
                        as (URLRequest, @escaping SessionTaskCompletion) -> URLSessionDataTask))!

                swizzledMethods = (originalMethod, swizzledMethod)
                method_exchangeImplementations(originalMethod, swizzledMethod)
            }
            swizzleRefCount += 1
        }
    }

    public static func stopMockingURLSession() {
        swizzleLock.sync {
            guard swizzleRefCount > 0 else {
                return
            }
            swizzleRefCount -= 1
            guard swizzleRefCount == 0, let swizzledMethods = swizzledMethods else {
                return
            }
            method_exchangeImplementations(swizzledMethods.0, swizzledMethods.1)
            self.swizzledMethods = nil

            // Allow other tests to enter.
            mockingExclusiveSemaphore.signal()
        }
    }

    public func decodeSentData<T: Decodable>(modelType: T.Type) -> T? {
        guard let httpBody = sentRequest?.httpBody else {
            return nil
        }
        return try? JSONDecoder().decode(modelType.self, from: httpBody)
    }

    public func decodeQueryItems<T: Decodable>(modelType: T.Type) -> T? {
        guard let url = sentRequest?.url,
              let urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: true),
              let queryItems = urlComponents.queryItems else {
            return nil
        }
        let array = queryItems.map { item -> String? in
            guard let value = item.value else {
                return nil
            }
            if let boolValue = Bool(value) {
                return "\"\(item.name)\": \(boolValue)"
            }
            if let intValue = Int(value) {
                return "\"\(item.name)\": \(intValue)"
            }
            return "\"\(item.name)\": \"\(value)\""
        }.compactMap { $0 }
        guard let jsonData = "{\(array.joined(separator: ","))}".data(using: .utf8) else {
            return nil
        }
        return try? JSONDecoder().decode(modelType.self, from: jsonData)
    }

    public override func dataTask(
        with request: URLRequest,
        completionHandler: @escaping SessionTaskCompletion) -> URLSessionDataTask {

        let mockedSession: URLSessionMock?
        if self.responds(to: #selector(getter: sentRequest)) {
            mockedSession = self // not swizzled
        } else {
            mockedSession = URLSessionMock.mockSessionLinks[self]?.value
        }

        let originalSession = mockedSession?.originalInstance ?? URLSession.shared
        guard let mockContainer = mockedSession else {
            return originalSession.dataTask(with: request)
        }

        // Cookies handling
        if let url = request.url,
           let header = mockContainer.httpResponse?.allHeaderFields as? [String: String] {
            let cookies = HTTPCookie.cookies(withResponseHeaderFields: header, for: url)
            HTTPCookieStorage.shared.setCookies(cookies, for: url, mainDocumentURL: nil)
        }

        mockContainer.sentRequest = request
        completionHandler(mockContainer.responseData,
                          mockContainer.httpResponse,
                          mockContainer.responseError)
        mockContainer.onCompletedTask?()

        let dummyRequest = URLRequest(url: URL(string: "about:blank")!)
        // URLSessionDataTask object must be created by an URLSession object
        return originalSession.dataTask(with: dummyRequest)
    }
}
