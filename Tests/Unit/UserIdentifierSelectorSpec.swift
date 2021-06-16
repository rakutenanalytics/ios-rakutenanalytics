import Quick
import Nimble
@testable import RAnalytics

// MARK: - UserIdentifierSelectorSpec

final class UserIdentifierSelectorSpec: QuickSpec {
    override func spec() {
        describe("UserIdentifierSelector") {
            let notificationName = NSNotification.Name(rawValue: "com.rakuten.esd.sdk.events.login.other")
            let noLoginFound = "NO_LOGIN_FOUND"

            describe("selectedTrackingIdentifier") {
                it("should return \(noLoginFound) at initialization") {
                    let externalCollector = ExternalCollectorFactory.mock()!
                    let userIdentifierSelector = UserIdentifierSelector(userIdentifiable: externalCollector)
                    expect(userIdentifierSelector.selectedTrackingIdentifier).to(equal(noLoginFound))
                }
                context("trackingIdentifier is nil") {
                    it("should return userID when userID is set to non-empty value") {
                        let externalCollector = ExternalCollectorFactory.mock()!
                        let userIdentifierSelector = UserIdentifierSelector(userIdentifiable: externalCollector)

                        externalCollector.userIdentifier = "userID"
                        NotificationCenter.default.post(name: notificationName, object: nil)

                        expect(userIdentifierSelector.selectedTrackingIdentifier).toEventually(equal("userID"))
                    }
                    it("should return \(noLoginFound) when userID is nil") {
                        let externalCollector = ExternalCollectorFactory.mock()!
                        let userIdentifierSelector = UserIdentifierSelector(userIdentifiable: externalCollector)

                        externalCollector.userIdentifier = nil
                        NotificationCenter.default.post(name: notificationName, object: nil)

                        expect(userIdentifierSelector.selectedTrackingIdentifier).toEventually(equal(noLoginFound))
                    }
                }
                context("trackingIdentifier is not nil") {
                    it("should return userID when userID is set to non-empty value") {
                        let externalCollector = ExternalCollectorFactory.mock()!
                        let userIdentifierSelector = UserIdentifierSelector(userIdentifiable: externalCollector)

                        externalCollector.userIdentifier = "userID"
                        NotificationCenter.default.post(name: notificationName, object: "trackingID")

                        expect(userIdentifierSelector.selectedTrackingIdentifier).toEventually(equal("userID"))
                    }
                    it("should return trackingID when userID is nil") {
                        let externalCollector = ExternalCollectorFactory.mock()!
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
