import Testing
import Foundation
@testable import RakutenAnalytics
#if canImport(RAnalyticsTestHelpers)
import RAnalyticsTestHelpers
#endif

@Suite("RpCookie")
struct RpCookieTests {
    var cookie: HTTPCookie?
    let dependenciesContainer = SimpleContainerMock()
    var ratTracker: RAnalyticsRATTracker?
    
    @MainActor
    func triggerCookieWriteToSharedStorage() async throws {
        guard let endpointAddress = BundleHelper.endpointAddress() else {
            return
        }
        // Force a URLSession request so URLSessionMock (swizzled) can write `Set-Cookie` into HTTPCookieStorage.shared.
        // This avoids relying on Reachability state during RATTracker initialization, which can be flaky right after app removal.
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            let request = URLRequest(url: endpointAddress)
            URLSession.shared.dataTask(with: request) { _, _, error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: ())
                }
            }.resume()
        }
    }
    
    func rpCookieFromStorage() -> HTTPCookie? {
        guard let endpointAddress = BundleHelper.endpointAddress() else {
            return nil
        }
        return dependenciesContainer.httpCookieStore.cookies(for: endpointAddress)?.first
    }
    
    mutating func setUp() {
        cookie = nil
        if let endpointAddress = BundleHelper.endpointAddress(), let cookieStorage = dependenciesContainer.httpCookieStore as? HTTPCookieStorage {
            cookieStorage.cookies(for: endpointAddress)?.forEach { cookieStorage.deleteCookie($0) }
        }
        
        URLSessionMock.startMockingURLSession()
    }
    
    mutating func tearDown() {
        URLSessionMock.stopMockingURLSession()
    }
    
    @Suite("When the RAT Tracker is initialized")
    struct WhenRATTrackerIsInitializedTests {
        @Test("should return non-nil cookie")
        @MainActor
        func testShouldReturnNonNilCookie() async throws {
            var spec = RpCookieTests()
            spec.setUp()
            defer { spec.tearDown() }
            
            let sessionMock = URLSessionMock.mock(originalInstance: .shared)
            
            sessionMock.stubRATSuccessResponse(
                cookieName: "TestCookieName",
                cookieValue: "TestCookieValue",
                expiryDate: "Fri, 16-Nov-50 16:59:07 GMT")
            
            spec.ratTracker = RAnalyticsRATTracker(dependenciesContainer: spec.dependenciesContainer)
            #expect(spec.ratTracker?.endpointURL != nil)

            // Deterministically trigger the mocked request → cookie write.
            try await spec.triggerCookieWriteToSharedStorage()
            
            try await TestingHelpers.eventually(timeout: 5.0) {
                spec.cookie = spec.rpCookieFromStorage()
                return spec.cookie?.name == "TestCookieName"
            }
            #expect(spec.cookie?.name == "TestCookieName")
            #expect(spec.cookie?.value == "TestCookieValue")
        }
    }
    
    @Suite("When fetched cookie is valid")
    struct WhenFetchedCookieIsValidTests {
        @Test("should return non-nil cookie")
        @MainActor
        func testShouldReturnNonNilCookie() async throws {
            var spec = RpCookieTests()
            spec.setUp()
            defer { spec.tearDown() }
            
            let sessionMock = URLSessionMock.mock(originalInstance: .shared)
            
            sessionMock.stubRATSuccessResponse(
                cookieName: "Rp",
                cookieValue: "CookieValue",
                expiryDate: "Fri, 16-Nov-50 16:59:07 GMT")
            
            spec.ratTracker = RAnalyticsRATTracker(dependenciesContainer: spec.dependenciesContainer)
            #expect(spec.ratTracker?.endpointURL != nil)

            // Deterministically trigger the mocked request → cookie write.
            try await spec.triggerCookieWriteToSharedStorage()
            
            try await TestingHelpers.eventually(timeout: 5.0) {
                spec.cookie = spec.rpCookieFromStorage()
                return spec.cookie?.name == "Rp"
            }
            #expect(spec.cookie?.name == "Rp")
            #expect(spec.cookie?.value == "CookieValue")
        }
    }
    
    @Suite("When fetched cookie is expired")
    struct WhenFetchedCookieIsExpiredTests {
        @Test("should return nil cookie")
        @MainActor
        func testShouldReturnNilCookie() async throws {
            var spec = RpCookieTests()
            spec.setUp()
            defer { spec.tearDown() }
            
            let sessionMock = URLSessionMock.mock(originalInstance: .shared)
            
            sessionMock.stubRATSuccessResponse(
                cookieName: "Rp",
                cookieValue: "CookieValue",
                expiryDate: "Fri, 16-Nov-16 16:59:07 GMT")
            
            spec.ratTracker = RAnalyticsRATTracker(dependenciesContainer: spec.dependenciesContainer)
            #expect(spec.ratTracker?.endpointURL != nil)
            
            try await TestingHelpers.performAsyncTest(timeForExecution: 1.0, timeout: 2.0) {
                spec.cookie = spec.rpCookieFromStorage()
                #expect(spec.cookie == nil)
            }
        }
    }
    
    @Suite("When a server error occurs")
    struct WhenServerErrorOccursTests {
        @Test("should return nil cookie")
        @MainActor
        func testShouldReturnNilCookie() async throws {
            var spec = RpCookieTests()
            spec.setUp()
            defer { spec.tearDown() }
            
            let sessionMock = URLSessionMock.mock(originalInstance: .shared)
            
            sessionMock.stubRATServerErrorResponse()
            
            spec.ratTracker = RAnalyticsRATTracker(dependenciesContainer: spec.dependenciesContainer)
            #expect(spec.ratTracker?.endpointURL != nil)
            
            try await TestingHelpers.performAsyncTest(timeForExecution: 1.0, timeout: 2.0) {
                spec.cookie = spec.rpCookieFromStorage()
                #expect(spec.cookie == nil)
            }
        }
    }
}
