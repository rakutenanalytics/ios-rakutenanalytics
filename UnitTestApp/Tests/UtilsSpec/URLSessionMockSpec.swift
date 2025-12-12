import Foundation
import Testing
@testable import RakutenAnalytics
#if canImport(RAnalyticsTestHelpers)
import RAnalyticsTestHelpers
#endif

@Suite("URLSessionMock")
struct URLSessionMockSpec {
    
    func createSessionAndMock() -> (originalSession: URLSession, sessionMock: URLSessionMock) {
        let originalSession = URLSession(configuration: .ephemeral)
        let sessionMock = URLSessionMock.mock(originalInstance: originalSession)
        return (originalSession, sessionMock)
    }
    
    @Test("should return the same mock instance for the same url session")
    func testReturnsSameMockInstance() {
        let (originalSession, sessionMock) = createSessionAndMock()
        #expect(URLSessionMock.mock(originalInstance: originalSession) === sessionMock)
    }
    
    @Test("should use originalSession if startMockingURLSession() was not called")
    func testUsesOriginalSessionWhenNotMocking() async throws {
        let (originalSession, sessionMock) = createSessionAndMock()
        
        sessionMock.httpResponse = HTTPURLResponse(
            url: URL(string: "some.url")!,
            statusCode: 500,
            httpVersion: nil,
            headerFields: nil)
        
        try await withCheckedThrowingContinuation { continuation in
            originalSession.dataTask(with: URLRequest(url: URL(string: "about:blank")!)) { _, response, _ in
                #expect(response?.url?.absoluteString == "about:blank")
                #expect(response is HTTPURLResponse == false)
                continuation.resume()
            }.resume()
        }
        
        #expect(sessionMock.sentRequest == nil)
    }
    
    @Test("should use originalSession if stopMockingURLSession() was called")
    func testUsesOriginalSessionAfterStopMocking() async throws {
        let (originalSession, sessionMock) = createSessionAndMock()
        
        URLSessionMock.startMockingURLSession()
        sessionMock.httpResponse = HTTPURLResponse(
            url: URL(string: "some.url")!,
            statusCode: 500,
            httpVersion: nil,
            headerFields: nil)
        URLSessionMock.stopMockingURLSession()
        
        try await withCheckedThrowingContinuation { continuation in
            originalSession.dataTask(with: URLRequest(url: URL(string: "about:blank")!)) { _, response, _ in
                #expect(response?.url?.absoluteString == "about:blank")
                #expect(response is HTTPURLResponse == false)
                continuation.resume()
            }.resume()
        }
        
        #expect(sessionMock.sentRequest == nil)
    }
    
    @Suite("Cookie storage")
    struct CookieStorageTests {
        let url: URL = URL(string: "https://rakuten.com")!
        let cookieName = "TestCookieName"
        let cookieValue = "TestCookieValue"
        let expiryDate = "Fri, 16-Nov-50 16:59:07 GMT"
        var cookieToSet: String {
            "\(cookieName)=\(cookieValue); path=/; expires=\(expiryDate); session-only=false; domain=.rakuten.com"
        }
        
        func setup() -> (originalSession: URLSession, sessionMock: URLSessionMock, urlRequest: URLRequest) {
            let originalSession = URLSession(configuration: .ephemeral)
            let sessionMock = URLSessionMock.mock(originalInstance: originalSession)
            let urlRequest = URLRequest(url: url)
            URLSessionMock.startMockingURLSession()
            return (originalSession, sessionMock, urlRequest)
        }
        
        func cleanup(cookie: HTTPCookie?) {
            URLSessionMock.stopMockingURLSession()
            if let cookie = cookie {
                HTTPCookieStorage.shared.deleteCookie(cookie)
            }
        }
        
        @Suite("When a request is sent")
        struct WhenRequestIsSentTests {
            let url: URL = URL(string: "https://rakuten.com")!
            let cookieName = "TestCookieName"
            let cookieValue = "TestCookieValue"
            let expiryDate = "Fri, 16-Nov-50 16:59:07 GMT"
            var cookieToSet: String {
                "\(cookieName)=\(cookieValue); path=/; expires=\(expiryDate); session-only=false; domain=.rakuten.com"
            }
            
