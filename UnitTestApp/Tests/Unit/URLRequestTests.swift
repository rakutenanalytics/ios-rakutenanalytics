import Testing
import Foundation
@testable import RakutenAnalytics
#if canImport(RAnalyticsTestHelpers)
import RAnalyticsTestHelpers
#endif

@Suite("URLRequest")
struct URLRequestTests {
    let urlString = "https://www.example.com"
    let url: URL! = URL(string: "https://www.example.com")
    let data = "foo".data(using: .utf8)!
    
    func createRequest() -> URLRequest {
        return URLRequest(url: url, body: data)
    }
    
    @Test("should return a request with passed-in url set")
    func testShouldReturnRequestWithPassedInURLSet() {
        let request = createRequest()
        #expect(request.url?.absoluteString == urlString)
    }
    
    @Test("should return a request with passed-in data set as body")
    func testShouldReturnRequestWithPassedInDataSetAsBody() {
        let request = createRequest()
        #expect(request.httpBody == data)
    }
    
    @Test("should return a request with timeout of 30s")
    func testShouldReturnRequestWithTimeoutOf30s() {
        let request = createRequest()
        #expect(request.timeoutInterval == 30.0)
    }
    
    @Test("should return a request set to reload ignoring cache")
    func testShouldReturnRequestSetToReloadIgnoringCache() {
        let request = createRequest()
        #expect(request.cachePolicy == .reloadIgnoringCacheData)
    }
    
    @Test("should return a request with context type header set to text/plain")
    func testShouldReturnRequestWithContentTypeHeaderSetToTextPlain() {
        let request = createRequest()
        #expect(request.allHTTPHeaderFields?["Content-Type"] == "text/plain")
    }
    
    @Test("should return a request with POST method set")
    func testShouldReturnRequestWithPOSTMethodSet() {
        let request = createRequest()
        #expect(request.httpMethod == "POST")
    }
    
    @Test("should return a request with content length header set to expected value")
    func testShouldReturnRequestWithContentLengthHeaderSetToExpectedValue() {
        let request = createRequest()
        #expect(request.allHTTPHeaderFields?["Content-Length"] == "\(data.count)")
    }
    
    @Test("should return a request with date header set to the expected timestamp")
    func testShouldReturnRequestWithDateHeaderSetToExpectedTimestamp() {
        let request = createRequest()
        let expectedTimestamp = DateFormatter.rfc1123DateFormatter.string(from: Date())
        
        #expect(request.allHTTPHeaderFields?["Date"] == expectedTimestamp)
    }
    
    @Suite("When timestamp is Wed, 09 Nov 2022 22:39:34 GMT")
    struct WhenTimestampIsWed09Nov2022Tests {
        @Test("should set the request date header to Wed, 09 Nov 2022 22:39:34 GMT")
        func testShouldSetRequestDateHeaderToWed09Nov2022() {
            let urlString = "https://www.example.com"
            let url: URL! = URL(string: urlString)
            let data = "foo".data(using: .utf8)!
            let date: Date! = DateFormatter.rfc1123DateFormatter.date(from: "Wed, 09 Nov 2022 22:39:34 GMT")
            
            let urlRequest = URLRequest(url: url, body: data, at: date)
            
            #expect(urlRequest.allHTTPHeaderFields?["Date"] == "Wed, 09 Nov 2022 22:39:34 GMT")
        }
    }
    
    @Test("should return a request with httpShouldHandleCookies set false")
    func testShouldReturnRequestWithHttpShouldHandleCookiesSetFalse() {
        let bundleMock = BundleMock()
        bundleMock.dictionary?["RATDisableSharedCookieStorage"] = false
        let httpRequest = URLRequest(url: url, body: data, environmentBundle: bundleMock)
        
        #expect(httpRequest.httpShouldHandleCookies == false)
    }
}
