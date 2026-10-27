import Testing
import Foundation
import UIKit
@testable import RakutenAnalytics
#if canImport(RAnalyticsTestHelpers)
import RAnalyticsTestHelpers
#endif

@Suite("DataCollectionConsentStore")
struct DataCollectionConsentStoreTests {

    @Suite("isEnabled")
    struct IsEnabledTests {
        @Suite("when privacy control is disabled")
        struct WhenPrivacyControlDisabledTests {
            @Test("should return true for all types")
            func testReturnsTrueForAllTypes() {
                let bundle = BundleMock()
                bundle.isPrivacyControlEnabled = false
                let store = DataCollectionConsentStore(userStorageHandler: UserDefaultsMock([:]), bundle: bundle)

                #expect(store.isEnabled(.location) == true)
                #expect(store.isEnabled(.mobileNetwork) == true)
                #expect(store.isEnabled(.deviceInformation) == true)
                #expect(store.isEnabled(.userInformation) == true)
                #expect(store.isEnabled(.all) == true)
            }
        }

        @Suite("when privacy control is enabled")
        struct WhenPrivacyControlEnabledTests {
            @Test("should return false when not explicitly enabled")
            func testReturnsFalseWhenNotEnabled() {
                let bundle = BundleMock()
                bundle.isPrivacyControlEnabled = true
                let storage = UserDefaultsMock([:])
                let store = DataCollectionConsentStore(userStorageHandler: storage, bundle: bundle)

                #expect(store.isEnabled(.location) == false)
                #expect(store.isEnabled(.mobileNetwork) == false)
                #expect(store.isEnabled(.deviceInformation) == false)
                #expect(store.isEnabled(.userInformation) == false)
                #expect(store.storedConsentState(for: .location) == .undetermined)
            }

            @Test("should return true after setEnabled for specific type")
            func testReturnsTrueAfterSetEnabled() async {
                let bundle = BundleMock()
                bundle.isPrivacyControlEnabled = true
                let storage = UserDefaultsMock([:])
                let store = DataCollectionConsentStore(userStorageHandler: storage, bundle: bundle)

                await store.setEnabled(true, for: .location)
                #expect(store.isEnabled(.location) == true)
                #expect(store.isEnabled(.mobileNetwork) == false)
            }

            @Test("should return true for all when all types enabled")
            func testReturnsTrueForAllWhenAllEnabled() async {
                let bundle = BundleMock()
                bundle.isPrivacyControlEnabled = true
                let storage = UserDefaultsMock([:])
                let store = DataCollectionConsentStore(userStorageHandler: storage, bundle: bundle)

                await store.setEnabled(true, for: .all)
                #expect(store.isEnabled(.all) == true)
                #expect(store.isEnabled(.location) == true)
                #expect(store.isEnabled(.userInformation) == true)
            }

            @Test("should return false for all when any type disabled")
            func testReturnsFalseForAllWhenAnyDisabled() async {
                let bundle = BundleMock()
                bundle.isPrivacyControlEnabled = true
                let storage = UserDefaultsMock([:])
                let store = DataCollectionConsentStore(userStorageHandler: storage, bundle: bundle)

                await store.setEnabled(true, for: .location)
                await store.setEnabled(true, for: .mobileNetwork)
                await store.setEnabled(false, for: .deviceInformation)
                #expect(store.isEnabled(.all) == false)
            }
        }
    }

    @Suite("setEnabled")
    struct SetEnabledTests {
        @Test("should persist value for location")
        func testPersistsValueForLocation() async {
            let bundle = BundleMock()
            bundle.isPrivacyControlEnabled = true
            let storage = UserDefaultsMock([:])
            let store = DataCollectionConsentStore(userStorageHandler: storage, bundle: bundle)

            await store.setEnabled(true, for: .location)
            #expect((storage.object(forKey: "RATDataCollection_location") as? NSNumber)?.boolValue == true)

            await store.setEnabled(false, for: .location)
            #expect((storage.object(forKey: "RATDataCollection_location") as? NSNumber)?.boolValue == false)
        }

        @Test("should update all types when setting .all")
        func testUpdatesAllTypesWhenSettingAll() async {
            let bundle = BundleMock()
            bundle.isPrivacyControlEnabled = true
            let storage = UserDefaultsMock([:])
            let store = DataCollectionConsentStore(userStorageHandler: storage, bundle: bundle)

            await store.setEnabled(true, for: .all)
            #expect(storage.bool(forKey: "RATDataCollection_location") == true)
            #expect(storage.bool(forKey: "RATDataCollection_mobileNetwork") == true)
            #expect(storage.bool(forKey: "RATDataCollection_deviceInformation") == true)
            #expect(storage.bool(forKey: "RATDataCollection_userInformation") == true)
        }

