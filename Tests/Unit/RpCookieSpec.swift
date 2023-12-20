import Quick
import Nimble
import Foundation
@testable import RakutenAnalytics
#if canImport(RAnalyticsTestHelpers)
import RAnalyticsTestHelpers
#endif

final class RpCookieSpec: QuickSpec {
    override func spec() {
        describe("RpCookie") {
            var cookie: HTTPCookie?
            let dependenciesContainer = SimpleContainerMock()
            var ratTracker: RAnalyticsRATTracker?

            func rpCookieFromStorage() -> HTTPCookie? {
                guard let endpointAddress = BundleHelper.endpointAddress() else {
                    return nil
                }
                return dependenciesContainer.httpCookieStore.cookies(for: endpointAddress)?.first
            }

            beforeEach {
                cookie = nil
                (dependenciesContainer.httpCookieStore as? HTTPCookieStorage)?.cookies?.forEach({ cookie in
                    (dependenciesContainer.httpCookieStore as? HTTPCookieStorage)?.deleteCookie(cookie)
                })

                URLSessionMock.startMockingURLSession()
            }

            afterEach {
                URLSessionMock.stopMockingURLSession()
            }

            context("When the RAT Tracker is initialized") {
                it("should return non-nil cookie") {
                    let sessionMock = URLSessionMock.mock(originalInstance: .shared)
                    
                    sessionMock.stubRATSuccessResponse(cookieName: "TestCookieName",
                                                       cookieValue: "TestCookieValue",
                                                       expiryDate: "Fri, 16-Nov-50 16:59:07 GMT")

                    ratTracker = RAnalyticsRATTracker(dependenciesContainer: dependenciesContainer)
                    expect(ratTracker?.endpointURL).toNot(beNil())

                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        cookie = rpCookieFromStorage()
                    }

                    expect(cookie?.name).toEventually(equal("TestCookieName"))
                    expect(cookie?.value).to(equal("TestCookieValue"))
                }
            }

            context("When fetched cookie is valid") {
                it("should return non-nil cookie") {
                    let sessionMock = URLSessionMock.mock(originalInstance: .shared)

                    sessionMock.stubRATSuccessResponse(cookieName: "Rp",
                                                       cookieValue: "CookieValue",
                                                       expiryDate: "Fri, 16-Nov-50 16:59:07 GMT")

                    ratTracker = RAnalyticsRATTracker(dependenciesContainer: dependenciesContainer)
                    expect(ratTracker?.endpointURL).toNot(beNil())

                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        cookie = rpCookieFromStorage()
                    }

                    expect(cookie?.name).toEventually(equal("Rp"))
                    expect(cookie?.value).to(equal("CookieValue"))
                }
            }

            context("When fetched cookie is expired") {
                it("should return nil cookie") {
                    let sessionMock = URLSessionMock.mock(originalInstance: .shared)

                    sessionMock.stubRATSuccessResponse(cookieName: "Rp",
                                                       cookieValue: "CookieValue",
                                                       expiryDate: "Fri, 16-Nov-16 16:59:07 GMT")

                    ratTracker = RAnalyticsRATTracker(dependenciesContainer: dependenciesContainer)
                    expect(ratTracker?.endpointURL).toNot(beNil())

                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        cookie = rpCookieFromStorage()
                    }

                    expect(cookie).toAfterTimeout(beNil(), timeout: 2.0)
                }
            }

            context("When a server error occurs") {
                it("should return nil cookie") {
                    let sessionMock = URLSessionMock.mock(originalInstance: .shared)

                    sessionMock.stubRATServerErrorResponse()

                    ratTracker = RAnalyticsRATTracker(dependenciesContainer: dependenciesContainer)
                    expect(ratTracker?.endpointURL).toNot(beNil())

                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        cookie = rpCookieFromStorage()
                    }

                    expect(cookie).toAfterTimeout(beNil(), timeout: 2.0)
                }
            }
        }
    }
}
