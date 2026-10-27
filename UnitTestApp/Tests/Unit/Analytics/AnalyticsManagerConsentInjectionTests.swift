import Testing
import AdSupport
import WebKit
import CoreLocation
@testable import RakutenAnalytics
#if canImport(RAnalyticsTestHelpers)
import RAnalyticsTestHelpers
#endif

@Suite("data collection consent injection")
struct AnalyticsManagerConsentInjectionTests {
    @Test("set and isDataCollectionEnabled honor injected consent store")
    func honorsInjectedConsentStore() async {
        let container = SimpleContainerMock()
        let bundle = BundleMock()
        bundle.isPrivacyControlEnabled = true
        container.bundle = bundle

        let consentMock = DataCollectionConsentStoreMock()
        consentMock.isPrivacyControlEnabled = true
        consentMock.enabledTypes = [.location, .mobileNetwork]
        container.dataCollectionConsent = consentMock

        let manager = AnalyticsManager(dependenciesContainer: container)

        #expect(manager.isDataCollectionEnabled(dataCollection: .location) == true)
        #expect(manager.isDataCollectionEnabled(dataCollection: .deviceInformation) == false)

        await manager.set(dataCollection: .deviceInformation, enabled: true)
        #expect(manager.isDataCollectionEnabled(dataCollection: .deviceInformation) == true)

        await manager.set(dataCollection: .location, enabled: false)
        #expect(manager.isDataCollectionEnabled(dataCollection: .location) == false)
    }
}
