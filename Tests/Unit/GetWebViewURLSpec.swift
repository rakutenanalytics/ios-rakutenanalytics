import Quick
import Nimble
import Foundation
import UIKit
import WebKit
@testable import RAnalytics

#if SWIFT_PACKAGE
import RAnalyticsTestHelpers
#endif

final class GetWebViewURLSpec: QuickSpec {
    override func spec() {
        describe("getWebViewURL") {
            let url: URL! = URL(string: "https://rat.rakuten.co.jp/")
            var customView: UIView!
            var webView: WKWebView!

            beforeEach {
                UserDefaults.standard.unregister(defaultsFor: UserDefaultsKeys.userAgentKey)
                customView = UIView()
                webView = WKWebView()
            }

            context("When the view does not contain a web view") {
                it("should return a nil URL") {
                    expect(customView.getWebViewURL()).to(beNil())
                }
            }

            context("When the view contain a web view") {
                context("When the web view does not have a loaded URL") {
                    it("should return a nil URL") {
                        customView.addSubview(webView)

                        expect(customView.getWebViewURL()).to(beNil())
                    }
                }

                context("When the web view has a loaded URL") {
                    let bundleIdentifier = "jp.co.rakuten.Host"
                    let shortVersion = "1.0.0"
                    let appUserAgent = "\(bundleIdentifier)/\(shortVersion)"
                    let bundle = BundleMock()
                    bundle.bundleIdentifier = bundleIdentifier
                    bundle.shortVersion = shortVersion

                    beforeEach {
                        webView.load(URLRequest(url: url))
                    }

                    describe("getWebViewURL") {
                        it("should return a non-nil URL") {
                            customView.addSubview(webView)

                            expect(customView.getWebViewURL()).toNot(beNil())
                        }
                    }

                    describe("rCurrentUserAgent") {
                        it("should return a non-empty value without the app user agent suffix") {
                            let userAgent = webView.rCurrentUserAgent

                            expect(userAgent).toNot(beEmpty())
                            expect(userAgent?.contains(appUserAgent)).to(beFalse())
                        }

                        context("When app user agent is set at buildtime (registered in UserDefaults)") {
                            context("On iOS 17 and above the userAgent is to be set to customUserAgent") {
                                it("should return a non-empty value with the app user agent suffix") {
                                    let webView = WKWebView()
                                    let defaultWebViewUserAgent: String! = webView.rCurrentUserAgent
                                    let webViewUserAgent: String = webView.webViewUserAgent(defaultWebViewUserAgent: defaultWebViewUserAgent,
                                                                                            for: bundle)!
                                    UserDefaults.standard.register(defaults: [UserDefaultsKeys.userAgentKey: webViewUserAgent])
                                    
                                    // need to set to customUserAgent
                                    webView.enableAppUserAgent(true, bundle: bundle)
                                    let userAgent = webView.rCurrentUserAgent
                                    webView.customUserAgent = webViewUserAgent
                                    let suffix = userAgent?.suffix(appUserAgent.count).description
                                    
                                    expect(userAgent).toNot(beEmpty())
                                    expect(suffix).to(equal(appUserAgent))
                                }
                            }
                        }

                        context("When app user agent is enabled at runtime") {
                            beforeEach {
                                webView.enableAppUserAgent(true, bundle: bundle)
                            }

                            it("should return a non-empty value with the app user agent suffix") {
                                let userAgent = webView.rCurrentUserAgent
                                let suffix = userAgent?.suffix(appUserAgent.count).description
                                
                                expect(suffix).to(equal(appUserAgent))
                            }

                            context("then disabled at runtime") {
                                it("should return an empty value without the app user agent suffix") {
                                    webView.enableAppUserAgent(false, bundle: bundle)

                                    let userAgent = webView.rCurrentUserAgent

                                    expect(userAgent).toNot(beEmpty())
                                    expect(userAgent?.contains(appUserAgent)).to(beFalse())
                                }
                            }
                        }

                        context("When a custom app user agent is set") {
                            let customAppUserAgent = "helloworld"

                            it("should return a non-empty value with the custom app user agent suffix") {
                                webView.enableAppUserAgent(true, with: customAppUserAgent, bundle: bundle)

                                let userAgent = webView.rCurrentUserAgent
                                let suffix = userAgent?.suffix(customAppUserAgent.count).description

                                expect(suffix).to(equal(customAppUserAgent))
                            }
                        }

                        context("When app user agent is disabled at runtime") {
                            beforeEach {
                                webView.enableAppUserAgent(false, bundle: bundle)
                            }

                            it("should return an empty value without the app user agent suffix") {
                                let userAgent = webView.rCurrentUserAgent

                                expect(userAgent).toNot(beEmpty())
                                expect(userAgent?.contains(appUserAgent)).to(beFalse())
                            }

                            context("then enabled at runtime") {
                                it("should return a non-empty value with the app user agent suffix") {
                                    webView.enableAppUserAgent(true, bundle: bundle)

                                    let userAgent = webView.rCurrentUserAgent
                                    let suffix = userAgent?.suffix(appUserAgent.count).description

                                    expect(suffix).to(equal(appUserAgent))
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
