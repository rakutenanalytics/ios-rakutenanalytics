import Testing
import AdSupport
import WebKit
import CoreLocation
@testable import RakutenAnalytics
#if canImport(RAnalyticsTestHelpers)
import RAnalyticsTestHelpers
#endif

@Suite("AnalyticsManager consent listener")
struct AnalyticsManagerConsentListenerTests {
    private static let analyticsCookieName = "ra_uid"

    @Test("location consent revoke stops monitoring synchronously on main thread")
    @MainActor
    func locationConsentRevokeStopsMonitoring() async {
        let container = SimpleContainerMock()
        let bundle = BundleMock()
        bundle.isPrivacyControlEnabled = true
        container.bundle = bundle

        let storage = UserDefaultsMock([:])
        let consentStore = DataCollectionConsentStore(userStorageHandler: storage, bundle: bundle)
        container.dataCollectionConsent = consentStore
        await consentStore.setEnabled(true, for: .location)

        let locationMock = LocationManagerMock()
        container.locationManager = locationMock

        let manager = AnalyticsManager(dependenciesContainer: container)
        #expect(manager.locationManagerIsUpdating == true)
        #expect(locationMock.startUpdatingLocationIsCalled == true)

        locationMock.stopUpdatingLocationIsCalled = false
        await consentStore.setEnabled(false, for: .location)

        #expect(locationMock.stopUpdatingLocationIsCalled == true)
    }

    @Test("device information consent revoke clears app-to-web cookies")
    @MainActor
    func deviceInformationRevokeClearsCookies() async throws {
        let container = SimpleContainerMock()
        let bundle = BundleMock()
        bundle.isPrivacyControlEnabled = true
        container.bundle = bundle

        let storage = UserDefaultsMock([:])
        let consentStore = DataCollectionConsentStore(userStorageHandler: storage, bundle: bundle)
        container.dataCollectionConsent = consentStore
        await consentStore.setEnabled(true, for: .deviceInformation)

        let cookieStore = WKHTTPCookieStorageMock()
        container.wkHttpCookieStore = cookieStore
        container.adIdentifierManager = ASIdentifierManagerMock()

        let manager = AnalyticsManager(dependenciesContainer: container)
        manager.enableAppToWebTracking = true

        _ = await manager.setWebTrackingCookieDomain(block: { "example.com" })
        try await TestingHelpers.eventuallyAsync(timeout: 2.0) {
            let cookies = await cookieStore.allCookies()
            return cookies.contains { $0.name == Self.analyticsCookieName }
        }

        await consentStore.setEnabled(false, for: .deviceInformation)

        try await TestingHelpers.eventuallyAsync(timeout: 2.0) {
            let cookies = await cookieStore.allCookies()
            return !cookies.contains { $0.name == Self.analyticsCookieName }
        }

        let cookiesAfter = await cookieStore.allCookies()
        #expect(!cookiesAfter.contains { $0.name == Self.analyticsCookieName })
    }
}
