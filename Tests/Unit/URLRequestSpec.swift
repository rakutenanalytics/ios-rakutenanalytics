import Quick
import Nimble
import Foundation
@testable import RakutenAnalytics
#if canImport(RAnalyticsTestHelpers)
import RAnalyticsTestHelpers
#endif

final class URLRequestSpec: QuickSpec {
    override func spec() {
        describe("URLRequest") {
            var request: URLRequest!
            let urlString = "https://www.example.com"
            let url: URL! = URL(string: urlString)
            let data = "foo".data(using: .utf8)!

            beforeEach {
                request = URLRequest(url: url, body: data)
            }

            it("should return a request with passed-in url set") {
                expect(request.url?.absoluteString).to(equal(urlString))
            }

            it("should return a request with passed-in data set as body") {
                expect(request.httpBody).to(equal(data))
            }

            it("should return a request with timeout of 30s") {
                expect(request.timeoutInterval).to(equal(30.0))
            }

            it("should return a request set to reload ignoring cache") {
                expect(request.cachePolicy).to(equal(.reloadIgnoringCacheData))
            }

            it("should return a request with context type header set to text/plain") {
                expect(request.allHTTPHeaderFields?["Content-Type"]).to(equal("text/plain"))
            }

            it("should return a request with POST method set") {
                expect(request.httpMethod).to(equal("POST"))
            }

            it("should return a request with content length header set to expected value") {
                expect(request.allHTTPHeaderFields?["Content-Length"]).to(equal("\(data.count)"))
            }

            it("should return a request with date header set to the expected timestamp") {
                let expectedTimestamp = DateFormatter.rfc1123DateFormatter.string(from: Date())

                expect(request.allHTTPHeaderFields?["Date"]).to(equal(expectedTimestamp))
            }

            context("When timestamp is Wed, 09 Nov 2022 22:39:34 GMT") {
                it("should set the request date header to Wed, 09 Nov 2022 22:39:34 GMT") {
                    let date: Date! = DateFormatter.rfc1123DateFormatter.date(from: "Wed, 09 Nov 2022 22:39:34 GMT")

                    let urlRequest = URLRequest(url: url, body: data, at: date)

                    expect(urlRequest.allHTTPHeaderFields?["Date"]).to(equal("Wed, 09 Nov 2022 22:39:34 GMT"))
                }
            }

            it("should return a request with httpShouldHandleCookies set false") {
                let bundleMock = BundleMock()
                bundleMock.dictionary?["RATDisableSharedCookieStorage"] = false
                let httpRequest = URLRequest(url: url, body: data, environmentBundle: bundleMock)

                expect(httpRequest.httpShouldHandleCookies).to(equal(false))
            }
        }
    }
}
