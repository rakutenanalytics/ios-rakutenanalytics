import Quick
import Nimble
import Foundation
@testable import RakutenAnalytics
#if canImport(RAnalyticsTestHelpers)
import RAnalyticsTestHelpers
#endif

// MARK: - UserIdentifierSelectorSpec

final class UserIdentifierSelectorSpec: QuickSpec {
    override func spec() {
        describe("UserIdentifierSelector") {
            let notificationName = Notification.Name(rawValue: "com.rakuten.esd.sdk.events.login.other")
            let dependenciesContainer = SimpleContainerMock()

            beforeEach {
                dependenciesContainer.userStorageHandler = UserDefaultsMock()
            }

            describe("selectedTrackingIdentifier") {
                it("should return nil at initialization") {
                    let externalCollector = RAnalyticsExternalCollector(dependenciesContainer: dependenciesContainer)
                    let userIdentifierSelector = UserIdentifierSelector(userIdentifiable: externalCollector)
                    expect(userIdentifierSelector.selectedTrackingIdentifier).to(beNil())
                }
                context("trackingIdentifier is nil") {
                    it("should return userID when userID is set to non-empty value") {
                        (dependenciesContainer.userStorageHandler as? UserDefaultsMock)?.dictionary = [:]
                        let externalCollector = RAnalyticsExternalCollector(dependenciesContainer: dependenciesContainer)
                        let userIdentifierSelector = UserIdentifierSelector(userIdentifiable: externalCollector)

                        externalCollector.userIdentifier = "userID"
                        NotificationCenter.default.post(name: notificationName, object: nil)

                        expect(userIdentifierSelector.selectedTrackingIdentifier).toEventually(equal("userID"))
                    }
                    it("should return nil when userID is nil") {
                        let externalCollector = RAnalyticsExternalCollector(dependenciesContainer: dependenciesContainer)
                        let userIdentifierSelector = UserIdentifierSelector(userIdentifiable: externalCollector)

                        externalCollector.userIdentifier = nil
                        NotificationCenter.default.post(name: notificationName, object: nil)

                        expect(userIdentifierSelector.selectedTrackingIdentifier).toEventually(beNil())
                    }
                }
                context("trackingIdentifier is not nil") {
                    it("should return userID when userID is set to non-empty value") {
                        (dependenciesContainer.userStorageHandler as? UserDefaultsMock)?.dictionary = [:]
                        let externalCollector = RAnalyticsExternalCollector(dependenciesContainer: dependenciesContainer)
                        let userIdentifierSelector = UserIdentifierSelector(userIdentifiable: externalCollector)

                        externalCollector.userIdentifier = "userID"
                        NotificationCenter.default.post(name: notificationName, object: "trackingID")

                        expect(userIdentifierSelector.selectedTrackingIdentifier).toEventually(equal("userID"))
                    }
                    it("should return trackingID when userID is nil") {
                        let externalCollector = RAnalyticsExternalCollector(dependenciesContainer: dependenciesContainer)
                        let userIdentifierSelector = UserIdentifierSelector(userIdentifiable: externalCollector)

                        externalCollector.userIdentifier = nil
                        NotificationCenter.default.post(name: notificationName, object: "trackingID")

                        expect(userIdentifierSelector.selectedTrackingIdentifier).toEventually(equal("trackingID"))
                    }
                }
            }
        }
    }
}
