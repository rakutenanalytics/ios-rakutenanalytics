import Testing
import UIKit
import CoreLocation.CLRegion
@testable import RakutenAnalytics
#if canImport(RAnalyticsTestHelpers)
import RAnalyticsTestHelpers
#endif

// MARK: - RAnalyticsLaunchCollectorTests

@Suite("RAnalyticsLaunchCollector")
struct RAnalyticsLaunchCollectorTests {
    private enum Constants {
        static let initialLaunchDateKey = "com.rakuten.esd.sdk.properties.analytics.launchInformation.initialLaunchDate"
        static let installLaunchDateKey = "com.rakuten.esd.sdk.properties.analytics.launchInformation.installLaunchDate"
        static let lastUpdateDateKey = "com.rakuten.esd.sdk.properties.analytics.launchInformation.lastUpdateDate"
        static let lastLaunchDateKey = "com.rakuten.esd.sdk.properties.analytics.launchInformation.lastLaunchDate"
        static let lastVersionKey = "com.rakuten.esd.sdk.properties.analytics.launchInformation.lastVersion"
        static let lastVersionLaunchesKey = "com.rakuten.esd.sdk.properties.analytics.launchInformation.lastVersionLaunches"
    }
    
    static func makeDependenciesFactory() -> SimpleContainerMock {
        let dependenciesFactory = SimpleContainerMock()
        dependenciesFactory.keychainHandler = KeychainHandlerMock()
        dependenciesFactory.userStorageHandler = UserDefaultsMock()
        dependenciesFactory.sharedUserStorageHandlerType = UserDefaultsMock.self
        
        let sharedUserStorageHandler = dependenciesFactory.sharedUserStorageHandlerType.init(suiteName: dependenciesFactory.bundle.appGroupId)
        dependenciesFactory.pushEventHandler = PushEventHandler(sharedUserStorageHandler: sharedUserStorageHandler, appGroupId: dependenciesFactory.bundle.appGroupId)
        return dependenciesFactory
    }
    
    static func tearDownDependenciesFactory(_ dependenciesFactory: SimpleContainerMock) {
        let keychainHandler = dependenciesFactory.keychainHandler as? KeychainHandlerMock
        keychainHandler?.status = errSecItemNotFound
        keychainHandler?.set(creationDate: nil, for: Constants.initialLaunchDateKey)
    }
    
    @Test("should track the initial launch event when the app is launched For the first time")
    @MainActor
    func testShouldTrackInitialLaunchEventWhenAppIsLaunchedForFirstTime() async throws {
        let dependenciesFactory = Self.makeDependenciesFactory()
        defer { Self.tearDownDependenciesFactory(dependenciesFactory) }
        
        let launchCollector = RAnalyticsLaunchCollector(dependenciesContainer: dependenciesFactory)
        #expect(launchCollector.isInitialLaunch == true)
        NotificationCenter.default.post(name: UIApplication.didFinishLaunchingNotification, object: nil, userInfo: nil)
        NotificationCenter.default.post(name: UIApplication.didBecomeActiveNotification, object: nil, userInfo: nil)
        try await TestingHelpers.eventuallyOnMain { launchCollector.isInitialLaunch == false }
    }
    
    @Test("should track the install event when the app is launched after install")
    @MainActor
    func testShouldTrackInstallEventWhenAppIsLaunchedAfterInstall() async throws {
        let dependenciesFactory = Self.makeDependenciesFactory()
        defer { Self.tearDownDependenciesFactory(dependenciesFactory) }
        
        let keychainHandler = dependenciesFactory.keychainHandler as? KeychainHandlerMock
        keychainHandler?.status = errSecSuccess
        keychainHandler?.set(creationDate: Date(), for: Constants.initialLaunchDateKey)
        
        (dependenciesFactory.userStorageHandler as? UserDefaultsMock)?.dictionary = nil
        
        let launchCollector = RAnalyticsLaunchCollector(dependenciesContainer: dependenciesFactory)
        #expect(launchCollector.isInstallLaunch == true)
        NotificationCenter.default.post(name: UIApplication.didFinishLaunchingNotification, object: nil, userInfo: nil)
        NotificationCenter.default.post(name: UIApplication.didBecomeActiveNotification, object: nil, userInfo: nil)
        try await TestingHelpers.eventuallyOnMain { launchCollector.isInstallLaunch == false }
    }
    
