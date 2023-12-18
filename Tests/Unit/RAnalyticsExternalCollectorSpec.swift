// swiftlint:disable type_body_length
// swiftlint:disable function_body_length

import Quick
import Nimble
import UIKit
@testable import RakutenAnalytics
#if canImport(RAnalyticsTestHelpers)
import RAnalyticsTestHelpers
#endif

// MARK: - RAnalyticsExternalCollectorSpec

final class RAnalyticsExternalCollectorSpec: QuickSpec {
    let notificationBaseName = "com.rakuten.esd.sdk.events"

    override func spec() {
        describe("RAnalyticsExternalCollector") {
            var dependenciesContainer: SimpleContainerMock!
            let raeErrorParams = ["rae_error": "login failure",
                                  "rae_error_message": "login fails",
                                  "type": "login.failure"]
            let idsdkError = NSError(domain: "com.analytics.error",
                                     code: 0,
                                     userInfo: [NSLocalizedDescriptionKey: "login failure", NSLocalizedFailureReasonErrorKey: "login fails"])
            let tracker = AnalyticsTrackerMock()
            var externalCollector: RAnalyticsExternalCollector!

            beforeEach {
                dependenciesContainer = SimpleContainerMock()
                dependenciesContainer.userStorageHandler = UserDefaultsMock([:])
                (dependenciesContainer.userStorageHandler as? UserDefaultsMock)?.dictionary = [:]
                dependenciesContainer.keychainHandler = KeychainHandlerMock()

                externalCollector = RAnalyticsExternalCollector(dependenciesContainer: dependenciesContainer)
                externalCollector.trackerDelegate = tracker
            }

            afterEach {
                tracker.reset()
            }

            describe("init") {
                it("should have the correct default values") {
                    expect(externalCollector.isLoggedIn).to(beFalse())
                    expect(externalCollector.trackingIdentifier).to(beNil())
                    expect(externalCollector.userIdentifier).to(beNil())
                    expect(externalCollector.loginMethod).to(equal(.other))
                }
            }

            describe("userIdentifier") {
                it("should set the expected value") {
                    externalCollector.userIdentifier = "myUserID"
                    expect(externalCollector.userIdentifier).to(equal("myUserID"))
                }

                it("should save the user identifier in the user defaults") {
                    externalCollector.userIdentifier = "myUserID"
                    let value = dependenciesContainer.userStorageHandler.string(forKey: RAnalyticsExternalCollector.Constants.userIdentifierKey)
                    expect(value).to(equal("myUserID"))
                }

                it("should delete the user identifier from the user defaults") {
                    externalCollector.userIdentifier = nil
                    let value = dependenciesContainer.userStorageHandler.string(forKey: RAnalyticsExternalCollector.Constants.userIdentifierKey)
                    expect(value).to(beNil())
                }
            }

            describe("easyIdentifier") {
                context("When the easy identifier is set to a non-nil value") {
                    it("should have the expected value") {
                        externalCollector.easyIdentifier = "myEasyID"

                        expect(externalCollector.easyIdentifier).to(equal("myEasyID"))
                    }

                    it("should save the easy identifier in the keychain") {
                        externalCollector.easyIdentifier = "myEasyID"
                        let value = try? dependenciesContainer.keychainHandler.string(for: RAnalyticsExternalCollector.Constants.easyIdentifierKey)

                        expect(value).to(equal("myEasyID"))
                    }
                }

                context("When the easy identifier is set to nil") {
                    it("should return nil") {
                        externalCollector.easyIdentifier = nil

                        expect(externalCollector.easyIdentifier).to(beNil())
                    }

                    it("should delete the easy identifier from the keychain") {
                        externalCollector.easyIdentifier = nil
                        let value = try? dependenciesContainer.keychainHandler.string(for: RAnalyticsExternalCollector.Constants.easyIdentifierKey)

                        expect(value).to(beNil())
                    }
                }

                context("When an easy identifier is already stored in the user defaults") {
                    it("should return an expected easy identifier value") {
                        dependenciesContainer.userStorageHandler.set(value: "myEasyID",
                                                                     forKey: RAnalyticsExternalCollector.Constants.easyIdentifierKey)

                        let externalCollector = RAnalyticsExternalCollector(dependenciesContainer: dependenciesContainer)

                        expect(externalCollector.easyIdentifier).to(equal("myEasyID"))
                    }

                    it("should save the easy identifier to the keychain") {
                        dependenciesContainer.userStorageHandler.set(value: "myEasyID",
                                                                     forKey: RAnalyticsExternalCollector.Constants.easyIdentifierKey)

                        _ = RAnalyticsExternalCollector(dependenciesContainer: dependenciesContainer)

                        let value = try? dependenciesContainer.keychainHandler.string(for: RAnalyticsExternalCollector.Constants.easyIdentifierKey)

                        expect(value).to(equal("myEasyID"))
                    }
                }

                context("When an easy identifier is not stored in the user defaults") {
                    it("should return a nil value") {
                        dependenciesContainer.userStorageHandler.set(value: nil, forKey: RAnalyticsExternalCollector.Constants.easyIdentifierKey)

                        let externalCollector = RAnalyticsExternalCollector(dependenciesContainer: dependenciesContainer)

                        expect(externalCollector.easyIdentifier).to(beNil())
                    }

                    it("should not save the easy identifier to the keychain") {
                        dependenciesContainer.userStorageHandler.set(value: nil, forKey: RAnalyticsExternalCollector.Constants.easyIdentifierKey)

                        _ = RAnalyticsExternalCollector(dependenciesContainer: dependenciesContainer)

                        let value = try? dependenciesContainer.keychainHandler.string(for: RAnalyticsExternalCollector.Constants.easyIdentifierKey)

                        expect(value).to(beNil())
                    }
                }
            }

            describe("trackLogin()") {
                context("RAE Login succeeds") {
                    it("should set trackingIdentifier to userIdentifier") {
                        externalCollector.trackLogin(.userIdentifier("userIdentifier"))

                        expect(externalCollector.trackingIdentifier).to(equal("userIdentifier"))
                    }

                    it("should set isLoggedIn to true") {
                        externalCollector.trackLogin(.userIdentifier("userIdentifier"))

                        expect(externalCollector.isLoggedIn).to(beTrue())
                    }

                    it("should track AnalyticsManager.Event.Name.login with no parameters") {
                        externalCollector.trackLogin(.userIdentifier("userIdentifier"))

                        expect(tracker.eventName).to(equal(AnalyticsManager.Event.Name.login))
                        expect(tracker.params).to(beNil())
                    }
                }

                context("IDSDK Login succeeds") {
                    it("should set easyIdentifier to idsdkIdentifier") {
                        externalCollector.trackLogin(.easyIdentifier("idsdkIdentifier"))

                        expect(externalCollector.easyIdentifier).to(equal("idsdkIdentifier"))
                    }

                    it("should set isLoggedIn to true") {
                        externalCollector.trackLogin(.easyIdentifier("idsdkIdentifier"))

                        expect(externalCollector.isLoggedIn).to(beTrue())
                    }

                    it("should track AnalyticsManager.Event.Name.login with no parameters") {
                        externalCollector.trackLogin(.easyIdentifier("idsdkIdentifier"))

                        expect(tracker.eventName).to(equal(AnalyticsManager.Event.Name.login))
                        expect(tracker.params).to(beNil())
                    }
                }
            }

            describe("trackLoginFailure()") {
                context("RAE Login fails") {
                    it("should set trackingIdentifier to nil") {
                        externalCollector.trackLoginFailure(.userIdentifier(dictionary: raeErrorParams))

                        expect(externalCollector.trackingIdentifier).to(beNil())
                    }

                    it("should set isLoggedIn to false") {
                        externalCollector.trackLoginFailure(.userIdentifier(dictionary: raeErrorParams))

                        expect(externalCollector.isLoggedIn).to(beFalse())
                    }

                    it("should track AnalyticsManager.Event.Name.loginFailure with parameters") {
                        externalCollector.trackLoginFailure(.userIdentifier(dictionary: raeErrorParams))

                        expect(tracker.eventName).to(equal(AnalyticsManager.Event.Name.loginFailure))
                        expect(tracker.params?["rae_error"] as? String).to(equal(raeErrorParams["rae_error"]))
                        expect(tracker.params?["rae_error_message"] as? String).to(equal(raeErrorParams["rae_error_message"]))
                        expect(tracker.params?["type"] as? String).to(equal(raeErrorParams["type"]))
                    }
                }

                context("IDSDK Login fails") {
                    it("should set easyIdentifier to nil") {
                        externalCollector.trackLoginFailure(.easyIdentifier(error: idsdkError))

                        expect(externalCollector.easyIdentifier).to(beNil())
                    }

                    it("should set isLoggedIn to false") {
                        externalCollector.trackLoginFailure(.easyIdentifier(error: idsdkError))

                        expect(externalCollector.isLoggedIn).to(beFalse())
                    }

                    it("should track AnalyticsManager.Event.Name.loginFailure with parameters") {
                        externalCollector.trackLoginFailure(.easyIdentifier(error: idsdkError))

                        expect(tracker.eventName).to(equal(AnalyticsManager.Event.Name.loginFailure))
                        expect(tracker.params?["idsdk_error"] as? String).to(equal(idsdkError.localizedDescription))
                        expect(tracker.params?["idsdk_error_message"] as? String).to(equal(idsdkError.localizedFailureReason))
                    }
                }
            }

            describe("trackLogout()") {
                context("RAE Logout") {
                    it("should set trackingIdentifier to nil") {
                        externalCollector.trackLogout()

                        expect(externalCollector.trackingIdentifier).to(beNil())
                    }

                    it("should set isLoggedIn to false") {
                        externalCollector.trackLogout()

                        expect(externalCollector.isLoggedIn).to(beFalse())
                    }

                    it("should track AnalyticsManager.Event.Name.logout with no parameters") {
                        externalCollector.trackLogout()

                        expect(tracker.eventName).to(equal(AnalyticsManager.Event.Name.logout))
                        expect(tracker.params as? [String: AnyHashable]).to(equal([:]))
                    }
                }

                context("IDSDK Logout") {
                    it("should set easyIdentifier to nil") {
                        externalCollector.trackLogout()

                        expect(externalCollector.easyIdentifier).to(beNil())
                    }

                    it("should set isLoggedIn to false") {
                        externalCollector.trackLogout()

                        expect(externalCollector.isLoggedIn).to(beFalse())
                    }

                    it("should track AnalyticsManager.Event.Name.logout with no parameters") {
                        externalCollector.trackLogout()

                        expect(tracker.eventName).to(equal(AnalyticsManager.Event.Name.logout))
                        expect(tracker.params as? [String: AnyHashable]).to(equal([:]))
                    }
                }
            }

            describe("receiveLoginNotification") {
                context("login methods are password and one_tap") {
                    it("should track AnalyticsManager.Event.Name.login when a login notification is received with a trackingIdentifier") {
                        let trackingIdentifier = "trackingIdentifier"
                        let loginMethods = ["password", "one_tap"]

                        loginMethods.forEach {
                            (dependenciesContainer.userStorageHandler as? UserDefaultsMock)?.dictionary = [:]

                            let externalCollector = RAnalyticsExternalCollector(dependenciesContainer: dependenciesContainer)
                            let notificationName = Notification.Name(rawValue: "\(self.notificationBaseName).login.\($0)")
                            expect(externalCollector.trackingIdentifier).to(beNil())
                            expect(externalCollector.loginMethod).to(equal(.other))
                            expect(externalCollector.isLoggedIn).to(beFalse())
                            expect(tracker.eventName).to(beNil())
                            expect(tracker.params).to(beNil())

                            NotificationCenter.default.post(name: notificationName, object: trackingIdentifier)

                            expect(externalCollector.trackingIdentifier).toEventually(equal(trackingIdentifier))

                            switch $0 {
                            case "password": expect(externalCollector.loginMethod).toEventually(equal(.passwordInput))
                            case "one_tap": expect(externalCollector.loginMethod).toEventually(equal(.oneTapLogin))
                            default: ()
                            }

                            expect(externalCollector.isLoggedIn).toEventually(beTrue())
                            expect(tracker.eventName).toEventually(equal(AnalyticsManager.Event.Name.login))
                            expect(tracker.params).to(beNil())
                            tracker.reset()
                        }
                    }
                }
                context("login method is other") {
                    it("should track AnalyticsManager.Event.Name.login when a login notification is received") {
                        let trackingIdentifier = "trackingIdentifier"
                        let notificationName = Notification.Name(rawValue: "\(self.notificationBaseName).login.other")

                        expect(externalCollector.trackingIdentifier).to(beNil())
                        expect(externalCollector.loginMethod).to(equal(.other))
                        expect(externalCollector.isLoggedIn).to(beFalse())
                        expect(tracker.eventName).to(beNil())
                        expect(tracker.params).to(beNil())

                        let passwordNotificationName = Notification.Name(rawValue: "\(self.notificationBaseName).login.password")
                        NotificationCenter.default.post(name: passwordNotificationName, object: trackingIdentifier)

                        expect(externalCollector.loginMethod).toEventually(equal(.passwordInput))
                        tracker.reset()

                        NotificationCenter.default.post(name: notificationName, object: trackingIdentifier)

                        expect(externalCollector.trackingIdentifier).toEventually(equal(trackingIdentifier))
                        expect(externalCollector.loginMethod).to(equal(.other))
                        expect(externalCollector.isLoggedIn).to(beTrue())
                        expect(tracker.eventName).toEventually(equal(AnalyticsManager.Event.Name.login))
                        expect(tracker.params).to(beNil())
                        tracker.reset()
                    }

                    it("should track AnalyticsManager.Event.Name.login when an IDSDK login notification is received") {
                        let easyIdentifier = "easyIdentifier"
                        let notificationName = Notification.Name(rawValue: "\(self.notificationBaseName).login.idtoken_memberid")

                        expect(externalCollector.easyIdentifier).to(beNil())
                        expect(externalCollector.loginMethod).to(equal(.other))
                        expect(externalCollector.isLoggedIn).to(beFalse())
                        expect(tracker.eventName).to(beNil())
                        expect(tracker.params).to(beNil())

                        let passwordNotificationName = Notification.Name(rawValue: "\(self.notificationBaseName).login.password")
                        NotificationCenter.default.post(name: passwordNotificationName, object: easyIdentifier)

                        expect(externalCollector.loginMethod).toEventually(equal(.passwordInput))
                        tracker.reset()

                        NotificationCenter.default.post(name: notificationName, object: easyIdentifier)

                        expect(externalCollector.easyIdentifier).toEventually(equal(easyIdentifier))
                        expect(externalCollector.loginMethod).to(equal(.other))
                        expect(externalCollector.isLoggedIn).to(beTrue())
                        expect(tracker.eventName).toEventually(equal(AnalyticsManager.Event.Name.login))
                        expect(tracker.params).to(beNil())
                        tracker.reset()
                    }
                }
            }
            describe("receiveLoginFailureNotification") {
                it("should track AnalyticsManager.Event.Name.loginFailure when a login failure notification is received") {
                    let notificationNames = ["\(self.notificationBaseName).login.failure",
                                             "\(self.notificationBaseName).login.failure.idtoken_memberid"]

                    notificationNames.forEach { notificationName in
                        expect(externalCollector.isLoggedIn).to(beFalse())
                        expect(tracker.eventName).to(beNil())
                        expect(tracker.params).to(beNil())

                        switch notificationName {
                        case "\(self.notificationBaseName).login.failure":
                            NotificationCenter.default.post(name: Notification.Name(rawValue: notificationName), object: raeErrorParams)

                        case "\(self.notificationBaseName).login.failure.idtoken_memberid":
                            NotificationCenter.default.post(name: Notification.Name(rawValue: notificationName), object: idsdkError)

                        default:
                            assertionFailure("Unexpected login failure case.")
                        }

                        expect(externalCollector.isLoggedIn).toAfterTimeout(beFalse())
                        expect(tracker.eventName).toEventually(equal(AnalyticsManager.Event.Name.loginFailure))

                        switch notificationName {
                        case "\(self.notificationBaseName).login.failure":
                            expect(tracker.params?["rae_error"] as? String).toEventually(equal(raeErrorParams["rae_error"]))
                            expect(tracker.params?["rae_error_message"] as? String).toEventually(equal(raeErrorParams["rae_error_message"]))
                            expect(tracker.params?["type"] as? String).toEventually(equal(raeErrorParams["type"]))

                        case "\(self.notificationBaseName).login.failure.idtoken_memberid":
                            expect(tracker.params?["idsdk_error"] as? String).toEventually(equal(idsdkError.localizedDescription))
                            expect(tracker.params?["idsdk_error_message"] as? String).toEventually(equal(idsdkError.localizedFailureReason))

                        default:
                            assertionFailure("Unexpected login failure case.")
                        }

                        tracker.reset()
                    }
                }
            }
            describe("receiveLogoutNotification") {
                it("should track AnalyticsManager.Event.Name.logout when a logout notification is received") {
                    let trackingIdentifier = "trackingIdentifier"
                    let logoutMethods = ["local", "global", "idtoken_memberid"]

                    logoutMethods.forEach {
                        let externalCollector = RAnalyticsExternalCollector(dependenciesContainer: dependenciesContainer)
                        let notificationName = Notification.Name(rawValue: "\(self.notificationBaseName).logout.\($0)")

                        expect(externalCollector.trackingIdentifier).to(beNil())
                        expect(externalCollector.easyIdentifier).to(beNil())
                        expect(externalCollector.isLoggedIn).to(beFalse())
                        expect(tracker.eventName).to(beNil())
                        expect(tracker.params).to(beNil())

                        NotificationCenter.default.post(name: Notification.Name(rawValue: "\(self.notificationBaseName).login.other"),
                                                        object: trackingIdentifier)

                        expect(externalCollector.isLoggedIn).toEventually(beTrue())
                        expect(externalCollector.trackingIdentifier).toEventually(equal(trackingIdentifier))
                        tracker.reset()

                        NotificationCenter.default.post(name: notificationName, object: nil)

                        expect(externalCollector.trackingIdentifier).toAfterTimeout(beNil())
                        expect(externalCollector.easyIdentifier).to(beNil())
                        expect(externalCollector.isLoggedIn).to(beFalse())
                        expect(tracker.eventName).toEventually(equal(AnalyticsManager.Event.Name.logout))

                        if $0 == "local" || $0 == "global" {
                            expect(tracker.params?[AnalyticsManager.Event.Parameter.logoutMethod] as? String).toEventually(equal($0))

                        } else {
                            expect(tracker.params?[AnalyticsManager.Event.Parameter.logoutMethod] as? String).toAfterTimeout(beNil())
                        }

                        tracker.reset()
                    }
                }
            }
            describe("receiveDiscoverNotification") {
                it("should track a discover event when a discover notification is received") {
                    let mapping = ["visitPreview": NSNotification.discoverPreviewVisit,
                                   "tapShowMore": NSNotification.discoverPreviewShowMore,
                                   "visitPage": NSNotification.discoverPageVisit]

                    mapping.forEach {
                        let externalCollector = RAnalyticsExternalCollector(dependenciesContainer: dependenciesContainer)
                        expect(externalCollector.isLoggedIn).to(beFalse())

                        let notificationName = Notification.Name(rawValue: "\(self.notificationBaseName).discover.\($0.key)")

                        expect(tracker.eventName).to(beNil())
                        expect(tracker.params).to(beNil())

                        NotificationCenter.default.post(name: notificationName, object: nil)

                        expect(tracker.eventName).toEventually(equal(mapping[$0.key]?.rawValue))
                        expect(tracker.params).toEventually(beNil())
                        tracker.reset()
                    }
                }
                it("should track a discover event with the correct identifier when a discover notification is received with an identifier") {
                    let identifier = "12345"
                    let mapping = ["tapPreview": NSNotification.discoverPreviewTap,
                                   "tapPage": NSNotification.discoverPageTap]

                    mapping.forEach {
                        let externalCollector = RAnalyticsExternalCollector(dependenciesContainer: dependenciesContainer)
                        expect(externalCollector.isLoggedIn).to(beFalse())

                        let notificationName = Notification.Name(rawValue: "\(self.notificationBaseName).discover.\($0.key)")

                        expect(tracker.eventName).to(beNil())
                        expect(tracker.params).to(beNil())

                        NotificationCenter.default.post(name: notificationName, object: identifier)

                        expect(tracker.eventName).toEventually(equal(mapping[$0.key]?.rawValue))
                        expect(tracker.params?["prApp"] as? String).toEventually(equal(identifier))
                        tracker.reset()
                    }
                }
                it("should track a discover event with correct parameters when a discover notification is received with an identifier and url") {
                    let identifier = "12345"
                    let urlString = "http://www.rakuten.co.jp"
                    let mapping = ["redirectPreview": NSNotification.discoverPreviewRedirect,
                                   "redirectPage": NSNotification.discoverPageRedirect]

                    mapping.forEach {
                        let externalCollector = RAnalyticsExternalCollector(dependenciesContainer: dependenciesContainer)
                        expect(externalCollector.isLoggedIn).to(beFalse())

                        let notificationName = Notification.Name(rawValue: "\(self.notificationBaseName).discover.\($0.key)")

                        expect(tracker.eventName).to(beNil())
                        expect(tracker.params).to(beNil())

                        NotificationCenter.default.post(name: notificationName, object: ["identifier": identifier, "url": urlString])

                        expect(tracker.eventName).toEventually(equal(mapping[$0.key]?.rawValue))
                        expect(tracker.params?["prApp"] as? String).toEventually(equal(identifier))
                        expect(tracker.params?["prStoreUrl"] as? String).toEventually(equal(urlString))
                        tracker.reset()
                    }
                }
            }
            describe("receiveSSODialogNotification") {
                it("should track AnalyticsManager.Event.Name.pageVisit when a ssodialog notification is received") {
                    let uiViewControllerType = UIViewController.self
                    let ssodialogParams = ["help", "privacypolicy", "forgotpassword", "register"]

                    ssodialogParams.forEach {
                        let externalCollector = RAnalyticsExternalCollector(dependenciesContainer: dependenciesContainer)
                        expect(externalCollector.isLoggedIn).to(beFalse())

                        let notificationName = Notification.Name(rawValue: "\(self.notificationBaseName).ssodialog")

                        expect(tracker.eventName).to(beNil())
                        expect(tracker.params).to(beNil())

                        NotificationCenter.default.post(name: notificationName, object: "\(uiViewControllerType)\($0)")

                        expect(tracker.eventName).toEventually(equal(AnalyticsManager.Event.Name.pageVisit))
                        expect(tracker.params?["page_id"] as? String).toEventually(equal("\(uiViewControllerType)\($0)"))
                        tracker.reset()
                    }
                }
            }
            describe("receiveCredentialsNotification") {
                it("should track a credential event when a credential notification is received") {
                    let mapping = ["ssocredentialfound": AnalyticsManager.Event.Name.SSOCredentialFound,
                                   "logincredentialfound": AnalyticsManager.Event.Name.loginCredentialFound]

                    mapping.forEach {
                        let externalCollector = RAnalyticsExternalCollector(dependenciesContainer: dependenciesContainer)
                        expect(externalCollector.isLoggedIn).to(beFalse())

                        let notificationName = Notification.Name(rawValue: "\(self.notificationBaseName).\($0.key)")

                        expect(tracker.eventName).to(beNil())
                        expect(tracker.params).to(beNil())

                        NotificationCenter.default.post(name: notificationName, object: nil)

                        expect(tracker.eventName).toEventually(equal($0.value))
                        expect(tracker.params?.isEmpty).toEventually(beTrue())
                        tracker.reset()
                    }
                }
            }
            describe("receiveCustomEventNotification") {
                it("should track AnalyticsManager.Event.Name.custom when a custom notification is received") {
                    let params: [String: Any] = ["eventName": "blah",
                                                 "eventData": ["foo": "bar"]]
                    expect(externalCollector.isLoggedIn).to(beFalse())

                    let notificationName = Notification.Name(rawValue: "\(self.notificationBaseName).custom")

                    expect(tracker.eventName).to(beNil())
                    expect(tracker.params).to(beNil())

                    NotificationCenter.default.post(name: notificationName, object: params)

                    expect(tracker.eventName).toEventually(equal(AnalyticsManager.Event.Name.custom))
                    expect(tracker.params?["eventName"] as? String).toEventually(equal(params["eventName"] as? String))
                    expect(tracker.params?["eventData"] as? [String: String]).toEventually(equal(params["eventData"] as? [String: String]))
                }
            }
        }
    }
}

// swiftlint:enable type_body_length
// swiftlint:enable function_body_length
