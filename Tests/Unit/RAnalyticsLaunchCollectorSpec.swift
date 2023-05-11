import Quick
import Nimble
import UIKit
import CoreLocation.CLRegion
@testable import RAnalytics
#if canImport(RAnalyticsTestHelpers)
import RAnalyticsTestHelpers
#endif

// MARK: - RAnalyticsLaunchCollectorSpec

final class RAnalyticsLaunchCollectorSpec: QuickSpec {
    private enum Constants {
        static let initialLaunchDateKey = "com.rakuten.esd.sdk.properties.analytics.launchInformation.initialLaunchDate"
        static let installLaunchDateKey = "com.rakuten.esd.sdk.properties.analytics.launchInformation.installLaunchDate"
        static let lastUpdateDateKey = "com.rakuten.esd.sdk.properties.analytics.launchInformation.lastUpdateDate"
        static let lastLaunchDateKey = "com.rakuten.esd.sdk.properties.analytics.launchInformation.lastLaunchDate"
        static let lastVersionKey = "com.rakuten.esd.sdk.properties.analytics.launchInformation.lastVersion"
        static let lastVersionLaunchesKey = "com.rakuten.esd.sdk.properties.analytics.launchInformation.lastVersionLaunches"
    }

    override func spec() {
        describe("RAnalyticsLaunchCollector") {
            let dependenciesFactory = SimpleContainerMock()
            let analyticsTrackerMock = AnalyticsTrackerMock()

            beforeEach {
                dependenciesFactory.keychainHandler = KeychainHandlerMock()
                dependenciesFactory.userStorageHandler = UserDefaultsMock()
                dependenciesFactory.sharedUserStorageHandlerType = UserDefaultsMock.self

                let sharedUserStorageHandler = dependenciesFactory.sharedUserStorageHandlerType.init(suiteName: dependenciesFactory.bundle.appGroupId)
                dependenciesFactory.pushEventHandler = PushEventHandler(sharedUserStorageHandler: sharedUserStorageHandler,
                                                                        appGroupId: dependenciesFactory.bundle.appGroupId)
            }

            afterEach {
                // Reset with default values
                let keychainHandler = dependenciesFactory.keychainHandler as? KeychainHandlerMock
                keychainHandler?.status = errSecItemNotFound
                keychainHandler?.set(creationDate: nil, for: Constants.initialLaunchDateKey)
            }
            it("should track the initial launch event when the app is launched For the first time") {
                let launchCollector = RAnalyticsLaunchCollector(dependenciesContainer: dependenciesFactory)
                expect(launchCollector).notTo(beNil())
                expect(launchCollector.isInitialLaunch).to(beTrue())
                NotificationCenter.default.post(name: UIApplication.didFinishLaunchingNotification, object: nil, userInfo: nil)
                expect(launchCollector.isInitialLaunch).toEventually(beFalse())
            }
            it("should track the install event when the app is launched after install") {
                let keychainHandler = dependenciesFactory.keychainHandler as? KeychainHandlerMock
                keychainHandler?.status = errSecSuccess
                keychainHandler?.set(creationDate: Date(), for: Constants.initialLaunchDateKey)

                (dependenciesFactory.userStorageHandler as? UserDefaultsMock)?.dictionary = nil

                let launchCollector = RAnalyticsLaunchCollector(dependenciesContainer: dependenciesFactory)
                expect(launchCollector).notTo(beNil())
                expect(launchCollector.isInstallLaunch).to(beTrue())
                NotificationCenter.default.post(name: UIApplication.didFinishLaunchingNotification, object: nil, userInfo: nil)
                expect(launchCollector.isInstallLaunch).toEventually(beFalse())
            }
            it("should track the update event when the app is launched after update") {
                let keychainHandler = dependenciesFactory.keychainHandler as? KeychainHandlerMock
                keychainHandler?.status = errSecSuccess
                keychainHandler?.set(creationDate: Date(), for: Constants.initialLaunchDateKey)

                let userDefaultsMock = dependenciesFactory.userStorageHandler as? UserDefaultsMock
                userDefaultsMock?.dictionary = [Constants.installLaunchDateKey: Date()]

                let launchCollector = RAnalyticsLaunchCollector(dependenciesContainer: dependenciesFactory)
                expect(launchCollector).notTo(beNil())
                expect(launchCollector.isUpdateLaunch).to(beTrue())
                NotificationCenter.default.post(name: UIApplication.didFinishLaunchingNotification, object: nil, userInfo: nil)
                expect(launchCollector.isUpdateLaunch).toEventually(beFalse())
            }
            it("should track the session start event when the app is resumed") {
                analyticsTrackerMock.dictionary = [AnalyticsManager.Event.Name.sessionStart: TrackerResult(tracked: false, parameters: nil)]

                let launchCollector = RAnalyticsLaunchCollector(dependenciesContainer: dependenciesFactory)
                launchCollector.trackerDelegate = analyticsTrackerMock

                expect(launchCollector).notTo(beNil())
                expect(analyticsTrackerMock.dictionary?[AnalyticsManager.Event.Name.sessionStart]?.tracked).to(beFalse())
                NotificationCenter.default.post(name: UIApplication.willEnterForegroundNotification, object: nil, userInfo: nil)
                expect(analyticsTrackerMock.dictionary?[AnalyticsManager.Event.Name.sessionStart]?.tracked).toEventually(beTrue())
            }
            it("should track the session end event when the app is suspended") {
                analyticsTrackerMock.dictionary = [AnalyticsManager.Event.Name.sessionEnd: TrackerResult(tracked: false, parameters: nil)]

                let launchCollector = RAnalyticsLaunchCollector(dependenciesContainer: dependenciesFactory)
                launchCollector.trackerDelegate = analyticsTrackerMock

                expect(launchCollector).notTo(beNil())
                expect(analyticsTrackerMock.dictionary?[AnalyticsManager.Event.Name.sessionEnd]?.tracked).to(beFalse())
                NotificationCenter.default.post(name: UIApplication.didEnterBackgroundNotification, object: nil, userInfo: nil)
                expect(analyticsTrackerMock.dictionary?[AnalyticsManager.Event.Name.sessionEnd]?.tracked).toEventually(beTrue())
            }
            it("should track the visit event when a presented view controller is UIViewController") {
                analyticsTrackerMock.dictionary = [AnalyticsManager.Event.Name.pageVisit: TrackerResult(tracked: false, parameters: nil)]

                let launchCollector = RAnalyticsLaunchCollector(dependenciesContainer: dependenciesFactory)
                launchCollector.trackerDelegate = analyticsTrackerMock

                expect(launchCollector).notTo(beNil())
                expect(analyticsTrackerMock.dictionary?[AnalyticsManager.Event.Name.pageVisit]?.tracked).to(beFalse())
                launchCollector.didPresentViewController(UIViewController())
                expect(analyticsTrackerMock.dictionary?[AnalyticsManager.Event.Name.pageVisit]?.tracked).toEventually(beTrue())
                expect(launchCollector.origin).toEventually(equal(.inner))
            }
            it("should not track the visit event when a presented view controller is UINavigationController") {
                analyticsTrackerMock.dictionary = [AnalyticsManager.Event.Name.pageVisit: TrackerResult(tracked: false, parameters: nil)]

                let launchCollector = RAnalyticsLaunchCollector(dependenciesContainer: dependenciesFactory)
                launchCollector.trackerDelegate = analyticsTrackerMock

                let origin = launchCollector.origin
                expect(launchCollector).notTo(beNil())
                expect(analyticsTrackerMock.dictionary?[AnalyticsManager.Event.Name.pageVisit]?.tracked).to(beFalse())
                launchCollector.didPresentViewController(UINavigationController())
                expect(analyticsTrackerMock.dictionary?[AnalyticsManager.Event.Name.pageVisit]?.tracked).toEventually(beFalse())
                expect(launchCollector.origin).toEventually(equal(origin))
            }

            it("should reset to defaults") {
                let userDefaultsMock = dependenciesFactory.userStorageHandler as? UserDefaultsMock

                let date = Date()
                userDefaultsMock?.dictionary = [Constants.installLaunchDateKey: date,
                                                Constants.lastUpdateDateKey: date,
                                                Constants.lastLaunchDateKey: date,
                                                Constants.lastVersionKey: "v1.0",
                                                Constants.lastVersionLaunchesKey: 10]

                let launchCollector = RAnalyticsLaunchCollector(dependenciesContainer: dependenciesFactory)
                expect(launchCollector.installLaunchDate).to(equal(date))
                expect(launchCollector.lastUpdateDate).to(equal(date))
                expect(launchCollector.lastLaunchDate).to(equal(date))
                expect(launchCollector.lastVersion).to(equal("v1.0"))
                expect(launchCollector.lastVersionLaunches).to(equal(10))

                let distantDate = Date.distantPast
                userDefaultsMock?.dictionary = [Constants.installLaunchDateKey: distantDate,
                                                Constants.lastUpdateDateKey: distantDate,
                                                Constants.lastLaunchDateKey: distantDate,
                                                Constants.lastVersionKey: "v100",
                                                Constants.lastVersionLaunchesKey: 100]

                launchCollector.resetToDefaults()
                expect(launchCollector.installLaunchDate).to(equal(distantDate))
                expect(launchCollector.lastUpdateDate).to(equal(distantDate))
                expect(launchCollector.lastLaunchDate).to(equal(distantDate))
                expect(launchCollector.lastVersion).to(equal("v100"))
                expect(launchCollector.lastVersionLaunches).to(equal(100))
            }
        }
    }
}
