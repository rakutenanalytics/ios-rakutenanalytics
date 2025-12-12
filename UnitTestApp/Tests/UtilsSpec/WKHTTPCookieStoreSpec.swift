import Testing
import Foundation
import WebKit
@testable import RakutenAnalytics
#if canImport(RAnalyticsTestHelpers)
import RAnalyticsTestHelpers
#endif

@Suite("WKHTTPCookieStore extension")
struct WKHTTPCookieStoreSpec {
    
    @MainActor
    static func createWebViewAndCookie() -> (webView: WKWebView, cookieStore: WKHTTPCookieStore, testCookie: HTTPCookie) {
        let webView = WKWebView()
        let cookieStore = webView.configuration.websiteDataStore.httpCookieStore
        
        let cookieProperties: [HTTPCookiePropertyKey: Any] = [
            .name: "TestCookie",
            .value: "TestValue",
            .domain: "example.com",
            .path: "/",
            .expires: Date().addingTimeInterval(3600)
        ]
        let testCookie = HTTPCookie(properties: cookieProperties)!
        
        return (webView, cookieStore, testCookie)
    }
    
    @Suite("when setting a cookie")
    struct WhenSettingCookieTests {
        @Test("adds the cookie to the store")
        @MainActor
        func testAddsCookieToStore() async throws {
            let (_, cookieStore, testCookie) = WKHTTPCookieStoreSpec.createWebViewAndCookie()
            
            try await withCheckedThrowingContinuation { continuation in
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
                        #expect(matchingCookie != nil)
                        continuation.resume()
                    }
                }
            }
        }
    }
    
    @Suite("when deleting a cookie")
    struct WhenDeletingCookieTests {
        @Test("removes the cookie from the store")
        @MainActor
        func testRemovesCookieFromStore() async throws {
            let (_, cookieStore, testCookie) = WKHTTPCookieStoreSpec.createWebViewAndCookie()
            
            try await withCheckedThrowingContinuation { continuation in
                let setCookieHandler: () -> Void = {
                    let deleteCookieHandler: () -> Void = {
                        cookieStore.getAllCookies { cookies in
                            // Check if a cookie with matching properties exists
                            let matchingCookie = cookies.first { cookie in
                                cookie.name == testCookie.name &&
                                cookie.value == testCookie.value &&
                                cookie.domain == testCookie.domain &&
                                cookie.path == testCookie.path &&
                                cookie.expiresDate == testCookie.expiresDate
                            }
                            #expect(matchingCookie == nil)
                            continuation.resume()
                        }
                    }
                    cookieStore.delete(cookie: testCookie, completionHandler: deleteCookieHandler)
                }
                cookieStore.set(cookie: testCookie, completionHandler: setCookieHandler)
            }
        }
    }
}
