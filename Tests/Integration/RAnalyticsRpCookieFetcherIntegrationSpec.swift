import Quick
import Nimble
import Foundation
@testable import RAnalytics
#if canImport(RAnalyticsTestHelpers)
import RAnalyticsTestHelpers
#endif

final class RAnalyticsRpCookieFetcherIntegrationSpec: QuickSpec {
    override func spec() {
        describe("RAnalyticsRpCookieFetcher") {
            describe("getRpCookieCompletionHandler") {
                it("should fetch a non-nil Rp Cookie") {
                    var cookie: HTTPCookie?
                    var error: Error?

                    // Remove the cookies from the storage so getRpCookieCompletionHandler can fetch a new cookie from the backend
                    HTTPCookieStorage.shared.removeCookies(since: Date.distantPast)

                    let fetcher = RAnalyticsRpCookieFetcher(cookieStorage: HTTPCookieStorage.shared)
                    fetcher?.getRpCookieCompletionHandler({ aCookie, anError in
                        cookie = aCookie
                        error = anError
                    })

                    expect(cookie).toEventuallyNot(beNil())
                    expect(error).to(beNil())
                }
            }
        }
    }
}
