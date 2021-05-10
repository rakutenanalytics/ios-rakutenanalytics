import Quick
import Nimble
@testable import RAnalytics

// MARK: - RAnalyticsRpCookieFetcherSpec

final class RAnalyticsRpCookieFetcherSpec: QuickSpec {
    override func spec() {
        describe("RAnalyticsRpCookieFetcher") {
            let headerFields = ["Set-Cookie": "Rp=cookieValue; path=/; expires=Fri, 16-Nov-50 16:59:07 GMT; session-only=0; domain=.rakuten.co.jp"]
            let response = HTTPURLResponse(url: URL(string: "https://domain.com")!,
                                           statusCode: 200,
                                           httpVersion: nil,
                                           headerFields: headerFields)
            let cookies = [HTTPCookie(properties: [.path: "/",
                                                   .name: "Rp",
                                                   .value: "abcdef",
                                                   .domain: ".rakuten.com",
                                                   .expires: Date.distantFuture])!]
            let bundleMock = BundleMock()
            let cookieStorageMock = HTTPCookieStorageMock()
            let sessionMock = SessionMock()

            beforeEach {
                sessionMock.response = response
                sessionMock.willComplete = nil
                cookieStorageMock.cookiesArray = nil
            }

            describe("init") {
                it("should return nil when endpointAddress is nil") {
                    bundleMock.mutableEndpointAddress = nil
                    let cookieFetcher = RAnalyticsRpCookieFetcher(cookieStorage: cookieStorageMock, bundle: bundleMock, session: sessionMock)
                    expect(cookieFetcher).toEventually(beNil())
                }

                it("should return not nil when endpointAddress is not nil") {
                    bundleMock.mutableEndpointAddress = URL(string: "https://domain.com")
                    let cookieFetcher = RAnalyticsRpCookieFetcher(cookieStorage: cookieStorageMock, bundle: bundleMock, session: sessionMock)
                    expect(cookieFetcher).toNotEventually(beNil())
                }
            }

            describe("getRpCookieCompletionHandler") {
                var cookieFetcher: RAnalyticsRpCookieFetcher?

                beforeEach {
                    bundleMock.mutableEndpointAddress = URL(string: "https://domain.com")
                    cookieFetcher = RAnalyticsRpCookieFetcher(cookieStorage: cookieStorageMock, bundle: bundleMock, session: sessionMock)
                }

                context("when user sets 'disable shared cookie storage' key to true in app info.plist") {
                    it("should return nil cookie") {
                        bundleMock.dictionary = ["RATDisableSharedCookieStorage": true]

                        var cookie: HTTPCookie?
                        cookieFetcher?.getRpCookieCompletionHandler({ aCookie, _ in
                            cookie = aCookie
                        })
                        expect(cookie).toEventually(beNil())
                    }
                }

                context("when user sets 'disable shared cookie storage' key to false in app info.plist") {
                    it("should return Rp cookie") {
                        bundleMock.dictionary = ["RATDisableSharedCookieStorage": false]
                        sessionMock.willComplete = {
                            cookieStorageMock.cookiesArray = cookies
                        }

                        var cookie: HTTPCookie?
                        cookieFetcher?.getRpCookieCompletionHandler({ aCookie, _ in
                            cookie = aCookie
                        })
                        expect(cookie?.name).toEventually(equal("Rp"))
                    }
                }

                context("when user did not set 'disable shared cookie storage' key in app info.plist") {
                    it("should return Rp cookie") {
                        bundleMock.dictionary = nil
                        sessionMock.willComplete = {
                            cookieStorageMock.cookiesArray = cookies
                        }

                        var cookie: HTTPCookie?
                        cookieFetcher?.getRpCookieCompletionHandler({ aCookie, _ in
                            cookie = aCookie
                        })
                        expect(cookie?.name).toEventually(equal("Rp"))
                    }
                }
            }

            describe("getRpCookieFromCookieStorage") {
                var cookieFetcher: RAnalyticsRpCookieFetcher?

                beforeEach {
                    bundleMock.mutableEndpointAddress = URL(string: "https://domain.com")
                    cookieFetcher = RAnalyticsRpCookieFetcher(cookieStorage: cookieStorageMock, bundle: bundleMock, session: sessionMock)
                }

                context("when rp cookie does not exist in the cookie storage") {
                    it("should return nil") {
                        cookieStorageMock.cookiesArray = nil
                        let rpCookie = cookieFetcher?.getRpCookieFromCookieStorage()
                        expect(rpCookie).toEventually(beNil())
                    }
                }

                context("when rp cookie exists in the cookie storage") {
                    it("should return the rp cookie") {
                        cookieStorageMock.cookiesArray = cookies
                        let rpCookie = cookieFetcher?.getRpCookieFromCookieStorage()
                        expect(rpCookie?.name).toEventually(equal("Rp"))
                    }
                }
            }
        }
    }
}