    @Test("should track the update event when the app is launched after update")
    @MainActor
    func testShouldTrackUpdateEventWhenAppIsLaunchedAfterUpdate() async throws {
        let dependenciesFactory = Self.makeDependenciesFactory()
        defer { Self.tearDownDependenciesFactory(dependenciesFactory) }
        
        let keychainHandler = dependenciesFactory.keychainHandler as? KeychainHandlerMock
        keychainHandler?.status = errSecSuccess
        keychainHandler?.set(creationDate: Date(), for: Constants.initialLaunchDateKey)
        
        let userDefaultsMock = dependenciesFactory.userStorageHandler as? UserDefaultsMock
        userDefaultsMock?.dictionary = [Constants.installLaunchDateKey: Date()]
        
        let launchCollector = RAnalyticsLaunchCollector(dependenciesContainer: dependenciesFactory)
        #expect(launchCollector.isUpdateLaunch == true)
        NotificationCenter.default.post(name: UIApplication.didFinishLaunchingNotification, object: nil, userInfo: nil)
        NotificationCenter.default.post(name: UIApplication.didBecomeActiveNotification, object: nil, userInfo: nil)
        try await TestingHelpers.eventuallyOnMain { launchCollector.isUpdateLaunch == false }
    }

    @Test("should track launch events only after the app becomes active")
    @MainActor
    func testShouldTrackLaunchEventsOnlyAfterAppBecomesActive() {
        let dependenciesFactory = Self.makeDependenciesFactory()
        let privateCenter = NotificationCenter()
        dependenciesFactory.notificationHandler = privateCenter
        defer {
            Self.tearDownDependenciesFactory(dependenciesFactory)
            RAnalyticsSessionStartCoordinator.shared.resetForTesting()
        }

        let analyticsTrackerMock = AnalyticsTrackerMock()
        analyticsTrackerMock.dictionary = [
            AnalyticsManager.Event.Name.sessionStart: TrackerResult(tracked: false, parameters: nil)
        ]

        RAnalyticsSessionStartCoordinator.shared.resetForTesting()
        let launchCollector = RAnalyticsLaunchCollector(dependenciesContainer: dependenciesFactory)
        launchCollector.trackerDelegate = analyticsTrackerMock

        privateCenter.post(name: UIApplication.didFinishLaunchingNotification, object: nil)
        #expect(analyticsTrackerMock.dictionary?[AnalyticsManager.Event.Name.sessionStart]?.tracked == false)

        privateCenter.post(name: UIApplication.didBecomeActiveNotification, object: nil)
        #expect(analyticsTrackerMock.dictionary?[AnalyticsManager.Event.Name.sessionStart]?.tracked == true)
    }
    
    @Test("should track the session start event when the app is resumed")
    @MainActor
    func testShouldTrackSessionStartEventWhenAppIsResumed() async throws {
        let dependenciesFactory = Self.makeDependenciesFactory()
        defer {
            Self.tearDownDependenciesFactory(dependenciesFactory)
            RAnalyticsSessionStartCoordinator.shared.resetForTesting()
        }
        
        let analyticsTrackerMock = AnalyticsTrackerMock()
        analyticsTrackerMock.dictionary = [AnalyticsManager.Event.Name.sessionStart: TrackerResult(tracked: false, parameters: nil)]
        
        let launchCollector = RAnalyticsLaunchCollector(dependenciesContainer: dependenciesFactory)
        launchCollector.trackerDelegate = analyticsTrackerMock
        
        #expect(analyticsTrackerMock.dictionary?[AnalyticsManager.Event.Name.sessionStart]?.tracked == false)
        NotificationCenter.default.post(name: UIApplication.didEnterBackgroundNotification, object: nil, userInfo: nil)
        NotificationCenter.default.post(name: UIApplication.willEnterForegroundNotification, object: nil, userInfo: nil)
        try await TestingHelpers.eventuallyOnMain { analyticsTrackerMock.dictionary?[AnalyticsManager.Event.Name.sessionStart]?.tracked == false }
        NotificationCenter.default.post(name: UIApplication.didBecomeActiveNotification, object: nil, userInfo: nil)
        try await TestingHelpers.eventuallyOnMain { analyticsTrackerMock.dictionary?[AnalyticsManager.Event.Name.sessionStart]?.tracked == true }
    }
    