            @Suite("When a non-nil valid cookie is set to the request header")
            struct ValidCookieTests {
                let url: URL = URL(string: "https://rakuten.com")!
                let cookieName = "TestCookieName"
                let cookieValue = "TestCookieValue"
                let expiryDate = "Fri, 16-Nov-50 16:59:07 GMT"
                var cookieToSet: String {
                    "\(cookieName)=\(cookieValue); path=/; expires=\(expiryDate); session-only=false; domain=.rakuten.com"
                }
                
                func setup() async throws -> (originalSession: URLSession, sessionMock: URLSessionMock, urlRequest: URLRequest) {
                    let originalSession = URLSession(configuration: .ephemeral)
                    let sessionMock = URLSessionMock.mock(originalInstance: originalSession)
                    let urlRequest = URLRequest(url: url)
                    URLSessionMock.startMockingURLSession()
                    
                    sessionMock.httpResponse = HTTPURLResponse(
                        url: url,
                        statusCode: 200,
                        httpVersion: nil,
                        headerFields: ["Set-Cookie": cookieToSet])
                    
                    try await withCheckedThrowingContinuation { continuation in
                        originalSession.dataTask(with: urlRequest) { _, _, _ in
                            continuation.resume()
                        }.resume()
                    }
                    
                    return (originalSession, sessionMock, urlRequest)
                }
                
                @Test("should set a non-nil request cookie in the cookie storage")
                func testSetsNonNilCookie() async throws {
                    _ = try await setup()
                    defer {
                        URLSessionMock.stopMockingURLSession()
                        if let cookie = HTTPCookieStorage.shared.cookies(for: url)?.first {
                            HTTPCookieStorage.shared.deleteCookie(cookie)
                        }
                    }
                    
                    try await TestingHelpers.eventually(timeout: 2.0) {
                        HTTPCookieStorage.shared.cookies(for: url)?.first != nil
                    }
                    #expect(HTTPCookieStorage.shared.cookies(for: url)?.first != nil)
                }
                
                @Test("should set a non-nil cookie name")
                func testSetsCookieName() async throws {
                    _ = try await setup()
                    defer {
                        URLSessionMock.stopMockingURLSession()
                        if let cookie = HTTPCookieStorage.shared.cookies(for: url)?.first {
                            HTTPCookieStorage.shared.deleteCookie(cookie)
                        }
                    }
                    
                    try await TestingHelpers.eventually(timeout: 2.0) {
                        HTTPCookieStorage.shared.cookies(for: url)?.first?.name == cookieName
                    }
                    #expect(HTTPCookieStorage.shared.cookies(for: url)?.first?.name == cookieName)
                }
                
                @Test("should set a non-nil cookie value")
                func testSetsCookieValue() async throws {
                    _ = try await setup()
                    defer {
                        URLSessionMock.stopMockingURLSession()
                        if let cookie = HTTPCookieStorage.shared.cookies(for: url)?.first {
                            HTTPCookieStorage.shared.deleteCookie(cookie)
                        }
                    }
                    
                    try await TestingHelpers.eventually(timeout: 2.0) {
                        HTTPCookieStorage.shared.cookies(for: url)?.first?.value == cookieValue
                    }
                    #expect(HTTPCookieStorage.shared.cookies(for: url)?.first?.value == cookieValue)
                }
            }
            
            @Suite("When an empty cookie is set to the request header")
            struct EmptyCookieTests {
                let url: URL = URL(string: "https://rakuten.com")!
                
                @Test("should set the request cookie in the cookie storage")
                func testSetsEmptyCookie() async throws {
                    let originalSession = URLSession(configuration: .ephemeral)
                    let sessionMock = URLSessionMock.mock(originalInstance: originalSession)
                    let urlRequest = URLRequest(url: url)
                    URLSessionMock.startMockingURLSession()
                    defer {
                        URLSessionMock.stopMockingURLSession()
                        if let cookie = HTTPCookieStorage.shared.cookies(for: url)?.first {
                            HTTPCookieStorage.shared.deleteCookie(cookie)
                        }
                    }
                    
                    sessionMock.httpResponse = HTTPURLResponse(
                        url: url,
                        statusCode: 200,
                        httpVersion: nil,
                        headerFields: ["Set-Cookie": ""])
                    
                    try await withCheckedThrowingContinuation { continuation in
                        originalSession.dataTask(with: urlRequest) { _, _, _ in
                            continuation.resume()
                        }.resume()
                    }
                    
                    try await TestingHelpers.performAsyncTest(timeForExecution: 1.0, timeout: 1.0) {
                        let cookie = HTTPCookieStorage.shared.cookies(for: url)?.first
                        #expect(cookie == nil)
                    }
                }
            }
            
