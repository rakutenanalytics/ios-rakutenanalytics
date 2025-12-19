import Foundation
import Testing
@testable import RakutenAnalytics
#if canImport(RAnalyticsTestHelpers)
import RAnalyticsTestHelpers
#endif

// MARK: - RAnalyticsRpCookieFetcherTests

@Suite("RAnalyticsRpCookieFetcher")
struct RAnalyticsRpCookieFetcherTests {
    static let headerFields = ["Set-Cookie": "Rp=cookieValue; path=/; expires=Fri, 16-Nov-50 16:59:07 GMT; session-only=0; domain=.rakuten.co.jp"]
    static let noRpCookieHeaderFields = ["Set-Token": "1234"]
    static let urlString = "https://domain.com"
    static let maximumTimeOut: UInt = 3
    
    static var response: HTTPURLResponse {
        HTTPURLResponse(
            url: URL(string: urlString)!,
            statusCode: 200,
            httpVersion: nil,
            headerFields: headerFields)!
    }
    
    static var cookies: [HTTPCookie] {
        [HTTPCookie(properties: [.path: "/",
                                 .name: "Rp",
                                 .value: "abcdef",
                                 .domain: ".rakuten.com",
                                 .expires: Date.distantFuture])!]
    }
    
    static var emptyResponse: HTTPURLResponse {
        HTTPURLResponse(
            url: URL(string: urlString)!,
            statusCode: 200,
            httpVersion: nil,
            headerFields: nil)!
    }
    
    static var noRpCookieResponse: HTTPURLResponse {
        HTTPURLResponse(
            url: URL(string: urlString)!,
            statusCode: 200,
            httpVersion: nil,
            headerFields: noRpCookieHeaderFields)!
    }
    
    @Suite("init")
    struct InitTests {
        @Test("should return nil when endpointAddress is nil")
        func testShouldReturnNilWhenEndpointAddressIsNil() async throws {
            let bundleMock = BundleMock()
            bundleMock.endpointAddress = nil
            let cookieStorageMock = HTTPCookieStorageMock()
            let sessionMock = SessionMock()
            let reachabilityMock = ReachabilityMock()
            
            let cookieFetcher = RAnalyticsRpCookieFetcher(
                cookieStorage: cookieStorageMock,
                bundle: bundleMock,
                session: sessionMock,
                reachability: reachabilityMock,
                maximumTimeOut: RAnalyticsRpCookieFetcherTests.maximumTimeOut)
            
            try await TestingHelpers.eventually {
                cookieFetcher == nil
            }
        }
        
        @Test("should return not nil when endpointAddress is not nil")
        func testShouldReturnNotNilWhenEndpointAddressIsNotNil() async throws {
            let bundleMock = BundleMock()
            bundleMock.endpointAddress = URL(string: RAnalyticsRpCookieFetcherTests.urlString)
            let cookieStorageMock = HTTPCookieStorageMock()
            let sessionMock = SessionMock()
            let reachabilityMock = ReachabilityMock()
            
            let cookieFetcher = RAnalyticsRpCookieFetcher(
                cookieStorage: cookieStorageMock,
                bundle: bundleMock,
                session: sessionMock,
                reachability: reachabilityMock,
                maximumTimeOut: RAnalyticsRpCookieFetcherTests.maximumTimeOut)
            
            try await TestingHelpers.eventually {
                cookieFetcher != nil
            }
        }
    }
    
    @Suite("getRpCookieCompletionHandler")
    struct GetRpCookieCompletionHandlerTests {
        struct TestHelper {
            let bundleMock = BundleMock()
            let cookieStorageMock = HTTPCookieStorageMock()
            let sessionMock = SessionMock()
            let reachabilityMock = ReachabilityMock()
            var cookieFetcher: RAnalyticsRpCookieFetcher?
            
            mutating func setUp() {
                sessionMock.response = nil
                sessionMock.error = nil
                sessionMock.willComplete = nil
                cookieStorageMock.cookiesArray = nil
                bundleMock.endpointAddress = URL(string: RAnalyticsRpCookieFetcherTests.urlString)
                cookieFetcher = RAnalyticsRpCookieFetcher(
                    cookieStorage: cookieStorageMock,
                    bundle: bundleMock,
                    session: sessionMock,
                    reachability: reachabilityMock,
                    maximumTimeOut: RAnalyticsRpCookieFetcherTests.maximumTimeOut)
            }
        }
        
        @Suite("The connection is unavailable")
        struct ConnectionUnavailableTests {
            var helper = TestHelper()
            
            mutating func setUp() {
                helper.setUp()
                helper.reachabilityMock.connection = .unavailable
            }
            
