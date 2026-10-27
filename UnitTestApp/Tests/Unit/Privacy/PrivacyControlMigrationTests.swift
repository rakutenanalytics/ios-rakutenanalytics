import Testing
import Foundation
@testable import RakutenAnalytics
#if canImport(RAnalyticsTestHelpers)
import RAnalyticsTestHelpers
#endif

@Suite("PrivacyControlMigration")
struct PrivacyControlMigrationTests {

    private func makeStore(privacyEnabled: Bool, storage: UserDefaultsMock = UserDefaultsMock([:])) -> DataCollectionConsentStore {
        let bundle = BundleMock()
        bundle.isPrivacyControlEnabled = privacyEnabled
        return DataCollectionConsentStore(userStorageHandler: storage, bundle: bundle)
    }

    @Suite("DataCollectionConsentStore migration persistence")
    struct StoreMigrationTests {
        @Test("storedPrivacyVersion returns nil when privacy control is disabled even if value exists")
        func privacyVersionNilWhenPrivacyDisabled() {
            let storage = UserDefaultsMock([:])
            storage.set(value: NSNumber(value: 1), forKey: RATConstants.PrivacyControl.privacyVersionKey)
            let store = PrivacyControlMigrationTests().makeStore(privacyEnabled: false, storage: storage)
            #expect(store.storedPrivacyVersion == nil)
        }

        @Test("typesWithoutConsent returns all individual types on fresh install")
        func freshInstallAllTypesNeedConsent() {
            let store = PrivacyControlMigrationTests().makeStore(privacyEnabled: true)
            #expect(store.typesWithoutConsent() == DataCollectionType.individualTypes)
            #expect(store.storedPrivacyVersion == nil)
        }

        @Test("persistPrivacyVersionIfAllConsentsDetermined stores version only when every type is set")
        func privacyVersionStoredWhenAllConsentsSet() async {
            let storage = UserDefaultsMock([:])
            let store = PrivacyControlMigrationTests().makeStore(privacyEnabled: true, storage: storage)

            await store.setEnabled(true, for: .location)
            await store.setEnabled(true, for: .mobileNetwork)
            await store.setEnabled(false, for: .deviceInformation)
            #expect(store.storedPrivacyVersion == nil)

            await store.setEnabled(true, for: .userInformation)
            #expect(store.storedPrivacyVersion == RATConstants.PrivacyControl.currentPrivacyVersion)
            #expect((storage.object(forKey: RATConstants.PrivacyControl.privacyVersionKey) as? NSNumber)?.intValue == 1)
        }

        @Test("setEnabled has no effect on privacy version when privacy control is disabled")
        func privacyVersionNotStoredWhenPrivacyDisabled() async {
            let storage = UserDefaultsMock([:])
            let store = PrivacyControlMigrationTests().makeStore(privacyEnabled: false, storage: storage)

            await store.setEnabled(true, for: .all)
            #expect(storage.object(forKey: RATConstants.PrivacyControl.privacyVersionKey) == nil)
        }

        @Test("cleared app data behaves like fresh install")
        func clearedAppDataLikeFreshInstall() async {
            let storage = UserDefaultsMock([:])
            let store = PrivacyControlMigrationTests().makeStore(privacyEnabled: true, storage: storage)

            await store.setEnabled(true, for: .all)
            #expect(store.storedPrivacyVersion == 1)

            storage.dictionary = [:]
            let restartedStore = PrivacyControlMigrationTests().makeStore(privacyEnabled: true, storage: storage)
            #expect(restartedStore.storedPrivacyVersion == nil)
            #expect(restartedStore.typesWithoutConsent() == DataCollectionType.individualTypes)
        }