            @Suite("When allHTTPHeaderFields is set to nil")
            struct NilHeaderFieldsTests {
                let url: URL = URL(string: "https://rakuten.com")!
                
                @Test("should set the request cookie in the cookie storage")
                func testSetsNilHeaderFields() async throws {
                    let originalSession = URLSession(configuration: .ephemeral)
                    let sessionMock = URLSessionMock.mock(originalInstance: originalSession)
                    let urlRequest = URLRequest(url: url)
                    URLSessionMock.startMockingURLSession()
                    defer {
                        URLSessionMock.stopMockingURLSession()
                        if let cookie = HTTPCookieStorage.shared.cookies(for: url)?.first {
                            HTTPCookieStorage.shared.deleteCookie(cookie)
                        }
                    }
                    
                    sessionMock.httpResponse = HTTPURLResponse(
                        url: url,
                        statusCode: 200,
                        httpVersion: nil,
                        headerFields: nil)
                    
                    try await withCheckedThrowingContinuation { continuation in
                        originalSession.dataTask(with: urlRequest) { _, _, _ in
                            continuation.resume()
                        }.resume()
                    }
                    
                    try await TestingHelpers.performAsyncTest(timeForExecution: 1.0, timeout: 1.0) {
                        let cookie = HTTPCookieStorage.shared.cookies(for: url)?.first
                        #expect(cookie == nil)
                    }
                }
            }
        }
    }
    
    @Suite("when startMockingURLSession() was called")
    struct WhenStartMockingCalledTests {
        func setup() -> (originalSession: URLSession, sessionMock: URLSessionMock) {
            let originalSession = URLSession(configuration: .ephemeral)
            let sessionMock = URLSessionMock.mock(originalInstance: originalSession)
            URLSessionMock.startMockingURLSession()
            return (originalSession, sessionMock)
        }
        
        func cleanup() {
            URLSessionMock.stopMockingURLSession()
        }
        
        @Test("should return mocked values in dataTask completion")
        func testReturnsMockedValues() async throws {
            let (originalSession, sessionMock) = setup()
            defer { cleanup() }
            
            let expectedResponse = HTTPURLResponse(
                url: URL(string: "some.url")!,
                statusCode: 500,
                httpVersion: nil,
                headerFields: nil)
            let expectedError = NSError(domain: "mock.domain", code: 1234, userInfo: ["user": "info"])
            let expectedData = "data".data(using: .utf8)
            sessionMock.httpResponse = expectedResponse
            sessionMock.responseError = expectedError
            sessionMock.responseData = expectedData
            
            try await withCheckedThrowingContinuation { continuation in
                originalSession.dataTask(with: URLRequest(url: URL(string: "https://google.com")!)) { data, response, error in
                    #expect(data == expectedData)
                    #expect((error as NSError?) == expectedError)
                    #expect(response == expectedResponse)
                    continuation.resume()
                }.resume()
            }
        }
        
        @Test("should call onCompletedTask when the task is finished")
        func testCallsOnCompletedTask() async throws {
            let (originalSession, sessionMock) = setup()
            defer { cleanup() }
            
            var onCompletedTaskCalled = false
            sessionMock.onCompletedTask = { onCompletedTaskCalled = true }
            
            try await withCheckedThrowingContinuation { continuation in
                originalSession.dataTask(with: URLRequest(url: URL(string: "https://google.com")!)) { _, _, _ in
                    continuation.resume()
                }.resume()
            }
            
            #expect(onCompletedTaskCalled == true)
        }
        
