import Testing
import Foundation
import UIKit
import WebKit
@testable import RakutenAnalytics

#if SWIFT_PACKAGE
import RAnalyticsTestHelpers
#endif

@Suite("getWebViewURL")
struct GetWebViewURLTests {
    static let url: URL = URL(string: "https://rat.rakuten.co.jp/")!

    @MainActor
    mutating func setUp() {
        UserDefaults.standard.unregister(defaultsFor: UserDefaultsKeys.userAgentKey)
    }

    @Suite("When the view does not contain a web view")
    struct WhenViewDoesNotContainWebViewTests {
        @Test("should return a nil URL")
        @MainActor
        func testReturnsNilURL() {
            let customView = UIView()
            #expect(customView.getWebViewURL() == nil)
        }
    }

    @Suite("When the view contain a web view")
    struct WhenViewContainsWebViewTests {
        @Suite("When the web view does not have a loaded URL")
        struct WhenWebViewDoesNotHaveLoadedURLTests {
            @Test("should return a nil URL")
            @MainActor
            func testReturnsNilURL() {
                let customView = UIView()
                let webView = WKWebView()
                customView.addSubview(webView)

                #expect(customView.getWebViewURL() == nil)
            }
        }

        @Suite("When the web view has a loaded URL")
        struct WhenWebViewHasLoadedURLTests {
            static let bundleIdentifier = "jp.co.rakuten.Host"
            static let shortVersion = "1.0.0"
            static let appUserAgent = "\(bundleIdentifier)/\(shortVersion)"
            
            static var bundle: BundleMock {
                let bundle = BundleMock()
                bundle.bundleIdentifier = bundleIdentifier
                bundle.shortVersion = shortVersion
                return bundle
            }

            @MainActor
            mutating func setUp() {
                UserDefaults.standard.unregister(defaultsFor: UserDefaultsKeys.userAgentKey)
            }

            @Suite("getWebViewURL")
            struct GetWebViewURLWhenLoadedURLTests {
                @Test("should return a non-nil URL")
                @MainActor
                func testReturnsNonNilURL() {
                    let customView = UIView()
                    let webView = WKWebView()
                    webView.load(URLRequest(url: GetWebViewURLTests.url))
                    customView.addSubview(webView)

                    #expect(customView.getWebViewURL() != nil)
                }
            }

            @Suite("rCurrentUserAgent")
            struct RCurrentUserAgentTests {
                @Test("should return a non-empty value without the app user agent suffix")
                @MainActor
                func testReturnsNonEmptyValueWithoutAppUserAgentSuffix() {
                    let webView = WKWebView()
                    webView.load(URLRequest(url: GetWebViewURLTests.url))
                    let userAgent = webView.rCurrentUserAgent
                    let appUserAgent = WhenWebViewHasLoadedURLTests.appUserAgent

                    #expect(!(userAgent?.isEmpty ?? true))
                    #expect(userAgent?.contains(appUserAgent) == false)
                }

                @Suite("When app user agent is set at buildtime (registered in UserDefaults)")
                struct WhenAppUserAgentSetAtBuildtimeTests {
                    @Suite("On iOS 17 and above the userAgent is to be set to customUserAgent")
                    struct OnIOS17AndAboveTests {
                        @Test("should return a non-empty value with the app user agent suffix")
                        @MainActor
                        func testReturnsNonEmptyValueWithAppUserAgentSuffix() {
                            let bundle = WhenWebViewHasLoadedURLTests.bundle
                            let appUserAgent = WhenWebViewHasLoadedURLTests.appUserAgent
                            let webView = WKWebView()
                            let defaultWebViewUserAgent: String = webView.rCurrentUserAgent!
                            let webViewUserAgent: String = webView.webViewUserAgent(defaultWebViewUserAgent: defaultWebViewUserAgent,
                                                                                    for: bundle)!
                            UserDefaults.standard.register(defaults: [UserDefaultsKeys.userAgentKey: webViewUserAgent])
                            
                            // need to set to customUserAgent
                            webView.enableAppUserAgent(true, bundle: bundle)
                            let userAgent = webView.rCurrentUserAgent
                            webView.customUserAgent = webViewUserAgent
                            let suffix = userAgent?.suffix(appUserAgent.count).description
                            
                            #expect(!(userAgent?.isEmpty ?? true))
                            #expect(suffix == appUserAgent)
                        }
                    }
                }