        @Test("interrupted migration keeps privacy version unset until all consents are set")
        func interruptedMigrationRetriesOnNextStartup() async {
            let storage = UserDefaultsMock([:])
            let store = PrivacyControlMigrationTests().makeStore(privacyEnabled: true, storage: storage)

            await store.setEnabled(true, for: .location)
            await store.setEnabled(false, for: .mobileNetwork)
            #expect(store.storedPrivacyVersion == nil)
            #expect(store.typesWithoutConsent() == [.deviceInformation, .userInformation])

            let restartedStore = PrivacyControlMigrationTests().makeStore(privacyEnabled: true, storage: storage)
            #expect(restartedStore.storedPrivacyVersion == nil)
            #expect(restartedStore.typesWithoutConsent() == [.deviceInformation, .userInformation])

            await restartedStore.setEnabled(true, for: .deviceInformation)
            await restartedStore.setEnabled(true, for: .userInformation)
            #expect(restartedStore.storedPrivacyVersion == 1)
        }

        @Test("partial consent leaves unset types reported as without consent")
        func partialConsentReportsRemainingTypes() {
            let storage = UserDefaultsMock([:])
            storage.set(value: NSNumber(value: true), forKey: "RATDataCollection_location")
            storage.set(value: NSNumber(value: false), forKey: "RATDataCollection_mobileNetwork")
            let store = PrivacyControlMigrationTests().makeStore(privacyEnabled: true, storage: storage)

            #expect(store.typesWithoutConsent() == [.deviceInformation, .userInformation])
        }

        @Test("same stored privacy version keeps existing consents")
        func samePrivacyVersionKeepsStoredConsents() {
            let storage = UserDefaultsMock([:])
            storage.set(value: NSNumber(value: 1), forKey: RATConstants.PrivacyControl.privacyVersionKey)
            storage.set(value: NSNumber(value: true), forKey: "RATDataCollection_location")
            storage.set(value: NSNumber(value: false), forKey: "RATDataCollection_mobileNetwork")
            storage.set(value: NSNumber(value: true), forKey: "RATDataCollection_deviceInformation")
            storage.set(value: NSNumber(value: true), forKey: "RATDataCollection_userInformation")
            let store = PrivacyControlMigrationTests().makeStore(privacyEnabled: true, storage: storage)

            #expect(store.storedPrivacyVersion == 1)
            #expect(store.typesWithoutConsent().isEmpty)
            #expect(store.isEnabled(.location) == true)
            #expect(store.isEnabled(.mobileNetwork) == false)
        }

        @Test("different stored privacy version still reports only unset types")
        func differentPrivacyVersionReportsMissingTypesOnly() {
            let storage = UserDefaultsMock([:])
            storage.set(value: NSNumber(value: 0), forKey: RATConstants.PrivacyControl.privacyVersionKey)
            storage.set(value: NSNumber(value: true), forKey: "RATDataCollection_location")
            storage.set(value: NSNumber(value: true), forKey: "RATDataCollection_mobileNetwork")
            storage.set(value: NSNumber(value: true), forKey: "RATDataCollection_deviceInformation")
            let store = PrivacyControlMigrationTests().makeStore(privacyEnabled: true, storage: storage)

            #expect(store.storedPrivacyVersion == 0)
            #expect(store.typesWithoutConsent() == [.userInformation])
        }
    }

    @Suite("PrivacyControlMigrationCoordinator callback")
    struct CallbackTests {
        @Test("does not invoke callback when privacy control is disabled")
        @MainActor
        func callbackNotInvokedWhenPrivacyDisabled() async {
            let coordinator = PrivacyControlMigrationCoordinator()
            let store = PrivacyControlMigrationTests().makeStore(privacyEnabled: false)
            var invoked = false

            coordinator.registerShowConsentCallback({ _ in
                invoked = true
            }, consentStore: store)

            await Task.yield()
            #expect(invoked == false)
        }

