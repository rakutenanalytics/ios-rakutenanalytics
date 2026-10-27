import CoreLocation
import Foundation
import UIKit.UIDevice
import Testing
@testable import RakutenAnalytics
#if canImport(RAnalyticsTestHelpers)
import RAnalyticsTestHelpers
#endif

@Suite("PrivacyConsentReactor integration")
struct PrivacyConsentReactorIntegrationTests {
    private static let appToWebCookieName = "ra_uid"

    @Test("multi-category consent revoke reconciles Geo, Rp, and app-to-web cookies")
    @MainActor
    func multiCategoryConsentRevokeReconcilesSubsystems() async throws {
        let container = SimpleContainerMock()
        let bundle = BundleMock()
        bundle.isPrivacyControlEnabled = true
        let endpoint = URL(string: "https://endpoint.co.jp")!
        bundle.endpointAddress = endpoint
        container.bundle = bundle

        let storage = UserDefaultsMock([:])
        let consentStore = DataCollectionConsentStore(userStorageHandler: storage, bundle: bundle)
        container.dataCollectionConsent = consentStore
        await consentStore.setEnabled(true, for: .all)

        let locationMock = LocationManagerMock()
        container.locationManager = locationMock

        let cookieStore = WKHTTPCookieStorageMock()
        container.wkHttpCookieStore = cookieStore
        container.adIdentifierManager = ASIdentifierManagerMock()

        let rpCookie = HTTPCookie(properties: [
            .name: RATConstants.RpCookie.cookieName,
            .value: "rp-integration-test",
            .domain: "endpoint.co.jp",
            .path: "/"
        ])!
        HTTPCookieStorage.shared.setCookie(rpCookie)
        #expect(HTTPCookieStorage.shared.cookies(for: endpoint)?.contains(where: {
            $0.name == RATConstants.RpCookie.cookieName
        }) == true)

        let analyticsManager = AnalyticsManager(dependenciesContainer: container)
        analyticsManager.enableAppToWebTracking = true
        _ = await analyticsManager.setWebTrackingCookieDomain(block: { "example.com" })

        let geoLocationManagerMock = GeoLocationManagerMock()
        let trackerMock = TrackerMock()
        analyticsManager.add(trackerMock)

        let geoManager = GeoManager(
            userStorageHandler: storage,
            geoLocationManager: geoLocationManagerMock,
            device: UIDevice.current,
            analyticsManager: analyticsManager,
            consentStore: consentStore
        )

        storage.removeObject(forKey: UserDefaultsKeys.configurationKey)
        geoManager.startLocationCollection()
        try await TestingHelpers.eventuallyOnMain(timeout: 1.0) {
            geoLocationManagerMock.requestLocationContinualIsCalled
        }

        try await TestingHelpers.eventuallyAsync(timeout: 2.0) {
            let cookies = await cookieStore.allCookies()
            return cookies.contains { $0.name == Self.appToWebCookieName }
        }
        #expect(locationMock.startUpdatingLocationIsCalled == true)

        geoLocationManagerMock.stopMonitoringSignificantLocationChangesIsCalled = false
        locationMock.stopUpdatingLocationIsCalled = false

        await consentStore.setEnabled(false, for: .all)

        #expect(geoLocationManagerMock.stopMonitoringSignificantLocationChangesIsCalled == true)
        #expect(locationMock.stopUpdatingLocationIsCalled == true)
        #expect(consentStore.isEnabled(.location) == false)
        #expect(consentStore.isEnabled(.deviceInformation) == false)
        #expect(consentStore.isEnabled(.userInformation) == false)
        #expect(HTTPCookieStorage.shared.cookies(for: endpoint)?.contains(where: {
            $0.name == RATConstants.RpCookie.cookieName
        }) != true)

        let cookiesAfterRevoke = await cookieStore.allCookies()
        #expect(!cookiesAfterRevoke.contains { $0.name == Self.appToWebCookieName })

        let location = CLLocation(latitude: 10.0, longitude: 20.0)
        geoLocationManagerMock.delegate?.geoLocationManager(didUpdateLocation: location, for: .continual)
        try await Task.sleep(nanoseconds: 100_000_000)
        #expect(trackerMock.event == nil)

        HTTPCookieStorage.shared.deleteCookie(rpCookie)
    }
}
