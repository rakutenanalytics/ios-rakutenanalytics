import Testing
import WebKit
@testable import RakutenAnalytics
#if canImport(RAnalyticsTestHelpers)
import RAnalyticsTestHelpers
#endif

// MARK: - RAnalyticsCookieInjectorTests

@Suite("RAnalyticsCookieInjector")
struct RAnalyticsCookieInjectorTests {
    static let deviceID = "cc851516e51366f4856d165c3ea117e592db6fba"
    static let idfa = "E621E1F8-A36C-495B-93FC-0C247A3E6E5Q"
    static let analyticsCookieName = "ra_uid"

    static var containerMock: SimpleContainerMock {
        let containerMock = SimpleContainerMock()
        containerMock.adIdentifierManager = ASIdentifierManagerMock()
        containerMock.wkHttpCookieStore = WKHTTPCookieStorageMock()
        return containerMock
    }

    @Suite("injectAppToWebTrackingCookie")
    struct InjectAppToWebTrackingCookieTests {
        var containerMock: SimpleContainerMock
        var adIdentifierManager: ASIdentifierManagerMock?
        var cookieInjector: RAnalyticsCookieInjector

        init() {
            containerMock = RAnalyticsCookieInjectorTests.containerMock
            adIdentifierManager = containerMock.adIdentifierManager as? ASIdentifierManagerMock
            cookieInjector = RAnalyticsCookieInjector(dependenciesContainer: containerMock)
        }

        @Test("should set expected cookie value using device identifier and idfa")
        @MainActor
        func testSetsExpectedCookieValueUsingDeviceIdentifierAndIdfa() async throws {
            var cookie: HTTPCookie?
            adIdentifierManager?.advertisingIdentifierUUIDString = RAnalyticsCookieInjectorTests.idfa
            await MainActor.run {
                cookieInjector.injectAppToWebTrackingCookie(domain: nil, deviceIdentifier: RAnalyticsCookieInjectorTests.deviceID) {
                    cookie = $0
                }
            }
            let expectedValue = "rat_uid%3D\(RAnalyticsCookieInjectorTests.deviceID)%3Ba_uid%3D\(RAnalyticsCookieInjectorTests.idfa)"
            try await TestingHelpers.eventuallyOnMain { cookie?.value == expectedValue }
            #expect(cookie?.value == expectedValue)
        }

        @Test("should set cookie path to /")
        @MainActor
        func testSetsCookiePathToRoot() async throws {
            var cookie: HTTPCookie?
            await MainActor.run {
                cookieInjector.injectAppToWebTrackingCookie(domain: nil, deviceIdentifier: RAnalyticsCookieInjectorTests.deviceID) {
                    cookie = $0
                }
            }
            try await TestingHelpers.eventuallyOnMain { cookie?.path == "/" }
            #expect(cookie?.path == "/")
        }

        @Test("should set cookie name to ra_uid")
        @MainActor
        func testSetsCookieNameToRaUid() async throws {
            var cookie: HTTPCookie?
            await MainActor.run {
                cookieInjector.injectAppToWebTrackingCookie(domain: nil, deviceIdentifier: RAnalyticsCookieInjectorTests.deviceID) {
                    cookie = $0
                }
            }
            try await TestingHelpers.eventuallyOnMain { cookie?.name == RAnalyticsCookieInjectorTests.analyticsCookieName }
            #expect(cookie?.name == RAnalyticsCookieInjectorTests.analyticsCookieName)
        }

        @Test("should set cookie samesite to none")
        @MainActor
        func testSetsCookieSameSiteToNone() async {
            var cookie: HTTPCookie?
            await MainActor.run {
                cookieInjector.injectAppToWebTrackingCookie(domain: nil, deviceIdentifier: RAnalyticsCookieInjectorTests.deviceID) {
                    cookie = $0
                }
            }
            #expect(cookie?.sameSitePolicy == nil)
        }

        @Test("should set cookie as secure")
        @MainActor
        func testSetsCookieAsSecure() async throws {
            var cookie: HTTPCookie?
            await MainActor.run {
                cookieInjector.injectAppToWebTrackingCookie(domain: nil, deviceIdentifier: RAnalyticsCookieInjectorTests.deviceID) {
                    cookie = $0
                }
            }
            try await TestingHelpers.eventuallyOnMain { cookie?.isSecure == true }
            #expect(cookie?.isSecure == true)
        }

        @Suite("when domain param is nil")
        struct WhenDomainParamIsNilTests {
            var containerMock: SimpleContainerMock
            var cookieInjector: RAnalyticsCookieInjector

            init() {
                containerMock = RAnalyticsCookieInjectorTests.containerMock
                cookieInjector = RAnalyticsCookieInjector(dependenciesContainer: containerMock)
            }

            @Test("should set default .rakuten.co.jp domain on cookie")
            @MainActor
            func testSetsDefaultRakutenDomainOnCookie() async throws {
                var cookie: HTTPCookie?
                await MainActor.run {
                    cookieInjector.injectAppToWebTrackingCookie(domain: nil, deviceIdentifier: RAnalyticsCookieInjectorTests.deviceID) {
                        cookie = $0
                    }
                }
                try await TestingHelpers.eventuallyOnMain { cookie?.domain == ".rakuten.co.jp" }
                #expect(cookie?.domain == ".rakuten.co.jp")
            }
        }