            @Test("should return an offline error")
            mutating func testShouldReturnOfflineError() async throws {
                setUp()
                
                var error: Error?
                
                helper.cookieFetcher?.getRpCookieCompletionHandler { _, anError in
                    error = anError
                }
                
                try await TestingHelpers.eventually {
                    error != nil
                }
                
                let nsError = error as NSError?
                #expect(nsError?.domain == ErrorDomain.rpCookieFetcherErrorDomain)
                #expect(nsError?.code == ErrorCode.rpCookieCantBeFetched.rawValue)
                #expect(nsError?.localizedDescription == ErrorDescription.rpCookieCantBeFetched)
                #expect(nsError?.localizedFailureReason == ErrorReason.connectionIsOffline)
            }
        }
        
        @Suite("The connection is available")
        struct ConnectionAvailableTests {
            var helper = TestHelper()
            
            mutating func setUp() {
                helper.setUp()
                helper.reachabilityMock.connection = .cellular
            }
            
            @Suite("when user sets 'disable shared cookie storage' key to true in app info.plist")
            struct DisableSharedCookieStorageTrueTests {
                var helper = TestHelper()
                
                mutating func setUp() {
                    helper.setUp()
                    helper.reachabilityMock.connection = .cellular
                    helper.bundleMock.dictionary = ["RATDisableSharedCookieStorage": true]
                }
                
                @Test("should return the Rp cookie when the Rp Cookie exists in the cookie storage")
                mutating func testShouldReturnRpCookieWhenCookieExistsInStorage() async throws {
                    setUp()
                    
                    var cookie: HTTPCookie?
                    var error: Error?
                    helper.sessionMock.response = RAnalyticsRpCookieFetcherTests.response
                    let cookieStorageMock = helper.cookieStorageMock
                    helper.sessionMock.willComplete = {
                        cookieStorageMock.cookiesArray = RAnalyticsRpCookieFetcherTests.cookies
                    }
                    
                    helper.cookieFetcher?.getRpCookieCompletionHandler { aCookie, anError in
                        DispatchQueue.main.async {
                            cookie = aCookie
                            error = anError
                        }
                    }
                    
                    try await TestingHelpers.eventually {
                        cookie != nil
                    }
                    #expect(error == nil)
                }
                
                @Test("should return an error when the Rp Cookie does not exist in the cookie storage")
                mutating func testShouldReturnErrorWhenCookieDoesNotExistInStorage() async throws {
                    setUp()
                    
                    var cookie: HTTPCookie?
                    var error: Error?
                    helper.sessionMock.response = RAnalyticsRpCookieFetcherTests.response
                    
                    helper.cookieFetcher?.getRpCookieCompletionHandler { aCookie, anError in
                        DispatchQueue.main.async {
                            cookie = aCookie
                            error = anError
                        }
                    }
                    
                    try await TestingHelpers.eventually {
                        error != nil
                    }
                    
                    try await TestingHelpers.eventually {
                        (error as NSError?)?.localizedDescription == "Cannot get Rp cookie from the Cookie Storage - \(RAnalyticsRpCookieFetcherTests.urlString)"
                    }
                    #expect(cookie == nil)
                }
            }
            
            @Suite("when user sets 'disable shared cookie storage' key to false in app info.plist")
            struct DisableSharedCookieStorageFalseTests {
                var helper = TestHelper()
                
                mutating func setUp() {
                    helper.setUp()
                    helper.reachabilityMock.connection = .cellular
                    helper.bundleMock.dictionary = ["RATDisableSharedCookieStorage": false]
                }
                
                @Test("should return Rp cookie when the http response contains the Rp Cookie")
                mutating func testShouldReturnRpCookieWhenResponseContainsCookie() async throws {
                    setUp()
                    
                    helper.sessionMock.response = RAnalyticsRpCookieFetcherTests.response
                    
                    var cookie: HTTPCookie?
                    var error: Error?
                    helper.cookieFetcher?.getRpCookieCompletionHandler { aCookie, anError in
                        DispatchQueue.main.async {
                            cookie = aCookie
                            error = anError
                        }
                    }
                    
                    try await TestingHelpers.eventually {
                        cookie?.name == "Rp"
                    }
                    #expect(error == nil)
                }
                