                @Suite("When app user agent is enabled at runtime")
                struct WhenAppUserAgentEnabledAtRuntimeTests {
                    @MainActor
                    mutating func setUp() {
                        UserDefaults.standard.unregister(defaultsFor: UserDefaultsKeys.userAgentKey)
                    }

                    @Test("should return a non-empty value with the app user agent suffix")
                    @MainActor
                    mutating func testReturnsNonEmptyValueWithAppUserAgentSuffix() {
                        setUp()
                        let bundle = WhenWebViewHasLoadedURLTests.bundle
                        let appUserAgent = WhenWebViewHasLoadedURLTests.appUserAgent
                        let webView = WKWebView()
                        webView.load(URLRequest(url: GetWebViewURLTests.url))
                        webView.enableAppUserAgent(true, bundle: bundle)
                        
                        let userAgent = webView.rCurrentUserAgent
                        let suffix = userAgent?.suffix(appUserAgent.count).description
                        
                        #expect(suffix == appUserAgent)
                    }

                    @Suite("then disabled at runtime")
                    struct ThenDisabledAtRuntimeTests {
                        @Test("should return an empty value without the app user agent suffix")
                        @MainActor
                        func testReturnsNonEmptyValueWithoutAppUserAgentSuffix() {
                            let bundle = WhenWebViewHasLoadedURLTests.bundle
                            let appUserAgent = WhenWebViewHasLoadedURLTests.appUserAgent
                            let webView = WKWebView()
                            webView.load(URLRequest(url: GetWebViewURLTests.url))
                            webView.enableAppUserAgent(true, bundle: bundle)
                            webView.enableAppUserAgent(false, bundle: bundle)

                            let userAgent = webView.rCurrentUserAgent

                            #expect(!(userAgent?.isEmpty ?? true))
                            #expect(userAgent?.contains(appUserAgent) == false)
                        }
                    }
                }

                @Suite("When a custom app user agent is set")
                struct WhenCustomAppUserAgentSetTests {
                    static let customAppUserAgent = "helloworld"

                    @Test("should return a non-empty value with the custom app user agent suffix")
                    @MainActor
                    func testReturnsNonEmptyValueWithCustomAppUserAgentSuffix() {
                        let bundle = WhenWebViewHasLoadedURLTests.bundle
                        let webView = WKWebView()
                        webView.load(URLRequest(url: GetWebViewURLTests.url))
                        webView.enableAppUserAgent(true, with: Self.customAppUserAgent, bundle: bundle)

                        let userAgent = webView.rCurrentUserAgent
                        let suffix = userAgent?.suffix(Self.customAppUserAgent.count).description

                        #expect(suffix == Self.customAppUserAgent)
                    }
                }

                @Suite("When app user agent is disabled at runtime")
                struct WhenAppUserAgentDisabledAtRuntimeTests {
                    @MainActor
                    mutating func setUp() {
                        UserDefaults.standard.unregister(defaultsFor: UserDefaultsKeys.userAgentKey)
                    }

                    @Test("should return an empty value without the app user agent suffix")
                    @MainActor
                    mutating func testReturnsNonEmptyValueWithoutAppUserAgentSuffix() {
                        setUp()
                        let bundle = WhenWebViewHasLoadedURLTests.bundle
                        let appUserAgent = WhenWebViewHasLoadedURLTests.appUserAgent
                        let webView = WKWebView()
                        webView.load(URLRequest(url: GetWebViewURLTests.url))
                        webView.enableAppUserAgent(false, bundle: bundle)

                        let userAgent = webView.rCurrentUserAgent

                        #expect(!(userAgent?.isEmpty ?? true))
                        #expect(userAgent?.contains(appUserAgent) == false)
                    }

                    @Suite("then enabled at runtime")
                    struct ThenEnabledAtRuntimeTests {
                        @Test("should return a non-empty value with the app user agent suffix")
                        @MainActor
                        func testReturnsNonEmptyValueWithAppUserAgentSuffix() {
                            let bundle = WhenWebViewHasLoadedURLTests.bundle
                            let appUserAgent = WhenWebViewHasLoadedURLTests.appUserAgent
                            let webView = WKWebView()
                            webView.load(URLRequest(url: GetWebViewURLTests.url))
                            webView.enableAppUserAgent(false, bundle: bundle)
                            webView.enableAppUserAgent(true, bundle: bundle)

                            let userAgent = webView.rCurrentUserAgent
                            let suffix = userAgent?.suffix(appUserAgent.count).description

                            #expect(suffix == appUserAgent)
                        }
                    }
                }
            }
        }
    }
}