        @Suite("when domain param is non-nil")
        struct WhenDomainParamIsNonNilTests {
            var containerMock: SimpleContainerMock
            var cookieInjector: RAnalyticsCookieInjector

            init() {
                containerMock = RAnalyticsCookieInjectorTests.containerMock
                cookieInjector = RAnalyticsCookieInjector(dependenciesContainer: containerMock)
            }

            @Test("should set passed in domain on cookie")
            @MainActor
            func testSetsPassedInDomainOnCookie() async throws {
                var cookie: HTTPCookie?
                await MainActor.run {
                    cookieInjector.injectAppToWebTrackingCookie(domain: ".my-domain.co.jp", deviceIdentifier: RAnalyticsCookieInjectorTests.deviceID) {
                        cookie = $0
                    }
                }
                try await TestingHelpers.eventuallyOnMain { cookie?.domain == ".my-domain.co.jp" }
                #expect(cookie?.domain == ".my-domain.co.jp")
            }
        }

        @Test("should return nil cookie when device identifier is empty")
        @MainActor
        func testReturnsNilCookieWhenDeviceIdentifierIsEmpty() async throws {
            var cookie: HTTPCookie?
            await MainActor.run {
                cookieInjector.injectAppToWebTrackingCookie(domain: nil, deviceIdentifier: "") {
                    cookie = $0
                }
            }
            try await TestingHelpers.performAsyncTestOnMain(timeForExecution: 1.0, timeout: 1.0) {
                #expect(cookie == nil)
            }
        }

        @Test("should inject cookie into WKWebsiteDataStore httpCookieStore")
        @MainActor
        func testInjectsCookieIntoWKWebsiteDataStoreHttpCookieStore() async throws {
            var hasCookie = false
            await MainActor.run {
                cookieInjector.injectAppToWebTrackingCookie(domain: nil, deviceIdentifier: RAnalyticsCookieInjectorTests.deviceID) { _ in
                    containerMock.wkHttpCookieStore.allCookies { cookies in
                        hasCookie = !cookies.filter { $0.name == RAnalyticsCookieInjectorTests.analyticsCookieName }.isEmpty
                    }
                }
            }
            try await TestingHelpers.eventuallyOnMain { hasCookie == true }
            #expect(hasCookie == true)
        }

        @Test("should inject cookie into WKWebsiteDataStore httpCookieStore")
        @MainActor
        func testInjectsCookieIntoWKWebsiteDataStoreHttpCookieStoreDuplicate() async throws {
            var hasCookie = false
            await MainActor.run {
                cookieInjector.injectAppToWebTrackingCookie(domain: nil, deviceIdentifier: RAnalyticsCookieInjectorTests.deviceID) { _ in
                    containerMock.wkHttpCookieStore.allCookies { cookies in
                        hasCookie = !cookies.filter { $0.name == RAnalyticsCookieInjectorTests.analyticsCookieName }.isEmpty
                    }
                }
            }
            try await TestingHelpers.eventuallyOnMain { hasCookie == true }
            #expect(hasCookie == true)
        }

        @Test("should delete cookies from WKWebsiteDataStore httpCookieStore")
        @MainActor
        func testDeletesCookiesFromWKWebsiteDataStoreHttpCookieStore() async throws {
            var hasCookie = true
            await MainActor.run {
                cookieInjector.injectAppToWebTrackingCookie(domain: nil, deviceIdentifier: RAnalyticsCookieInjectorTests.deviceID) {_ in
                    cookieInjector.clearCookies {
                        containerMock.wkHttpCookieStore.allCookies { cookies in
                            hasCookie = !cookies.filter { $0.name == RAnalyticsCookieInjectorTests.analyticsCookieName }.isEmpty
                        }
                    }
                }
            }
            try await TestingHelpers.eventuallyOnMain { hasCookie == false }
            #expect(hasCookie == false)
        }

        @Test("should replace the existing cookie by the new one that has the same name into WKWebsiteDataStore httpCookieStore")
        @MainActor
        func testReplacesExistingCookieByNewOneWithSameName() async throws {
            var previousCookie: HTTPCookie?
            var replacedCookie: HTTPCookie?
            var ratCookies: [HTTPCookie]?

            await MainActor.run {
                cookieInjector.injectAppToWebTrackingCookie(domain: "https://domain1.com", deviceIdentifier: RAnalyticsCookieInjectorTests.deviceID) {
                    previousCookie = $0

                    cookieInjector.injectAppToWebTrackingCookie(domain: "https://domain2.com", deviceIdentifier: RAnalyticsCookieInjectorTests.deviceID) {
                        replacedCookie = $0

                        containerMock.wkHttpCookieStore.allCookies { cookies in
                            ratCookies = cookies.filter { $0.name == RAnalyticsCookieInjectorTests.analyticsCookieName }
                        }
                    }
                }
            }

            try await TestingHelpers.eventuallyOnMain { ratCookies?.count == 1 }
            #expect(ratCookies?.count == 1)
            #expect(previousCookie?.domain == "https://domain1.com")
            #expect(replacedCookie?.domain == "https://domain2.com")
            #expect(ratCookies?.first?.name == RAnalyticsCookieInjectorTests.analyticsCookieName)
            #expect(ratCookies?.first?.domain == "https://domain2.com")
        }
    }
}