                @Test("should return an error when the http response does not contain the Rp Cookie - empty headers")
                mutating func testShouldReturnErrorWhenResponseDoesNotContainCookieEmptyHeaders() async throws {
                    setUp()
                    
                    helper.sessionMock.response = RAnalyticsRpCookieFetcherTests.emptyResponse
                    
                    var cookie: HTTPCookie?
                    var error: Error?
                    helper.cookieFetcher?.getRpCookieCompletionHandler { aCookie, anError in
                        DispatchQueue.main.async {
                            cookie = aCookie
                            error = anError
                        }
                    }
                    
                    try await TestingHelpers.eventually {
                        error != nil
                    }
                    
                    try await TestingHelpers.eventually {
                        (error as NSError?)?.localizedDescription == "Cannot get Rp cookie from the RAT Server HTTP Response - \(RAnalyticsRpCookieFetcherTests.urlString)"
                    }
                    
                    try await TestingHelpers.eventually {
                        (error as NSError?)?.localizedFailureReason == "The header fields are empty."
                    }
                    #expect(cookie == nil)
                }
                
                @Test("should return an error when the http response does not contain the Rp Cookie - no Rp cookie")
                mutating func testShouldReturnErrorWhenResponseDoesNotContainCookieNoRpCookie() async throws {
                    setUp()
                    
                    helper.sessionMock.response = RAnalyticsRpCookieFetcherTests.noRpCookieResponse
                    
                    var cookie: HTTPCookie?
                    var error: Error?
                    helper.cookieFetcher?.getRpCookieCompletionHandler { aCookie, anError in
                        DispatchQueue.main.async {
                            cookie = aCookie
                            error = anError
                        }
                    }
                    
                    try await TestingHelpers.eventually {
                        error != nil
                    }
                    
                    try await TestingHelpers.eventually {
                        (error as NSError?)?.localizedDescription == "Cannot get Rp cookie from the RAT Server HTTP Response - \(RAnalyticsRpCookieFetcherTests.urlString)"
                    }
                    
                    try await TestingHelpers.eventually {
                        (error as NSError?)?.localizedFailureReason == "The Rp Cookie is not in the http response header fields."
                    }
                    #expect(cookie == nil)
                }
            }
            
            @Suite("when user did not set 'disable shared cookie storage' key in app info.plist")
            struct DisableSharedCookieStorageNotSetTests {
                var helper = TestHelper()
                
                mutating func setUp() {
                    helper.setUp()
                    helper.reachabilityMock.connection = .cellular
                    helper.bundleMock.dictionary = nil
                }
                
                @Test("should return Rp cookie when the http response contains the Rp Cookie")
                mutating func testShouldReturnRpCookieWhenResponseContainsCookie() async throws {
                    setUp()
                    
                    helper.sessionMock.response = RAnalyticsRpCookieFetcherTests.response
                    
                    var cookie: HTTPCookie?
                    var error: Error?
                    helper.cookieFetcher?.getRpCookieCompletionHandler { aCookie, anError in
                        DispatchQueue.main.async {
                            cookie = aCookie
                            error = anError
                        }
                    }
                    
                    try await TestingHelpers.eventually {
                        cookie?.name == "Rp"
                    }
                    #expect(error == nil)
                }
                
                @Test("should return an error when the http response does not contain the Rp Cookie - empty headers")
                mutating func testShouldReturnErrorWhenResponseDoesNotContainCookieEmptyHeaders() async throws {
                    setUp()
                    
                    helper.sessionMock.response = RAnalyticsRpCookieFetcherTests.emptyResponse
                    
                    var cookie: HTTPCookie?
                    var error: Error?
                    helper.cookieFetcher?.getRpCookieCompletionHandler { aCookie, anError in
                        DispatchQueue.main.async {
                            cookie = aCookie
                            error = anError
                        }
                    }
                    
                    try await TestingHelpers.eventually {
                        error != nil
                    }
                    
                    try await TestingHelpers.eventually {
                        (error as NSError?)?.localizedDescription == "Cannot get Rp cookie from the RAT Server HTTP Response - \(RAnalyticsRpCookieFetcherTests.urlString)"
                    }
                    
                    try await TestingHelpers.eventually {
                        (error as NSError?)?.localizedFailureReason == "The header fields are empty."
                    }
                    #expect(cookie == nil)
                }
                
                @Test("should return an error when the http response does not contain the Rp Cookie - no Rp cookie")
                mutating func testShouldReturnErrorWhenResponseDoesNotContainCookieNoRpCookie() async throws {
                    setUp()
                    
                    helper.sessionMock.response = RAnalyticsRpCookieFetcherTests.noRpCookieResponse
                    
                    var cookie: HTTPCookie?
                    var error: Error?
                    helper.cookieFetcher?.getRpCookieCompletionHandler { aCookie, anError in
                        DispatchQueue.main.async {
                            cookie = aCookie
                            error = anError
                        }
                    }
                    
                    try await TestingHelpers.eventually {
                        error != nil
                    }
                    
                    try await TestingHelpers.eventually {
                        (error as NSError?)?.localizedDescription == "Cannot get Rp cookie from the RAT Server HTTP Response - \(RAnalyticsRpCookieFetcherTests.urlString)"
                    }
                    
                    try await TestingHelpers.eventually {
                        (error as NSError?)?.localizedFailureReason == "The Rp Cookie is not in the http response header fields."
                    }
                    #expect(cookie == nil)
                }
            }
            