    @Test("should defer the session start event until state restoration completes")
    @MainActor
    func testShouldDeferSessionStartEventUntilStateRestorationCompletes() async throws {
        let dependenciesFactory = Self.makeDependenciesFactory()
        defer {
            Self.tearDownDependenciesFactory(dependenciesFactory)
            RAnalyticsSessionStartCoordinator.shared.resetForTesting()
        }
        
        let analyticsTrackerMock = AnalyticsTrackerMock()
        analyticsTrackerMock.dictionary = [AnalyticsManager.Event.Name.sessionStart: TrackerResult(tracked: false, parameters: nil)]
        
        let launchCollector = RAnalyticsLaunchCollector(dependenciesContainer: dependenciesFactory)
        launchCollector.trackerDelegate = analyticsTrackerMock
        
        NotificationCenter.default.post(name: UIApplication.didEnterBackgroundNotification, object: nil, userInfo: nil)
        NotificationCenter.default.post(name: UIApplication.willEnterForegroundNotification, object: nil, userInfo: nil)
        RAnalyticsSessionStartCoordinator.shared.stateRestorationExtended()
        NotificationCenter.default.post(name: UIApplication.didBecomeActiveNotification, object: nil, userInfo: nil)
        try await TestingHelpers.eventuallyOnMain { analyticsTrackerMock.dictionary?[AnalyticsManager.Event.Name.sessionStart]?.tracked == false }
        RAnalyticsSessionStartCoordinator.shared.stateRestorationCompleted()
        try await TestingHelpers.eventuallyOnMain { analyticsTrackerMock.dictionary?[AnalyticsManager.Event.Name.sessionStart]?.tracked == true }
    }
    
    @Test("should track the session end event when the app is suspended")
    @MainActor
    func testShouldTrackSessionEndEventWhenAppIsSuspended() async throws {
        let dependenciesFactory = Self.makeDependenciesFactory()
        defer { Self.tearDownDependenciesFactory(dependenciesFactory) }
        
        let analyticsTrackerMock = AnalyticsTrackerMock()
        analyticsTrackerMock.dictionary = [AnalyticsManager.Event.Name.sessionEnd: TrackerResult(tracked: false, parameters: nil)]
        
        let launchCollector = RAnalyticsLaunchCollector(dependenciesContainer: dependenciesFactory)
        launchCollector.trackerDelegate = analyticsTrackerMock
        
        #expect(analyticsTrackerMock.dictionary?[AnalyticsManager.Event.Name.sessionEnd]?.tracked == false)
        NotificationCenter.default.post(name: UIApplication.didEnterBackgroundNotification, object: nil, userInfo: nil)
        try await TestingHelpers.eventuallyOnMain { analyticsTrackerMock.dictionary?[AnalyticsManager.Event.Name.sessionEnd]?.tracked == true }
    }
    
