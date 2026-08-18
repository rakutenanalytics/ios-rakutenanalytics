import Testing
import AdSupport
import WebKit
import CoreLocation
@testable import RakutenAnalytics
#if canImport(RAnalyticsTestHelpers)
import RAnalyticsTestHelpers
#endif

@Suite("AnalyticsManager's Web View User Agent")
struct AnalyticsManagerUATests {
    static let shortVersion = "1.0"
    static let bundleIdentifier = "jp.co.rakuten.Host"
    
    static var dependenciesContainer: SimpleContainerMock {
        let container = SimpleContainerMock()
        let bundle = BundleMock.create()
        bundle.bundleIdentifier = bundleIdentifier
        bundle.shortVersion = shortVersion
        container.bundle = bundle
        return container
    }
    
    static var bundle: BundleMock {
        let bundle = BundleMock.create()
        bundle.bundleIdentifier = bundleIdentifier
        bundle.shortVersion = shortVersion
        return bundle
    }

    @Suite("Web View User Agent feature")
    struct WebViewUserAgentFeatureTests {
        static let appUserAgent = "\(AnalyticsManagerUATests.bundleIdentifier)/\(AnalyticsManagerUATests.shortVersion)"

        @Suite("When the web view user agent is enabled at buildtime")
        struct WhenWebViewUserAgentEnabledAtBuildtimeTests {

            @Suite("On iOS 17 and above the userAgent to be set to customUserAgent")
            struct OnIOS17AndAboveTests {
                mutating func setUp() {
                    UserDefaults.standard.unregister(defaultsFor: UserDefaultsKeys.userAgentKey)
                }

                @Test("should add the app user agent suffix to the WKWebView's user agent")
                @MainActor
                mutating func testAddsAppUserAgentSuffixToWKWebViewUserAgent() async throws {
                    setUp()
                    var userAgent: String?
                    var webView: WKWebView?
                    
                    let bundle = BundleMock.create()
                    bundle.bundleIdentifier = AnalyticsManagerUATests.bundleIdentifier
                    bundle.shortVersion = AnalyticsManagerUATests.shortVersion
                    bundle.isWebViewAppUserAgentEnabledAtBuildtime = true
                    
                    let dependenciesContainer = SimpleContainerMock()
                    dependenciesContainer.bundle = bundle
                    
                    _ = AnalyticsManager(dependenciesContainer: dependenciesContainer)

                    await MainActor.run {
                        webView = WKWebView()
                        webView?.enableAppUserAgent(true, bundle: bundle)
                        userAgent = webView?.rCurrentUserAgent
                    }

                    let testAppUserAgent = WebViewUserAgentFeatureTests.appUserAgent
                    try await TestingHelpers.eventuallyOnMain {
                        userAgent?.suffix(testAppUserAgent.count).description == testAppUserAgent
                    }
                }
            }

            @Suite("Then the web view user agent is disabled at runtime")
            struct ThenWebViewUserAgentDisabledAtRuntimeTests {
                mutating func setUp() {
                    UserDefaults.standard.unregister(defaultsFor: UserDefaultsKeys.userAgentKey)
                }

                @Test("should not add the app user agent suffix to the WKWebView's user agent")
                @MainActor
                mutating func testDoesNotAddAppUserAgentSuffixToWKWebViewUserAgent() async throws {
                    setUp()
                    var webView: WKWebView?
                    var userAgent: String?

                    let bundle = BundleMock.create()
                    bundle.bundleIdentifier = AnalyticsManagerUATests.bundleIdentifier
                    bundle.shortVersion = AnalyticsManagerUATests.shortVersion
                    bundle.isWebViewAppUserAgentEnabledAtBuildtime = true

                    let dependenciesContainer = SimpleContainerMock()
                    dependenciesContainer.bundle = bundle

                    let manager = AnalyticsManager(dependenciesContainer: dependenciesContainer)

                    await MainActor.run {
                        webView = WKWebView()
                    }

                    let testWebView = webView
                    try await TestingHelpers.eventuallyOnMain { testWebView != nil }

                    webView?.enableAppUserAgent(false, bundle: bundle, manager: manager)

                    userAgent = webView?.rCurrentUserAgent
                    let testAppUserAgent = WebViewUserAgentFeatureTests.appUserAgent
                    #expect(userAgent?.contains(testAppUserAgent) == false)
                }
            }
        }

        @Suite("When the web view user agent is disabled at buildtime")
        struct WhenWebViewUserAgentDisabledAtBuildtimeTests {
            mutating func setUp() {
                UserDefaults.standard.unregister(defaultsFor: UserDefaultsKeys.userAgentKey)
            }

            @Test("should not add the app user agent suffix to the WKWebView's user agent")
            @MainActor
            mutating func testDoesNotAddAppUserAgentSuffixToWKWebViewUserAgent() async throws {
                setUp()
                var userAgent: String?

                let bundle = BundleMock.create()
                bundle.bundleIdentifier = AnalyticsManagerUATests.bundleIdentifier
                bundle.shortVersion = AnalyticsManagerUATests.shortVersion
                bundle.isWebViewAppUserAgentEnabledAtBuildtime = false

                let dependenciesContainer = SimpleContainerMock()
                dependenciesContainer.bundle = bundle

                _ = AnalyticsManager(dependenciesContainer: dependenciesContainer)

                await MainActor.run {
                    userAgent = WKWebView().rCurrentUserAgent
                }

                try await TestingHelpers.eventuallyOnMain { !(userAgent?.isEmpty ?? true) }
                let testAppUserAgent = WebViewUserAgentFeatureTests.appUserAgent
                #expect(userAgent?.contains(testAppUserAgent) == false)
            }

            @Suite("Then the web view user agent is enabled at runtime")
            struct ThenWebViewUserAgentEnabledAtRuntimeTests {
                mutating func setUp() {
                    UserDefaults.standard.unregister(defaultsFor: UserDefaultsKeys.userAgentKey)
                }

                @Test("should add the app user agent suffix to the WKWebView's user agent")
                @MainActor
                mutating func testAddsAppUserAgentSuffixToWKWebViewUserAgent() async throws {
                    setUp()
                    var webView: WKWebView?
                    var userAgent: String?

                    let bundle = BundleMock.create()
                    bundle.bundleIdentifier = AnalyticsManagerUATests.bundleIdentifier
                    bundle.shortVersion = AnalyticsManagerUATests.shortVersion
                    bundle.isWebViewAppUserAgentEnabledAtBuildtime = false

                    let dependenciesContainer = SimpleContainerMock()
                    dependenciesContainer.bundle = bundle

                    let manager = AnalyticsManager(dependenciesContainer: dependenciesContainer)

                    await MainActor.run {
                        webView = WKWebView()
                    }

                    let testWebView = webView
                    try await TestingHelpers.eventuallyOnMain { testWebView != nil }

                    webView?.enableAppUserAgent(true, bundle: bundle, manager: manager)

                    userAgent = webView?.rCurrentUserAgent
                    let testAppUserAgent = WebViewUserAgentFeatureTests.appUserAgent
                    #expect(userAgent?.suffix(testAppUserAgent.count).description == testAppUserAgent)
                }
            }
        }
    }
}
