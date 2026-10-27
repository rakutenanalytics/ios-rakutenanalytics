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
            adIdentifierManager?.advertisingIdentifierUUIDString = RAnalyticsCookieInjectorTests.idfa
            let cookie = await cookieInjector.injectAppToWebTrackingCookie(
                domain: nil,
                deviceIdentifier: RAnalyticsCookieInjectorTests.deviceID
            )
            let expectedValue = "rat_uid%3D\(RAnalyticsCookieInjectorTests.deviceID)%3Ba_uid%3D\(RAnalyticsCookieInjectorTests.idfa)"
            #expect(cookie?.value == expectedValue)
        }

        @Test("should set cookie path to /")
        @MainActor
        func testSetsCookiePathToRoot() async throws {
            let cookie = await cookieInjector.injectAppToWebTrackingCookie(
                domain: nil,
                deviceIdentifier: RAnalyticsCookieInjectorTests.deviceID
            )
            #expect(cookie?.path == "/")
        }

        @Test("should set cookie name to ra_uid")
        @MainActor
        func testSetsCookieNameToRaUid() async throws {
            let cookie = await cookieInjector.injectAppToWebTrackingCookie(
                domain: nil,
                deviceIdentifier: RAnalyticsCookieInjectorTests.deviceID
            )
            #expect(cookie?.name == RAnalyticsCookieInjectorTests.analyticsCookieName)
        }

        @Test("should set cookie samesite to none")
        @MainActor
        func testSetsCookieSameSiteToNone() async {
            let cookie = await cookieInjector.injectAppToWebTrackingCookie(
                domain: nil,
                deviceIdentifier: RAnalyticsCookieInjectorTests.deviceID
            )
            #expect(cookie?.sameSitePolicy == nil)
        }

        @Test("should set cookie as secure")
        @MainActor
        func testSetsCookieAsSecure() async throws {
            let cookie = await cookieInjector.injectAppToWebTrackingCookie(
                domain: nil,
                deviceIdentifier: RAnalyticsCookieInjectorTests.deviceID
            )
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
                let cookie = await cookieInjector.injectAppToWebTrackingCookie(
                    domain: nil,
                    deviceIdentifier: RAnalyticsCookieInjectorTests.deviceID
                )
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
                let cookie = await cookieInjector.injectAppToWebTrackingCookie(
                    domain: ".my-domain.co.jp",
                    deviceIdentifier: RAnalyticsCookieInjectorTests.deviceID
                )
                #expect(cookie?.domain == ".my-domain.co.jp")
            }
        }

        @Test("should return nil cookie when device identifier is empty")
        @MainActor
        func testReturnsNilCookieWhenDeviceIdentifierIsEmpty() async throws {
            let cookie = await cookieInjector.injectAppToWebTrackingCookie(domain: nil, deviceIdentifier: "")
            #expect(cookie == nil)
        }

        @Test("should inject cookie into WKWebsiteDataStore httpCookieStore")
        @MainActor
        func testInjectsCookieIntoWKWebsiteDataStoreHttpCookieStore() async throws {
            _ = await cookieInjector.injectAppToWebTrackingCookie(
                domain: nil,
                deviceIdentifier: RAnalyticsCookieInjectorTests.deviceID
            )
            let cookies = await containerMock.wkHttpCookieStore.allCookies()
            let hasCookie = !cookies.filter { $0.name == RAnalyticsCookieInjectorTests.analyticsCookieName }.isEmpty
            #expect(hasCookie == true)
        }

        @Test("should inject cookie into WKWebsiteDataStore httpCookieStore duplicate")
        @MainActor
        func testInjectsCookieIntoWKWebsiteDataStoreHttpCookieStoreDuplicate() async throws {
            _ = await cookieInjector.injectAppToWebTrackingCookie(
                domain: nil,
                deviceIdentifier: RAnalyticsCookieInjectorTests.deviceID
            )
            let cookies = await containerMock.wkHttpCookieStore.allCookies()
            let hasCookie = !cookies.filter { $0.name == RAnalyticsCookieInjectorTests.analyticsCookieName }.isEmpty
            #expect(hasCookie == true)
        }

        @Test("should delete cookies from WKWebsiteDataStore httpCookieStore")
        @MainActor
        func testDeletesCookiesFromWKWebsiteDataStoreHttpCookieStore() async throws {
            _ = await cookieInjector.injectAppToWebTrackingCookie(
                domain: nil,
                deviceIdentifier: RAnalyticsCookieInjectorTests.deviceID
            )
            await cookieInjector.clearCookies()
            let cookies = await containerMock.wkHttpCookieStore.allCookies()
            let hasCookie = !cookies.filter { $0.name == RAnalyticsCookieInjectorTests.analyticsCookieName }.isEmpty
            #expect(hasCookie == false)
        }

        @Test("should keep one ra_uid cookie per distinct domain in WKWebsiteDataStore httpCookieStore")
        @MainActor
        func testKeepsOneTrackingCookiePerDistinctDomain() async throws {
            let firstDomainCookie = await cookieInjector.injectAppToWebTrackingCookie(
                domain: "https://domain1.com",
                deviceIdentifier: RAnalyticsCookieInjectorTests.deviceID
            )
            let secondDomainCookie = await cookieInjector.injectAppToWebTrackingCookie(
                domain: "https://domain2.com",
                deviceIdentifier: RAnalyticsCookieInjectorTests.deviceID
            )
            let cookies = await containerMock.wkHttpCookieStore.allCookies()
            let ratCookies = cookies.filter { $0.name == RAnalyticsCookieInjectorTests.analyticsCookieName }
            let ratCookieDomains = Set(ratCookies.map(\.domain))

            #expect(ratCookies.count == 2)
            #expect(firstDomainCookie?.domain == "https://domain1.com")
            #expect(secondDomainCookie?.domain == "https://domain2.com")
            #expect(ratCookieDomains == ["https://domain1.com", "https://domain2.com"])
        }

        @Test("should replace the existing cookie for the same domain in WKWebsiteDataStore httpCookieStore")
        @MainActor
        func testReplacesExistingCookieForSameDomain() async throws {
            let previousCookie = await cookieInjector.injectAppToWebTrackingCookie(
                domain: ".example.com",
                deviceIdentifier: RAnalyticsCookieInjectorTests.deviceID
            )
            let replacedCookie = await cookieInjector.injectAppToWebTrackingCookie(
                domain: ".example.com",
                deviceIdentifier: "another-device-id-value0123456789abcd"
            )
            let cookies = await containerMock.wkHttpCookieStore.allCookies()
            let ratCookies = cookies.filter { $0.name == RAnalyticsCookieInjectorTests.analyticsCookieName }

            #expect(ratCookies.count == 1)
            #expect(ratCookies.first?.domain == ".example.com")
            #expect(replacedCookie?.domain == ".example.com")
            #expect(ratCookies.first?.value == replacedCookie?.value)
            #expect(ratCookies.first?.value != previousCookie?.value)
        }
    }
}
