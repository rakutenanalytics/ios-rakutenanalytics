import Foundation
import Testing
@testable import RakutenAnalytics
#if canImport(RAnalyticsTestHelpers)
import RAnalyticsTestHelpers
#endif

@Suite("RAnalyticsRpCookieFetcher")
struct RAnalyticsRpCookieFetcherIntegrationTests {
    
    @Test("getRpCookieCompletionHandler - should fetch a non-nil Rp Cookie")
    @MainActor
    func testGetRpCookieCompletionHandlerFetchesNonNilCookie() async throws {
        await Task.detached(priority: .userInitiated) {
            HTTPCookieStorage.shared.removeCookies(since: Date.distantPast)
        }.value
        
        guard let fetcher = RAnalyticsRpCookieFetcher(cookieStorage: HTTPCookieStorage.shared) else {
            #expect(Bool(false), "RAnalyticsRpCookieFetcher initialization failed")
            return
        }
        
        let (cookie, error) = await withCheckedContinuation { (continuation: CheckedContinuation<(HTTPCookie?, NSError?), Never>) in
            fetcher.getRpCookieCompletionHandler { aCookie, anError in
                Task { @MainActor in
                    continuation.resume(returning: (aCookie, anError))
                }
            }
        }
        
        try await TestingHelpers.eventuallyOnMain(timeout: 2.0) { cookie != nil }
        #expect(cookie != nil)
        #expect(error == nil)
    }
}