            @Suite("when the session returns an error")
            struct SessionErrorTests {
                var helper = TestHelper()
                
                mutating func setUp() {
                    helper.setUp()
                    helper.reachabilityMock.connection = .cellular
                }
                
                @Test("should return an error after retry timeout")
                mutating func testShouldReturnErrorAfterRetryTimeout() async throws {
                    setUp()
                    
                    var cookie: HTTPCookie?
                    var error: Error?
                    let rpError = NSError(domain: NSURLErrorDomain, code: 500, userInfo: nil)
                    helper.sessionMock.error = rpError
                    
                    helper.cookieFetcher?.getRpCookieCompletionHandler { aCookie, anError in
                        DispatchQueue.main.async {
                            cookie = aCookie
                            error = anError
                        }
                    }
                    
                    try await TestingHelpers.eventually(timeout: TimeInterval(RAnalyticsRpCookieFetcherTests.maximumTimeOut)) {
                        (error as NSError?) == rpError
                    }
                    #expect(cookie == nil)
                }
            }
            
            @Suite("when the session returns a status code equal to 400")
            struct SessionStatusCode400Tests {
                var helper = TestHelper()
                
                mutating func setUp() {
                    helper.setUp()
                    helper.reachabilityMock.connection = .cellular
                }
                
                @Test("should return an error after retry timeout")
                mutating func testShouldReturnErrorAfterRetryTimeout() async throws {
                    setUp()
                    
                    var cookie: HTTPCookie?
                    var error: Error?
                    let errorResponse = HTTPURLResponse(
                        url: URL(string: RAnalyticsRpCookieFetcherTests.urlString)!,
                        statusCode: 400,
                        httpVersion: nil,
                        headerFields: nil)
                    helper.sessionMock.response = errorResponse
                    
                    helper.cookieFetcher?.getRpCookieCompletionHandler { aCookie, anError in
                        DispatchQueue.main.async {
                            cookie = aCookie
                            error = anError
                        }
                    }
                    
                    try await TestingHelpers.eventually(timeout: TimeInterval(RAnalyticsRpCookieFetcherTests.maximumTimeOut)) {
                        error != nil
                    }
                    #expect(cookie == nil)
                }
            }
        }
    }
    
    @Suite("getRpCookieFromCookieStorage")
    struct GetRpCookieFromCookieStorageTests {
        struct TestHelper {
            let bundleMock = BundleMock()
            let cookieStorageMock = HTTPCookieStorageMock()
            let sessionMock = SessionMock()
            var cookieFetcher: RAnalyticsRpCookieFetcher?
            
            mutating func setUp() {
                cookieStorageMock.cookiesArray = nil
                bundleMock.endpointAddress = URL(string: RAnalyticsRpCookieFetcherTests.urlString)
                cookieFetcher = RAnalyticsRpCookieFetcher(
                    cookieStorage: cookieStorageMock,
                    bundle: bundleMock,
                    session: sessionMock,
                    reachability: nil,
                    maximumTimeOut: RAnalyticsRpCookieFetcherTests.maximumTimeOut)
            }
        }
        
        @Suite("when rp cookie does not exist in the cookie storage")
        struct RpCookieDoesNotExistTests {
            var helper = TestHelper()
            
            mutating func setUp() {
                helper.setUp()
                helper.cookieStorageMock.cookiesArray = nil
            }
            
            @Test("should return nil")
            mutating func testShouldReturnNil() async throws {
                setUp()
                
                let rpCookie = helper.cookieFetcher?.getRpCookieFromCookieStorage()
                
                try await TestingHelpers.performAsyncTest(timeForExecution: 1.0, timeout: 1.0) {
                    #expect(rpCookie == nil)
                }
            }
        }
        
        @Suite("when rp cookie exists in the cookie storage")
        struct RpCookieExistsTests {
            var helper = TestHelper()
            
            mutating func setUp() {
                helper.setUp()
                helper.cookieStorageMock.cookiesArray = RAnalyticsRpCookieFetcherTests.cookies
            }
            
            @Test("should return the rp cookie")
            mutating func testShouldReturnRpCookie() async throws {
                setUp()
                
                let rpCookie = helper.cookieFetcher?.getRpCookieFromCookieStorage()
                
                try await TestingHelpers.eventually {
                    rpCookie?.name == "Rp"
                }
            }
        }
    }
}
