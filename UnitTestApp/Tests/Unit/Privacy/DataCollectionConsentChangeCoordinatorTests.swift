import Testing
import Foundation
@testable import RakutenAnalytics
#if canImport(RAnalyticsTestHelpers)
import RAnalyticsTestHelpers
#endif

@Suite("DataCollectionConsentChangeCoordinator")
struct ConsentChangeCoordinatorTests {

    private final class NotificationCountingListener: DataCollectionConsentListener {
        private(set) var notificationCount = 0

        @MainActor
        func reactToDataCollectionConsentDidChange() async {
            notificationCount += 1
        }
    }

    private final class ReentrantConsentListener: DataCollectionConsentListener {
        private let store: DataCollectionConsentStore
        private(set) var notificationCount = 0

        init(store: DataCollectionConsentStore) {
            self.store = store
        }

        @MainActor
        func reactToDataCollectionConsentDidChange() async {
            notificationCount += 1
            if notificationCount == 1 {
                await store.setEnabled(true, for: .mobileNetwork)
            }
        }
    }

    @Test("subscribe delivers consent change notifications")
    @MainActor
    func subscribeDeliversConsentChangeNotifications() async {
        let bundle = BundleMock()
        bundle.isPrivacyControlEnabled = true
        let coordinator = DataCollectionConsentChangeCoordinator()
        let store = DataCollectionConsentStore(
            userStorageHandler: UserDefaultsMock([:]),
            bundle: bundle,
            sideEffectHandler: DefaultConsentSideEffectHandler(changeCoordinator: coordinator)
        )
        let listener = NotificationCountingListener()

        await coordinator.subscribe(listener: listener)
        await store.setEnabled(true, for: .location)
        #expect(listener.notificationCount == 1)
        await coordinator.unsubscribe(listener: listener)
    }

    @Test("unsubscribe stops consent change notifications")
    @MainActor
    func unsubscribeStopsConsentChangeNotifications() async {
        let bundle = BundleMock()
        bundle.isPrivacyControlEnabled = true
        let coordinator = DataCollectionConsentChangeCoordinator()
        let store = DataCollectionConsentStore(
            userStorageHandler: UserDefaultsMock([:]),
            bundle: bundle,
            sideEffectHandler: DefaultConsentSideEffectHandler(changeCoordinator: coordinator)
        )
        let listener = NotificationCountingListener()

        await coordinator.subscribe(listener: listener)
        await store.setEnabled(true, for: .location)
        await coordinator.unsubscribe(listener: listener)
        await store.setEnabled(false, for: .location)

        #expect(listener.notificationCount == 1)
    }

    @Test("reentrant setEnabled during notification completes without deadlock")
    @MainActor
    func reentrantSetEnabledDuringNotificationCompletesWithoutDeadlock() async {
        let bundle = BundleMock()
        bundle.isPrivacyControlEnabled = true
        let coordinator = DataCollectionConsentChangeCoordinator()
        let store = DataCollectionConsentStore(
            userStorageHandler: UserDefaultsMock([:]),
            bundle: bundle,
            sideEffectHandler: DefaultConsentSideEffectHandler(changeCoordinator: coordinator)
        )
        let listener = ReentrantConsentListener(store: store)

        await coordinator.subscribe(listener: listener)
        await store.setEnabled(true, for: .location)

        #expect(listener.notificationCount == 2)
        #expect(store.isEnabled(.location) == true)
        #expect(store.isEnabled(.mobileNetwork) == true)
        await coordinator.unsubscribe(listener: listener)
    }
}