        @Test("invokes callback with all types on fresh install")
        @MainActor
        func callbackReportsAllTypesOnFreshInstall() async {
            let coordinator = PrivacyControlMigrationCoordinator()
            let store = PrivacyControlMigrationTests().makeStore(privacyEnabled: true)
            var receivedTypes: [DataCollectionType]?

            coordinator.registerShowConsentCallback({ types in
                receivedTypes = types
            }, consentStore: store)

            #expect(receivedTypes != nil)
            #expect(receivedTypes == DataCollectionType.individualTypes)
        }

        @Test("invokes callback with only unset types when some consents exist")
        @MainActor
        func callbackReportsUnsetTypesOnly() async {
            let coordinator = PrivacyControlMigrationCoordinator()
            let storage = UserDefaultsMock([:])
            storage.set(value: NSNumber(value: true), forKey: "RATDataCollection_location")
            let store = PrivacyControlMigrationTests().makeStore(privacyEnabled: true, storage: storage)
            var receivedTypes: [DataCollectionType]?

            coordinator.registerShowConsentCallback({ types in
                receivedTypes = types
            }, consentStore: store)

            #expect(receivedTypes != nil)
            #expect(receivedTypes == [.mobileNetwork, .deviceInformation, .userInformation])
        }

        @Test("invokes callback with empty list when all consents are already set")
        @MainActor
        func callbackEmptyWhenAllConsentsSet() async {
            let coordinator = PrivacyControlMigrationCoordinator()
            let storage = UserDefaultsMock([:])
            storage.set(value: NSNumber(value: 1), forKey: RATConstants.PrivacyControl.privacyVersionKey)
            storage.set(value: NSNumber(value: true), forKey: "RATDataCollection_location")
            storage.set(value: NSNumber(value: true), forKey: "RATDataCollection_mobileNetwork")
            storage.set(value: NSNumber(value: true), forKey: "RATDataCollection_deviceInformation")
            storage.set(value: NSNumber(value: true), forKey: "RATDataCollection_userInformation")
            let store = PrivacyControlMigrationTests().makeStore(privacyEnabled: true, storage: storage)
            var receivedTypes: [DataCollectionType]?

            coordinator.registerShowConsentCallback({ types in
                receivedTypes = types
            }, consentStore: store)

            #expect(receivedTypes != nil)
            #expect(receivedTypes?.isEmpty == true)
        }

        @Test("delivers startup notification only once per launch")
        @MainActor
        func startupNotificationDeliveredOncePerLaunch() async {
            let coordinator = PrivacyControlMigrationCoordinator()
            let store = PrivacyControlMigrationTests().makeStore(privacyEnabled: true)
            var invocationCount = 0

            coordinator.registerShowConsentCallback({ _ in
                invocationCount += 1
            }, consentStore: store)

            coordinator.runStartupMigrationIfNeeded(consentStore: store)

            #expect(invocationCount == 1)
        }

        @Test("startup run without a callback does not consume the once-per-launch slot")
        @MainActor
        func startupRunWithoutCallbackDoesNotBlockLaterRegistration() async {
            let coordinator = PrivacyControlMigrationCoordinator()
            let store = PrivacyControlMigrationTests().makeStore(privacyEnabled: true)
            var invocationCount = 0

            coordinator.runStartupMigrationIfNeeded(consentStore: store)

            coordinator.registerShowConsentCallback({ _ in
                invocationCount += 1
            }, consentStore: store)

            #expect(invocationCount == 1)
        }

        @Test("AsyncStream delivers types needing consent")
        @MainActor
        func asyncStreamDeliversTypesNeedingConsent() async {
            let coordinator = PrivacyControlMigrationCoordinator()
            let store = PrivacyControlMigrationTests().makeStore(privacyEnabled: true)

            let streamTask = Task {
                var iterator = coordinator.typesNeedingConsentUpdates.makeAsyncIterator()
                return await iterator.next()
            }

            coordinator.registerShowConsentCallback({ _ in }, consentStore: store)

            let received = await streamTask.value
            #expect(received == DataCollectionType.individualTypes)
        }
    }
}