        @Test("should keep a copy of last URLRequest in `sentRequest` var")
        func testKeepsCopyOfSentRequest() async throws {
            let (originalSession, sessionMock) = setup()
            defer { cleanup() }
            
            let request = URLRequest(url: URL(string: "https://google.com")!)
            #expect(sessionMock.sentRequest == nil)
            
            try await withCheckedThrowingContinuation { continuation in
                originalSession.dataTask(with: request) { _, _, _ in
                    continuation.resume()
                }.resume()
            }
            
            #expect(sessionMock.sentRequest != nil)
            #expect(sessionMock.sentRequest == request)
        }
        
        @Suite("when calling decodeSentData()")
        struct DecodeSentDataTests {
            func setup() -> (originalSession: URLSession, sessionMock: URLSessionMock) {
                let originalSession = URLSession(configuration: .ephemeral)
                let sessionMock = URLSessionMock.mock(originalInstance: originalSession)
                URLSessionMock.startMockingURLSession()
                return (originalSession, sessionMock)
            }
            
            func cleanup() {
                URLSessionMock.stopMockingURLSession()
            }
            
            @Test("should succeed if all expected parameters are present")
            func testSucceedsWithAllParameters() async throws {
                let (originalSession, sessionMock) = setup()
                defer { cleanup() }
                
                let jsonData = """
                {"identifier":100, "isTest":true, "appVersion":"1.2.3", "sdkVersion":"0.0.5"}
                """.data(using: .utf8)!
                
                var request = URLRequest(url: URL(string: "https://google.com")!)
                request.httpBody = jsonData
                
                try await withCheckedThrowingContinuation { continuation in
                    originalSession.dataTask(with: request) { _, _, _ in
                        continuation.resume()
                    }.resume()
                }
                
                let decodedModel = sessionMock.decodeSentData(modelType: BodyModel.self)
                #expect(decodedModel != nil)
                #expect(decodedModel?.identifier == 100)
                #expect(decodedModel?.isTest == true)
                #expect(decodedModel?.appVersion == "1.2.3")
                #expect(decodedModel?.sdkVersion == "0.0.5")
            }
            
            @Test("should succeed if there are optional parameters in the json")
            func testSucceedsWithOptionalParameters() async throws {
                let (originalSession, sessionMock) = setup()
                defer { cleanup() }
                
                let jsonData = """
                {"identifier":100, "isTest":true, "appVersion":"1.2.3", "sdkVersion":"0.0.5", "locale":"pl"}
                """.data(using: .utf8)!
                
                var request = URLRequest(url: URL(string: "https://google.com")!)
                request.httpBody = jsonData
                
                try await withCheckedThrowingContinuation { continuation in
                    originalSession.dataTask(with: request) { _, _, _ in
                        continuation.resume()
                    }.resume()
                }
                
                let decodedModel = sessionMock.decodeSentData(modelType: BodyModel.self)
                #expect(decodedModel != nil)
                #expect(decodedModel?.identifier == 100)
                #expect(decodedModel?.isTest == true)
                #expect(decodedModel?.appVersion == "1.2.3")
                #expect(decodedModel?.sdkVersion == "0.0.5")
            }
            
            @Test("should fail if not all expected parameters are present")
            func testFailsWithMissingParameters() async throws {
                let (originalSession, sessionMock) = setup()
                defer { cleanup() }
                
                let jsonData = """
                {"identifier":100, "isTest":true, "appVersion":"1.2.3"}
                """.data(using: .utf8)!
                
                var request = URLRequest(url: URL(string: "https://google.com")!)
                request.httpBody = jsonData
                
                try await withCheckedThrowingContinuation { continuation in
                    originalSession.dataTask(with: request) { _, _, _ in
                        continuation.resume()
                    }.resume()
                }
                
                let decodedModel = sessionMock.decodeSentData(modelType: BodyModel.self)
                #expect(decodedModel == nil)
            }
            
            @Test("should fail if parameter type does not match")
            func testFailsWithWrongParameterType() async throws {
                let (originalSession, sessionMock) = setup()
                defer { cleanup() }
                
                let jsonData = """
                {"identifier":"id", "isTest":true, "appVersion":"1.2.3", "sdkVersion":"0.0.5"}
                """.data(using: .utf8)!
                
                var request = URLRequest(url: URL(string: "https://google.com")!)
                request.httpBody = jsonData
                
                try await withCheckedThrowingContinuation { continuation in
                    originalSession.dataTask(with: request) { _, _, _ in
                        continuation.resume()
                    }.resume()
                }
                
                let decodedModel = sessionMock.decodeSentData(modelType: BodyModel.self)
                #expect(decodedModel == nil)
            }
        }
        
