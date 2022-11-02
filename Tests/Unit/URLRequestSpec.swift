import Quick
import Nimble
import Foundation
@testable import RAnalytics
#if canImport(RAnalyticsTestHelpers)
import RAnalyticsTestHelpers
#endif

final class URLRequestSpec: QuickSpec {
    override func spec() {
        describe("ratRequest") {
            let urlString = "https://www.example.com"
            let data = "foo".data(using: .utf8)!
            let request = URLRequest(url: URL(string: urlString)!, body: data)

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

            it("should return a request with httpShouldHandleCookies set false") {
                let bundleMock = BundleMock()
                bundleMock.dictionary?["RATDisableSharedCookieStorage"] = false
                let httpRequest = URLRequest(url: URL(string: urlString)!, body: data, environmentBundle: bundleMock)

                expect(httpRequest.httpShouldHandleCookies).to(equal(false))
            }
        }
    }
}
