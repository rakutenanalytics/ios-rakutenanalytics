import Quick
import Nimble
import UIKit
@testable import RAnalytics

// MARK: - RAnalyticsExternalCollectorSpec

final class RAnalyticsExternalCollectorSpec: QuickSpec {
    let notificationBaseName = "com.rakuten.esd.sdk.events"

    override func spec() {
        describe("RAnalyticsExternalCollector") {
            var dependenciesContainer: SimpleContainerMock!
            beforeEach {
                dependenciesContainer = SimpleContainerMock()
                dependenciesContainer.userStorageHandler = UserDefaultsMock()
                dependenciesContainer.tracker = AnalyticsTrackerMock()
            }
            describe("init") {
                it("should have the correct default values") {
                    let externalCollector = RAnalyticsExternalCollector(dependenciesContainer: dependenciesContainer)
                    expect(externalCollector.isLoggedIn).to(beFalse())
                    expect(externalCollector.trackingIdentifier).to(beNil())
                    expect(externalCollector.userIdentifier).to(beNil())
                    expect(externalCollector.loginMethod).to(equal(.other))
                }
            }
            describe("receiveLoginNotification") {
                context("login methods are password and one_tap") {
                    it("should track AnalyticsManager.Event.Name.login when a login notification is received with a trackingIdentifier") {
                        let tracker = (dependenciesContainer.tracker as? AnalyticsTrackerMock)
                        let trackingIdentifier = "trackingIdentifier"
                        let loginMethods = ["password", "one_tap"]

                        loginMethods.forEach {
                            let externalCollector = RAnalyticsExternalCollector(dependenciesContainer: dependenciesContainer)
                            let notificationName = NSNotification.Name(rawValue: "\(self.notificationBaseName).login.\($0)")
                            expect(externalCollector.trackingIdentifier).to(beNil())
                            expect(externalCollector.loginMethod).to(equal(.other))
                            expect(externalCollector.isLoggedIn).to(beFalse())
                            expect(tracker?.eventName).to(beNil())
                            expect(tracker?.params).to(beNil())

                            NotificationCenter.default.post(name: notificationName, object: trackingIdentifier)

                            expect(externalCollector.trackingIdentifier).toEventually(equal(trackingIdentifier))

                            switch $0 {
                            case "password": expect(externalCollector.loginMethod).toEventually(equal(.passwordInput))
                            case "one_tap": expect(externalCollector.loginMethod).toEventually(equal(.oneTapLogin))
                            default: ()
                            }

                            expect(externalCollector.isLoggedIn).toEventually(beTrue())
                            expect(tracker?.eventName).toEventually(equal(AnalyticsManager.Event.Name.login))
                            expect(tracker?.params).toAfterTimeout(beNil())
                            tracker?.reset()
                        }
                    }
                }
                context("login method is other") {
                    it("should track AnalyticsManager.Event.Name.login when a login notification is received") {
                        let tracker = (dependenciesContainer.tracker as? AnalyticsTrackerMock)
                        let trackingIdentifier = "trackingIdentifier"
                        let externalCollector = RAnalyticsExternalCollector(dependenciesContainer: dependenciesContainer)
                        let notificationName = NSNotification.Name(rawValue: "\(self.notificationBaseName).login.other")

                        expect(externalCollector.trackingIdentifier).to(beNil())
                        expect(externalCollector.loginMethod).to(equal(.other))
                        expect(externalCollector.isLoggedIn).to(beFalse())
                        expect(tracker?.eventName).to(beNil())
                        expect(tracker?.params).to(beNil())

                        let passwordNotificationName = NSNotification.Name(rawValue: "\(self.notificationBaseName).login.password")
                        NotificationCenter.default.post(name: passwordNotificationName, object: trackingIdentifier)

                        expect(externalCollector.loginMethod).toEventually(equal(.passwordInput))
                        tracker?.reset()

                        NotificationCenter.default.post(name: notificationName, object: trackingIdentifier)

                        expect(externalCollector.trackingIdentifier).toEventually(equal(trackingIdentifier))
                        expect(externalCollector.loginMethod).toAfterTimeout(equal(.other))
                        expect(externalCollector.isLoggedIn).toEventually(beTrue())
                        expect(tracker?.eventName).toEventually(equal(AnalyticsManager.Event.Name.login))
                        expect(tracker?.params).toAfterTimeout(beNil())
                        tracker?.reset()
                    }

                    it("should track AnalyticsManager.Event.Name.login when an IDSDK login notification is received") {
                        let tracker = (dependenciesContainer.tracker as? AnalyticsTrackerMock)
                        let easyIdentifier = "easyIdentifier"
                        let externalCollector = RAnalyticsExternalCollector(dependenciesContainer: dependenciesContainer)
                        let notificationName = NSNotification.Name(rawValue: "\(self.notificationBaseName).login.idtoken_memberid")

                        expect(externalCollector.easyIdentifier).to(beNil())
                        expect(externalCollector.loginMethod).to(equal(.other))
                        expect(externalCollector.isLoggedIn).to(beFalse())
                        expect(tracker?.eventName).to(beNil())
                        expect(tracker?.params).to(beNil())

                        let passwordNotificationName = NSNotification.Name(rawValue: "\(self.notificationBaseName).login.password")
                        NotificationCenter.default.post(name: passwordNotificationName, object: easyIdentifier)

                        expect(externalCollector.loginMethod).toEventually(equal(.passwordInput))
                        tracker?.reset()

                        NotificationCenter.default.post(name: notificationName, object: easyIdentifier)

                        expect(externalCollector.easyIdentifier).toEventually(equal(easyIdentifier))
                        expect(externalCollector.loginMethod).toAfterTimeout(equal(.other))
                        expect(externalCollector.isLoggedIn).toEventually(beTrue())
                        expect(tracker?.eventName).toEventually(equal(AnalyticsManager.Event.Name.login))
                        expect(tracker?.params).toAfterTimeout(beNil())
                        tracker?.reset()
                    }
                }
            }
            describe("receiveLoginFailureNotification") {
                it("should track AnalyticsManager.Event.Name.loginFailure when a login failure notification is received") {
                    let params = ["rae_error": "login failure",
                                  "rae_error_message": "login fails",
                                  "type": "login.failure"]
                    let idsdkError = NSError(domain: "com.analytics.error",
                                             code: 0,
                                             userInfo: [NSLocalizedDescriptionKey: "login failure", NSLocalizedFailureReasonErrorKey: "login fails"])
                    let tracker = (dependenciesContainer.tracker as? AnalyticsTrackerMock)
                    let externalCollector = RAnalyticsExternalCollector(dependenciesContainer: dependenciesContainer)
                    let notificationNames = ["\(self.notificationBaseName).login.failure",
                                             "\(self.notificationBaseName).login.failure.idtoken_memberid"]

                    notificationNames.forEach { notificationName in
                        expect(externalCollector.isLoggedIn).to(beFalse())
                        expect(tracker?.eventName).to(beNil())
                        expect(tracker?.params).to(beNil())

                        switch notificationName {
                        case "\(self.notificationBaseName).login.failure":
                            NotificationCenter.default.post(name: NSNotification.Name(rawValue: notificationName), object: params)

                        case "\(self.notificationBaseName).login.failure.idtoken_memberid":
                            NotificationCenter.default.post(name: NSNotification.Name(rawValue: notificationName), object: idsdkError)

                        default:
                            assertionFailure("Unexpected login failure case.")
                        }

                        expect(externalCollector.isLoggedIn).toAfterTimeout(beFalse())
                        expect(tracker?.eventName).toEventually(equal(AnalyticsManager.Event.Name.loginFailure))

                        switch notificationName {
                        case "\(self.notificationBaseName).login.failure":
                            expect(tracker?.params?["rae_error"] as? String).toEventually(equal(params["rae_error"]))
                            expect(tracker?.params?["rae_error_message"] as? String).toEventually(equal(params["rae_error_message"]))
                            expect(tracker?.params?["type"] as? String).toEventually(equal(params["type"]))

                        case "\(self.notificationBaseName).login.failure.idtoken_memberid":
                            expect(tracker?.params?["idsdk_error"] as? String).toEventually(equal(idsdkError.localizedDescription))
                            expect(tracker?.params?["idsdk_error_message"] as? String).toEventually(equal(idsdkError.localizedFailureReason))

                        default:
                            assertionFailure("Unexpected login failure case.")
                        }

                        tracker?.reset()
                    }
                }
            }
            describe("receiveLogoutNotification") {
                it("should track AnalyticsManager.Event.Name.logout when a logout notification is received") {
                    let tracker = (dependenciesContainer.tracker as? AnalyticsTrackerMock)
                    let trackingIdentifier = "trackingIdentifier"
                    let logoutMethods = ["local", "global", "idtoken_memberid"]

                    logoutMethods.forEach {
                        let externalCollector = RAnalyticsExternalCollector(dependenciesContainer: dependenciesContainer)
                        let notificationName = NSNotification.Name(rawValue: "\(self.notificationBaseName).logout.\($0)")

                        expect(externalCollector.trackingIdentifier).to(beNil())
                        expect(externalCollector.easyIdentifier).to(beNil())
                        expect(externalCollector.isLoggedIn).to(beFalse())
                        expect(tracker?.eventName).to(beNil())
                        expect(tracker?.params).to(beNil())

                        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "\(self.notificationBaseName).login.other"),
                                                        object: trackingIdentifier)

                        expect(externalCollector.isLoggedIn).toEventually(beTrue())
                        expect(externalCollector.trackingIdentifier).toEventually(equal(trackingIdentifier))
                        tracker?.reset()

                        NotificationCenter.default.post(name: notificationName, object: nil)

                        expect(externalCollector.trackingIdentifier).toAfterTimeout(beNil())
                        expect(externalCollector.easyIdentifier).toAfterTimeout(beNil())
                        expect(externalCollector.isLoggedIn).toAfterTimeout(beFalse())
                        expect(tracker?.eventName).toEventually(equal(AnalyticsManager.Event.Name.logout))

                        if $0 == "local" || $0 == "global" {
                            expect(tracker?.params?[AnalyticsManager.Event.Parameter.logoutMethod] as? String).toEventually(equal($0))

                        } else {
                            expect(tracker?.params?[AnalyticsManager.Event.Parameter.logoutMethod] as? String).toAfterTimeout(beNil())
                        }

                        tracker?.reset()
                    }
                }
            }
            describe("receiveDiscoverNotification") {
                it("should track a discover event when a discover notification is received") {
                    let tracker = (dependenciesContainer.tracker as? AnalyticsTrackerMock)
                    let mapping = ["visitPreview": NSNotification.discoverPreviewVisit,
                                   "tapShowMore": NSNotification.discoverPreviewShowMore,
                                   "visitPage": NSNotification.discoverPageVisit]

                    mapping.forEach {
                        let externalCollector = RAnalyticsExternalCollector(dependenciesContainer: dependenciesContainer)
                        expect(externalCollector.isLoggedIn).to(beFalse())

                        let notificationName = NSNotification.Name(rawValue: "\(self.notificationBaseName).discover.\($0.key)")

                        expect(tracker?.eventName).to(beNil())
                        expect(tracker?.params).to(beNil())

                        NotificationCenter.default.post(name: notificationName, object: nil)

                        expect(tracker?.eventName).toEventually(equal(mapping[$0.key]?.rawValue))
                        expect(tracker?.params).toEventually(beNil())
                        tracker?.reset()
                    }
                }
                it("should track a discover event with the correct identifier when a discover notification is received with an identifier") {
                    let tracker = (dependenciesContainer.tracker as? AnalyticsTrackerMock)
                    let identifier = "12345"
                    let mapping = ["tapPreview": NSNotification.discoverPreviewTap,
                                   "tapPage": NSNotification.discoverPageTap]

                    mapping.forEach {
                        let externalCollector = RAnalyticsExternalCollector(dependenciesContainer: dependenciesContainer)
                        expect(externalCollector.isLoggedIn).to(beFalse())

                        let notificationName = NSNotification.Name(rawValue: "\(self.notificationBaseName).discover.\($0.key)")

                        expect(tracker?.eventName).to(beNil())
                        expect(tracker?.params).to(beNil())

                        NotificationCenter.default.post(name: notificationName, object: identifier)

                        expect(tracker?.eventName).toEventually(equal(mapping[$0.key]?.rawValue))
                        expect(tracker?.params?["prApp"] as? String).toEventually(equal(identifier))
                        tracker?.reset()
                    }
                }
                it("should track a discover event with correct parameters when a discover notification is received with an identifier and url") {
                    let tracker = (dependenciesContainer.tracker as? AnalyticsTrackerMock)
                    let identifier = "12345"
                    let urlString = "http://www.rakuten.co.jp"
                    let mapping = ["redirectPreview": NSNotification.discoverPreviewRedirect,
                                   "redirectPage": NSNotification.discoverPageRedirect]

                    mapping.forEach {
                        let externalCollector = RAnalyticsExternalCollector(dependenciesContainer: dependenciesContainer)
                        expect(externalCollector.isLoggedIn).to(beFalse())

                        let notificationName = NSNotification.Name(rawValue: "\(self.notificationBaseName).discover.\($0.key)")

                        expect(tracker?.eventName).to(beNil())
                        expect(tracker?.params).to(beNil())

                        NotificationCenter.default.post(name: notificationName, object: ["identifier": identifier, "url": urlString])

                        expect(tracker?.eventName).toEventually(equal(mapping[$0.key]?.rawValue))
                        expect(tracker?.params?["prApp"] as? String).toEventually(equal(identifier))
                        expect(tracker?.params?["prStoreUrl"] as? String).toEventually(equal(urlString))
                        tracker?.reset()
                    }
                }
            }
            describe("receiveSSODialogNotification") {
                it("should track AnalyticsManager.Event.Name.pageVisit when a ssodialog notification is received") {
                    let tracker = (dependenciesContainer.tracker as? AnalyticsTrackerMock)
                    let UIViewControllerType = UIViewController.self
                    let ssodialogParams = ["help", "privacypolicy", "forgotpassword", "register"]

                    ssodialogParams.forEach {
                        let externalCollector = RAnalyticsExternalCollector(dependenciesContainer: dependenciesContainer)
                        expect(externalCollector.isLoggedIn).to(beFalse())

                        let notificationName = NSNotification.Name(rawValue: "\(self.notificationBaseName).ssodialog")

                        expect(tracker?.eventName).to(beNil())
                        expect(tracker?.params).to(beNil())

                        NotificationCenter.default.post(name: notificationName, object: "\(UIViewControllerType)\($0)")

                        expect(tracker?.eventName).toEventually(equal(AnalyticsManager.Event.Name.pageVisit))
                        expect(tracker?.params?["page_id"] as? String).toEventually(equal("\(UIViewControllerType)\($0)"))
                        tracker?.reset()
                    }
                }
            }
            describe("receiveCredentialsNotification") {
                it("should track a credential event when a credential notification is received") {
                    let tracker = (dependenciesContainer.tracker as? AnalyticsTrackerMock)
                    let mapping = ["ssocredentialfound": AnalyticsManager.Event.Name.SSOCredentialFound,
                                   "logincredentialfound": AnalyticsManager.Event.Name.loginCredentialFound]

                    mapping.forEach {
                        let externalCollector = RAnalyticsExternalCollector(dependenciesContainer: dependenciesContainer)
                        expect(externalCollector.isLoggedIn).to(beFalse())

                        let notificationName = NSNotification.Name(rawValue: "\(self.notificationBaseName).\($0.key)")

                        expect(tracker?.eventName).to(beNil())
                        expect(tracker?.params).to(beNil())

                        NotificationCenter.default.post(name: notificationName, object: nil)

                        expect(tracker?.eventName).toEventually(equal($0.value))
                        expect(tracker?.params?.isEmpty).toEventually(beTrue())
                        tracker?.reset()
                    }
                }
            }
            describe("receiveCustomEventNotification") {
                it("should track AnalyticsManager.Event.Name.custom when a custom notification is received") {
                    let tracker = (dependenciesContainer.tracker as? AnalyticsTrackerMock)
                    let params: [String: Any] = ["eventName": "blah",
                                                 "eventData": ["foo": "bar"]]
                    let externalCollector = RAnalyticsExternalCollector(dependenciesContainer: dependenciesContainer)
                    expect(externalCollector.isLoggedIn).to(beFalse())

                    let notificationName = NSNotification.Name(rawValue: "\(self.notificationBaseName).custom")

                    expect(tracker?.eventName).to(beNil())
                    expect(tracker?.params).to(beNil())

                    NotificationCenter.default.post(name: notificationName, object: params)

                    expect(tracker?.eventName).toEventually(equal(AnalyticsManager.Event.Name.custom))
                    expect(tracker?.params?["eventName"] as? String).toEventually(equal(params["eventName"] as? String))
                    expect(tracker?.params?["eventData"] as? [String: String]).toEventually(equal(params["eventData"] as? [String: String]))
                }
            }
        }
    }
}