        @Test("should have no effect when privacy control disabled")
        func testNoEffectWhenPrivacyControlDisabled() async {
            let bundle = BundleMock()
            bundle.isPrivacyControlEnabled = false
            let storage = UserDefaultsMock([:])
            let store = DataCollectionConsentStore(userStorageHandler: storage, bundle: bundle)

            await store.setEnabled(false, for: .location)
            #expect(store.isEnabled(.location) == true)
        }

        @Test("set all to false disables user information including Rp cookie consent")
        func setAllFalseDisablesUserInformation() async {
            let bundle = BundleMock()
            bundle.isPrivacyControlEnabled = true
            let storage = UserDefaultsMock([:])
            let store = DataCollectionConsentStore(userStorageHandler: storage, bundle: bundle)

            await store.setEnabled(false, for: .all)
            #expect(store.isEnabled(.userInformation) == false)
        }

        @Test("only userInformation true enables Rp-related consent")
        func userInformationEnablesRpConsent() async {
            let bundle = BundleMock()
            bundle.isPrivacyControlEnabled = true
            let storage = UserDefaultsMock([:])
            let store = DataCollectionConsentStore(userStorageHandler: storage, bundle: bundle)

            await store.setEnabled(true, for: .mobileNetwork)
            #expect(store.isEnabled(.userInformation) == false)
            await store.setEnabled(true, for: .userInformation)
            #expect(store.isEnabled(.userInformation) == true)
        }
    }

    @Suite("storedConsentState edge cases")
    struct StoredConsentStateEdgeCasesTests {
        @Test("storedConsentState returns nil for aggregate type .all when privacy enabled")
        func storedConsentStateForAllIsNil() {
            let bundle = BundleMock()
            bundle.isPrivacyControlEnabled = true
            let store = DataCollectionConsentStore(userStorageHandler: UserDefaultsMock([:]), bundle: bundle)
            #expect(store.storedConsentState(for: .all) == nil)
        }

        @Test("storedConsentState returns nil when privacy control disabled")
        func storedConsentStateNilWhenPrivacyDisabled() {
            let bundle = BundleMock()
            bundle.isPrivacyControlEnabled = false
            let storage = UserDefaultsMock([:])
            storage.set(value: NSNumber(value: true), forKey: "RATDataCollection_location")
            let store = DataCollectionConsentStore(userStorageHandler: storage, bundle: bundle)
            #expect(store.storedConsentState(for: .location) == nil)
        }

        @Test("non-bool stored object is treated as undetermined")
        func corruptStoredValueIsUndetermined() {
            let bundle = BundleMock()
            bundle.isPrivacyControlEnabled = true
            let storage = UserDefaultsMock([:])
            storage.set(value: "not-a-bool", forKey: "RATDataCollection_location")
            let store = DataCollectionConsentStore(userStorageHandler: storage, bundle: bundle)
            #expect(store.storedConsentState(for: .location) == .undetermined)
            #expect(store.isEnabled(.location) == false)
        }
    }

    @Suite("consent mutation ordering")
    struct ConsentMutationOrderingTests {
        @Test("Geo is paused before setEnabled returns on main thread")
        @MainActor
        func geoPausedBeforeSetEnabledReturnsOnMainThread() async throws {
            let bundle = BundleMock()
            bundle.isPrivacyControlEnabled = true
            let storage = UserDefaultsMock([:])
            let store = DataCollectionConsentStore(userStorageHandler: storage, bundle: bundle)
            await store.setEnabled(true, for: .all)

            let geoLocationManagerMock = GeoLocationManagerMock()
            let geoManager = GeoManager(
                userStorageHandler: storage,
                geoLocationManager: geoLocationManagerMock,
                device: UIDevice.current,
                analyticsManager: {
                    let analyticsManager = AnalyticsManager(dependenciesContainer: SimpleDependenciesContainer())
                    analyticsManager.add(TrackerMock())
                    return analyticsManager
                }(),
                consentStore: store
            )

            storage.removeObject(forKey: UserDefaultsKeys.configurationKey)
            geoManager.startLocationCollection()
            try await TestingHelpers.eventuallyOnMain(timeout: 1.0) {
                geoLocationManagerMock.requestLocationContinualIsCalled
            }

            geoLocationManagerMock.stopMonitoringSignificantLocationChangesIsCalled = false
            await store.setEnabled(false, for: .location)

            #expect(geoLocationManagerMock.stopMonitoringSignificantLocationChangesIsCalled == true)
            #expect(store.isEnabled(.location) == false)
        }
    }
}
