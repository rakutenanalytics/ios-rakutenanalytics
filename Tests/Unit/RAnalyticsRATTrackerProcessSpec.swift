// swiftlint:disable line_length
// swiftlint:disable type_body_length
// swiftlint:disable function_body_length

import Quick
import Nimble
import SQLite3
import Foundation
@testable import RAnalytics
#if canImport(RAnalyticsTestHelpers)
import RAnalyticsTestHelpers
#endif

// MARK: - RAnalyticsRATTrackerProcessSpec

class RAnalyticsRATTrackerProcessSpec: QuickSpec {
    override func spec() {
        describe("RAnalyticsRATTracker") {
            let expecter = RAnalyticsRATExpecter()
            var databaseConnection: SQlite3Pointer!
            let dependenciesContainer = SimpleContainerMock()
            var ratTracker: RAnalyticsRATTracker!

            beforeEach {
                let databaseTableName = "testTableName_RAnalyticsRATTrackerSpec"
                databaseConnection = DatabaseTestUtils.openRegularConnection()!
                let database = DatabaseTestUtils.mkDatabase(connection: databaseConnection)

                let bundle = BundleMock()
                bundle.accountIdentifier = 777
                bundle.applicationIdentifier = 888
                bundle.mutableEndpointAddress = URL(string: "https://endpoint.co.jp/")!

                dependenciesContainer.bundle = bundle
                dependenciesContainer.databaseConfiguration = DatabaseConfiguration(database: database, tableName: databaseTableName)
                dependenciesContainer.session = SwityURLSessionMock()
                dependenciesContainer.deviceCapability = DeviceMock()
                dependenciesContainer.telephonyNetworkInfoHandler = TelephonyNetworkInfoMock()
                dependenciesContainer.analyticsStatusBarOrientationGetter = ApplicationMock(.portrait)

                ratTracker = RAnalyticsRATTracker(dependenciesContainer: dependenciesContainer)
                ratTracker.set(batchingDelay: 0)

                expecter.dependenciesContainer = dependenciesContainer
                expecter.endpointURL = dependenciesContainer.bundle.endpointAddress
                expecter.databaseTableName = dependenciesContainer.databaseConfiguration?.tableName
                expecter.databaseConnection = databaseConnection
                expecter.ratTracker = ratTracker
            }

            afterEach {
                DatabaseTestUtils.deleteTableIfExists(dependenciesContainer.databaseConfiguration!.tableName, connection: databaseConnection)
                dependenciesContainer.databaseConfiguration?.database.closeConnection()
                databaseConnection = nil
            }

            describe("process(event:state:)") {
                it("should not process the event if the event name is unknown") {
                    let event = RAnalyticsEvent(name: "", parameters: nil)
                    let processed = ratTracker.process(event: event, state: Tracking.defaultState)
                    expect(processed).to(beFalse())
                }

                it("should process the event if the event name prefix is rat.") {
                    expecter.expectEvent(Tracking.defaultEvent, state: Tracking.defaultState, equal: "defaultEvent")
                }

                it("should process the initialLaunch event") {
                    let event = RAnalyticsEvent(name: RAnalyticsEvent.Name.initialLaunch, parameters: nil)
                    expecter.expectEvent(event, state: Tracking.defaultState, equal: RAnalyticsEvent.Name.initialLaunch)
                }

                it("should process the install event") {
                    let event = RAnalyticsEvent(name: RAnalyticsEvent.Name.install, parameters: nil)
                    var appInfoPayload: String?
                    var sdkInfoPayload: [String: Any]?

                    expecter.expectEvent(event, state: Tracking.defaultState, equal: RAnalyticsEvent.Name.install) {
                        let cp = $0.first?[PayloadParameterKeys.cp] as? [String: Any]
                        appInfoPayload = cp?[RAnalyticsConstants.appInfoKey] as? String

                        sdkInfoPayload = $0.first?[RAnalyticsConstants.sdkDependenciesKey] as? [String: Any]
                    }
                    expect(appInfoPayload).toEventuallyNot(beNil())
                    expect(appInfoPayload?.contains("xcode")).to(beTrue())
                    expect(appInfoPayload?.contains("iphonesimulator")).to(beTrue())

                    expect(sdkInfoPayload).toNot(beNil())
                    expect(sdkInfoPayload?["analytics"] as? String).toNot(beNil())
                }

                it("should process the sessionStart event") {
                    let event = RAnalyticsEvent(name: RAnalyticsEvent.Name.sessionStart, parameters: nil)
                    var cpPayload: [String: Any]?

                    expecter.expectEvent(event, state: Tracking.defaultState, equal: RAnalyticsEvent.Name.sessionStart) {
                        cpPayload = $0.first?[PayloadParameterKeys.cp] as? [String: Any]
                    }
                    expect(cpPayload).toEventuallyNot(beNil())

                    let daysSinceLastUse: Int! = cpPayload?["days_since_last_use"] as? Int
                    let daysSinceFirstUse: Int! = cpPayload?["days_since_first_use"] as? Int
                    expect(daysSinceLastUse).to(beGreaterThanOrEqualTo(0))
                    expect(daysSinceLastUse).to(equal(daysSinceFirstUse - 2))
                }

                it("should process the sessionEnd event") {
                    let event = RAnalyticsEvent(name: RAnalyticsEvent.Name.sessionEnd, parameters: nil)
                    expecter.expectEvent(event, state: Tracking.defaultState, equal: RAnalyticsEvent.Name.sessionEnd)
                }

                it("should process the applicationUpdate event") {
                    let event = RAnalyticsEvent(name: RAnalyticsEvent.Name.applicationUpdate, parameters: nil)
                    var cpPayload: [String: Any]?

                    expecter.expectEvent(event, state: Tracking.defaultState, equal: RAnalyticsEvent.Name.applicationUpdate) {
                        cpPayload = $0.first?[PayloadParameterKeys.cp] as? [String: Any]
                    }
                    expect(cpPayload).toEventuallyNot(beNil())
                    expect(cpPayload?["launches_since_last_upgrade"] as? Int).to(beGreaterThan(0))
                    expect(cpPayload?["days_since_last_upgrade"] as? Int).to(beGreaterThan(0))
                }

                context("Login") {
                    it("should process the login event when the login method is oneTapLogin") {
                        let event = RAnalyticsEvent(name: RAnalyticsEvent.Name.login, parameters: nil)
                        var cpPayload: [String: Any]?

                        let state: RAnalyticsState! = Tracking.defaultState.copy() as? RAnalyticsState
                        state.loginMethod = .oneTapLogin

                        expecter.expectEvent(event, state: state, equal: RAnalyticsEvent.Name.login) {
                            cpPayload = $0.first?[PayloadParameterKeys.cp] as? [String: Any]
                        }
                        expect(cpPayload).toEventuallyNot(beNil())
                        expect(cpPayload?["login_method"] as? String).to(equal(RAnalyticsLoginMethod.oneTapLogin.toString))
                    }

                    it("should process the login event when the login method is passwordInput") {
                        let event = RAnalyticsEvent(name: RAnalyticsEvent.Name.login, parameters: nil)
                        var cpPayload: [String: Any]?

                        let state: RAnalyticsState! = Tracking.defaultState.copy() as? RAnalyticsState
                        state.loginMethod = .passwordInput

                        expecter.expectEvent(event, state: state, equal: RAnalyticsEvent.Name.login) {
                            cpPayload = $0.first?[PayloadParameterKeys.cp] as? [String: Any]
                        }
                        expect(cpPayload).toEventuallyNot(beNil())
                        expect(cpPayload?["login_method"] as? String).to(equal(RAnalyticsLoginMethod.passwordInput.toString))
                    }

                    it("should process the login event with an empty cp when the login method is other") {
                        let event = RAnalyticsEvent(name: RAnalyticsEvent.Name.login, parameters: nil)
                        var cpPayload: [String: Any]?

                        let state: RAnalyticsState! = Tracking.defaultState.copy() as? RAnalyticsState
                        state.loginMethod = .other

                        expecter.expectEvent(event, state: state, equal: RAnalyticsEvent.Name.login) {
                            cpPayload = $0.first?[PayloadParameterKeys.cp] as? [String: Any]
                        }
                        expect(cpPayload).toAfterTimeout(beNil())
                    }
                }

                context("Logout") {
                    it("should process the logout event when the login method is local") {
                        let event = RAnalyticsEvent(name: RAnalyticsEvent.Name.logout,
                                                    parameters: [RAnalyticsEvent.Parameter.logoutMethod: RAnalyticsEvent.LogoutMethod.local])
                        var cpPayload: [String: Any]?

                        expecter.expectEvent(event, state: Tracking.defaultState, equal: RAnalyticsEvent.Name.logout) {
                            cpPayload = $0.first?[PayloadParameterKeys.cp] as? [String: Any]
                        }
                        expect(cpPayload).toEventuallyNot(beNil())
                        expect(cpPayload?["logout_method"] as? String).to(equal(RAnalyticsEvent.LogoutMethod.local.toLogoutString))
                    }

                    it("should process the logout event when the login method is global") {
                        let event = RAnalyticsEvent(name: RAnalyticsEvent.Name.logout,
                                                    parameters: [RAnalyticsEvent.Parameter.logoutMethod: RAnalyticsEvent.LogoutMethod.global])
                        var cpPayload: [String: Any]?

                        expecter.expectEvent(event, state: Tracking.defaultState, equal: RAnalyticsEvent.Name.logout) {
                            cpPayload = $0.first?[PayloadParameterKeys.cp] as? [String: Any]
                        }
                        expect(cpPayload).toEventuallyNot(beNil())
                        expect(cpPayload?["logout_method"] as? String).to(equal(RAnalyticsEvent.LogoutMethod.global.toLogoutString))
                    }

                    it("should process the logout event with an empty cp when the login method is empty") {
                        let event = RAnalyticsEvent(name: RAnalyticsEvent.Name.logout, parameters: nil)
                        var cpPayload: [String: Any]?

                        expecter.expectEvent(event, state: Tracking.defaultState, equal: RAnalyticsEvent.Name.logout) {
                            cpPayload = $0.first?[PayloadParameterKeys.cp] as? [String: Any]
                        }
                        expect(cpPayload).toEventually(beNil())
                    }
                }

                context("Login Failure") {
                    it("should process the loginFailure event when there is a password login error") {
                        let event = RAnalyticsEvent(name: RAnalyticsEvent.Name.loginFailure,
                                                    parameters: ["type": "password_login", "rae_error": "invalid_grant"])
                        var cpPayload: [String: Any]?

                        expecter.expectEvent(event, state: Tracking.defaultState, equal: RAnalyticsEvent.Name.loginFailure) {
                            cpPayload = $0.first?[PayloadParameterKeys.cp] as? [String: Any]
                        }
                        expect(cpPayload).toEventuallyNot(beNil())
                        expect(cpPayload?["type"] as? String).to(equal("password_login"))
                        expect(cpPayload?["rae_error"] as? String).to(equal("invalid_grant"))
                    }

                    it("should process the loginFailure event when there is a sso login error") {
                        let event = RAnalyticsEvent(name: RAnalyticsEvent.Name.loginFailure,
                                                    parameters: ["type": "sso_login", "rae_error": "invalid_scope"])
                        var cpPayload: [String: Any]?

                        expecter.expectEvent(event, state: Tracking.defaultState, equal: RAnalyticsEvent.Name.loginFailure) {
                            cpPayload = $0.first?[PayloadParameterKeys.cp] as? [String: Any]
                        }
                        expect(cpPayload).toEventuallyNot(beNil())
                        expect(cpPayload?["type"] as? String).to(equal("sso_login"))
                        expect(cpPayload?["rae_error"] as? String).to(equal("invalid_scope"))
                    }

                    it("should process the loginFailure event when there is a IDSDK login error") {
                        let event = RAnalyticsEvent(name: RAnalyticsEvent.Name.loginFailure,
                                                    parameters: ["idsdk_error": "IDSDK Login Error", "idsdk_error_message": "Network Error"])
                        var cpPayload: [String: Any]?

                        expecter.expectEvent(event, state: Tracking.defaultState, equal: RAnalyticsEvent.Name.loginFailure) {
                            cpPayload = $0.first?[PayloadParameterKeys.cp] as? [String: Any]
                        }
                        expect(cpPayload).toEventuallyNot(beNil())
                        expect(cpPayload?["idsdk_error"] as? String).to(equal("IDSDK Login Error"))
                        expect(cpPayload?["idsdk_error_message"] as? String).to(equal("Network Error"))
                    }
                }

                context("Page Visit") {
                    context("The referral tracking is a Visited Page") {
                        it("should process the pageVisit event with an internal ref and pgn equal to the page identifier") {
                            let event = RAnalyticsEvent(name: RAnalyticsEvent.Name.pageVisit, parameters: ["page_id": "TestPage"])
                            var payload: [String: Any]?
                            var cpPayload: [String: Any]?

                            expecter.expectEvent(event, state: Tracking.defaultState, equal: RAnalyticsEvent.Name.pageVisitForRAT) {
                                payload = $0.first
                                cpPayload = $0.first?[PayloadParameterKeys.cp] as? [String: Any]
                            }
                            expect(payload).toEventuallyNot(beNil())
                            expect(cpPayload).toNot(beNil())
                            expect(payload?[PayloadParameterKeys.pgn] as? String).to(equal("TestPage"))
                            expect(cpPayload?[PayloadParameterKeys.refType] as? String).to(equal("internal"))
                        }

                        it("should process the pageVisit event with an internal ref and pgn equal to CustomPage") {
                            let event = RAnalyticsEvent(name: RAnalyticsEvent.Name.pageVisit, parameters: nil)
                            var payload: [String: Any]?
                            var cpPayload: [String: Any]?

                            expecter.expectEvent(event, state: Tracking.defaultState, equal: RAnalyticsEvent.Name.pageVisitForRAT) {
                                payload = $0.first
                                cpPayload = $0.first?[PayloadParameterKeys.cp] as? [String: Any]
                            }
                            expect(payload).toEventuallyNot(beNil())
                            expect(cpPayload).toNot(beNil())
                            expect(payload?[PayloadParameterKeys.pgn] as? String).to(equal(NSStringFromClass(CustomPage.self)))
                            expect(cpPayload?[PayloadParameterKeys.refType] as? String).to(equal("internal"))
                        }

                        it("should process the second pageVisit event with ref equal to the first pageVisit event's page identifier") {
                            let firstPage = "FirstPage"
                            let secondPage = "SecondPage"

                            let firstEvent = RAnalyticsEvent(name: RAnalyticsEvent.Name.pageVisit, parameters: ["page_id": firstPage])
                            let secondEvent = RAnalyticsEvent(name: RAnalyticsEvent.Name.pageVisit, parameters: ["page_id": secondPage])

                            var payload: [String: Any]?

                            ratTracker.process(event: firstEvent, state: Tracking.defaultState)

                            let session = dependenciesContainer.session as? SwityURLSessionMock

                            session?.completion = {
                                let databaseConfiguration: DatabaseConfiguration! = dependenciesContainer.databaseConfiguration as? DatabaseConfiguration
                                let data = DatabaseTestUtils.fetchTableContents(databaseConfiguration.tableName,
                                                                                connection: databaseConnection)[1]
                                payload = try? JSONSerialization.jsonObject(with: data,
                                                                            options: JSONSerialization.ReadingOptions(rawValue: 0)) as? [String: Any]
                            }
                            ratTracker.process(event: secondEvent, state: Tracking.defaultState)

                            expect(payload).toEventuallyNot(beNil())
                            expect((payload)?[PayloadParameterKeys.pgn] as? String).to(equal(secondPage))
                            expect((payload)?[PayloadParameterKeys.ref] as? String).to(equal(firstPage))
                        }

                        it("should process the pageVisit event with an external ref") {
                            let pageId = "TestPage"
                            let event = RAnalyticsEvent(name: RAnalyticsEvent.Name.pageVisit, parameters: ["page_id": pageId])
                            var payload: [String: Any]?
                            var cpPayload: [String: Any]?

                            let state: RAnalyticsState! = Tracking.defaultState.copy() as? RAnalyticsState
                            state.origin = .external

                            expecter.expectEvent(event, state: state, equal: RAnalyticsEvent.Name.pageVisitForRAT) {
                                payload = $0.first
                                cpPayload = $0.first?[PayloadParameterKeys.cp] as? [String: Any]
                            }
                            expect(payload).toEventuallyNot(beNil())
                            expect(cpPayload).toNot(beNil())
                            expect(payload?[PayloadParameterKeys.pgn] as? String).to(equal(pageId))
                            expect(cpPayload?[PayloadParameterKeys.refType] as? String).to(equal("external"))
                        }

                        it("should process the pageVisit event with a push ref") {
                            let pageId = "TestPage"
                            let event = RAnalyticsEvent(name: RAnalyticsEvent.Name.pageVisit, parameters: ["page_id": pageId])
                            var payload: [String: Any]?
                            var cpPayload: [String: Any]?

                            let state: RAnalyticsState! = Tracking.defaultState.copy() as? RAnalyticsState
                            state.origin = .push

                            expecter.expectEvent(event, state: state, equal: RAnalyticsEvent.Name.pageVisitForRAT) {
                                payload = $0.first
                                cpPayload = $0.first?[PayloadParameterKeys.cp] as? [String: Any]
                            }
                            expect(payload).toEventuallyNot(beNil())
                            expect(cpPayload).toNot(beNil())
                            expect(payload?[PayloadParameterKeys.pgn] as? String).to(equal(pageId))
                            expect(cpPayload?[PayloadParameterKeys.refType] as? String).to(equal("push"))
                        }

                    }

                    context("The referral tracking is an App") {
                        it("should process a pageVisit event and a deeplink event") {
                            var payloads = [[String: Any]]()
                            let event = RAnalyticsEvent(name: RAnalyticsEvent.Name.pageVisit, parameters: nil)
                            let state = RAnalyticsState(sessionIdentifier: "sessionIdentifier", deviceIdentifier: "deviceIdentifier")
                            let model = ReferralAppModel(bundleIdentifier: "jp.co.rakuten.app",
                                                         accountIdentifier: 111,
                                                         applicationIdentifier: 222,
                                                         link: "campaignCode",
                                                         component: "news",
                                                         customParameters: ["key1": "value1"])
                            state.referralTracking = .referralApp(model)

                            expecter.expectEvent(event, state: state, equal: RAnalyticsEvent.Name.pageVisitForRAT) {
                                payloads = $0
                            }

                            expect(payloads.isEmpty).toEventually(beFalse())
                            expect(payloads.count).to(equal(2))

                            let payload1 = payloads[0]
                            let cpPayload1 = payload1[PayloadParameterKeys.cp] as? [String: Any]

                            let payload2 = payloads[1]
                            let cpPayload2 = payload2[PayloadParameterKeys.cp] as? [String: Any]

                            expect(payload1[PayloadParameterKeys.etype] as? String).to(equal(RAnalyticsEvent.Name.pageVisitForRAT))
                            expect(payload1[PayloadParameterKeys.acc] as? Int).to(equal(777))
                            expect(payload1[PayloadParameterKeys.aid] as? Int).to(equal(888))
                            expect(payload1[PayloadParameterKeys.ref] as? String).to(equal("jp.co.rakuten.app"))
                            expect(cpPayload1).toNot(beNil())
                            expect(cpPayload1?[PayloadParameterKeys.refType] as? String).to(equal(RAnalyticsOrigin.external.toString))
                            expect(cpPayload1?[PayloadParameterKeys.refLink] as? String).to(equal("campaignCode"))
                            expect(cpPayload1?[PayloadParameterKeys.refComponent] as? String).to(equal("news"))

                            expect(payload2).toNot(beNil())
                            expect(payload2[PayloadParameterKeys.etype] as? String).to(equal(RAnalyticsEvent.Name.deeplink))
                            expect(payload2[PayloadParameterKeys.acc] as? Int).to(equal(111))
                            expect(payload2[PayloadParameterKeys.aid] as? Int).to(equal(222))
                            expect(payload2[PayloadParameterKeys.ref] as? String).to(equal("jp.co.rakuten.app"))
                            expect(cpPayload2).toNot(beNil())
                            expect(cpPayload2?[PayloadParameterKeys.refType] as? String).to(equal(RAnalyticsOrigin.external.toString))
                            expect(cpPayload2?[PayloadParameterKeys.refLink] as? String).to(equal("campaignCode"))
                            expect(cpPayload2?[PayloadParameterKeys.refComponent] as? String).to(equal("news"))
                        }
                    }
                }

                context("The push notification is received") {
                    context("request identifier is nil") {
                        it("should process the _rem_push_received event with a tracking identifier") {
                            let trackingIdentifier = "trackingIdentifier"
                            let event = RAnalyticsEvent(name: RAnalyticsEvent.Name.pushNotificationReceived,
                                                        parameters: [RAnalyticsEvent.Parameter.pushTrackingIdentifier: trackingIdentifier])
                            var payload: [String: Any]?
                            var cpPayload: [String: Any]?

                            expecter.expectEvent(event, state: Tracking.defaultState, equal: RAnalyticsEvent.Name.pushNotificationReceived) {
                                payload = $0.first
                                cpPayload = $0.first?[PayloadParameterKeys.cp] as? [String: Any]
                            }
                            expect(payload).toEventuallyNot(beNil())
                            expect(cpPayload).toNot(beNil())
                            expect(cpPayload?["push_notify_value"] as? String).to(equal(trackingIdentifier))
                            expect(cpPayload?[PayloadParameterKeys.pushRequestIdentifier]).to(beNil())
                        }

                        it("should process the _rem_push_received event with rid") {
                            let event = RAnalyticsEvent(name: RAnalyticsEvent.Name.pushNotificationReceived,
                                                        pushNotificationPayload: ["rid": "123456"])
                            var payload: [String: Any]?
                            var cpPayload: [String: Any]?

                            expecter.expectEvent(event, state: Tracking.defaultState, equal: RAnalyticsEvent.Name.pushNotificationReceived) {
                                payload = $0.first
                                cpPayload = $0.first?[PayloadParameterKeys.cp] as? [String: Any]
                            }
                            expect(payload).toEventuallyNot(beNil())
                            expect(cpPayload).toNot(beNil())
                            expect(cpPayload?["push_notify_value"] as? String).to(equal("rid:123456"))
                            expect(cpPayload?[PayloadParameterKeys.pushRequestIdentifier]).to(beNil())
                        }
                    }

                    context("request identifier is not nil") {
                        it("should process the _rem_push_received event with a tracking identifier and a request identifier") {
                            let trackingIdentifier = "trackingIdentifier"
                            let requestIdentifier = "requestIdentifier"
                            let event = RAnalyticsEvent(name: RAnalyticsEvent.Name.pushNotificationReceived,
                                                        parameters: [RAnalyticsEvent.Parameter.pushTrackingIdentifier: trackingIdentifier,
                                                                     RAnalyticsEvent.Parameter.pushRequestIdentifier: requestIdentifier])
                            var payload: [String: Any]?
                            var cpPayload: [String: Any]?

                            expecter.expectEvent(event, state: Tracking.defaultState, equal: RAnalyticsEvent.Name.pushNotificationReceived) {
                                payload = $0.first
                                cpPayload = $0.first?[PayloadParameterKeys.cp] as? [String: Any]
                            }
                            expect(payload).toEventuallyNot(beNil())
                            expect(cpPayload).toNot(beNil())
                            expect(cpPayload?["push_notify_value"] as? String).to(equal(trackingIdentifier))
                            expect(cpPayload?[PayloadParameterKeys.pushRequestIdentifier] as? String).to(equal(requestIdentifier))
                        }

                        it("should process the _rem_push_received event with rid and a request identifier") {
                            let requestIdentifier = "requestIdentifier"
                            let event = RAnalyticsEvent(name: RAnalyticsEvent.Name.pushNotificationReceived,
                                                        pushNotificationPayload: ["rid": "123456"],
                                                        pushRequestIdentifier: requestIdentifier)

                            var payload: [String: Any]?
                            var cpPayload: [String: Any]?

                            expecter.expectEvent(event, state: Tracking.defaultState, equal: RAnalyticsEvent.Name.pushNotificationReceived) {
                                payload = $0.first
                                cpPayload = $0.first?[PayloadParameterKeys.cp] as? [String: Any]
                            }
                            expect(payload).toEventuallyNot(beNil())
                            expect(cpPayload).toNot(beNil())
                            expect(cpPayload?["push_notify_value"] as? String).to(equal("rid:123456"))
                            expect(cpPayload?[PayloadParameterKeys.pushRequestIdentifier] as? String).to(equal(requestIdentifier))
                        }
                    }
                }

                context("The push notification is opened") {
                    it("should process the _rem_push_notify event with a tracking identifier") {
                        let trackingIdentifier = "trackingIdentifier"
                        let event = RAnalyticsEvent(name: RAnalyticsEvent.Name.pushNotification,
                                                    parameters: [RAnalyticsEvent.Parameter.pushTrackingIdentifier: trackingIdentifier])
                        var payload: [String: Any]?
                        var cpPayload: [String: Any]?

                        expecter.expectEvent(event, state: Tracking.defaultState, equal: RAnalyticsEvent.Name.pushNotification) {
                            payload = $0.first
                            cpPayload = $0.first?[PayloadParameterKeys.cp] as? [String: Any]
                        }
                        expect(payload).toEventuallyNot(beNil())
                        expect(cpPayload).toNot(beNil())
                        expect(cpPayload?["push_notify_value"] as? String).to(equal(trackingIdentifier))
                    }

                    it("should process the _rem_push_notify event with rid") {
                        let event = RAnalyticsEvent(pushNotificationPayload: ["rid": "123456"])
                        var payload: [String: Any]?
                        var cpPayload: [String: Any]?

                        expecter.expectEvent(event, state: Tracking.defaultState, equal: RAnalyticsEvent.Name.pushNotification) {
                            payload = $0.first
                            cpPayload = $0.first?[PayloadParameterKeys.cp] as? [String: Any]
                        }
                        expect(payload).toEventuallyNot(beNil())
                        expect(cpPayload).toNot(beNil())
                        expect(cpPayload?["push_notify_value"] as? String).to(equal("rid:123456"))
                    }
                }

                context("Push conversion event") {
                    it("should not process the _rem_push_cv event when request identifier and conversion action are empty") {
                        let event = RAnalyticsEvent(pushRequestIdentifier: "",
                                                    pushConversionAction: "")
                        var payload: [String: Any]?

                        expecter.processEvent(event, state: Tracking.defaultState) {
                            payload = $0.first
                        }

                        expect(payload).toAfterTimeout(beNil())
                    }

                    it("should not process the _rem_push_cv event when request identifier is empty") {
                        let event = RAnalyticsEvent(pushRequestIdentifier: "",
                                                    pushConversionAction: "pushConversionAction")
                        var payload: [String: Any]?

                        expecter.processEvent(event, state: Tracking.defaultState) {
                            payload = $0.first
                        }

                        expect(payload).toAfterTimeout(beNil())
                    }

                    it("should not process the _rem_push_cv event when conversion action is empty") {
                        let event = RAnalyticsEvent(pushRequestIdentifier: "pushRequestIdentifier",
                                                    pushConversionAction: "")
                        var payload: [String: Any]?

                        expecter.processEvent(event, state: Tracking.defaultState) {
                            payload = $0.first
                        }

                        expect(payload).toAfterTimeout(beNil())
                    }

                    it("should process the _rem_push_cv event when request identifier and conversion action are not empty") {
                        let event = RAnalyticsEvent(pushRequestIdentifier: "pushRequestIdentifier",
                                                    pushConversionAction: "pushConversionAction")
                        var payload: [String: Any]?
                        var cpPayload: [String: Any]?

                        expecter.expectEvent(event, state: Tracking.defaultState, equal: RAnalyticsEvent.Name.pushNotificationConversion) {
                            payload = $0.first
                            cpPayload = $0.first?[PayloadParameterKeys.cp] as? [String: Any]
                        }
                        expect(payload).toEventuallyNot(beNil())
                        expect(cpPayload).toNot(beNil())
                        expect(cpPayload?[PayloadParameterKeys.pushRequestIdentifier] as? String).to(equal("pushRequestIdentifier"))
                        expect(cpPayload?[PayloadParameterKeys.pushConversionAction] as? String).to(equal("pushConversionAction"))
                    }
                }

                context("PNP events") {
                    context("Push auto registration event") {
                        verify(RAnalyticsEvent.Name.pushAutoRegistration)
                    }

                    context("Push auto unregistration event") {
                        verify(RAnalyticsEvent.Name.pushAutoUnregistration)
                    }

                    func verify(_ eventName: String) {
                        it("should not process the \(eventName) event when parameters is nil") {
                            let event = RAnalyticsEvent(name: eventName,
                                                        parameters: nil)
                            var payload: [String: Any]?

                            expecter.processEvent(event, state: Tracking.defaultState) {
                                payload = $0.first
                            }

                            expect(payload).toAfterTimeout(beNil())
                        }

                        it("should not process the \(eventName) event when parameters is empty") {
                            let event = RAnalyticsEvent(name: eventName,
                                                        parameters: [:])
                            var payload: [String: Any]?

                            expecter.processEvent(event, state: Tracking.defaultState) {
                                payload = $0.first
                            }

                            expect(payload).toAfterTimeout(beNil())
                        }

                        it("should not process the \(eventName) event when pnpClientId parameter is missing") {
                            let event = RAnalyticsEvent(name: eventName,
                                                        parameters: [PayloadParameterKeys.PNP.deviceId: Tracking.deviceToken])
                            var payload: [String: Any]?

                            expecter.processEvent(event, state: Tracking.defaultState) {
                                payload = $0.first
                            }

                            expect(payload).toAfterTimeout(beNil())
                        }

                        it("should not process the \(eventName) event when deviceId parameter is missing") {
                            let event = RAnalyticsEvent(name: eventName,
                                                        parameters: [PayloadParameterKeys.PNP.pnpClientId: Tracking.pnpClientIdentifier])
                            var payload: [String: Any]?

                            expecter.processEvent(event, state: Tracking.defaultState) {
                                payload = $0.first
                            }

                            expect(payload).toAfterTimeout(beNil())
                        }

                        it("should not process the \(eventName) event when pnpClientId parameter is empty") {
                            let event = RAnalyticsEvent(name: eventName,
                                                        parameters: [PayloadParameterKeys.PNP.pnpClientId: ""])
                            var payload: [String: Any]?

                            expecter.processEvent(event, state: Tracking.defaultState) {
                                payload = $0.first
                            }

                            expect(payload).toAfterTimeout(beNil())
                        }

                        it("should not process the \(eventName) event when deviceId parameter is empty") {
                            let event = RAnalyticsEvent(name: eventName,
                                                        parameters: [PayloadParameterKeys.PNP.deviceId: ""])
                            var payload: [String: Any]?

                            expecter.processEvent(event, state: Tracking.defaultState) {
                                payload = $0.first
                            }

                            expect(payload).toAfterTimeout(beNil())
                        }

                        it("should process the \(eventName) event when parameters is not nil") {
                            let event = RAnalyticsEvent(name: eventName,
                                                        parameters: [PayloadParameterKeys.PNP.deviceId: Tracking.deviceToken,
                                                                     PayloadParameterKeys.PNP.pnpClientId: Tracking.pnpClientIdentifier])
                            var payload: [String: Any]?
                            var cpPayload: [String: Any]?

                            expecter.processEvent(event, state: Tracking.defaultState) {
                                payload = $0.first
                                cpPayload = $0.first?[PayloadParameterKeys.cp] as? [String: Any]
                            }

                            expect(payload).toEventuallyNot(beNil())
                            expect(cpPayload).toNot(beNil())
                            expect(cpPayload?[PayloadParameterKeys.PNP.deviceId] as? String).to(equal(Tracking.deviceToken))
                            expect(cpPayload?[PayloadParameterKeys.PNP.pnpClientId] as? String).to(equal(Tracking.pnpClientIdentifier))
                        }
                    }
                }

                it("should process the discover event with an app name and a store URL") {
                    let discoverEvent = "_rem_discover_event"
                    let appName = "appName"
                    let storeURL = "storeUrl"
                    let event = RAnalyticsEvent(name: discoverEvent,
                                                parameters: ["prApp": appName, "prStoreUrl": storeURL])
                    var payload: [String: Any]?
                    var cpPayload: [String: Any]?

                    expecter.expectEvent(event, state: Tracking.defaultState, equal: discoverEvent) {
                        payload = $0.first
                        cpPayload = $0.first?[PayloadParameterKeys.cp] as? [String: Any]
                    }
                    expect(payload).toEventuallyNot(beNil())
                    expect(cpPayload).toNot(beNil())

                    let prApp = cpPayload?["prApp"] as? String
                    expect(prApp).to(equal(appName))

                    let prStoreUrl = cpPayload?["prStoreUrl"] as? String
                    expect(prStoreUrl).to(equal(storeURL))
                }

                it("should process the SSOCredentialFound event") {
                    let event = RAnalyticsEvent(name: RAnalyticsEvent.Name.SSOCredentialFound, parameters: ["source": "device"])
                    expecter.expectEvent(event, state: Tracking.defaultState, equal: RAnalyticsEvent.Name.SSOCredentialFound)
                }

                context("LoginCredentialFound") {
                    it("should process the loginCredentialFound event with icloud source") {
                        let event = RAnalyticsEvent(name: RAnalyticsEvent.Name.loginCredentialFound, parameters: ["source": "icloud"])
                        expecter.expectEvent(event, state: Tracking.defaultState, equal: RAnalyticsEvent.Name.loginCredentialFound)
                    }

                    it("should process the loginCredentialFound event with password-manager source") {
                        let event = RAnalyticsEvent(name: RAnalyticsEvent.Name.loginCredentialFound, parameters: ["source": "password-manager"])
                        expecter.expectEvent(event, state: Tracking.defaultState, equal: RAnalyticsEvent.Name.loginCredentialFound)
                    }
                }

                it("should process the credentialStrategies event") {
                    let event = RAnalyticsEvent(name: RAnalyticsEvent.Name.credentialStrategies,
                                                parameters: ["strategies": ["password-manager": "true"]])
                    expecter.expectEvent(event, state: Tracking.defaultState, equal: RAnalyticsEvent.Name.credentialStrategies)
                }

                context("Custom") {
                    it("should process the custom event with eventData parameters") {
                        let event = RAnalyticsEvent(name: RAnalyticsEvent.Name.custom,
                                                    parameters: ["eventName": "etypeName", "eventData": ["foo": "bar"]])
                        var payload: [String: Any]?
                        var cpPayload: [String: Any]?

                        expecter.expectEvent(event, state: Tracking.defaultState, equal: "etypeName") {
                            payload = $0.first
                            cpPayload = $0.first?[PayloadParameterKeys.cp] as? [String: Any]
                        }
                        expect(payload).toEventuallyNot(beNil())
                        expect(cpPayload).toNot(beNil())

                        let foo = cpPayload?["foo"] as? String
                        expect(foo).to(equal("bar"))
                    }

                    it("should process the custom event without eventData parameters") {
                        let event = RAnalyticsEvent(name: RAnalyticsEvent.Name.custom,
                                                    parameters: ["eventName": "etypeName"])
                        var payload: [String: Any]?
                        var cpPayload: [String: Any]?

                        expecter.expectEvent(event, state: Tracking.defaultState, equal: "etypeName") {
                            payload = $0.first
                            cpPayload = $0.first?[PayloadParameterKeys.cp] as? [String: Any]
                        }
                        expect(payload).toEventuallyNot(beNil())
                        expect(cpPayload).to(beNil())
                    }

                    it("should not process the custom event without eventName") {
                        let event = RAnalyticsEvent(name: RAnalyticsEvent.Name.custom,
                                                    parameters: ["blah": "name", "eventData": ["foo": "bar"]])
                        expect(ratTracker.process(event: event, state: Tracking.defaultState)).to(beFalse())
                    }

                    it("should process the custom event with customAccNumber") {
                        let event = RAnalyticsEvent(name: RAnalyticsEvent.Name.custom,
                                                    parameters: ["eventName": "etypeName", "customAccNumber": 10])
                        var payload: [String: Any]?

                        expecter.expectEvent(event, state: Tracking.defaultState, equal: "etypeName") {
                            payload = $0.first
                        }
                        expect(payload).toEventuallyNot(beNil())
                        expect(payload?[PayloadParameterKeys.acc] as? NSNumber).to(equal(NSNumber(value: 10)))
                    }

                    for accNumber in [0, -2, 6.33] {
                        it("should process the custom event with deafult account number when customAccNumber is \(accNumber)") {
                            let event = RAnalyticsEvent(name: RAnalyticsEvent.Name.custom,
                                                        parameters: ["eventName": "etypeName", "customAccNumber": accNumber])
                            var payload: [String: Any]?

                            expecter.expectEvent(event, state: Tracking.defaultState, equal: "etypeName") {
                                payload = $0.first
                            }
                            expect(payload).toEventuallyNot(beNil())
                            expect(payload?[PayloadParameterKeys.acc] as? NSNumber).to(equal(NSNumber(value: 777)))
                        }
                    }
                }

                it("should not process an unknown event") {
                    let event = RAnalyticsEvent(name: "unknown", parameters: nil)
                    expect(ratTracker.process(event: event, state: Tracking.defaultState)).to(beFalse())
                }
            }
        }
    }
}
