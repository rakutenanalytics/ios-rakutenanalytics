import Quick
import Nimble
@testable import RAnalytics

// MARK: - RAnalyticsRpCookieFetcherSpec

final class RAnalyticsRpCookieFetcherSpec: QuickSpec {
    override func spec() {
        describe("RAnalyticsRpCookieFetcher") {
            let headerFields = ["Set-Cookie": "Rp=cookieValue; path=/; expires=Fri, 16-Nov-50 16:59:07 GMT; session-only=0; domain=.rakuten.co.jp"]
            let urlString = "https://domain.com"
            let response = HTTPURLResponse(url: URL(string: urlString)!,
                                           statusCode: 200,
                                           httpVersion: nil,
                                           headerFields: headerFields)
            let cookies = [HTTPCookie(properties: [.path: "/",
                                                   .name: "Rp",
                                                   .value: "abcdef",
                                                   .domain: ".rakuten.com",
                                                   .expires: Date.distantFuture])!]
            let emptyResponse = HTTPURLResponse(url: URL(string: urlString)!,
                                                statusCode: 200,
                                                httpVersion: nil,
                                                headerFields: nil)
            let bundleMock = BundleMock()
            let cookieStorageMock = HTTPCookieStorageMock()
            let sessionMock = SessionMock()
            let maximumTimeOut: UInt = 3

            describe("init") {
                it("should return nil when endpointAddress is nil") {
                    bundleMock.mutableEndpointAddress = nil
                    let cookieFetcher = RAnalyticsRpCookieFetcher(cookieStorage: cookieStorageMock,
                                                                  bundle: bundleMock,
                                                                  session: sessionMock,
                                                                  maximumTimeOut: maximumTimeOut)
                    expect(cookieFetcher).toEventually(beNil())
                }

                it("should return not nil when endpointAddress is not nil") {
                    bundleMock.mutableEndpointAddress = URL(string: urlString)
                    let cookieFetcher = RAnalyticsRpCookieFetcher(cookieStorage: cookieStorageMock,
                                                                  bundle: bundleMock,
                                                                  session: sessionMock,
                                                                  maximumTimeOut: maximumTimeOut)
                    expect(cookieFetcher).toNotEventually(beNil())
                }
            }

            describe("getRpCookieCompletionHandler") {
                beforeEach {
                    sessionMock.response = nil
                    sessionMock.error = nil
                    sessionMock.willComplete = nil
                    cookieStorageMock.cookiesArray = nil
                }

                var cookieFetcher: RAnalyticsRpCookieFetcher?

                beforeEach {
                    bundleMock.mutableEndpointAddress = URL(string: urlString)
                    cookieFetcher = RAnalyticsRpCookieFetcher(cookieStorage: cookieStorageMock,
                                                              bundle: bundleMock,
                                                              session: sessionMock,
                                                              maximumTimeOut: maximumTimeOut)
                }

                context("when user sets 'disable shared cookie storage' key to true in app info.plist") {
                    it("should return the Rp cookie when the Rp Cookie exists in the cookie storage") {
                        bundleMock.dictionary = ["RATDisableSharedCookieStorage": true]

                        var cookie: HTTPCookie?
                        var error: Error?
                        sessionMock.response = response
                        sessionMock.willComplete = {
                            cookieStorageMock.cookiesArray = cookies
                        }

                        cookieFetcher?.getRpCookieCompletionHandler { aCookie, anError in
                            cookie = aCookie
                            error = anError
                        }
                        expect(cookie).toEventuallyNot(beNil())
                        expect(error).to(beNil())
                    }

                    it("should return an error when the Rp Cookie does not exist in the cookie storage") {
                        bundleMock.dictionary = ["RATDisableSharedCookieStorage": true]

                        var cookie: HTTPCookie?
                        var error: Error?
                        sessionMock.response = response
                        cookieFetcher?.getRpCookieCompletionHandler { aCookie, anError in
                            cookie = aCookie
                            error = anError
                        }
                        expect(error).toEventuallyNot(beNil())
                        expect((error as NSError?)?.localizedDescription)
                            .toEventually(equal("Cannot get Rp cookie from the Cookie Storage - \(urlString)"))
                        expect(cookie).to(beNil())
                    }
                }

                context("when user sets 'disable shared cookie storage' key to false in app info.plist") {
                    it("should return Rp cookie when the http response contains the RP Cookie") {
                        bundleMock.dictionary = ["RATDisableSharedCookieStorage": false]
                        sessionMock.response = response

                        var cookie: HTTPCookie?
                        var error: Error?
                        cookieFetcher?.getRpCookieCompletionHandler { aCookie, anError in
                            cookie = aCookie
                            error = anError
                        }
                        expect(cookie?.name).toEventually(equal("Rp"))
                        expect(error).to(beNil())
                    }

                    it("should return an error when the http response does not contain the RP Cookie") {
                        bundleMock.dictionary = ["RATDisableSharedCookieStorage": false]
                        sessionMock.response = emptyResponse

                        var cookie: HTTPCookie?
                        var error: Error?
                        cookieFetcher?.getRpCookieCompletionHandler { aCookie, anError in
                            cookie = aCookie
                            error = anError
                        }
                        expect(error).toEventuallyNot(beNil())
                        expect((error as NSError?)?.localizedDescription)
                            .toEventually(equal("Cannot get Rp cookie from the RAT Server HTTP Response - \(urlString)"))
                        expect(cookie).to(beNil())
                    }
                }

                context("when user did not set 'disable shared cookie storage' key in app info.plist") {
                    it("should return Rp cookie when the http response contains the RP Cookie") {
                        bundleMock.dictionary = nil
                        sessionMock.response = response

                        var cookie: HTTPCookie?
                        var error: Error?
                        cookieFetcher?.getRpCookieCompletionHandler { aCookie, anError in
                            cookie = aCookie
                            error = anError
                        }
                        expect(cookie?.name).toEventually(equal("Rp"))
                        expect(error).to(beNil())
                    }

                    it("should return an error when the http response does not contain the RP Cookie") {
                        bundleMock.dictionary = nil
                        sessionMock.response = emptyResponse

                        var cookie: HTTPCookie?
                        var error: Error?
                        cookieFetcher?.getRpCookieCompletionHandler { aCookie, anError in
                            cookie = aCookie
                            error = anError
                        }
                        expect(error).toEventuallyNot(beNil())
                        expect((error as NSError?)?.localizedDescription)
                            .toEventually(equal("Cannot get Rp cookie from the RAT Server HTTP Response - \(urlString)"))
                        expect(cookie).to(beNil())
                    }
                }

                context("when the session returns an error") {
                    it("should return an error after retry timeout") {
                        var cookie: HTTPCookie?
                        var error: Error?
                        let rpError = NSError(domain: NSURLErrorDomain, code: 500, userInfo: nil)
                        sessionMock.error = rpError
                        cookieFetcher?.getRpCookieCompletionHandler { aCookie, anError in
                            cookie = aCookie
                            error = anError
                        }
                        expect(error as NSError?).toEventually(equal(rpError), timeout: .seconds(Int(maximumTimeOut)))
                        expect(cookie).to(beNil())
                    }
                }

                context("when the session returns a status code equal to 400") {
                    it("should return an error after retry timeout") {
                        var cookie: HTTPCookie?
                        var error: Error?
                        let errorResponse = HTTPURLResponse(url: URL(string: urlString)!,
                                                            statusCode: 400,
                                                            httpVersion: nil,
                                                            headerFields: nil)
                        sessionMock.response = errorResponse
                        cookieFetcher?.getRpCookieCompletionHandler { aCookie, anError in
                            cookie = aCookie
                            error = anError
                        }
                        expect(error as NSError?).toAfterTimeoutNot(beNil(), timeout: TimeInterval(maximumTimeOut))
                        expect(cookie).to(beNil())
                    }
                }
            }

            describe("getRpCookieFromCookieStorage") {
                beforeEach {
                    cookieStorageMock.cookiesArray = nil
                }

                var cookieFetcher: RAnalyticsRpCookieFetcher?

                beforeEach {
                    bundleMock.mutableEndpointAddress = URL(string: urlString)
                    cookieFetcher = RAnalyticsRpCookieFetcher(cookieStorage: cookieStorageMock,
                                                              bundle: bundleMock,
                                                              session: sessionMock,
                                                              maximumTimeOut: maximumTimeOut)
                }

                context("when rp cookie does not exist in the cookie storage") {
                    it("should return nil") {
                        cookieStorageMock.cookiesArray = nil
                        let rpCookie = cookieFetcher?.getRpCookieFromCookieStorage()
                        expect(rpCookie).toAfterTimeout(beNil())
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
