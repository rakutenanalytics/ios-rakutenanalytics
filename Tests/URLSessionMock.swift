import Foundation

class URLSessionMock: URLSession {

    typealias SessionTaskCompletion = (Data?, URLResponse?, Error?) -> Void

    static var swizzledMethods: (Method, Method)?
    private static var mockSessionLinks = [URLSession: WeakWrapper<URLSessionMock>]()

    private let originalInstance: URLSession?

    @objc var sentRequest: URLRequest?
    var httpResponse: HTTPURLResponse?
    var responseData: Data?
    var responseError: Error?
    var completionHandler: (() -> Void)?

    static func mock(originalInstance: URLSession) -> URLSessionMock {
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

    static func startMockingURLSession() {
        guard swizzledMethods == nil else {
            return
        }

        let originalMethod = class_getInstanceMethod(
            URLSession.self,
            #selector(URLSession().dataTask(with:completionHandler:)
                as (URLRequest, @escaping SessionTaskCompletion) -> URLSessionDataTask))!

        let dummyObject = URLSessionMock(originalInstance: URLSession())
        let swizzledMethod = class_getInstanceMethod(
            URLSessionMock.self,
            #selector(dummyObject.dataTask(with:completionHandler:)
                as (URLRequest, @escaping SessionTaskCompletion) -> URLSessionDataTask))!

        swizzledMethods = (originalMethod, swizzledMethod)
        method_exchangeImplementations(originalMethod, swizzledMethod)
    }

    static func stopMockingURLSession() {
        guard let swizzledMethods = swizzledMethods else {
            return
        }
        method_exchangeImplementations(swizzledMethods.0, swizzledMethods.1)
        self.swizzledMethods = nil
    }

    func decodeSentData<T: Decodable>(modelType: T.Type) -> T? {
        guard let httpBody = sentRequest?.httpBody else {
            return nil
        }
        return try? JSONDecoder().decode(modelType.self, from: httpBody)
    }

    override func dataTask(
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

        mockContainer.sentRequest = request
        completionHandler(mockContainer.responseData,
                          mockContainer.httpResponse,
                          mockContainer.responseError)
        mockContainer.completionHandler?()

        let dummyRequest = URLRequest(url: URL(string: "about:blank")!)
        // URLSessionDataTask object must be created by an URLSession object
        return originalSession.dataTask(with: dummyRequest)
    }
}
