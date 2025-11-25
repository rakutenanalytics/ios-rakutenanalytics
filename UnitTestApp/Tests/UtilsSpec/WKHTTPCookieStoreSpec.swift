import Quick
import Nimble
import Foundation
import WebKit
@testable import RakutenAnalytics
#if canImport(RAnalyticsTestHelpers)
import RAnalyticsTestHelpers
#endif

class WKHTTPCookieStoreSpec: QuickSpec {
    override class func spec() {
        describe("WKHTTPCookieStore extension") {
            var webView: WKWebView!
            var cookieStore: WKHTTPCookieStore!
            var testCookie: HTTPCookie!

            beforeEach {
                webView = WKWebView()
                cookieStore = webView.configuration.websiteDataStore.httpCookieStore

                let cookieProperties: [HTTPCookiePropertyKey: Any] = [
                    .name: "TestCookie",
                    .value: "TestValue",
                    .domain: "example.com",
                    .path: "/",
                    .expires: Date().addingTimeInterval(3600)
                ]
                testCookie = HTTPCookie(properties: cookieProperties)
            }

            context("when setting a cookie") {
                it("adds the cookie to the store") {
                    waitUntil { done in
                        cookieStore.set(cookie: testCookie) {
                            cookieStore.getAllCookies { cookies in
                                // Check if a cookie with the same properties exists
                                let matchingCookie = cookies.first { cookie in
                                    cookie.name == testCookie.name &&
                                    cookie.value == testCookie.value &&
                                    cookie.domain == testCookie.domain &&
                                    cookie.path == testCookie.path &&
                                    cookie.expiresDate == testCookie.expiresDate
                                }
                                expect(matchingCookie).toNot(beNil())
                                done()
                            }
                        }
                    }
                }
            }

            context("when deleting a cookie") {
                it("removes the cookie from the store") {
                    waitUntil { done in
                        cookieStore.set(cookie: testCookie) {
                            cookieStore.delete(cookie: testCookie) {
                                cookieStore.getAllCookies { cookies in
                                    expect(cookies).toNot(contain(testCookie))
                                    done()
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
