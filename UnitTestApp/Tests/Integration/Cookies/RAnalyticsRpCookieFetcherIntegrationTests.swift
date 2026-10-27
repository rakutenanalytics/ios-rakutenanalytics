import Foundation
import Testing
@testable import RakutenAnalytics
#if canImport(RAnalyticsTestHelpers)
import RAnalyticsTestHelpers
#endif

@Suite("RAnalyticsRpCookieFetcher")
struct RAnalyticsRpCookieFetcherIntegrationTests {

    @Test("fetchRpCookie - should fetch a non-nil Rp Cookie")
    @MainActor
    func testFetchRpCookieFetchesNonNilCookie() async throws {
        await Task.detached(priority: .userInitiated) {
            HTTPCookieStorage.shared.removeCookies(since: Date.distantPast)
        }.value

        guard let fetcher = RAnalyticsRpCookieFetcher(cookieStorage: HTTPCookieStorage.shared) else {
            #expect(Bool(false), "RAnalyticsRpCookieFetcher initialization failed")
            return
        }

        let cookie = try await fetcher.fetchRpCookie()
        #expect(cookie.name == "Rp")
    }
}
