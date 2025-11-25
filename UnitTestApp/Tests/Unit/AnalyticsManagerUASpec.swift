import Quick
import Nimble
import AdSupport
import WebKit
import CoreLocation
@testable import RakutenAnalytics
#if canImport(RAnalyticsTestHelpers)
import RAnalyticsTestHelpers
#endif

final class AnalyticsManagerUASpec: QuickSpec {
    override class func spec() {
        describe("AnalyticsManager's Web View User Agent") {
            let shortVersion = "1.0"
            let bundleIdentifier = "jp.co.rakuten.Host"
            let dependenciesContainer = SimpleContainerMock()
            let bundle = BundleMock.create()
            bundle.bundleIdentifier = bundleIdentifier
            bundle.shortVersion = shortVersion
            dependenciesContainer.bundle = bundle

            describe("Web View User Agent feature") {
                let appUserAgent = "\(bundleIdentifier)/\(shortVersion)"

                beforeEach {
                    UserDefaults.standard.unregister(defaultsFor: UserDefaultsKeys.userAgentKey)
                }

                context("When the web view user agent is enabled at buildtime") {
                    context("On iOS 17 and above the userAgent to be set to customUserAgent") {
                        it("should add the app user agent suffix to the WKWebView's user agent") {
                            var userAgent: String?
                            var webView: WKWebView?
                            bundle.isWebViewAppUserAgentEnabledAtBuildtime = true
                            _ = AnalyticsManager(dependenciesContainer: dependenciesContainer)

                            DispatchQueue.main.async {
                                webView = WKWebView()
                                webView?.enableAppUserAgent(true, bundle: bundle)
                                userAgent = webView?.rCurrentUserAgent
                            }

                            expect(userAgent?.suffix(appUserAgent.count).description).toEventually(equal(appUserAgent))
                        }
                    }

                    context("Then the web view user agent is disabled at runtime") {
                        it("should not add the app user agent suffix to the WKWebView's user agent") {
                            var webView: WKWebView?
                            var userAgent: String?

                            bundle.isWebViewAppUserAgentEnabledAtBuildtime = true

                            let manager = AnalyticsManager(dependenciesContainer: dependenciesContainer)

                            DispatchQueue.main.async {
                                webView = WKWebView()
                            }

                            expect(webView).toEventuallyNot(beNil())

                            webView?.enableAppUserAgent(false, bundle: bundle, manager: manager)

                            userAgent = webView?.rCurrentUserAgent
                            expect(userAgent?.contains(appUserAgent)).to(beFalse())
                        }
                    }
                }

                context("When the web view user agent is disabled at buildtime") {
                    it("should not add the app user agent suffix to the WKWebView's user agent") {
                        var userAgent: String?

                        bundle.isWebViewAppUserAgentEnabledAtBuildtime = false

                        _ = AnalyticsManager(dependenciesContainer: dependenciesContainer)

                        DispatchQueue.main.async {
                            userAgent = WKWebView().rCurrentUserAgent
                        }

                        expect(userAgent).toEventuallyNot(beEmpty())
                        expect(userAgent?.contains(appUserAgent)).to(beFalse())
                    }

                    context("Then the web view user agent is enabled at runtime") {
                        it("should add the app user agent suffix to the WKWebView's user agent") {
                            var webView: WKWebView?
                            var userAgent: String?

                            bundle.isWebViewAppUserAgentEnabledAtBuildtime = false

                            let manager = AnalyticsManager(dependenciesContainer: dependenciesContainer)

                            DispatchQueue.main.async {
                                webView = WKWebView()
                            }

                            expect(webView).toEventuallyNot(beNil())

                            webView?.enableAppUserAgent(true, bundle: bundle, manager: manager)

                            userAgent = webView?.rCurrentUserAgent
                            expect(userAgent?.suffix(appUserAgent.count).description).to(equal(appUserAgent))
                        }
                    }
                }
            }
        }
    }
}
