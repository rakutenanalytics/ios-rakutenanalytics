import Quick
import Nimble
import WebKit
@testable import RakutenAnalytics
#if canImport(RAnalyticsTestHelpers)
import RAnalyticsTestHelpers
#endif

// MARK: - RAnalyticsCookieInjectorSpec

final class RAnalyticsCookieInjectorSpec: QuickSpec {
    override class func spec() {
        describe("RAnalyticsCookieInjector") {
            let deviceID = "cc851516e51366f4856d165c3ea117e592db6fba"
            let idfa = "E621E1F8-A36C-495B-93FC-0C247A3E6E5Q"

            let containerMock = SimpleContainerMock()
            containerMock.adIdentifierManager = ASIdentifierManagerMock()
            containerMock.wkHttpCookieStore = WKHTTPCookieStorageMock()

            let adIdentifierManager: ASIdentifierManagerMock! = containerMock.adIdentifierManager as? ASIdentifierManagerMock
            let cookieInjector = RAnalyticsCookieInjector(dependenciesContainer: containerMock)
            let analyticsCookieName = "ra_uid"

            describe("injectAppToWebTrackingCookie") {
                it("should set expected cookie value using device identifier and idfa") {
                    var cookie: HTTPCookie?
                    adIdentifierManager.advertisingIdentifierUUIDString = idfa
                    cookieInjector.injectAppToWebTrackingCookie(domain: nil, deviceIdentifier: deviceID) {
                        cookie = $0
                    }
                    expect(cookie?.value).toEventually(equal("rat_uid%3D\(deviceID)%3Ba_uid%3D\(idfa)"))
                }

                it("should set cookie path to /") {
                    var cookie: HTTPCookie?
                    cookieInjector.injectAppToWebTrackingCookie(domain: nil, deviceIdentifier: deviceID) {
                        cookie = $0
                    }
                    expect(cookie?.path).toEventually(equal("/"))
                }

                it("should set cookie name to ra_uid") {
                    var cookie: HTTPCookie?
                    cookieInjector.injectAppToWebTrackingCookie(domain: nil, deviceIdentifier: deviceID) {
                        cookie = $0
                    }
                    expect(cookie?.name).toEventually(equal(analyticsCookieName))
                }

                if #available(iOS 13.0, *) {
                    it("should set cookie samesite to none") {
                        var cookie: HTTPCookie?
                        cookieInjector.injectAppToWebTrackingCookie(domain: nil, deviceIdentifier: deviceID) {
                            cookie = $0
                        }
                        expect(cookie?.sameSitePolicy).to(beNil())
                    }
                }

                it("should set cookie as secure") {
                    var cookie: HTTPCookie?
                    cookieInjector.injectAppToWebTrackingCookie(domain: nil, deviceIdentifier: deviceID) {
                        cookie = $0
                    }
                    expect(cookie?.isSecure).toEventually(beTrue())
                }

                context("when domain param is nil") {
                    it("should set default .rakuten.co.jp domain on cookie") {
                        var cookie: HTTPCookie?
                        cookieInjector.injectAppToWebTrackingCookie(domain: nil, deviceIdentifier: deviceID) {
                            cookie = $0
                        }
                        expect(cookie?.domain).toEventually(equal(".rakuten.co.jp"))
                    }
                }

                context("when domain param is non-nil") {
                    it("should set passed in domain on cookie") {
                        var cookie: HTTPCookie?
                        cookieInjector.injectAppToWebTrackingCookie(domain: ".my-domain.co.jp", deviceIdentifier: deviceID) {
                            cookie = $0
                        }
                        expect(cookie?.domain).toEventually(equal(".my-domain.co.jp"))
                    }
                }

                it("should return nil cookie when device identifier is empty") {
                    var cookie: HTTPCookie?
                    cookieInjector.injectAppToWebTrackingCookie(domain: nil, deviceIdentifier: "") {
                        cookie = $0
                    }
                    QuickSpec.performAsyncTest(timeForExecution: 1.0, timeout: 1.0) {
                        expect(cookie).to(beNil())
                    }
                }

                it("should inject cookie into WKWebsiteDataStore httpCookieStore") {
                    var hasCookie = false
                    cookieInjector.injectAppToWebTrackingCookie(domain: nil, deviceIdentifier: deviceID) { _ in
                        containerMock.wkHttpCookieStore.allCookies { cookies in
                            hasCookie = !cookies.filter { $0.name == analyticsCookieName }.isEmpty
                        }
                    }
                    expect(hasCookie).toEventually(beTrue())
                }

                it("should inject cookie into WKWebsiteDataStore httpCookieStore") {
                    var hasCookie = false
                    cookieInjector.injectAppToWebTrackingCookie(domain: nil, deviceIdentifier: deviceID) { _ in
                        containerMock.wkHttpCookieStore.allCookies { cookies in
                            hasCookie = !cookies.filter { $0.name == analyticsCookieName }.isEmpty
                        }
                    }
                    expect(hasCookie).toEventually(beTrue())
                }

                it("should delete cookies from WKWebsiteDataStore httpCookieStore") {
                    var hasCookie = true
                    cookieInjector.injectAppToWebTrackingCookie(domain: nil, deviceIdentifier: deviceID) {_ in
                        cookieInjector.clearCookies {
                            containerMock.wkHttpCookieStore.allCookies { cookies in
                                hasCookie = !cookies.filter { $0.name == analyticsCookieName }.isEmpty
                            }
                        }
                    }
                    expect(hasCookie).toEventually(beFalse())
                }

                it("should replace the existing cookie by the new one that has the same name into WKWebsiteDataStore httpCookieStore") {
                    var previousCookie: HTTPCookie?
                    var replacedCookie: HTTPCookie?
                    var ratCookies: [HTTPCookie]?

                    cookieInjector.injectAppToWebTrackingCookie(domain: "https://domain1.com", deviceIdentifier: deviceID) {
                        previousCookie = $0

                        cookieInjector.injectAppToWebTrackingCookie(domain: "https://domain2.com", deviceIdentifier: deviceID) {
                            replacedCookie = $0

                            containerMock.wkHttpCookieStore.allCookies { cookies in
                                ratCookies = cookies.filter { $0.name == analyticsCookieName }
                            }
                        }
                    }

                    expect(ratCookies?.count).toEventually(equal(1))
                    expect(previousCookie?.domain).to(equal("https://domain1.com"))
                    expect(replacedCookie?.domain).to(equal("https://domain2.com"))
                    expect(ratCookies?.first?.name).to(equal(analyticsCookieName))
                    expect(ratCookies?.first?.domain).to(equal("https://domain2.com"))
                }
            }
        }
    }
}
