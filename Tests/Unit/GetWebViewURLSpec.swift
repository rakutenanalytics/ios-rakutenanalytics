import Quick
import Nimble
import Foundation
import UIKit
import WebKit
@testable import RAnalytics

final class GetWebViewURLSpec: QuickSpec {
    override func spec() {
        describe("getWebViewURL") {
            let url: URL! = URL(string: "https://rat.rakuten.co.jp/")
            var customView: UIView!
            var webView: WKWebView!

            beforeEach {
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
                    it("should return a non-nil URL") {
                        webView.load(URLRequest(url: url))
                        customView.addSubview(webView)

                        expect(customView.getWebViewURL()).toNot(beNil())
                    }
                }
            }
        }
    }
}