    @Test("should not track session start when app backgrounds before didBecomeActive")
    @MainActor
    func testShouldNotTrackSessionStartWhenAppBackgroundsBeforeDidBecomeActive() async throws {
        let dependenciesFactory = Self.makeDependenciesFactory()
        defer {
            Self.tearDownDependenciesFactory(dependenciesFactory)
            RAnalyticsSessionStartCoordinator.shared.resetForTesting()
        }

        let analyticsTrackerMock = AnalyticsTrackerMock()
        analyticsTrackerMock.dictionary = [AnalyticsManager.Event.Name.sessionStart: TrackerResult(tracked: false, parameters: nil)]

        let launchCollector = RAnalyticsLaunchCollector(dependenciesContainer: dependenciesFactory)
        launchCollector.trackerDelegate = analyticsTrackerMock

        // Arm the flag first, then simulate interrupted foreground transition
        NotificationCenter.default.post(name: UIApplication.didEnterBackgroundNotification, object: nil, userInfo: nil)
        NotificationCenter.default.post(name: UIApplication.willEnterForegroundNotification, object: nil, userInfo: nil)
        // Second background cancels the pending start
        NotificationCenter.default.post(name: UIApplication.didEnterBackgroundNotification, object: nil, userInfo: nil)
        // A late didBecomeActive must not fire the deferred session start
        NotificationCenter.default.post(name: UIApplication.didBecomeActiveNotification, object: nil, userInfo: nil)
        try await TestingHelpers.eventuallyOnMain { analyticsTrackerMock.dictionary?[AnalyticsManager.Event.Name.sessionStart]?.tracked == false }
    }

    @Test("should not track session start when state restoration completes after app has backgrounded")
    @MainActor
    func testShouldNotTrackSessionStartWhenStateRestorationCompletesAfterBackground() async throws {
        let dependenciesFactory = Self.makeDependenciesFactory()
        defer {
            Self.tearDownDependenciesFactory(dependenciesFactory)
            RAnalyticsSessionStartCoordinator.shared.resetForTesting()
        }

        let analyticsTrackerMock = AnalyticsTrackerMock()
        analyticsTrackerMock.dictionary = [AnalyticsManager.Event.Name.sessionStart: TrackerResult(tracked: false, parameters: nil)]

        let launchCollector = RAnalyticsLaunchCollector(dependenciesContainer: dependenciesFactory)
        launchCollector.trackerDelegate = analyticsTrackerMock

        NotificationCenter.default.post(name: UIApplication.didEnterBackgroundNotification, object: nil, userInfo: nil)
        NotificationCenter.default.post(name: UIApplication.willEnterForegroundNotification, object: nil, userInfo: nil)
        RAnalyticsSessionStartCoordinator.shared.stateRestorationExtended()
        NotificationCenter.default.post(name: UIApplication.didBecomeActiveNotification, object: nil, userInfo: nil)
        // App backgrounds before state restoration callback arrives
        NotificationCenter.default.post(name: UIApplication.didEnterBackgroundNotification, object: nil, userInfo: nil)
        // Late stateRestorationCompleted must not fire the deferred session start
        RAnalyticsSessionStartCoordinator.shared.stateRestorationCompleted()
        try await TestingHelpers.eventuallyOnMain { analyticsTrackerMock.dictionary?[AnalyticsManager.Event.Name.sessionStart]?.tracked == false }
    }

    @Test("should not track session start on cold launch when willEnterForeground fires without prior background")
    @MainActor
    func testShouldNotTrackSessionStartWhenWillEnterForegroundFiresWithoutPriorBackground() {
        let dependenciesFactory = Self.makeDependenciesFactory()
        let privateCenter = NotificationCenter()
        dependenciesFactory.notificationHandler = privateCenter
        defer {
            Self.tearDownDependenciesFactory(dependenciesFactory)
            RAnalyticsSessionStartCoordinator.shared.resetForTesting()
        }

        let analyticsTrackerMock = AnalyticsTrackerMock()
        analyticsTrackerMock.dictionary = [AnalyticsManager.Event.Name.sessionStart: TrackerResult(tracked: false, parameters: nil)]

        RAnalyticsSessionStartCoordinator.shared.resetForTesting()
        let launchCollector = RAnalyticsLaunchCollector(dependenciesContainer: dependenciesFactory)
        launchCollector.trackerDelegate = analyticsTrackerMock

        privateCenter.post(name: UIApplication.willEnterForegroundNotification, object: nil)
        privateCenter.post(name: UIApplication.didBecomeActiveNotification, object: nil)
        #expect(analyticsTrackerMock.dictionary?[AnalyticsManager.Event.Name.sessionStart]?.tracked == false)
    }

