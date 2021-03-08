import Quick
import Nimble
import UIKit

// MARK: - RAnalyticsExternalCollectorSpec

final class RAnalyticsExternalCollectorSpec: QuickSpec {
    let notificationBaseName = "com.rakuten.esd.sdk.events"

    override func spec() {
        describe("RAnalyticsExternalCollector") {
            var dependenciesFactory: AnyDependenciesContainer!
            beforeEach {
                dependenciesFactory = AnyDependenciesContainer()
                dependenciesFactory.registerObject(UserDefaultsMock())
                dependenciesFactory.registerObject(AnalyticsTrackerMock())
            }
            describe("init") {
                it("should fail if all the required dependencies are missing") {
                    let container = AnyDependenciesContainer()
                    let externalCollector = RAnalyticsExternalCollector(dependenciesFactory: container)
                    expect(externalCollector).to(beNil())
                }
                it("should fail if userStorageHandler is missing") {
                    let container = AnyDependenciesContainer()
                    container.registerObject(AnalyticsTrackerMock())
                    let externalCollector = RAnalyticsExternalCollector(dependenciesFactory: container)
                    expect(externalCollector).to(beNil())
                }
                it("should fail if tracker is missing") {
                    let container = AnyDependenciesContainer()
                    container.registerObject(UserDefaultsMock())
                    let externalCollector = RAnalyticsExternalCollector(dependenciesFactory: container)
                    expect(externalCollector).to(beNil())
                }
                it("should succeed if all the required dependencies exist") {
                    let container = AnyDependenciesContainer()
                    container.registerObject(UserDefaultsMock())
                    container.registerObject(AnalyticsTrackerMock())
                    let externalCollector = RAnalyticsExternalCollector(dependenciesFactory: container)
                    expect(externalCollector).toNot(beNil())
                }
                it("should have the correct default values") {
                    let container = AnyDependenciesContainer()
                    container.registerObject(UserDefaultsMock())
                    container.registerObject(AnalyticsTrackerMock())
                    let externalCollector = RAnalyticsExternalCollector(dependenciesFactory: container)
                    expect(externalCollector?.isLoggedIn).to(beFalse())
                    expect(externalCollector?.trackingIdentifier).to(beNil())
                    expect(externalCollector?.userIdentifier).to(beNil())
                    expect(externalCollector?.loginMethod).to(equal(.other))
                }
            }
            describe("receiveLoginNotification") {
                context("login methods are password and one_tap") {
                    it("should track AnalyticsManager.Event.Name.login when a login notification is received with a trackingIdentifier") {
                        let tracker = (dependenciesFactory.tracker as? AnalyticsTrackerMock)
                        let trackingIdentifier = "trackingIdentifier"
                        let loginMethods = ["password", "one_tap"]

                        loginMethods.forEach {
                            let externalCollector = RAnalyticsExternalCollector(dependenciesFactory: dependenciesFactory)
                            let notificationName = NSNotification.Name(rawValue: "\(self.notificationBaseName).login.\($0)")

                            expect(externalCollector).toNot(beNil())
                            expect(externalCollector?.trackingIdentifier).to(beNil())
                            expect(externalCollector?.loginMethod).to(equal(.other))
                            expect(externalCollector?.isLoggedIn).to(beFalse())
                            expect(tracker?.eventName).to(beNil())
                            expect(tracker?.params).to(beNil())

                            NotificationCenter.default.post(name: notificationName, object: trackingIdentifier)

                            switch $0 {
                            case "password": expect(externalCollector?.loginMethod).toEventually(equal(.passwordInput))
                            case "one_tap": expect(externalCollector?.loginMethod).toEventually(equal(.oneTapLogin))
                            default: ()
                            }

                            expect(externalCollector?.isLoggedIn).toEventually(beTrue())
                            expect(externalCollector?.trackingIdentifier).toEventually(equal(trackingIdentifier))
                            expect(tracker?.eventName).toEventually(equal(AnalyticsManager.Event.Name.login))
                            expect(tracker?.params).toEventually(beNil())
                            tracker?.reset()
                        }
                    }
                }
                context("login method is other") {
                    it("should track AnalyticsManager.Event.Name.login when a login notification is received") {
                        let tracker = (dependenciesFactory.tracker as? AnalyticsTrackerMock)
                        let trackingIdentifier = "trackingIdentifier"
                        let externalCollector = RAnalyticsExternalCollector(dependenciesFactory: dependenciesFactory)
                        let notificationName = NSNotification.Name(rawValue: "\(self.notificationBaseName).login.other")

                        expect(externalCollector).toNot(beNil())
                        expect(externalCollector?.trackingIdentifier).to(beNil())
                        expect(externalCollector?.loginMethod).to(equal(.other))
                        expect(externalCollector?.isLoggedIn).to(beFalse())
                        expect(tracker?.eventName).to(beNil())
                        expect(tracker?.params).to(beNil())

                        let passwordNotificationName = NSNotification.Name(rawValue: "\(self.notificationBaseName).login.password")
                        NotificationCenter.default.post(name: passwordNotificationName, object: trackingIdentifier)

                        expect(externalCollector?.loginMethod).toEventually(equal(.passwordInput))
                        tracker?.reset()

                        NotificationCenter.default.post(name: notificationName, object: trackingIdentifier)

                        expect(externalCollector?.loginMethod).toEventually(equal(.other))

                        expect(externalCollector?.isLoggedIn).toEventually(beTrue())
                        expect(externalCollector?.trackingIdentifier).toEventually(equal(trackingIdentifier))
                        expect(tracker?.eventName).toEventually(equal(AnalyticsManager.Event.Name.login))
                        expect(tracker?.params).toEventually(beNil())
                        tracker?.reset()
                    }
                }
            }
            describe("receiveLoginFailureNotification") {
                it("should track AnalyticsManager.Event.Name.loginFailure when a login failure notification is received") {
                    let params = ["rae_error": "login failure",
                                  "rae_error_message": "login fails",
                                  "type": "login.failure"]
                    let tracker = (dependenciesFactory.tracker as? AnalyticsTrackerMock)
                    let externalCollector = RAnalyticsExternalCollector(dependenciesFactory: dependenciesFactory)
                    let notificationName = NSNotification.Name(rawValue: "\(self.notificationBaseName).login.failure")

                    expect(externalCollector).toNot(beNil())
                    expect(externalCollector?.isLoggedIn).to(beFalse())
                    expect(tracker?.eventName).to(beNil())
                    expect(tracker?.params).to(beNil())

                    NotificationCenter.default.post(name: notificationName, object: params)

                    expect(externalCollector?.isLoggedIn).toEventually(beFalse())
                    expect(tracker?.eventName).toEventually(equal(AnalyticsManager.Event.Name.loginFailure))
                    expect(tracker?.params?["rae_error"] as? String).toEventually(equal(params["rae_error"]))
                    expect(tracker?.params?["rae_error_message"] as? String).toEventually(equal(params["rae_error_message"]))
                    expect(tracker?.params?["type"] as? String).toEventually(equal(params["type"]))
                }
            }
            describe("receiveLogoutNotification") {
                it("should track AnalyticsManager.Event.Name.logout when a logout notification is received") {
                    let tracker = (dependenciesFactory.tracker as? AnalyticsTrackerMock)
                    let trackingIdentifier = "trackingIdentifier"
                    let logoutMethods = ["local", "global"]

                    logoutMethods.forEach {
                        let externalCollector = RAnalyticsExternalCollector(dependenciesFactory: dependenciesFactory)
                        let notificationName = NSNotification.Name(rawValue: "\(self.notificationBaseName).logout.\($0)")

                        expect(externalCollector).toNot(beNil())
                        expect(externalCollector?.trackingIdentifier).to(beNil())
                        expect(externalCollector?.isLoggedIn).to(beFalse())
                        expect(tracker?.eventName).to(beNil())
                        expect(tracker?.params).to(beNil())

                        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "\(self.notificationBaseName).login.other"),
                                                        object: trackingIdentifier)

                        expect(externalCollector?.isLoggedIn).toEventually(beTrue())
                        expect(externalCollector?.trackingIdentifier).toEventually(equal(trackingIdentifier))
                        tracker?.reset()

                        NotificationCenter.default.post(name: notificationName, object: nil)

                        expect(externalCollector?.isLoggedIn).toEventually(beFalse())
                        expect(externalCollector?.trackingIdentifier).toEventually(beNil())
                        expect(tracker?.eventName).toEventually(equal(AnalyticsManager.Event.Name.logout))
                        expect(tracker?.params?[AnalyticsManager.Event.Parameter.logoutMethod] as? String).toEventually(equal($0))
                        tracker?.reset()
                    }
                }
            }
            describe("receiveDiscoverNotification") {
                it("should track a discover event when a discover notification is received") {
                    let tracker = (dependenciesFactory.tracker as? AnalyticsTrackerMock)
                    let mapping = ["visitPreview": NSNotification.discoverPreviewVisit,
                                   "tapShowMore": NSNotification.discoverPreviewShowMore,
                                   "visitPage": NSNotification.discoverPageVisit]

                    mapping.forEach {
                        let externalCollector = RAnalyticsExternalCollector(dependenciesFactory: dependenciesFactory)
                        let notificationName = NSNotification.Name(rawValue: "\(self.notificationBaseName).discover.\($0.key)")

                        expect(externalCollector).toNot(beNil())
                        expect(tracker?.eventName).to(beNil())
                        expect(tracker?.params).to(beNil())

                        NotificationCenter.default.post(name: notificationName, object: nil)

                        expect(tracker?.eventName).toEventually(equal(mapping[$0.key]?.rawValue))
                        expect(tracker?.params).toEventually(beNil())
                        tracker?.reset()
                    }
                }
                it("should track a discover event with the correct identifier when a discover notification is received with an identifier") {
                    let tracker = (dependenciesFactory.tracker as? AnalyticsTrackerMock)
                    let identifier = "12345"
                    let mapping = ["tapPreview": NSNotification.discoverPreviewTap,
                                   "tapPage": NSNotification.discoverPageTap]

                    mapping.forEach {
                        let externalCollector = RAnalyticsExternalCollector(dependenciesFactory: dependenciesFactory)
                        let notificationName = NSNotification.Name(rawValue: "\(self.notificationBaseName).discover.\($0.key)")

                        expect(externalCollector).toNot(beNil())
                        expect(tracker?.eventName).to(beNil())
                        expect(tracker?.params).to(beNil())

                        NotificationCenter.default.post(name: notificationName, object: identifier)

                        expect(tracker?.eventName).toEventually(equal(mapping[$0.key]?.rawValue))
                        expect(tracker?.params?["prApp"] as? String).toEventually(equal(identifier))
                        tracker?.reset()
                    }
                }
                it("should track a discover event with correct parameters when a discover notification is received with an identifier and url") {
                    let tracker = (dependenciesFactory.tracker as? AnalyticsTrackerMock)
                    let identifier = "12345"
                    let urlString = "http://www.rakuten.co.jp"
                    let mapping = ["redirectPreview": NSNotification.discoverPreviewRedirect,
                                   "redirectPage": NSNotification.discoverPageRedirect]

                    mapping.forEach {
                        let externalCollector = RAnalyticsExternalCollector(dependenciesFactory: dependenciesFactory)
                        let notificationName = NSNotification.Name(rawValue: "\(self.notificationBaseName).discover.\($0.key)")

                        expect(externalCollector).toNot(beNil())
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
                    let tracker = (dependenciesFactory.tracker as? AnalyticsTrackerMock)
                    let UIViewControllerType = UIViewController.self
                    let ssodialogParams = ["help", "privacypolicy", "forgotpassword", "register"]

                    ssodialogParams.forEach {
                        let externalCollector = RAnalyticsExternalCollector(dependenciesFactory: dependenciesFactory)
                        let notificationName = NSNotification.Name(rawValue: "\(self.notificationBaseName).ssodialog")

                        expect(externalCollector).toNot(beNil())
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
                    let tracker = (dependenciesFactory.tracker as? AnalyticsTrackerMock)
                    let mapping = ["ssocredentialfound": AnalyticsManager.Event.Name.SSOCredentialFound,
                                   "logincredentialfound": AnalyticsManager.Event.Name.loginCredentialFound]

                    mapping.forEach {
                        let externalCollector = RAnalyticsExternalCollector(dependenciesFactory: dependenciesFactory)
                        let notificationName = NSNotification.Name(rawValue: "\(self.notificationBaseName).\($0.key)")

                        expect(externalCollector).toNot(beNil())
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
                    let tracker = (dependenciesFactory.tracker as? AnalyticsTrackerMock)
                    let params: [String: Any] = ["eventName": "blah",
                                                 "eventData": ["foo": "bar"]]
                    let externalCollector = RAnalyticsExternalCollector(dependenciesFactory: dependenciesFactory)
                    let notificationName = NSNotification.Name(rawValue: "\(self.notificationBaseName).custom")

                    expect(externalCollector).toNot(beNil())
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