        @Suite("when calling decodeQueryItems()")
        struct DecodeQueryItemsTests {
            func setup() -> (originalSession: URLSession, sessionMock: URLSessionMock) {
                let originalSession = URLSession(configuration: .ephemeral)
                let sessionMock = URLSessionMock.mock(originalInstance: originalSession)
                URLSessionMock.startMockingURLSession()
                return (originalSession, sessionMock)
            }
            
            func cleanup() {
                URLSessionMock.stopMockingURLSession()
            }
            
            @Test("should succeed if all expected parameters are present")
            func testSucceedsWithAllParameters() async throws {
                let (originalSession, sessionMock) = setup()
                defer { cleanup() }
                
                let urlQuery = URL(string: "http://config.url?isTest=true&identifier=100&appVersion=1.2.3&sdkVersion=0.0.5")!
                
                try await withCheckedThrowingContinuation { continuation in
                    originalSession.dataTask(with: URLRequest(url: urlQuery)) { _, _, _ in
                        continuation.resume()
                    }.resume()
                }
                
                let decodedModel = sessionMock.decodeQueryItems(modelType: URLQueryModel.self)
                #expect(decodedModel != nil)
                #expect(decodedModel?.identifier == 100)
                #expect(decodedModel?.isTest == true)
                #expect(decodedModel?.appVersion == "1.2.3")
                #expect(decodedModel?.sdkVersion == "0.0.5")
            }
            
            @Test("should succeed if there are optional parameters in the url")
            func testSucceedsWithOptionalParameters() async throws {
                let (originalSession, sessionMock) = setup()
                defer { cleanup() }
                
                let urlQuery = URL(string: "http://config.url?isTest=true&identifier=100&appVersion=1.2.3&sdkVersion=0.0.5&locale=pl")!
                
                try await withCheckedThrowingContinuation { continuation in
                    originalSession.dataTask(with: URLRequest(url: urlQuery)) { _, _, _ in
                        continuation.resume()
                    }.resume()
                }
                
                let decodedModel = sessionMock.decodeQueryItems(modelType: URLQueryModel.self)
                #expect(decodedModel != nil)
                #expect(decodedModel?.identifier == 100)
                #expect(decodedModel?.isTest == true)
                #expect(decodedModel?.appVersion == "1.2.3")
                #expect(decodedModel?.sdkVersion == "0.0.5")
            }
            
            @Test("should fail if not all expected parameters are present")
            func testFailsWithMissingParameters() async throws {
                let (originalSession, sessionMock) = setup()
                defer { cleanup() }
                
                let urlQuery = URL(string: "http://config.url?isTest=true&identifier=100&appVersion=1.2.3")!
                
                try await withCheckedThrowingContinuation { continuation in
                    originalSession.dataTask(with: URLRequest(url: urlQuery)) { _, _, _ in
                        continuation.resume()
                    }.resume()
                }
                
                let decodedModel = sessionMock.decodeQueryItems(modelType: URLQueryModel.self)
                #expect(decodedModel == nil)
            }
            
            @Test("should fail if parameter type does not match")
            func testFailsWithWrongParameterType() async throws {
                let (originalSession, sessionMock) = setup()
                defer { cleanup() }
                
                let urlQuery = URL(string: "http://config.url?isTest=true&identifier=id&appVersion=1.2.3&sdkVersion=0.0.5")!
                
                try await withCheckedThrowingContinuation { continuation in
                    originalSession.dataTask(with: URLRequest(url: urlQuery)) { _, _, _ in
                        continuation.resume()
                    }.resume()
                }
                
                let decodedModel = sessionMock.decodeQueryItems(modelType: URLQueryModel.self)
                #expect(decodedModel == nil)
            }
        }
    }
}

internal struct URLQueryModel: Codable {
    let identifier: Int
    let isTest: Bool
    let appVersion: String
    let sdkVersion: String
}

private struct BodyModel: Codable {
    let identifier: Int
    let isTest: Bool
    let appVersion: String
    let sdkVersion: String
}