    @Test("should track the visit event when a presented view controller is UIViewController")
    @MainActor
    func testShouldTrackVisitEventWhenPresentedViewControllerIsUIViewController() async throws {
        let dependenciesFactory = Self.makeDependenciesFactory()
        defer { Self.tearDownDependenciesFactory(dependenciesFactory) }
        
        let analyticsTrackerMock = AnalyticsTrackerMock()
        analyticsTrackerMock.dictionary = [AnalyticsManager.Event.Name.pageVisit: TrackerResult(tracked: false, parameters: nil)]
        
        let launchCollector = RAnalyticsLaunchCollector(dependenciesContainer: dependenciesFactory)
        launchCollector.trackerDelegate = analyticsTrackerMock
        
        #expect(analyticsTrackerMock.dictionary?[AnalyticsManager.Event.Name.pageVisit]?.tracked == false)
        launchCollector.didPresentViewController(UIViewController())
        try await TestingHelpers.eventuallyOnMain { analyticsTrackerMock.dictionary?[AnalyticsManager.Event.Name.pageVisit]?.tracked == true }
        try await TestingHelpers.eventuallyOnMain { launchCollector.origin == .inner }
    }
    
    @Test("should not track the visit event when a presented view controller is UINavigationController")
    @MainActor
    func testShouldNotTrackVisitEventWhenPresentedViewControllerIsUINavigationController() async throws {
        let dependenciesFactory = Self.makeDependenciesFactory()
        defer { Self.tearDownDependenciesFactory(dependenciesFactory) }
        
        let analyticsTrackerMock = AnalyticsTrackerMock()
        analyticsTrackerMock.dictionary = [AnalyticsManager.Event.Name.pageVisit: TrackerResult(tracked: false, parameters: nil)]
        
        let launchCollector = RAnalyticsLaunchCollector(dependenciesContainer: dependenciesFactory)
        launchCollector.trackerDelegate = analyticsTrackerMock
        
        let origin = launchCollector.origin
        #expect(analyticsTrackerMock.dictionary?[AnalyticsManager.Event.Name.pageVisit]?.tracked == false)
        launchCollector.didPresentViewController(UINavigationController())
        try await TestingHelpers.eventuallyOnMain { analyticsTrackerMock.dictionary?[AnalyticsManager.Event.Name.pageVisit]?.tracked == false }
        try await TestingHelpers.eventuallyOnMain { launchCollector.origin == origin }
    }
    
    @Test("should reset to defaults")
    func testShouldResetToDefaults() {
        let dependenciesFactory = Self.makeDependenciesFactory()
        defer { Self.tearDownDependenciesFactory(dependenciesFactory) }
        
        let userDefaultsMock = dependenciesFactory.userStorageHandler as? UserDefaultsMock
        
        let date = Date()
        userDefaultsMock?.dictionary = [Constants.installLaunchDateKey: date,
                                        Constants.lastUpdateDateKey: date,
                                        Constants.lastLaunchDateKey: date,
                                        Constants.lastVersionKey: "v1.0",
                                        Constants.lastVersionLaunchesKey: 10]
        
        let launchCollector = RAnalyticsLaunchCollector(dependenciesContainer: dependenciesFactory)
        #expect(launchCollector.installLaunchDate == date)
        #expect(launchCollector.lastUpdateDate == date)
        #expect(launchCollector.lastLaunchDate == date)
        #expect(launchCollector.lastVersion == "v1.0")
        #expect(launchCollector.lastVersionLaunches == 10)
        
        let distantDate = Date.distantPast
        userDefaultsMock?.dictionary = [Constants.installLaunchDateKey: distantDate,
                                        Constants.lastUpdateDateKey: distantDate,
                                        Constants.lastLaunchDateKey: distantDate,
                                        Constants.lastVersionKey: "v100",
                                        Constants.lastVersionLaunchesKey: 100]
        
        launchCollector.resetToDefaults()
        #expect(launchCollector.installLaunchDate == distantDate)
        #expect(launchCollector.lastUpdateDate == distantDate)
        #expect(launchCollector.lastLaunchDate == distantDate)
        #expect(launchCollector.lastVersion == "v100")
        #expect(launchCollector.lastVersionLaunches == 100)
    }
}
